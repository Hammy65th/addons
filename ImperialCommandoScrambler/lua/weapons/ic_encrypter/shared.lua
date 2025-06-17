if SERVER then
    AddCSLuaFile()
end

SWEP.PrintName       = "IC Encrypter" -- rc_encrypter
SWEP.Author          = "Hammy"
SWEP.Instructions    = "Look at a player and type /iclink to link into comms, /icunlink to delink from comms."
SWEP.HoldType        = "slam"
SWEP.Primary.Ammo    = "none"
SWEP.Slot            = 1
SWEP.SlotPos         = 2
SWEP.IconLetter      = "C"
SWEP.ViewModelFOV    = 0
SWEP.Category        = "[IC] Scrambler"
SWEP.DrawCrosshair   = false
SWEP.WorldModel      = ""
SWEP.ViewModel       = ""

SWEP.Primary.ExtraMags      = 0
SWEP.Primary.DefaultClip    = 0
SWEP.Secondary.ExtraMags    = 0
SWEP.Secondary.DefaultClip  = 0
SWEP.Primary.Ammo           = "none"
SWEP.AdminSpawnable         = false
SWEP.Spawnable              = true

function SWEP:CustomAmmoDisplay()
    self.AmmoDisplay = self.AmmoDisplay or {}
    self.AmmoDisplay.Draw = false
    return self.AmmoDisplay
end

function SWEP:Initialize()
    if SERVER then
        resource.AddFile("sound/weapons/click.mp3")
    end
end

function SWEP:PrimaryAttack()
    if self.FiredLast and CurTime() - self.FiredLast < 0.6 then return end
    self.FiredLast = CurTime()

    self:SetNextPrimaryFire(CurTime() + 1)

    -- Toggle scrambler active state on the owner
    self.Owner.iccommsActive = not self.Owner.iccommsActive

    if CLIENT then
        net.Start("iccomms_VoiceHandeler")
        net.WriteInt(2, 3)
        net.WriteBool(self.Owner.iccommsActive)
        net.SendToServer()
    end

    self:EmitSound("weapons/click.mp3", 30)
end

function SWEP:SecondaryAttack()
    -- No secondary attack behavior needed
end
