local ic_uplinked = {}
local ic_lastEmitted = {}

-- Timer to check player states and manage sound muting and scrambling
timer.Create("icComms_CheckSound", 0.1, 0, function()
    for _, v in pairs(player.GetAll()) do
        if v:GetNWBool("icScramblerActive") and not ic_uplinked[v] then
            if LocalPlayer():HasWeapon("ic_decrypter") then
                v:SetMuted(false)
            elseif v:HasWeapon("ic_encrypter") and not LocalPlayer():HasWeapon("ic_encrypter") then
                v:SetMuted(true)
            else
                v:SetMuted(false)
            end
        else
            v:SetMuted(false)
        end

        if v:GetNWBool("icIsHeTalking") and v:HasWeapon("ic_encrypter") and v:GetNWBool("icScramblerActive")
            and not ic_uplinked[v] and v ~= LocalPlayer() and not LocalPlayer():HasWeapon("ic_encrypter") then

            local shouldSkip = false

            if istable(ic_lastEmitted[v]) then
                if CurTime() - ic_lastEmitted[v].time < ic_lastEmitted[v].duration then
                    shouldSkip = true
                end
            end

            if v:GetPos():Distance(LocalPlayer():GetPos()) > 200 then
                shouldSkip = true
            end

            if shouldSkip then return end

            local soundplay = "iccomms/rceffect-" .. tostring(math.random(1, 11)) .. ".mp3"
            v:EmitSound(soundplay, icComms.Config.SoundLevel)
            ic_lastEmitted[v] = { time = CurTime(), duration = 2 }
        end
    end
end)

-- Network message handler to update uplinked status
net.Receive("iccomms_handler", function()
    local ply = net.ReadEntity()
    local action = net.ReadBool()
    ic_uplinked[ply] = action
    if action then
        print(ply:Nick() .. " has uplinked you!")
    else
        print(ply:Nick() .. " has delinked you!")
    end
end)

-- Hooks to send voice state to the server
hook.Add("PlayerStartVoice", "icComms_StartVoiceHook", function(ply)
    if ply == LocalPlayer() then
        net.Start("iccomms_VoiceHandeler")
        net.WriteInt(1, 3)
        net.WriteBool(true)
        net.SendToServer()
    end
end)

hook.Add("PlayerEndVoice", "icComms_EndVoiceHook", function(ply)
    if ply == LocalPlayer() then
        net.Start("iccomms_VoiceHandeler")
        net.WriteInt(1, 3)
        net.WriteBool(false)
        net.SendToServer()
    end
end)

-- HUD display for scrambler status
hook.Add("HUDPaint", "icComms_HUDPaint", function()
    if LocalPlayer():HasWeapon("ic_encrypter") then
        surface.SetMaterial(Material("materials/iccomms.png"))
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(5, 5, 270, 55)
        surface.SetFont("HudDefault")

        if LocalPlayer():GetNWBool("icScramblerActive") then
            draw.SimpleText("Scrambler Active", "HudDefault", 30, 20, Color(255, 255, 255, 255))
        else
            draw.SimpleText("Scrambler Deactivated", "HudDefault", 30, 20, Color(255, 255, 255, 255))
        end
    end
end)
