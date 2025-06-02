print("[SWEP] Loaded client-side")

include("shared.lua")

local radiusModes = {
    [1] = { dist = 64, name = "Whisper" },
    [2] = { dist = 192, name = "Normal Voice" },
    [3] = { dist = 448, name = "Yelling" }
}

local currentRadiusMode = 2

net.Receive("Datapad_RadiusMode", function()
    currentRadiusMode = net.ReadUInt(2)
end)

hook.Add("HUDPaint", "DatapadRadiusModeDisplay", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) or wep:GetClass() ~= "weapon_sw_datapad" then return end

    local mode = radiusModes[currentRadiusMode]
    if not mode then return end

    local text = "Mode: " .. mode.name .. " (" .. mode.dist .. " units)"
    local font = "DermaDefaultBold"
    surface.SetFont(font)
    local w, h = surface.GetTextSize(text)
    local x = ScrW() - w - 20
    local y = ScrH() - h - 20

    draw.SimpleText(text, font, x, y, Color(0, 200, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)

surface.CreateFont("Datapad_Headline", {
    font = "Orbitron",
    size = 26,
    weight = 700,
    antialias = true,
    extended = true,
})

surface.CreateFont("Datapad_Text", {
    font = "Roboto Mono",
    size = 18,
    weight = 500,
    antialias = true,
    extended = true,
})

local datapadFrame = nil


net.Receive("Datapad_Open_UI", function()
    local current = net.ReadString()
    local headline = net.ReadString()
    

    local frame = vgui.Create("DFrame")
    frame:SetSize(620, 520)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(true)
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(12, 17, 23))

        surface.SetDrawColor(20, 40, 60, 30)
        for x = 0, w, 20 do
            surface.DrawLine(x, 0, x, h)
        end
        for y = 0, h, 20 do
            surface.DrawLine(0, y, w, y)
        end

        local glowColor = Color(0, 220, 255, 150)
        surface.SetDrawColor(glowColor)
        surface.DrawOutlinedRect(0, 0, w, h)
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4)
    end

    local headlineEntry = vgui.Create("DTextEntry", frame)
    headlineEntry:SetFont("Datapad_Headline")
    headlineEntry:SetTextColor(Color(0, 220, 255))
    headlineEntry:SetDrawBackground(false)
    headlineEntry:SetMultiline(false)
    headlineEntry:SetPos(20, 8)
    headlineEntry:SetSize(frame:GetWide() - 40, 32)
    headlineEntry:SetText(headline or "DATAPAD HEADER")
    headlineEntry.Paint = function(self, w, h)
        self:DrawTextEntryText(Color(0, 220, 255), Color(0, 120, 180), Color(0, 220, 255))
        draw.RoundedBox(0, 0, h - 4, w, 2, Color(0, 220, 255, 180))
    end

    local textEntry = vgui.Create("DTextEntry", frame)
    textEntry:SetMultiline(true)
    textEntry:SetFont("Datapad_Text")
    textEntry:SetTextColor(Color(150, 220, 255))
    textEntry:SetDrawBackground(false)
    textEntry:SetPos(10, 50)
    textEntry:SetSize(frame:GetWide() - 20, frame:GetTall() - 110)
    textEntry:SetText(current or "")
    textEntry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(15, 30, 45))
        self:DrawTextEntryText(Color(150, 220, 255), Color(80, 160, 200), Color(150, 220, 255))
    end

    local btnWidth, btnHeight = 120, 40
    local spacing = 20
    local totalWidth = btnWidth * 2 + spacing
    local btnY = frame:GetTall() - btnHeight - 15

    local saveBtn = vgui.Create("DButton", frame)
    saveBtn:SetText("SAVE")
    saveBtn:SetSize(btnWidth, btnHeight)
    saveBtn:SetPos((frame:GetWide() - totalWidth) / 2, btnY)
    saveBtn:SetTextColor(Color(0, 200, 255))
    saveBtn.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 100, 150, 150))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 180, 255, 180))
        end
    end
    saveBtn.DoClick = function()
        net.Start("Datapad_Save")
        net.WriteString(textEntry:GetValue())
        net.WriteString(headlineEntry:GetValue())
        net.SendToServer()
        frame:Close()
        surface.PlaySound("buttons/button14.wav")
    end

    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetText("CANCEL")
    cancelBtn:SetSize(btnWidth, btnHeight)
    cancelBtn:SetPos((frame:GetWide() - totalWidth) / 2 + btnWidth + spacing, btnY)
    cancelBtn:SetTextColor(Color(0, 200, 255))
    cancelBtn.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 180))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(80, 80, 80, 220))
        end
    end
    cancelBtn.DoClick = function()
        frame:Close()
        surface.PlaySound("buttons/button10.wav")
    end
end)

local shareCooldown = 0

hook.Add("PlayerButtonDown", "Datapad_Share_OnR", function(ply, button)
    if button == KEY_R then
        
        if IsValid(datapadFrame) and datapadFrame:IsVisible() then
            print("[CLIENT] Datapad UI is open; share cancelled")
            return
        end

        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep:GetClass() == "weapon_sw_datapad" then
            print("[CLIENT] Sending share net message")
            net.Start("Datapad_Share")
            net.SendToServer()
        else
            print("[CLIENT] You are not holding the datapad!")
        end
    end
end)





net.Receive("Datapad_ReceiveShared", function()
    local senderName = net.ReadString()
    local headline = net.ReadString()
    local content = net.ReadString()

    print("[CLIENT] Received datapad message from " .. senderName)
    print("Headline: " .. headline)
    print("Content: " .. content)

   
    chat.AddText(Color(0, 200, 255), "[Datapad from " .. senderName .. "]: ",
                 Color(255, 255, 0), headline .. " - " .. content)
end)



