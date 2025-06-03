include("shared.lua")

surface.CreateFont("Datapad_Headline", {
    font = "Arial",
    size = 24,
    weight = 700,
    antialias = true,
})

surface.CreateFont("Datapad_Text", {
    font = "Arial",
    size = 16,
    weight = 400,
    antialias = true,
})

local lastOpenedPage = 1

net.Receive("Datapad_Open_UI", function()
    local pageCount = net.ReadUInt(8)
    local pages = {}

    for i = 1, pageCount do
        local headline = net.ReadString()
        local text = net.ReadString()
        pages[i] = {
            headline = headline,
            text = text
        }
    end

    local currentPage = lastOpenedPage or 1
    if currentPage > pageCount then currentPage = 1 end

    local frame = vgui.Create("DFrame")
    frame:SetSize(700, 520)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(true)
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(12, 17, 23))
        surface.SetDrawColor(20, 40, 60, 30)
        for x = 0, w, 20 do surface.DrawLine(x, 0, x, h) end
        for y = 0, h, 20 do surface.DrawLine(0, y, w, y) end
        local glowColor = Color(0, 220, 255, 150)
        surface.SetDrawColor(glowColor)
        surface.DrawOutlinedRect(0, 0, w, h)
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4)
    end

    local sidebar = vgui.Create("DPanel", frame)
    sidebar:SetPos(0, 0)
    sidebar:SetSize(80, frame:GetTall())
    sidebar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(12, 17, 23))
        surface.SetDrawColor(20, 40, 60, 30)
        for x = 0, w, 20 do surface.DrawLine(x, 0, x, h) end
        for y = 0, h, 20 do surface.DrawLine(0, y, w, y) end
        surface.SetDrawColor(0, 220, 255, 100)
        surface.DrawLine(w - 1, 0, w - 1, h)
        local outlineColor = Color(0, 220, 255, 150)
        surface.SetDrawColor(outlineColor)
        surface.DrawOutlinedRect(0, 0, w, h)
        surface.DrawOutlinedRect(1, 1, w - 2, h - 2)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4)
    end

    local headlineEntry, textEntry

    local function createPageButton(index, yOffset)
        local btn = vgui.Create("DButton", sidebar)
        btn:SetSize(70, 40)
        btn:SetPos(5, yOffset)
        btn:SetText("Page " .. index)
        btn:SetTextColor(Color(0, 200, 255))
        btn.Paint = function(self, w, h)
            local bg = (currentPage == index) and Color(0, 180, 255, 100) or Color(20, 40, 60, 100)
            draw.RoundedBox(4, 0, 0, w, h, bg)
        end
        btn.DoClick = function()
            if currentPage == index then return end
            pages[currentPage].text = textEntry:GetValue()
            pages[currentPage].headline = headlineEntry:GetValue()
            currentPage = index
            lastOpenedPage = currentPage
            headlineEntry:SetText(pages[currentPage].headline or "")
            textEntry:SetText(pages[currentPage].text or "")
            surface.PlaySound("buttons/button16.wav")
        end
    end

    for i = 1, 4 do
        createPageButton(i, 60 + (i - 1) * 50)
        pages[i] = pages[i] or { headline = "Page " .. i, text = "" }
    end

    headlineEntry = vgui.Create("DTextEntry", frame)
    headlineEntry:SetFont("Datapad_Headline")
    headlineEntry:SetTextColor(Color(0, 220, 255))
    headlineEntry:SetDrawBackground(false)
    headlineEntry:SetMultiline(false)
    headlineEntry:SetPos(90, 8)
    headlineEntry:SetSize(frame:GetWide() - 100, 32)
    headlineEntry:SetText(pages[currentPage].headline or "")
    headlineEntry.Paint = function(self, w, h)
        self:DrawTextEntryText(Color(0, 220, 255), Color(0, 120, 180), Color(0, 220, 255))
        draw.RoundedBox(0, 0, h - 4, w, 2, Color(0, 220, 255, 180))
    end

    textEntry = vgui.Create("DTextEntry", frame)
    textEntry:SetMultiline(true)
    textEntry:SetFont("Datapad_Text")
    textEntry:SetTextColor(Color(150, 220, 255))
    textEntry:SetDrawBackground(false)
    textEntry:SetPos(90, 50)
    textEntry:SetSize(frame:GetWide() - 100, frame:GetTall() - 150) -- Adjusted height for spacing
    textEntry:SetText(pages[currentPage].text or "")
    textEntry.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(15, 30, 45))
        self:DrawTextEntryText(Color(150, 220, 255), Color(80, 160, 200), Color(150, 220, 255))
    end

    local saveBtn = vgui.Create("DButton", frame)
    saveBtn:SetText("SAVE")
    saveBtn:SetSize(120, 40)
    saveBtn:SetPos(frame:GetWide() / 2 - 130, frame:GetTall() - 60)
    saveBtn:SetTextColor(Color(0, 200, 255))
    saveBtn.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(0, 100, 150, 150))
        if self:IsHovered() then
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 180, 255, 180))
        end
    end
    saveBtn.DoClick = function()
        pages[currentPage].headline = headlineEntry:GetValue()
        pages[currentPage].text = textEntry:GetValue()
        net.Start("Datapad_Save")
        net.WriteUInt(4, 8)
        for i = 1, 4 do
            net.WriteString(pages[i].headline or "")
            net.WriteString(pages[i].text or "")
        end
        net.SendToServer()
        frame:Close()
        surface.PlaySound("buttons/button14.wav")
    end

    local cancelBtn = vgui.Create("DButton", frame)
    cancelBtn:SetText("CANCEL")
    cancelBtn:SetSize(120, 40)
    cancelBtn:SetPos(frame:GetWide() / 2 + 10, frame:GetTall() - 60)
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

    datapadFrame = frame
    frame.OnClose = function() datapadFrame = nil end
end)
