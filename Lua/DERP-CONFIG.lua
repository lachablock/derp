/*
The Derp configuration
	by Lach
v1
*/

// To prevent duplicate freeslots
local function SafeFreeslot(...)
	for _, item in ipairs({...})
		if rawget(_G, item) == nil
			freeslot(item)
		end
	end
end

function A_SetPAnim(mo, var1, var2)
	local player = mo.player
	if not player return end
	player.panim = var2
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
	action = A_SetPAnim,
	var2 = PA_ABILITY,
}

states[S_DERP_LANDING] = {
	sprite = SPR_PLAY,
	frame = SPR2_LAND,
	tics = 1,
	action = A_SetPAnim,
	var2 = PA_DASH, // yes, this is the cleanest way to not have your animation reset while on an upwards moving platform...
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
	action = A_SetPAnim,
	var1 = S_PLAY_STND,
	var2 = PA_IDLE,
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

// Commands

local FILENAME = "client/TheDerp.dat"

rawset(_G, "DP_NONE", 0)
rawset(_G, "DP_COMMON", 1)
rawset(_G, "DP_ALL", 2)
rawset(_G, "DP_DEFAULT", DP_COMMON)

local POSESET_NAMES = {
	[DP_NONE] = "none",
	[DP_COMMON] = "common",
	[DP_ALL] = "all",
}

local function Boolean(arg)
	if arg == "on"
	or arg == "yes"
	or arg == "true"
		return true
	elseif arg == "off"
	or arg == "no"
	or arg == "false"
		return false
	end
end

local function poseset(player, arg)
	if player.derp_poseset == nil
		player.derp_poseset = 1
	end
	if arg
		arg = arg:lower()
		local num = tonumber(arg)
		local bool = Boolean(arg)
		local val
		
		if num ~= nil
		and POSESET_NAMES[num]
			val = num
		elseif bool == false
		or arg == POSESET_NAMES[DP_NONE]
			val = DP_NONE
		elseif bool == true
		or arg == POSESET_NAMES[DP_COMMON]
			val = DP_COMMON
		elseif arg == POSESET_NAMES[DP_ALL]
			val = DP_ALL
		end
		
		if val ~= nil
			player.derp_poseset = val
			if io and player == consoleplayer
				local file = io.openlocal(FILENAME, "w+")
				file:write(player.derp_poseset)
				file:close()
			end
			return
		end
	end
	
	local message = ""
	message = $ .. "\"poseset\" is \""..POSESET_NAMES[player.derp_poseset].."\" default is \""..POSESET_NAMES[DP_DEFAULT].."\""
	message = $ .. "\nposeset <arg>:"
	message = $ .. "\n- "..POSESET_NAMES[DP_NONE]..": Derp will not pose"
	message = $ .. "\n- "..POSESET_NAMES[DP_COMMON]..": Derp will only pose tastefully"
	message = $ .. "\n- "..POSESET_NAMES[DP_ALL]..": Derp will pose tastefully and memefully"
	CONS_Printf(player, message)
end

COM_AddCommand("poseset2", poseset, 2)
COM_AddCommand("poseset", poseset)

if io
	addHook("ThinkFrame", do
		if consoleplayer and consoleplayer.valid
		and consoleplayer.derp_poseset == nil
			local file = io.openlocal(FILENAME)
			if file
				local num = file:read("*n")
				if num ~= nil and POSESET_NAMES[num]
					COM_BufInsertText(consoleplayer, "poseset "..num)
					file:close()
					return
				end
			end
			COM_BufInsertText(consoleplayer, "poseset "..DP_DEFAULT)
		end
	end)
end

// Poses

local DEFAULT_POSE = {
	["sprite"] = SPR_PLAY,
	["frames"] = {FF_FULLBRIGHT},
	["sound"] = sfx_s3k77,
	["colors"] = {0, SKINCOLOR_SUPERORANGE2}
}

local POSES = {
	[SPR2_TAL1] = {
		["poses"] = 7 // important!! this MUST match the number of frames in the SPR2 set EXCEPT those that are used in animations (e.g. sans)
	},
	[SPR2_TAL2] = {
		["poses"] = 4,
		[A] = { // peter
			["sound"] = sfx_itseem,
		},
		[C] = { // dab
			["frames"] = {F, G}, // TAL0 frames the particles can choose from
			["sound"] = sfx_airhrn, // sound to play when pose is picked
			["colors"] = {0}, // list of skincolors to color the particles (0 = player color)
		},
		[D] = { // Jojo
			["frames"] = {B},
			["sound"] = sfx_menace,
		},
	},
	[SPR2_TAL3] = {
		["poses"] = 5,
		[A] = { // cursed
			["frames"] = {},
			["sound"] = sfx_nsafe,
			["cursed"] = true,
		},
		[B] = { // Mill
			["sound"] = sfx_waaaaa
		},
		[C] = { // Kart
			["frames"] = {I},
			["sound"] = sfx_yeeeah,
		},
		[D] = { // Dirk
			["sprite"] = SPR_SNO1, // alternate sprite set to use, if SPR2_TAL0 is not desirable
			["sound"] = sfx_s3k80,
			["frames"] = {A, B, C},
		},
		[E] = { // sans
			["frames"] = {D|FF_FULLBRIGHT, E|FF_FULLBRIGHT},
			["sound"] = sfx_sans,
			["animate"] = {E, F},
		},
	},
	[SPR2_TAL4] = {
		["poses"] = 5,
		[A] = { // Orville
			["frames"] = {C},
			["sound"] = sfx_qmark,
			["colors"] = {SKINCOLOR_BLUE, SKINCOLOR_SUNSET},
		},
		[B] = { // old Derp,
			["repeatsound"] = sfx_shderp,
		},
		[C] = { // Super Saiyan
			["sound"] = sfx_haaaaa,
			["colors"] = {SKINCOLOR_SUPERGOLD1, SKINCOLOR_SUPERGOLD2, SKINCOLOR_SUPERGOLD3, SKINCOLOR_SUPERGOLD4, SKINCOLOR_SUPERGOLD5},
		},
		[E] = { // Paco
			["frames"] = {C},
			["sound"] = sfx_qmark,
		},
	}	
}

rawset(_G, "DERP_DEFAULT_POSE", DEFAULT_POSE)
rawset(_G, "DERP_POSES", POSES)

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