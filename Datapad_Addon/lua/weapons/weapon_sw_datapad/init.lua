print("[SWEP] Loaded server-side")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

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

local datapadData = {}

function SWEP:Initialize()
    self:SetHoldType("slam")
    self.RadiusMode = 2
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.5)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local wep = owner:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == weaponClass then
        net.Start("Datapad_Open_UI")
        net.WriteString(wep.StoredText or "")
        net.WriteString(wep.StoredHeadline or "DATAPAD HEADER")
        net.Send(owner)
    end
end

function SWEP:SecondaryAttack()
    self.RadiusMode = (self.RadiusMode % 3) + 1

    local owner = self:GetOwner()
    if IsValid(owner) and owner:IsPlayer() then
        net.Start("Datapad_RadiusMode")
        net.WriteUInt(self.RadiusMode, 2)
        net.Send(owner)

        local modeNames = { "Whisper", "Normal Voice", "Yelling" }
        owner:ChatPrint("[Datapad] Voice mode set to: " .. modeNames[self.RadiusMode])
    end

    self:SetNextSecondaryFire(CurTime() + 0.3)
end

function SWEP:GetCurrentRadius()
    return radiusModes[self.RadiusMode] or 192
end

net.Receive("Datapad_Save", function(_, ply)
    local text = net.ReadString()
    local headline = net.ReadString()
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == weaponClass then
        wep.StoredText = string.sub(text, 1, 2048)
        wep.StoredHeadline = string.sub(headline, 1, 256)
        datapadData[ply:SteamID()] = {
            text = wep.StoredText,
            headline = wep.StoredHeadline
        }
        print("[SERVER] Saved text and headline for player " .. ply:Nick())
    end
end)

net.Receive("Datapad_Share", function(_, ply)
    print("[SERVER] Received Datapad_Share net message from: " .. ply:Nick())
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= weaponClass then return end

    local radius = wep:GetCurrentRadius()
    local pos = ply:GetPos()
    local headline = wep.StoredHeadline or "Shared Message"
    local content = wep.StoredText or ""

    local receivers = 0

    for _, target in ipairs(player.GetAll()) do
        if target ~= ply and target:GetPos():Distance(pos) <= radius then
            net.Start("Datapad_ReceiveShared")
            net.WriteString(ply:Nick())
            net.WriteString(headline)
            net.WriteString(content)
            net.Send(target)
            receivers = receivers + 1
        end
    end

    print("[SERVER] " .. ply:Nick() .. " shared datapad to " .. receivers .. " nearby player(s) within " .. radius .. " units")
    ply:ChatPrint("[Datapad] Shared with " .. receivers .. " nearby player(s) (" .. radius .. " units)")
end)



hook.Add("PlayerDeath", "Datapad_SaveOnDeath", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == weaponClass then
        datapadData[ply:SteamID()] = {
            text = wep.StoredText or "",
            headline = wep.StoredHeadline or "DATAPAD HEADER"
        }
        print("[SERVER] Saved datapad on death for player " .. ply:Nick())
    end
end)

hook.Add("PlayerSwitchWeapon", "Datapad_RestoreOnSwitch", function(ply, oldWep, newWep)
    if IsValid(newWep) and newWep:GetClass() == weaponClass then
        local data = datapadData[ply:SteamID()]
        if data then
            newWep.StoredText = data.text or ""
            newWep.StoredHeadline = data.headline or "DATAPAD HEADER"
            print("[SERVER] Restored datapad for player " .. ply:Nick() .. " on weapon switch")
        end
    end
end)

function SWEP:Equip(owner)
    local data = datapadData[owner:SteamID()]
    if data then
        self.StoredText = data.text or ""
        self.StoredHeadline = data.headline or "DATAPAD HEADER"
        print("[SERVER] Restored datapad for player " .. owner:Nick() .. " on Equip")
    end
end
