/*
The Derp configuration
	by Lach
beta
*/

// To prevent duplicate freeslots
local function SafeFreeslot(...)
	for _, item in ipairs({...})
		if rawget(_G, item) == nil
			freeslot(item)
		end
	end
end

SafeFreeslot("sfx_dbmper", "sfx_itseem", "sfx_sans", "sfx_yeeeah", "sfx_airhrn",
"sfx_menace", "sfx_waaaaa", "sfx_shderp", "sfx_haaaaa", "sfx_nsafe", "sfx_qmark",
"sfx_capwsh")

sfxinfo[sfx_dbmper].caption = "Plunge"
sfxinfo[sfx_itseem].caption = "It seems today,"
sfxinfo[sfx_sans].caption = "A bad time"
sfxinfo[sfx_yeeeah].caption = "Yeah!"
sfxinfo[sfx_airhrn].caption = "Airhorn"
sfxinfo[sfx_menace].caption = "Menacing"
sfxinfo[sfx_waaaaa].caption = "Mill why."
sfxinfo[sfx_shderp].caption = "/"
sfxinfo[sfx_haaaaa].caption = "HAAAAA!"
sfxinfo[sfx_nsafe].caption = "you think you're safe?"
sfxinfo[sfx_qmark].caption = "How did I get here??"
sfxinfo[sfx_capwsh].caption = "Pivoting"
sfxinfo[sfx_capwsh].flags = $ | SF_NOINTERRUPT

SafeFreeslot("S_DERP_BOUNCE", "S_DERP_LANDING", "S_DERP_POSE", "S_DERP_MINECART",
"S_DERP_THROW1", "S_DERP_THROW2", "S_DERP_THROW3", "S_DERP_PARTICLE",
"S_DERP_MINECARTHAND", "S_DERP_MINECARTHAT")

states[S_DERP_BOUNCE] = {
	sprite = SPR_PLAY,
	frame = SPR2_BNCE,
	action = A_RollAngle,
	var1 = 0,
	var2 = 1,
}

states[S_DERP_LANDING] = {
	sprite = SPR_PLAY,
	frame = SPR2_LAND,
	tics = 1,
	nextstate = S_DERP_BOUNCE
}

states[S_DERP_POSE] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL1,
	tics = 23,
	nextstate = S_PLAY_JUMP
}

states[S_DERP_MINECART] = {
	sprite = SPR_PLAY,
	frame = SPR2_TALA
}

states[S_DERP_THROW1] = {
	sprite = SPR_PLAY,
	frame = SPR2_FIRE|FF_ANIMATE,
	tics = 7,
	var2 = 5,
	nextstate = S_DERP_THROW2
}

states[S_DERP_THROW2] = {
	sprite = SPR_PLAY,
	frame = SPR2_FIRE|FF_SPR2ENDSTATE,
	tics = 4,
	var1 = S_PLAY_WALK,
	nextstate = S_DERP_THROW2
}

states[S_DERP_PARTICLE] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL0
}

states[S_DERP_MINECARTHAND] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL7,
	tics = 1,
}

states[S_DERP_MINECARTHAT] = {
	sprite = SPR_PLAY,
	frame = SPR2_TAL9,
	tics = 1,
	action = A_ChangeAngleRelative,
	var1 = 20,
	var2 = 20,
	nextstate = S_DERP_MINECARTHAT,
}

SafeFreeslot("S_BOOMEARANG", "MT_BOOMEARANG", "MT_DERP_EAR", "MT_DERP_MINECARTHAT")

states[S_BOOMEARANG] = {
	sprite = SPR_PLAY,
	frame = SPR2_TALB,
	tics = 2,
	nextstate = S_BOOMEARANG
}

mobjinfo[MT_BOOMEARANG] = {
	spawnstate = S_BOOMEARANG,
	deathstate = S_BOOMEARANG,
	height = 20*FRACUNIT,
	radius = 10*FRACUNIT,
	spawnhealth = 1000,
	reactiontime = 8, // number of tics before ear can interact with player
	speed = 16*FRACUNIT, // base travel speed
	raisestate = ANG10, // base turning speed
	meleestate = 5, // afterimages
	damage = 3, // number of wall bounces ear can take before it gives up
	painsound = sfx_bnce1, // sound to play when bouncing
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_SLIDEME
}

mobjinfo[MT_DERP_EAR] = {
	spawnstate = S_INVISIBLE,
	height = mobjinfo[MT_PLAYER].height,
	radius = mobjinfo[MT_PLAYER].radius,
	flags = mobjinfo[MT_THOK].flags
}

mobjinfo[MT_DERP_MINECARTHAT] = {
	spawnstate = S_DERP_MINECARTHAT,
	radius = 8*FRACUNIT,
	height = 8*FRACUNIT,
	flags = MF_NOCLIPTHING|MF_SCENERY,
	speed = -3*FRACUNIT,
	painchance = ANG60,
	mass = 14*FRACUNIT,
	damage = -8*FRACUNIT,
}

// Ear overlay

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
	[SPR2_PAIN] = {
		[A] = "L",
	},
	[SPR2_ROLL] = {
		[A] = "M",
		[C] = "N",
		[E] = "O",
		[G] = "P",
	},
	[SPR2_GASP] = {
		[A] = "Q",
	},
	[SPR2_SPNG] = {
		[A] = "Q",
	},
	[SPR2_FALL] = {
		[A] = "R",
		[B] = "S",
	},
	[SPR2_EDGE] = {
		[A] = "T",
		[B] = "U",
	},
	[SPR2_RIDE] = {
		[A] = "V",
	},
	[SPR2_SKID] = {
		[A] = "W",
	},
	[SPR2_TAL1] = {
		[A] = "X",
		[B] = "Y",
		[C] = "Z",
		[D] = "0",
		[E] = "1",
		[F] = "2",
		[G] = "3",
	},
	[SPR2_TAL2] = {
		[A] = "4",
		[B] = "5",
		[C] = "6",
		[D] = "7",
	},
	[SPR2_TAL3] = {
		[A] = "8",
		[B] = "9",
		[C] = "a",
		[E] = "b",
		[F] = "b",
	},
	[SPR2_TAL4] = {
		[B] = "c",
		[D] = "d",
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

for _, frames in pairs(EAR_FRAMES)
	for playerframe, earframe in pairs(frames)
		frames[playerframe] = R_Char2Frame($)
	end
end

rawset(_G, "DERP_EAR_FRAMES", EAR_FRAMES)