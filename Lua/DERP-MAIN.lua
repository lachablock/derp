/*
The Derp
	by Lach
beta
*/

local SKIN = "derp" // skin to run code for

local MAX_BOUNCES = 3 // maximum number of mid-air bounces
local BOUNCE_START_SOUND = sfx_dbmper // sound to play when starting a bounce
local BOUNCE_LAND_SOUND = sfx_s3k87 // sound to play when hitting the ground during a bounce
local BOUNCE_ACCEL = FRACUNIT // amount of fall speed to add each tic when bouncing
local BOUNCE_POWER = 80*FRACUNIT // how much height to add or subtract from each bounce (see below)
local BOUNCE_HEIGHT = 4096*FRACUNIT // the height at which Derp's bounces should normalize
local MIN_BOUNCE_SPEED = 8*FRACUNIT // the minimum amount of power to bounce with
local BOUNCE_ANIM_TIME = 14 // after bouncing, return to jump anim after this number of tics
local BOUNCE_DISPLAY_FAST_THRESHOLD = 10*FRACUNIT // while bouncing, show the stretch frame when above this vertical speed

local UNCOMMON_POSE_CHANCE = 15*FRACUNIT/100 // chance for uncommon pose to show up (TAL2)
local RARE_POSE_CHANCE = 5*FRACUNIT/100 // chance for rare pose to show up (TAL3)
local SUPERRARE_POSE_CHANCE = 1*FRACUNIT/100 // chance for super rare pose to show up (TAL4)

local MAX_STARS = 16 // number of stars to spawn when Derp transitions into spring state after the third bounce
local STAR_SPEED = 5*FRACUNIT // speed the stars expand
local STAR_LIFETIME = 18 // tics the stars last for
local STAR_SOUND = sfx_s3k77 // sound to play when stars spawn

local DEFAULT_POSE = {
	["sprite"] = SPR_PLAY,
	["frames"] = {FF_FULLBRIGHT},
	["sound"] = STAR_SOUND,
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

local BUTTONS = {BT_USE}

rawset(_G, "DF_BOUNCING", 1 << 0)
rawset(_G, "DF_UNDERWATERBOUNCE", 1 << 1)
rawset(_G, "DF_ROTSPRITE", 1 << 2)

// hah! you thought these were constants? fuck you, I am a degenerate programmer

RARE_POSE_CHANCE = $ + SUPERRARE_POSE_CHANCE
UNCOMMON_POSE_CHANCE = $ + RARE_POSE_CHANCE

local function valid(mo)
	return mo and mo.valid
end

local function sign(num)
	if num < 0
		return -1
	end
	return 1
end

// sets Derp to one of his poses

local function ChoosePose(mo)
	local rarity = P_RandomFixed()
	
	if rarity < SUPERRARE_POSE_CHANCE
		mo.sprite2 = $ + 1
	end
	if rarity < RARE_POSE_CHANCE
		mo.sprite2 = $ + 1
	end
	if rarity < UNCOMMON_POSE_CHANCE
		mo.sprite2 = $ + 1
	end
	
	local pose = POSES[mo.sprite2]
	local frame = P_RandomByte() % pose.poses
	mo.frame = $ + frame
	pose = $[frame]
	pose = $ or DEFAULT_POSE
	
	S_StartSound(mo, pose.sound == nil and DEFAULT_POSE.sound or pose.sound)
	return pose
end

// Spawns a star mobj and returns it

local function SpawnStar(mo, pose, z, minaiming, maxaiming)
	local colors = pose.colors or DEFAULT_POSE.colors
	local frames = pose.frames or DEFAULT_POSE.frames
	
	if not #frames
		return
	end
	local star = P_SpawnMobj(mo.x, mo.y, z, MT_PARTICLE)
	
	star.scale = 1
	star.destscale = mo.scale/P_RandomRange(1,3)
	star.fuse = STAR_LIFETIME
	star.skin = SKIN
	star.state = S_DERP_PARTICLE
	star.eflags = $ | (mo.eflags & MFE_VERTICALFLIP)
	
	star.sprite = pose.sprite or DEFAULT_POSE.sprite
	star.frame = $ + frames[P_RandomKey(#frames) + 1]
	star.color = colors[P_RandomKey(#colors) + 1] or mo.player.skincolor
	
	local aiming = FixedAngle(P_RandomRange(minaiming, maxaiming) << FRACBITS)
	local angle = FixedAngle(P_RandomKey(360) << FRACBITS)
	local hthrust = cos(aiming)
	
	star.zthrust = FixedMul(sin(aiming), mo.scale)
	star.xthrust = FixedMul(FixedMul(cos(angle), hthrust), mo.scale)
	star.ythrust = FixedMul(FixedMul(sin(angle), hthrust), mo.scale)
	
	return star
end

// returns true if Derp is bouncing on a bustable FOF and breaks it

local function BustGround(mo)
	local sector = mo.subsector.sector
	local flip = mo.eflags & MFE_VERTICALFLIP
	
	for fof in sector.ffloors()
		if not fof.valid
		or (fof.flags & (FF_EXISTS|FF_BLOCKPLAYER|FF_BUSTUP)) ~= (FF_EXISTS|FF_BLOCKPLAYER|FF_BUSTUP)
			continue
		end
		
		local slope = flip and fof.b_slope or not flip and fof.t_slope or nil
		
		if slope
			if slope == mo.standingslope
				EV_CrumbleChain(sector, fof)
				return true
			end
		else
			if flip
				if fof.bottomheight == mo.ceilingz
					EV_CrumbleChain(sector, fof)
					return true
				end
			else
				if fof.topheight == mo.floorz
					EV_CrumbleChain(sector, fof)
					return true
				end
			end
		end
	end
	
	return false
end
			

// main thinker

addHook("ThinkFrame", do
	for player in players.iterate
		local mo = player.mo
		
		if not mo
			continue
		end
		
		if mo.skin ~= SKIN
		or not mo.health
			if mo.derp
				local derp = mo.derp
				if valid(derp.ear)
					P_RemoveMobj(derp.ear)
				end
				mo.derp = nil
			end
			continue
		end
		
		if not mo.derp
			mo.derp = {}
			local derp = mo.derp
			derp.flags = 0
			derp.roll = 0
			derp.stars = {}
			derp.buttons = {}
			
			for i = 1, #BUTTONS
				derp.buttons[BUTTONS[i]] = 0
			end
		end
		
		local derp = mo.derp
		local flip = P_MobjFlip(mo)
		local grounded = P_IsObjectOnGround(mo)
		
		// count buttons held
		
		for i = 1, #BUTTONS
			derp.buttons[BUTTONS[i]] = player.cmd.buttons & BUTTONS[i] and $ + 1 or 0
		end
		
		// NiGHTS stuff
		
		if (mo.state == S_PLAY_SUPER_TRANS4 or mo.state == S_PLAY_NIGHTS_TRANS4)
		and mo.tics == states[mo.state].tics - 1
			local tics = mo.tics
			mo.state = $
			mo.tics = tics
		end
		
		if player.powers[pw_carry] == CR_NIGHTSMODE
			if player.exiting
			and mo.state == S_PLAY_NIGHTS_FLOAT
				mo.state = S_PLAY_SPRING
			end
			continue
		end
		
		// Boomearang
		
		if mo.state >= S_DERP_THROW1
		and mo.state <= S_DERP_THROW2
			player.pflags = $ | PF_FULLSTASIS
			if mo.state == S_DERP_THROW1
			and mo.tics == 1
				local angle = player.drawangle
				local x = P_ReturnThrustX(mo, angle, 11*mo.scale)
					+ P_ReturnThrustX(mo, angle - ANGLE_90, 15*mo.scale)
				local y = P_ReturnThrustY(mo, angle, 11*mo.scale)
					+ P_ReturnThrustY(mo, angle - ANGLE_90, 15*mo.scale)
				local ear = P_SpawnMobjFromMobj(mo, x, y, 0, MT_BOOMEARANG)
				ear.target = mo
				ear.skin = mo.skin
				ear.state = $
				ear.color = mo.color
				//if derp.buttons[BT_USE] == states[mo.state].tics - 1
					//ear.flags2 = $ | MF2_AMBUSH
					//ear.angle = angle
				//else
					ear.angle = angle - ANGLE_90
				//end
				derp.ear = ear
			end
		end
		
		if valid(derp.ear)
		and not valid(derp.ear.tracer)
		and derp.ear.reactiontime <= 0
			local item = P_LookForEnemies(player, false, true)
			if valid(item)
			and not (item.type == MT_METALSONIC_BATTLE and item.flags2 & MF2_INVERTAIMABLE)
				if derp.buttons[BT_USE] == 1
					derp.ear.tracer = item
				else
					P_SpawnLockOn(player, item, S_LOCKON1)
				end
			end
		end
		
		// Bounce
		if derp.flags & DF_BOUNCING // if bouncing towards the ground
			if (grounded or mo.state == S_DERP_BOUNCE and flip*mo.momz > 0 and flip*derp.momz <= 0) // if on the ground, bounce back up
			and not P_PlayerInPain(player)
			and player.playerstate ~= PST_DEAD
			and not (player.pflags & PF_SLIDING)
			and not player.powers[pw_carry]
				player.pflags = $ & ~PF_NOJUMPDAMAGE | PF_JUMPED | PF_THOKKED
				derp.flags = $ & ~DF_BOUNCING
				derp.tics = BOUNCE_ANIM_TIME
				
				local bustground = BustGround(mo)
				
				local normalgrav = FixedMul(gravity, mo.scale)
				local grav = min(abs(P_GetMobjGravity(mo)), normalgrav)
				/*if derp.flags & DF_UNDERWATERBOUNCE and mo.eflags & (MFE_UNDERWATER|MFE_TOUCHWATER) == (MFE_UNDERWATER|MFE_TOUCHWATER)
					grav = $ / 3
					derp.flags = $ & ~DF_UNDERWATERBOUNCE
				end*/
				local minbounce = FixedDiv(FixedMul(MIN_BOUNCE_SPEED, grav), normalgrav)
				local height = abs(derp.fallheight - mo.z)
				local bounceadd = min(max(BOUNCE_HEIGHT - height, -BOUNCE_POWER), BOUNCE_POWER)
				mo.momz = flip*FixedSqrt(FixedMul(derp.fallspeed, derp.fallspeed) + FixedMul(grav << 1, height + bounceadd))
				if bustground or flip*mo.momz < minbounce // make sure bounce power is at least the minimum
					mo.momz = flip*minbounce
				end
				S_StartSound(mo, BOUNCE_LAND_SOUND)
				
				mo.state = S_DERP_LANDING // set back to bouncing animation
				player.panim = PA_ABILITY
				
				local slope = mo.standingslope
				
				if slope
					local roll = slope.zangle
					player.drawangle = slope.xydirection
					if roll > 0
						player.drawangle = $ + ANGLE_180
					else
						roll = InvAngle(roll)
					end
					mo.frame = $ + 6*(roll/ANG1)/90
					derp.roll = roll
				else
					derp.roll = 0
				end
				
				// spawn stars!!
				local z
				local minaiming, maxaiming
				if mo.eflags & MFE_VERTICALFLIP
					z = mo.z + mo.height
					minaiming = -60
					maxaiming = -15
				else
					z = mo.z
					minaiming = 15
					maxaiming = 60
				end
				for i = 1, MAX_STARS
					table.insert(derp.stars, SpawnStar(mo, DEFAULT_POSE, z, minaiming, maxaiming))
				end
			else // otherwise, make sure player is still in bounce state, and apply momentum if so
				if mo.state ~= S_DERP_BOUNCE or mo.eflags & MFE_GOOWATER
					derp.flags = $ & ~DF_BOUNCING
				else
					local addspeed = FixedMul(BOUNCE_ACCEL, mo.scale)
					mo.momz = $ - flip * addspeed
					player.pflags = $ | PF_JUMPSTASIS
				end
			end
		elseif mo.eflags & MFE_JUSTHITFLOOR
			derp.bounces = 0
		end
		
		if mo.state == S_DERP_BOUNCE // bounce animation
			derp.roll = R_PointToAngle2(0, 0, abs(mo.momz), sign(mo.momz)*FixedHypot(mo.momx, mo.momy))
			if derp.flags & DF_BOUNCING
				local ghost = P_SpawnGhostMobj(mo)
				mo.frame = (-flip*mo.momz > FixedMul(BOUNCE_DISPLAY_FAST_THRESHOLD, mo.scale) and B or A) | ($ & ~FF_FRAMEMASK)
				ghost.fuse = 6
				ghost.rollangle = mo.rollangle
			else
				if derp.tics <= 0
					if derp.bounces // change animation based on whether bounces remain
						mo.state = S_PLAY_ROLL
					elseif mo.eflags & MFE_GOOWATER
						mo.state = S_PLAY_JUMP
						player.pflags = $ | PF_NOJUMPDAMAGE
					else
						mo.state = S_DERP_POSE
						derp.pose = ChoosePose(mo)
						player.pflags = $ | PF_NOJUMPDAMAGE
						local z = mo.z + (mo.height >> 1)
						for i = 1, MAX_STARS // spawn stars!! why the fuck am I putting so much effort into this!!
							local star = SpawnStar(mo, derp.pose, z, -90, 90)
							
							if not star
								break
							end
							
							star.distx = 0
							star.disty = 0
							star.distz = mo.height >> 1
							
							table.insert(derp.stars, star)
						end
					end
				else
					if derp.tics > BOUNCE_ANIM_TIME - 3
					or derp.tics < BOUNCE_ANIM_TIME >> 1
						mo.frame = A | ($ & ~FF_FRAMEMASK)
					else
						mo.frame = B | ($ & ~FF_FRAMEMASK)
					end
					derp.tics = $ - 1
				end
			end
		end
		
		// rotsprite bounce
		/*if derp.flags & DF_ROTSPRITE
			if mo.state ~= S_DERP_BOUNCE
			and mo.state ~= S_DERP_LANDING
				derp.flags = $ & ~DF_ROTSPRITE
				derp.roll = 0
				player.sloperollangle_override = false
				mo.rollangle = 0
			else
				local angle
				if grounded
					angle = player.drawangle
				else
					angle = R_PointToAngle2(0, 0, mo.momx, mo.momy)
				end
				mo.rollangle = FixedMul(sin(angle - R_PointToAngle(mo.x, mo.y)), derp.roll)
				player.sloperollangle_override = true
			end
		end*/
		
		// Bounce pose
		if mo.state == S_DERP_POSE
			if derp.pose.animate // Sans
				mo.frame = derp.pose.animate[((leveltime/3) % #derp.pose.animate) + 1] | ($ & ~FF_FRAMEMASK)
			end
			
			if derp.pose.repeatsound
				S_StartSound(mo, derp.pose.repeatsound)
			end
			
			if derp.pose.cursed
				if not valid(derp.cursedhand)
					mo.tics = $ + 10
					local hand = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_THOK)
					hand.skin = SKIN
					hand.state = S_DERP_PARTICLE
					hand.frame = $ + (H | (mo.frame & ~FF_FRAMEMASK))
					hand.scale = mo.scale/3
					hand.height = mo.height
					hand.tics = mo.tics
					derp.cursedhand = hand
				end
				local hand = derp.cursedhand
				local cameraangle = R_PointToAngle(mo.x, mo.y)
				local transangle = cameraangle - ANGLE_90
				local x = FixedMul(-4*cos(cameraangle) + min(12, mo.tics)*cos(transangle), mo.scale)
				local y = FixedMul(-4*sin(cameraangle) + min(12, mo.tics)*sin(transangle), mo.scale)
				hand.flags2 = mo.flags2
				hand.eflags = mo.eflags
				P_TeleportMove(hand, mo.x + x, mo.y + y, mo.z + (player.height >> 1))
				if mo.tics <= 2*states[mo.state].tics/3
					if mo.tics == 2*states[mo.state].tics/3
						//S_StartSound(nil, sfx_nsafe, player)
					end
					hand.scale = $ + FRACUNIT/3
					hand.height = mo.height
				end
			end
		elseif valid(derp.cursedhand)
			P_RemoveMobj(derp.cursedhand)
			derp.cursedhand = nil
		end
		
		// Minecart frame
		if player.powers[pw_carry] == CR_MINECART
		and mo.state ~= S_DERP_MINECART
			mo.state = S_DERP_MINECART
		end
		
		// animate stars
		for i = #derp.stars, 1, -1
			local star = derp.stars[i]
			if not valid(star)
				table.remove(derp.stars, i)
				continue
			end
			
			local adddist = STAR_SPEED * star.fuse / STAR_LIFETIME
			local x = FixedMul(adddist, star.xthrust)
			local y = FixedMul(adddist, star.ythrust)
			local z = FixedMul(adddist, star.zthrust)
			
			if star.distx ~= nil
				star.distx = $ + x
				star.disty = $ + y
				star.distz = $ + z
				
				x = mo.x + star.distx
				y = mo.y + star.disty
				z = mo.z + star.distz
			else
				x = star.x + $
				y = star.y + $
				z = star.z + $
			end
			
			P_TeleportMove(star, x, y, z)
			
			if star.fuse < STAR_LIFETIME >> 1
			and star.frame & FF_FULLBRIGHT
				if P_RandomKey(2)
					star.flags2 = $ ^^ MF2_DONTDRAW
				end
			end
		end
		
		// variable handling
		derp.momz = mo.momz
	end
end)

// Activate bounce

addHook("AbilitySpecial", function(player)
	local mo = player.mo
	
	if not mo
	or mo.skin ~= SKIN
	or player.charability ~= skins[SKIN].ability
		return
	end
	
	local derp = mo.derp
	
	if derp.flags & DF_BOUNCING
	or mo.eflags & MFE_GOOWATER
		return true
	end
	
	if not (player.pflags & PF_THOKKED)
		player.pflags = $ & ~PF_NOJUMPDAMAGE | PF_THOKKED
		derp.bounces = MAX_BOUNCES
	end
	
	if derp.bounces
		S_StartSound(mo, BOUNCE_START_SOUND)
		derp.bounces = $ - 1
		derp.flags = $ | DF_BOUNCING | DF_ROTSPRITE
		derp.fallheight = mo.z
		derp.fallspeed = mo.momz
		if mo.eflags & (MFE_TOUCHWATER|MFE_UNDERWATER) == (MFE_TOUCHWATER|MFE_UNDERWATER)
			derp.flags = $ | DF_UNDERWATERBOUNCE
		else
			derp.flags = $ & ~DF_UNDERWATERBOUNCE
		end
		derp.tics = 0
		mo.state = S_DERP_BOUNCE
		player.panim = PA_ABILITY
	end
	
	return true
end)

// Activate boomearang

addHook("SpinSpecial", function(player)
	local mo = player.mo
	
	if player.pflags & PF_USEDOWN
	or not mo
	or not mo.derp
	or valid(mo.derp.ear)
	or mo.derp.flags & DF_BOUNCING
	or not P_IsObjectOnGround(mo)
	or not player.charability
		return
	end
	
	mo.state = S_DERP_THROW1
	player.pflags = $ | PF_FULLSTASIS
	player.drawangle = mo.angle
	S_StartSound(mo, sfx_s3k4a)
end)

// Boomearang logic

addHook("MobjThinker", function(ear)
	if not ear.valid then return end
	
	local info = ear.info
	local aiming = 0
	local speed
	local angspeed
	
	// semantics
	
	if ear.angspeed == nil
		ear.speed = FixedMul(info.speed, ear.scale)
		ear.angspeed = info.raisestate
		ear.time = 0
	end
	
	if ear.reactiontime > 0
		ear.reactiontime = $ - 1
	else
		ear.speed = $ + (ear.scale /10)
		ear.angspeed = $ + (ANG1 >> 2)
	end
	
	speed = ear.speed
	angspeed = ear.angspeed
	
	// aesthetics
	
	S_StartSound(ear, sfx_capwsh)
	P_SpawnGhostMobj(ear).fuse = info.meleestate
	
	// logic
	
	if ear.flags2 & MF2_AMBUSH
		speed = ear.reactiontime * $ >> 1
	else
		local mo
		local z
		local tracer = ear.tracer
		if valid(tracer)
		and tracer.health
		and not (tracer.flags2 & MF2_FRET)
		and (tracer.flags & MF_SHOOTABLE and true) ~= (tracer.flags2 & MF2_INVERTAIMABLE and true)
		and not (tracer.type == MT_METALSONIC_BATTLE and tracer.flags2 & MF2_INVERTAIMABLE)
		and not (tracer.flags & (MF_NOCLIP|MF_NOCLIPTHING))
			mo = ear.tracer
			z = mo.z + (mo.height >> 1)
		else
			ear.tracer = nil
			if valid(ear.target)
				mo = ear.target
				if mo.eflags & MFE_VERTICALFLIP
					z = mo.z + 10*mo.scale
				else
					z = mo.z + mo.height - 10*mo.scale
				end
			end
		end
		if mo
			local dist = FixedHypot(mo.x - ear.x, mo.y - ear.y)
			local angle = R_PointToAngle2(ear.x, ear.y, mo.x, mo.y)
			local diff = angle - ear.angle
			
			if mo == ear.target
				speed = max($, FixedHypot(mo.momx, mo.momy) + 8*mo.scale)
			end
			
			if dist > speed + mo.radius + ear.radius
				ear.flags = $ | MF_NOCLIP
			else
				ear.flags = $ & ~MF_NOCLIP
			end
			
			ear.angle = $ + (ear.reactiontime and angspeed or max(min(diff, angspeed), -angspeed))
			if not ear.reactiontime
				aiming = R_PointToAngle2(0, 0, dist, z - ear.z - (ear.height >> 1))
			end
		end
	end
	
	ear.time = $ + 1
	
	// movement
	
	ear.momz = FixedMul(speed, sin(aiming))
	P_InstaThrust(ear, ear.angle, FixedMul(speed, cos(aiming)))
end, MT_BOOMEARANG)

addHook("MobjMoveCollide", function(ear, item)
	if valid(item)
	and item.type ~= MT_PLAYER
	and item.z <= ear.z + ear.height
	and ear.z <= item.z + item.height
		if (item.flags & MF_SHOOTABLE and true) ~= (item.flags2 & MF2_INVERTAIMABLE and true)
			if item.flags & MF_MONITOR
				P_KillMobj(item, ear, ear.target)
			else
				P_DamageMobj(item, ear, ear.target)
			end
		end
		if item == ear.tracer
			local info = ear.info
			ear.speed = $ + FixedMul(info.speed >> 3, ear.scale)
			ear.angspeed = $ + (info.raisestate >> 1)
			ear.tracer = nil
		end
	end
end, MT_BOOMEARANG)

addHook("TouchSpecial", function(ear, mo)
	if ear.reactiontime return true end
	P_RemoveMobj(ear)
end, MT_BOOMEARANG)