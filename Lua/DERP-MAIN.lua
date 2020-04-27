/*
The Derp
	by Lach
beta
*/

local SKIN = "derp" // skin to run code for

local EAR_SPR2 = SPR2_TAL8 // I've picked TAL8 for the separated ear but you can change it here if you want

local BOOMEARANG_KNOCKBACK_DELAY = 3*TICRATE

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

local BUTTONS = {BT_USE}

rawset(_G, "DF_BOUNCING", 1 << 0)
rawset(_G, "DF_UNDERWATERBOUNCE", 1 << 1)

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

local function ChoosePose(player)
	local mo = player.mo
	local val = player.derp_poseset
	
	if val == nil
		val = DP_DEFAULT
		player.derp_poseset = DP_DEFAULT
	end
	
	if val == DP_NONE
		mo.state = S_PLAY_JUMP
		return DERP_DEFAULT_POSE
	elseif val > DP_COMMON
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
	end
	
	local pose = DERP_POSES[mo.sprite2]
	local frame = P_RandomByte() % pose.poses
	mo.frame = $ + frame
	pose = $[frame]
	pose = $ or DERP_DEFAULT_POSE
	
	return pose
end

// Spawns a star mobj and returns it

local function SpawnStar(player, mo, pose, z, minaiming, maxaiming)
	local colors = pose.colors or DERP_DEFAULT_POSE.colors
	local frames = pose.frames or DERP_DEFAULT_POSE.frames
	
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
	
	star.sprite = pose.sprite or DERP_DEFAULT_POSE.sprite
	star.frame = $ + frames[P_RandomKey(#frames) + 1]
	star.color = colors[P_RandomKey(#colors) + 1] or player.skincolor
	
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
		
		// while this timer is active, the player can't be knocked back by boomearangs
		if mo.derp_knockback
			mo.derp_knockback = $ - 1
		end
		
		// if the player dies or switches skins, get rid of the Derp-related variables
		if mo.skin ~= SKIN
		or not mo.health
			if mo.derp
				local derp = mo.derp
				if derp.prevcarry == CR_MINECART
					local hat = P_SpawnMobjFromMobj(mo, 0, 0, mo.height, MT_DERP_MINECARTHAT)
					hat.skin = mo.skin
					hat.state = $
					P_SetObjectMomZ(hat, hat.info.mass, false)
					hat.movedir = mo.angle + ANGLE_90
				end
				if valid(derp.ear)
					P_RemoveMobj(derp.ear)
				end
				mo.derp = nil
			end
			continue
		end
		
		// set up Derp variables
		if not mo.derp
			mo.derp = {}
			local derp = mo.derp
			derp.flags = 0
			derp.stars = {}
			derp.buttons = {}
			derp.prevposition = {mo.x, mo.y, mo.z}
			
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
		
		// NiGHTS stuff - Derp has an extra transformation frame
		if (mo.state == S_PLAY_SUPER_TRANS4 or mo.state == S_PLAY_NIGHTS_TRANS4)
		and mo.tics == states[mo.state].tics - 1
			local tics = mo.tics
			mo.state = $
			mo.tics = tics
		end
		
		if player.powers[pw_carry] == CR_NIGHTSMODE
			if player.exiting
			and mo.state == S_PLAY_NIGHTS_FLOAT // Derp uses the spring state here since it has actual rotations
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
				local ear = P_SpawnMobjFromMobj(mo, 0, 0, 0, MT_BOOMEARANG)
				ear.target = mo
				ear.skin = mo.skin
				ear.state = $
				ear.color = mo.color
				ear.angle = angle - ANGLE_90
				P_TryMove(ear, mo.x + x, mo.y + y, true)
				derp.ear = ear
			end
		end
		
		local ear = derp.ear // search for items to target while boomearang is out
		if valid(ear)
		and not valid(ear.tracer)
		and ear.reactiontime <= 0
		and not (ear.flags2 & MF2_DONTRESPAWN)
			local item = P_LookForEnemies(player, false, true)
			if valid(item)
			and not (item.type == MT_METALSONIC_BATTLE and item.flags2 & MF2_INVERTAIMABLE)
				if derp.buttons[BT_USE] == 1
					ear.tracer = item
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
				
				if slope // rotate & angle the player if bouncing off a slope
					local roll = slope.zangle
					player.drawangle = slope.xydirection
					if roll > 0
						player.drawangle = $ + ANGLE_180
					else
						roll = InvAngle(roll)
					end
					mo.frame = $ + 6*(roll/ANG1)/90
					mo.rollangle = FixedMul(sin(player.drawangle - R_PointToAngle(mo.x, mo.y)), roll)
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
					table.insert(derp.stars, SpawnStar(player, mo, DERP_DEFAULT_POSE, z, minaiming, maxaiming))
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
			if derp.flags & DF_BOUNCING
				local frame = min(max(-flip*mo.momz/FixedMul(BOUNCE_DISPLAY_FAST_THRESHOLD, mo.scale), 0), 3)
				local ghost = P_SpawnGhostMobj(mo)
				if valid(ghost.tracer) // no followmobj ghosts here, sorry
					P_RemoveMobj(ghost.tracer)
				end
				P_TeleportMove(ghost, unpack(derp.prevposition))
				ghost.fuse = 5
				ghost.rollangle = mo.rollangle
				mo.frame = frame | ($ & ~FF_FRAMEMASK)
			else
				if derp.tics <= 0
					if derp.bounces // change animation based on whether bounces remain
						mo.state = S_PLAY_ROLL
					elseif mo.eflags & MFE_GOOWATER
						mo.state = S_PLAY_JUMP
						player.pflags = $ | PF_NOJUMPDAMAGE
					else
						mo.state = S_DERP_POSE
						derp.pose = ChoosePose(player)
						S_StartSound(mo, derp.pose.sound == nil and DERP_DEFAULT_POSE.sound or derp.pose.sound)
						player.pflags = $ | PF_NOJUMPDAMAGE
						local z = mo.z + (mo.height >> 1)
						for i = 1, MAX_STARS // spawn stars!!
							local star = SpawnStar(player, mo, derp.pose, z, -90, 90)
							
							if not star
								break
							end
							
							star.distx = 0
							star.disty = 0
							star.distz = mo.height >> 1
							
							table.insert(derp.stars, star)
						end
					end
				else // sort-of-hardcoded bounce animation
					local frames = {0, 1, 2, 3, 3, 2, 2, 2, 1, 1, 1, 0, 0, 0}
					derp.tics = $ - 1
					mo.frame = (frames[BOUNCE_ANIM_TIME - derp.tics] or 0) | ($ & ~FF_FRAMEMASK)
				end
			end
		end
		
		// Bounce pose
		if mo.state == S_DERP_POSE
			if derp.pose.animate // Sans
				mo.frame = derp.pose.animate[((leveltime/3) % #derp.pose.animate) + 1] | ($ & ~FF_FRAMEMASK)
			end
			
			if derp.pose.repeatsound // old Derp
				S_StartSound(mo, derp.pose.repeatsound)
			end
			
			if derp.pose.cursed // cursed Derp
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
			local angle = player.drawangle
			local voff = 28*FRACUNIT
			local hoff = 12*FRACUNIT
			local zoff = 18*FRACUNIT
			local angleoff = R_PointToAngle2(0, 0, voff, hoff)
			local dist = FixedHypot(hoff, voff)
			if mo.state ~= S_DERP_MINECART
				mo.state = S_DERP_MINECART
			end
			for i = 0, 1 // spawn hands each frame because I'm LAZY
				local xoff = FixedMul(dist, cos(angle + angleoff))
				local yoff = FixedMul(dist, sin(angle + angleoff))
				local hand = P_SpawnMobjFromMobj(mo, xoff, yoff, zoff, MT_THOK)
				hand.angle = angle
				hand.skin = mo.skin
				hand.state = S_DERP_MINECARTHAND
				hand.frame = $ + i
				hand.flags2 = $ | (mo.flags2 & MF2_DONTDRAW)
				angleoff = InvAngle($)
			end
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
			
			if star.distx ~= nil // star moves relative to Derp's position
				star.distx = $ + x
				star.disty = $ + y
				star.distz = $ + z
				
				x = mo.x + star.distx
				y = mo.y + star.disty
				z = mo.z + star.distz
			else // star moves relative to its spawn position
				x = star.x + $
				y = star.y + $
				z = star.z + $
			end
			
			P_TeleportMove(star, x, y, z)
			
			if star.fuse < STAR_LIFETIME >> 1
			and star.frame & FF_FULLBRIGHT // fullbright particles flicker towards the end of their lifespan
				if P_RandomKey(2)
					star.flags2 = $ ^^ MF2_DONTDRAW
				end
			end
		end
		
		// Handle followmobj ear
		local ear = player.followmobj
		if valid(ear) and ear.type == skins[SKIN].followitem
			local info = ear.info
			
			if not (ear.flags2 & MF2_DONTRESPAWN)
				ear.flags2 = $ | MF2_DONTRESPAWN
				ear.skin = mo.skin
				ear.sprite = SPR_PLAY
				ear.sprite2 = EAR_SPR2
			end
			
			local frame = DERP_EAR_FRAMES[mo.sprite2]
			frame = $ and $[mo.frame & FF_FRAMEMASK] or nil
			
			if frame == nil
			or valid(derp.ear)
			or mo.sprite ~= SPR_PLAY
				ear.frame = 0
			else
				ear.frame = frame | (mo.frame & ~FF_FRAMEMASK)
				
				ear.flags2 = mo.flags2
				ear.eflags = mo.eflags
				ear.color = mo.color
				ear.rollangle = mo.rollangle
			end
		end
		
		// variable handling
		derp.momz = mo.momz
		derp.prevposition = {mo.x, mo.y, mo.z}
		derp.prevcarry = player.powers[pw_carry]
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
		derp.flags = $ | DF_BOUNCING
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
	or player.pflags & (PF_JUMPED|PF_THOKKED)
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

local function EarBounce(ear)
	if not ear.valid return end
	
	S_StartSound(ear, ear.info.painsound)
	ear.momx = -$
	ear.momy = -$
	ear.momz = -$
	ear.angle = $ + ANGLE_180
	ear.aiming = InvAngle($)
	ear.bounces = $ - 1
	if ear.bounces <= 0
		ear.flags = $ | MF_NOCLIP | MF_NOCLIPHEIGHT
		ear.tracer = nil
		ear.flags2 = $ | MF2_DONTRESPAWN
	end
end

addHook("MobjThinker", function(ear)
	if not ear.valid then return end
	if not valid(ear.target)
		P_RemoveMobj(ear)
		return
	end
	
	local info = ear.info
	local aiming = 0
	local speed
	local angspeed
	
	// semantics
	
	if ear.angspeed == nil
		ear.bounces = 3
		ear.speed = FixedMul(info.speed, ear.scale)
		ear.angspeed = info.raisestate
		ear.aiming = 0
		ear.time = 0
	end
	
	if ear.reactiontime > 0
		ear.reactiontime = $ - 1
	else
		local speed = FixedHypot(FixedHypot(ear.momx, ear.momy), ear.momz)
		if speed < 3*(ear.speed >> 2)
		and not (ear.flags2 & MF2_DONTRESPAWN)
			EarBounce(ear)
		end
		ear.speed = $ + (ear.scale /10)
		ear.angspeed = $ + (ANG1 >> 2)
	end
	
	speed = ear.speed
	angspeed = ear.angspeed
	
	// aesthetics
	
	if ear.flags2 & MF2_DONTRESPAWN
		ear.flags2 = $ ^^ MF2_DONTDRAW
	end
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
			mo = ear.target
			if mo.eflags & MFE_VERTICALFLIP
				z = mo.z + 10*mo.scale
			else
				z = mo.z + mo.height - 10*mo.scale
			end
		end
		if mo
			local dist = FixedHypot(mo.x - ear.x, mo.y - ear.y)
			local angle = R_PointToAngle2(ear.x, ear.y, mo.x, mo.y)
			local aiming = R_PointToAngle2(0, ear.z + (ear.height >> 1), dist, z)
			local angdiff = angle - ear.angle
			local aimdiff = aiming - ear.aiming
			
			if mo == ear.target
				speed = max($, FixedHypot(mo.momx, mo.momy) + 8*mo.scale)
			end
			
			if ear.reactiontime
				ear.angle = $ + angspeed
			else
				ear.angle = $ + max(min(angdiff, angspeed), -angspeed)
				ear.aiming = $ + max(min(aimdiff, angspeed), -angspeed)
			end
		end
	end
	
	ear.time = $ + 1
	
	// movement
	
	ear.momz = FixedMul(speed, sin(ear.aiming))
	P_InstaThrust(ear, ear.angle, FixedMul(speed, cos(ear.aiming)))
end, MT_BOOMEARANG)

addHook("MobjMoveBlocked", function(ear)
	EarBounce(ear)
end, MT_BOOMEARANG)

addHook("MobjMoveCollide", function(ear, item)
	local mo
	local player
	if not ear.valid
	or not valid(item)
	or item.type == MT_PLAYER
	or item.z > ear.z + ear.height
	or ear.z > item.z + item.height
		return
	end
	
	mo = ear.target
	if not valid(mo) // does the boomearang have an owner?
	or not mo.player
	or not mo.derp
		return
	end
	
	if (item.flags & MF_SHOOTABLE and true) ~= (item.flags2 & MF2_INVERTAIMABLE and true)
		// spawn stars!!
		local z
		local minaiming, maxaiming
		if P_IsObjectOnGround(item) // if the object is grounded, spawn stars at its base
			if item.eflags & MFE_VERTICALFLIP
				z = item.z + item.height
				minaiming = -90
				maxaiming = -15
			else
				z = item.z
				minaiming = 15
				maxaiming = 90
			end
		else // if the object is aerial, spawn stars at its center
			z = item.z + (item.height >> 1)
			minaiming = -90
			maxaiming = 90
		end
		for i = 1, MAX_STARS
			table.insert(mo.derp.stars, SpawnStar(mo.player, item, DERP_DEFAULT_POSE, z, minaiming, maxaiming))
		end
		
		if item.flags & MF_MONITOR
			P_KillMobj(item, ear, mo)
		else
			P_DamageMobj(item, ear, mo)
		end
	end
	if item == ear.tracer // if the object it hits is its target, speed up
		local info = ear.info
		ear.speed = $ + FixedMul(info.speed >> 3, ear.scale)
		ear.angspeed = $ + (info.raisestate >> 1)
		ear.bounces = info.damage
		ear.tracer = nil
	end
end, MT_BOOMEARANG)

addHook("TouchSpecial", function(ear, mo)
	if not (ear.valid and mo.valid) return end
	
	local player = mo.player
	
	if ear.target == mo // remove the boomearang if it returns to its owner
		if not ear.tracer
		and not ear.reactiontime
			P_RemoveMobj(ear)
		end
	elseif player // knock back other players
	and not player.powers[pw_flashing]
	and not player.powers[pw_super]
	and not player.powers[pw_invulnerability]
	and not mo.derp_knockback
		P_DoPlayerPain(player, ear, ear.target)
		S_StartSound(mo, sfx_shldls)
		player.powers[pw_flashing] = 0
		mo.derp_knockback = BOOMEARANG_KNOCKBACK_DELAY
	end
	return true
end, MT_BOOMEARANG)

// tee hee extras

addHook("MobjThinker", function(mo)
	if not mo.valid return end
	
	if P_IsObjectOnGround(mo)
		P_KillMobj(mo)
		return
	end
	
	local flip = P_MobjFlip(mo)
	local info = mo.info
	local fallspeed = flip*mo.momz
	if fallspeed <= 0
		if fallspeed < info.speed
			P_SetObjectMomZ(mo, info.speed, false)
		end
		mo.threshold = $ + ANG10
		mo.rollangle = FixedMul(info.painchance, sin(mo.threshold))
		P_InstaThrust(mo, mo.movedir, FixedMul(info.damage, cos(mo.threshold)))
	end
end, MT_DERP_MINECARTHAT)