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
"S_DERP_THROW1", "S_DERP_THROW2", "S_DERP_THROW3", "S_DERP_PARTICLE")

states[S_DERP_BOUNCE] = {
	sprite = SPR_PLAY,
	frame = SPR2_BNCE
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

SafeFreeslot("S_BOOMEARANG", "MT_BOOMEARANG")

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
	reactiontime = 8, // amount of tics before ear can interact with player
	speed = 16*FRACUNIT, // travel speed
	mass = ANG10, // turning speed
	damage = 5, // afterimages
	flags = MF_SPECIAL|MF_NOGRAVITY|MF_SLIDEME|MF_MISSILE
}