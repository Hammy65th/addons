if (SERVER) then
	AddCSLuaFile()
	
	SWEP.HoldType			= "slam"
	SWEP.Weight				= 5
	SWEP.AutoSwitchTo 		= false;
	SWEP.AutoSwitchFrom 	= false;

end

SWEP.PrintName			= "IC Decrypter"
SWEP.Author				= "Hammy"
SWEP.Instructions = "Allows you to hear Imperial Commando, while not sounding like them."
SWEP.Primary.Ammo		= "none"
SWEP.HoldType			= "slam"
SWEP.Slot				= 1
SWEP.SlotPos			= 2
SWEP.IconLetter			= "C"
SWEP.ViewModelFOV		= 0
SWEP.Category 			= "[IC] Scrambler"
SWEP.DrawCrosshair		= false
SWEP.WorldModel   		= ""
SWEP.Primary.ExtraMags = 0
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ExtraMags = 0
SWEP.Secondary.DefaultClip = 0
SWEP.WorldModel   		= ""
SWEP.ViewModel = ""


SWEP.Primary.ExtraMags = 0
SWEP.Primary.DefaultClip = 0
SWEP.Secondary.ExtraMags = 0
SWEP.Secondary.DefaultClip = 0
SWEP.Primary.Ammo		= "none"
SWEP.AdminSpawnable = false
SWEP.Spawnable = true



function SWEP:CustomAmmoDisplay()
	self.AmmoDisplay = self.AmmoDisplay or {}
	self.AmmoDisplay.Draw = false
	return self.AmmoDisplay
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end
