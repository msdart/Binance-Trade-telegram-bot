--<<Techies fast start helper and many more>>

require("libs.ScriptConfig")
require("libs.Utils")
require("libs.TargetFind")

local config = ScriptConfig.new()
config:SetParameter("AutoPick", true)
config:SetParameter("SkillBuild", 1)
config:SetParameter("StartingItems", 1)
config:SetParameter("CheatMidMine", "T", config.TYPE_HOTKEY)
config:Load()

local autopick = config.AutoPick
local skillbuild = config.SkillBuild
local startingitems = config.StartingItems
local midmine = config.CheatMidMine

local x_ratio = client.screenSize.x/1600
local F14 = drawMgr:CreateFont("F11","Tahoma",14*x_ratio,550*x_ratio)
local victimText = drawMgr:CreateText(-40*x_ratio,-65*x_ratio,0x5279FFff,"",F14) victimText.visible = false

local reg = false
local active = false
local unbindhotkeys = false
local drawblockpoints = true
local mine_position = nil
local state = 1

local sleepTick = nil

local mine_effect = nil
local forcestaff_effect = nil
local effects = {}

--=====================<< SkillBuilds >>=======================
--1 - mine, 2 - trap, 3 - suicide, 6 - ult, 7 - attribute bonus
local sb1 = {1,3,1,3,1,6,1,3,3,2,6,2,2,2,7,6,7,7,7,7,7,7,7,7,7}
local sb2 = {1,7,1,7,1,6,1,7,7,7,6,2,2,2,2,6,7,7,7,7,7,3,3,3,3}
--====================<< Starting Items >>=====================
--38 - clarity, 28 - sage mask, 46 - tp, 177 - soul ring recipe
local bi1 = {38, 38, 38, 28, 46}
local bi2 = {38, 38, 38, 28, 177}
--=========================<< END >>===========================

Positions = {
	--[[Radiant]]
	
	--[[Easy camp]] 			{Vector(2596,-4519,256)},
	--[[Easy camp 2]] 			{Vector(3680,-4448,256)},
	--[[Easy camp 3]] 			{Vector(3365,-4441,256)},
	--[[Left hard camp]]		{Vector(-1498,-4122,128)},
	--[[Left medium camp]]		{Vector(-800,-3360,127)},
	--[[Left medium camp 2]]	{Vector(32,-3452,256)},
	--[[Right hard camp]]		{Vector(2035,-3612,256)},
	--[[Right hard camp 2]]		{Vector(1958,-3289,256)},
	--[[Right medium camp]]		{Vector(3488,-3168,241)},
	--[[Ancient camp]] 			{Vector(-3488,160,248)},
	--[[Ancient camp 2]]		{Vector(-3110,738,256)},
	--[[Ancient camp 3]]		{Vector(-2784,480,256)},

	--[[Dire]]
	
	--[[Easy camp]]				{Vector(-3360,4000,256)},
	--[[Easy camp 2]] 			{Vector(-2714,4260,256)},
	--[[Easy camp 3]] 			{Vector(-3168,4256,256)},
	--[[Left hard camp]]		{Vector(-3764,3296,256)},
	--[[Left hard camp 2]]		{Vector(-4000,3296,256)},
	--[[Left hard camp 3]]		{Vector(-4990,3360,256)},
	--[[Left medium camp]]		{Vector(-992,2336,256)},
	--[[Left medium camp 2]]	{Vector(-1056,2464,256)},
	--[[Left medium camp 3]]	{Vector(-1312,2336,256)},
	--[[Right hard camp]]		{Vector(1504,2848,256)},
	--[[Right hard camp 2]]		{Vector(1632,3424,256)},
	--[[Right medium camp]]		{Vector(-736,3296,256)},
	--[[Right medium camp 2]]	{Vector(-352,3296,256)},
	--[[Ancient camp]]			{Vector(3936,-1120,256)},
	--[[Ancient camp 2]]		{Vector(4384,-224,128)},
	--[[Ancient camp 3]]		{Vector(3691,-249,256)},
	
}

function Key(msg,code)
	if not PlayingGame() or client.chat then return end	
	
	
	if msg == KEY_DOWN then
		local me = entityList:GetMyHero()
		local forcestaff = me:FindItem("item_dagon")
		if code == 70 and forcestaff and forcestaff.cd == 0 and forcestaff:CanBeCasted() and not forcestaff_effect then
			forcestaff_effect = Effect(me,"range_display")
			forcestaff_effect:SetVector(1,Vector(forcestaff.castRange,0,0))
		end
	end	
	if msg == KEY_UP then
		if code == 70 and forcestaff_effect then
			forcestaff_effect = nil
			collectgarbage("collect")
		end
	end
end

function Tick(tick)
	if not client.connected or client.loading or client.console then return end
	local state
	if client.gameState == Client.STATE_PICK and autopick then
		client:ExecuteCmd("dota_select_hero npc_dota_hero_techies")
		autopick = false
	end		
	
	if PlayingGame() then
		local me = entityList:GetMyHero()	
		if not me then return end
		if me.classId ~= CDOTA_Unit_Hero_Techies then return end
		
		if drawblockpoints then
			for i = 1,#Positions do
				effects[i] = Effect( Positions[i][1], "blueTorch_flame")
				effects[i]:SetVector( 0, Positions[i][1])
			end
			state = 1
			drawblockpoints = false
		end
		
		local mp = entityList:GetMyPlayer()
		
		local sel = mp.selection[1]
		if sel and sel.name == "npc_dota_hero_techies" and unbindhotkeys then
			client:ExecuteCmd("unbind q")
			client:ExecuteCmd("unbind w")
			client:ExecuteCmd("unbind d")
			client:ExecuteCmd("unbind f")
			client:ExecuteCmd("unbind r")
			unbindhotkeys = false
		elseif sel and sel.name ~= "npc_dota_hero_techies" and not unbindhotkeys then
			client:ExecuteCmd("bind q \"dota_ability_quickcast 0\"")
			client:ExecuteCmd("bind w \"dota_ability_quickcast 1\"")
			client:ExecuteCmd("bind d \"dota_ability_quickcast 3\"")
			client:ExecuteCmd("bind f \"dota_ability_quickcast 4\"")
			client:ExecuteCmd("bind r \"dota_ability_quickcast 5\"")
			unbindhotkeys = true
		end
		
		if sleepTick and sleepTick > tick then
			active = false 
		else
			active = true
		end
		
		if skillbuild == 1 then
			sb = sb1
		elseif skillbuild == 2 then
			sb = sb2
		end
		
		if startingitems == 1 then
			bi = bi1
		elseif startingitems == 2 then
			bi = bi2
		end
		
		if mp.team == LuaEntity.TEAM_DIRE then
			mine_position = Vector(6152,-4459,256)
		elseif mp.team == LuaEntity.TEAM_RADIANT then
			mine_position = Vector(-6259,4897,256)
		end
		
		if client.gameTime < 120 and not mine_effect then
			mine_effect = Effect(mine_position,"aura_vlads")
			mine_effect:SetVector(0,mine_position)
		elseif client.gameTime > 120 and mine_effect then
			mine_effect = nil
			collectgarbage("collect")
		end

		if active then
			local points = me.abilityPoints		
			if points > 0 then
				local prev = SelectUnit(me)
				mp:LearnAbility(me:GetAbility(sb[me.level+1-points]))
				SelectBack(prev)
				sleepTick = GetTick() + 125
			end
		end
		
		--[[ D hotkey - better focused detonate ]]
		if IsKeyDown(68) and not client.chat and sel and sel.name == "npc_dota_hero_techies" then
			local cursor = client.mousePosition
			local friendly_mine = entityList:GetEntities({classId==CDOTA_NPC_TechiesMines}) 
			for i,v in ipairs(friendly_mine) do
				if v.alive and v.name == "npc_dota_techies_remote_mine" and GetDistance2D(v,cursor) <= 200 and v:GetAbility(1).level == 1 then
					local prev = SelectUnit(me)
					mp:Select(v)
					v:CastAbility(v:GetAbility(1))
					SelectBack(prev)
				end
			end
		end
		
		if me.alive then
			if state == 1 and me.level == 1 then
				for i, itemID in ipairs(bi) do
					mp:BuyItem(itemID)
				end
				state = 2
				sleepTick = GetTick() + 500
			end
			if active then
				if state == 2 and bi2 then
					local tp = me:FindItem("item_tpscroll")
					local mine = me:GetAbility(1)
					if tp and mine then
						me:CastAbility(tp,mine_position)
						me:CastAbility(mine,mine_position,true)
						state = 3
					end
				end
			end
			if not client.chat and active and sel and sel.name == "npc_dota_hero_techies" then
				local cursor = client.mousePosition
				local friendly_mine = entityList:GetEntities(function (ent) return ent.classId==CDOTA_NPC_TechiesMines and GetDistance2D(ent,cursor) <= 100 end)[1]
				--[[ Q hotkey - land mine ]]
				if IsKeyDown(81) then
					local mine = me:GetAbility(1)
					if mine:CanBeCasted() and friendly_mine then
						me:CastAbility(mine,friendly_mine.position)
						sleepTick = GetTick() + 250
					elseif mine:CanBeCasted() then
						me:CastAbility(mine,cursor)
						sleepTick = GetTick() + 250
					end
				end
				--[[ W hotkey - trap ]]
				if IsKeyDown(87) then
					local trap = me:GetAbility(2)
					if trap:CanBeCasted() and friendly_mine then
						me:CastAbility(trap,friendly_mine.position)
						sleepTick = GetTick() + 250
					elseif trap:CanBeCasted() then
						me:CastAbility(trap,cursor)
						sleepTick = GetTick() + 250
					end
				end
				--[[ R hotkey - remote mine ]]
				if IsKeyDown(82) then
					local remote_mine = me:GetAbility(6)
					if remote_mine:CanBeCasted() and friendly_mine then
						me:CastAbility(remote_mine,friendly_mine.position)
						sleepTick = GetTick() + 250
					elseif remote_mine:CanBeCasted() then
						me:CastAbility(remote_mine,cursor)
						sleepTick = GetTick() + 250
					end
				end
				--[[ end hotkey - cheat remote mine on mid ]] -- I don't know if we should use it.
				if IsKeyDown(midmine) then
					local remote_mine = me:GetAbility(6)
					local mine = me:GetAbility(1)
					local trap = me:GetAbility(2)
					if remote_mine:CanBeCasted() then
						me:CastAbility(remote_mine,nil)
						sleepTick = GetTick() + 250
					elseif mine:CanBeCasted() then
						me:CastAbility(mine,nil)
						sleepTick = GetTick() + 250
					elseif trap:CanBeCasted() then
						me:CastAbility(trap,nil)
						sleepTick = GetTick() + 250
					end
				end
				--[[ F hotkey - forcestaff ]]
				local forcestaff = me:FindItem("item_dagon")
				if forcestaff and forcestaff.cd == 0 and forcestaff:CanBeCasted() then
					local victim = targetFind:GetClosestToMouse(100)
					local friendly_mine = entityList:GetEntities(function (ent) return ent.classId==CDOTA_NPC_TechiesMines and GetDistance2D(ent,victim) < 600 + 425 end)[1]
					if victim and not victim.visible then victim = nil end
					if victim and victim.alive and victim.visible then
						local IV  = victim:IsInvul()
						local MI  = victim:IsMagicImmune()
						local LS  = victim:IsLinkensProtected()
						if not (IV or MI or LS) then
							if friendly_mine then
								victimText.visible = true
								victimText.text = "Blow him up!"
								victimText.entity = victim
								victimText.color = 0xAFAFAFAA
								if GetDistance2D(me,victim) <= forcestaff.castRange then
									victimText.color = 0xFF0000FF
								end
								if victim.healthbarOffset then
									victimText.entityPosition = Vector(0,0,victim.healthbarOffset)
								end	
								--Maybe I should add "me:GetTurnTime(victim) == 0" to next if
								if IsKeyDown(70) then
									if (math.max(math.abs(FindAngleR(victim) - math.rad(FindAngleBetween(victim, friendly_mine))) - 0.69, 0) > -(1/500)*math.pi) and (math.max(math.abs(FindAngleR(victim) - math.rad(FindAngleBetween(victim, friendly_mine))) - 0.69, 0) < (1/500)*math.pi) and GetDistance2D(victim,me) <= forcestaff.castRange then
										me:CastAbility(forcestaff,victim)
										sleepTick = GetTick() + 250
									end
								end
							elseif victimText.visible then
								victimText.visible = false
							end
						end
					elseif victimText and victimText.visible then
						victimText.visible = false
					end	
				end
			end
		end
	end
end

function Load()
	if client.connected and not (client.loading or client.console) then
		reg = true
		script:RegisterEvent(EVENT_KEY,Key)
		script:RegisterEvent(EVENT_TICK,Tick)
		script:UnregisterEvent(Load)
	end
end

function GameClose()
	victimText.visible = false
	active = false
	unbindhotkeys = false
	sleepTick = nil
	mine_position = nil
	mine_effect = nil
	forcestaff_effect = nil
	effects = {}
	collectgarbage("collect")
	if reg then
		script:UnregisterEvent(Key)
		script:UnregisterEvent(Tick)
		script:RegisterEvent(EVENT_TICK,Load)
		reg = false
	end
end

script:RegisterEvent(EVENT_CLOSE,GameClose)
script:RegisterEvent(EVENT_TICK,Load)
