util.AddNetworkString("iccomms_handler")
util.AddNetworkString("iccomms_VoiceHandeler")

local uplinked = {}

local function linkingHandeler(ply, link, action)
    uplinked[ply] = uplinked[ply] or {}
    uplinked[ply][link] = action

    net.Start("iccomms_handler")
    net.WriteEntity(ply)
    net.WriteBool(action)
    net.Send(link)

    net.Start("iccomms_handler")
    net.WriteEntity(link)
    net.WriteBool(action)
    net.Send(ply)
end

local isHeTalking = {}
net.Receive("iccomms_VoiceHandeler", function(len, ply)
    local action = net.ReadInt(3)
    local boolean = net.ReadBool()

     if action == 1 then
     ply:SetNWBool("icIsHeTalking", boolean)
    elseif action == 2 and ply:HasWeapon("ic_encrypter") then
        ply:SetNWBool("icScramblerActive", boolean)
end

end)

net.Receive("iccomms_handler", function(len, ply)
    local link = net.ReadEntity()
    local action = net.ReadBool()

    linkingHandeler(ply, link, action)
end)

hook.Add( "PlayerSay", "icComms_ChatHandle", function( ply, text, team )
    local link = ply:GetEyeTrace().Entity
    if ply:HasWeapon("ic_encrypter") then
        if string.find(string.lower(text), "/iclink") then
            if !IsValid(link) or !link:IsPlayer() then
                ply:ChatPrint("You need to be looking at a player!")
                return ""
            else
                linkingHandeler(ply, link, true)
                ply:ChatPrint("You successfully uplinked "..link:Nick().."!")
                return ""
            end
        elseif string.find(string.lower(text), "/icunlink") then
            if !IsValid(link) or !link:IsPlayer() then
                ply:ChatPrint("You need to be looking at a player!")
                return ""
            else
                linkingHandeler(ply, link, false)
                ply:ChatPrint("You successfully delinked "..link:Nick().."!")
                return ""
            end
        end
    end
end )

hook.Add("OnPlayerChangedTeam", "icComms_ChangeTeamRemoveUpLink", function(ply, before, after)
    if istable(uplinked[ply]) and (istable(RPExtraTeams[after].weapons) and !table.HasValue(RPExtraTeams[after].weapons, "ic_encrypter") or (isstring(RPExtraTeams[after].weapons) and RPExtraTeams[after].weapons == "ic_encrypter") ) then
        for k,v in pairs(uplinked[ply]) do
            linkingHandeler(ply, k, false)
        end
    end
end)