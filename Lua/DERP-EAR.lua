/*
Derp's ear overlay
	by Lach
beta
*/

local SKIN = "derp"
local EAR_SPR2 = SPR2_TAL8 // I've picked TAL8 for the separated ear but you can change it here if you want

local EAR_FRAMES = {
	[SPR2_STND] = {
		[A] = "B", // this says: for STND frame A, use TAL8 frame B
	},
	[SPR2_WAIT] = {
		[A] = "B", // this says: for WAIT frame A, use TAL8 frame B
		[B] = "B", // this says: for WAIT frame B, use TAL8 frame B
	},
	[SPR2_WALK] = {
		[A] = "C", // ok epic thanks for the tutorial
		[B] = "D",
		[C] = "E",
		[D] = "D",
		[E] = "C",
		[F] = "F",
		[G] = "G",
		[H] = "F",
	},
	[SPR2_RUN] = {
		[A] = "H", 
		[B] = "I", 
		[C] = "J", 
		[D] = "K",
	},
}

/*
I've set the default frame to A, which is invisible. This will work as a fallback for ears that don't exist yet, or for when other people change Derp to a custom state or something.
If you set an ear frame to a letter that you haven't imported a sprite for yet it will probably show up as the red <!> in-game.

The 2.2 lump letters for frames are:
A - Z, then
0 - 9, then
a - z
*/

// This is all code now so you can ignore the stuff below this line

for _, frames in pairs(EAR_FRAMES)
	for playerframe, earframe in pairs(frames)
		frames[playerframe] = R_Char2Frame($)
	end
end

local function valid(mo)
	return mo and mo.valid
end

addHook("FollowMobj", function(player, ear)
	local mo = player.mo
	
	if not (mo and mo.derp and ear.valid and ear.type == skins[SKIN].followitem)
		return
	end
	
	local derp = mo.derp
	local info = ear.info
	
	if not (ear.flags2 & MF2_DONTRESPAWN)
		ear.flags2 = $ | MF2_DONTRESPAWN
		ear.skin = mo.skin
		ear.sprite = SPR_PLAY
		ear.sprite2 = EAR_SPR2
	end
	
	local frame = EAR_FRAMES[mo.sprite2]
	frame = $ and $[mo.frame & FF_FRAMEMASK] or nil
	
	if frame == nil
	or valid(derp.ear)
	or derp.flags & DF_BOUNCING
	or mo.sprite ~= SPR_PLAY
		ear.frame = 0
		return
	end
	
	ear.frame = frame | (mo.frame & ~FF_FRAMEMASK)
	
	ear.flags2 = mo.flags2
	ear.eflags = mo.eflags
	ear.color = mo.color
end)