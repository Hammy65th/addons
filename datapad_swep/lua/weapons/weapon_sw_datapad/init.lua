print("[SWEP] Loaded server-side")

AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")


util.AddNetworkString("Datapad_Open_UI")
util.AddNetworkString("Datapad_Save")
util.AddNetworkString("Datapad_RadiusMode")
util.AddNetworkString("Datapad_Share")
util.AddNetworkString("Datapad_ReceiveShared")

local weaponClass = "weapon_sw_datapad"

local radiusModes = {
    [1] = 64,
    [2] = 192,
    [3] = 448
}

-- Only persists during a life (reset on disconnect)
local deathData = {}

function SWEP:Initialize()
    self:SetHoldType("slam")
    self.RadiusMode = 2

    -- Initialize 4 empty pages with default content
    self.Pages = {}
    for i = 1, 4 do
        self.Pages[i] = {
            headline = "DATAPAD HEADER",
            text = ""
        }
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    net.Start("Datapad_Open_UI")
    net.WriteUInt(4, 8)  -- send page count first
    for i = 1, 4 do
        local page = (self.Pages and self.Pages[i]) or { headline = "DATAPAD HEADER", text = "" }
        net.WriteString(page.headline)
        net.WriteString(page.text)
    end
    net.Send(owner)
end


function SWEP:SecondaryAttack()
    self.RadiusMode = (self.RadiusMode % 3) + 1
    self:SetNextSecondaryFire(CurTime() + 0.3)

    local owner = self:GetOwner()
    if IsValid(owner) then
        net.Start("Datapad_RadiusMode")
        net.WriteUInt(self.RadiusMode, 2)
        net.Send(owner)

        local modeNames = { "Whisper", "Normal Voice", "Yelling" }
        owner:ChatPrint("[Datapad] Voice mode set to: " .. modeNames[self.RadiusMode])
    end
end

function SWEP:GetCurrentRadius()
    return radiusModes[self.RadiusMode] or 192
end

-- Receive all 4 pages and update the SWEP
net.Receive("Datapad_Save", function(_, ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= weaponClass then return end

    wep.Pages = {}
    for i = 1, 4 do
        local headline = net.ReadString()
        local text = net.ReadString()
        wep.Pages[i] = {
            headline = string.sub(headline, 1, 256),
            text = string.sub(text, 1, 2048)
        }
    end

    print("[SERVER] Saved 4 pages for " .. ply:Nick())
end)

-- Share a specific page with nearby players
net.Receive("Datapad_Share", function(_, ply)
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= weaponClass then return end

    local pageIndex = net.ReadUInt(8)
    local page = (wep.Pages and wep.Pages[pageIndex]) or { headline = "Shared Message", text = "" }

    local radius = wep:GetCurrentRadius()
    local pos = ply:GetPos()
    local receivers = 0

    for _, target in ipairs(player.GetAll()) do
        if target ~= ply and target:GetPos():Distance(pos) <= radius then
            net.Start("Datapad_ReceiveShared")
            net.WriteString(ply:Nick())
            net.WriteString(page.headline)
            net.WriteString(page.text)
            net.Send(target)
            receivers = receivers + 1
        end
    end

    ply:ChatPrint("[Datapad] Shared page " .. pageIndex .. " with " .. receivers .. " player(s) (" .. radius .. " units)")
    print("[SERVER] " .. ply:Nick() .. " shared page " .. pageIndex .. " to " .. receivers .. " player(s)")
end)

-- Save pages on death
hook.Add("PlayerDeath", "Datapad_SaveOnDeath", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == weaponClass then
        deathData[ply] = {
            Pages = table.Copy(wep.Pages or {})
        }
        print("[SERVER] Saved datapad pages for " .. ply:Nick() .. " on death")
    end
end)

-- Restore pages on weapon switch
hook.Add("PlayerSwitchWeapon", "Datapad_RestoreOnSwitch", function(ply, oldWep, newWep)
    if IsValid(newWep) and newWep:GetClass() == weaponClass then
        local data = deathData[ply]
        if data and data.Pages then
            newWep.Pages = table.Copy(data.Pages)
            print("[SERVER] Restored datapad pages for " .. ply:Nick() .. " on switch")
        end
    end
end)

-- Restore pages on equip
function SWEP:Equip(owner)
    local data = deathData[owner]
    if data and data.Pages then
        self.Pages = table.Copy(data.Pages)
        print("[SERVER] Restored datapad pages for " .. owner:Nick() .. " on Equip")
    end
end

-- Share current page on R key pressed
hook.Add("PlayerButtonDown", "Datapad_ShareOnReload", function(ply, button)
    if button == KEY_R then
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= weaponClass then return end

        -- For simplicity, share page 1 by default (or you can track current page if you want)
        local pageIndex = 1
        local page = (wep.Pages and wep.Pages[pageIndex]) or { headline = "Shared Message", text = "" }
        local radius = wep:GetCurrentRadius()
        local pos = ply:GetPos()
        local receivers = 0

        for _, target in ipairs(player.GetAll()) do
            if target ~= ply and target:GetPos():Distance(pos) <= radius then
                net.Start("Datapad_ReceiveShared")
                net.WriteString(ply:Nick())
                net.WriteString(page.headline)
                net.WriteString(page.text)
                net.Send(target)
                receivers = receivers + 1
            end
        end

        ply:ChatPrint("[Datapad] Shared current page (page " .. pageIndex .. ") with " .. receivers .. " player(s) (" .. radius .. " units)")
        print("[SERVER] " .. ply:Nick() .. " shared page " .. pageIndex .. " to " .. receivers .. " player(s) using R key")
    end
end)
