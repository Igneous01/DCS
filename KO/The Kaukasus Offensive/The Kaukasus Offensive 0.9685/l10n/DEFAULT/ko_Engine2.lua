----------------------------------------------------------------------------------------------------------
-- 										koEngine
----------------------------------------------------------------------------------------------------------
-- 
---		 Core of The Kaukasus Offensive
--			- Definitions
--			- Utility Functiosn
--			- Runtime
--
----------------------------------------------------------------------------------------------------------

--MissionData = MissionData or {}
PlayerList = {}							-- the players-online list
koEngine = {}

----------------------------------------------------------------------------------------------------------
-- 										JSON/UDP stuff
----------------------------------------------------------------------------------------------------------

package.path  = package.path..";.\\LuaSocket\\?.lua;"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

local JSON = loadfile("Scripts\\JSON.lua")()
local socket = require("socket")

-- UDP Declaration
koEngine.JSON = JSON
koEngine.GAMEGUI_RECEIVE_PORT = 6005	-- SR clientlist port
koEngine.GAMEGUI_SEND_TO_PORT = 6006
koEngine.SAVEGAME_SEND_TO_PORT = 6007
koEngine.UDPSavegameSendSocket = socket.udp()
koEngine.UDPGameGuiReceiveSocket = socket.udp()
koEngine.UDPGameGuiReceiveSocket:setsockname("*", koEngine.GAMEGUI_RECEIVE_PORT)
koEngine.UDPGameGuiReceiveSocket:settimeout(.0001) --receive timer

koEngine.savegameFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_Savegame.lua"
koEngine.playerListFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_PlayersOnline.lua"
koEngine.playerDataFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_PlayerData.lua"
koEngine.scoreboardFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_Scores.lua"
koEngine.scoreboardFileName2 = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\scores\\ko_Scores_"
koEngine.scoreIDFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_ScoreID.lua"
koEngine.sessionIDFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_SessionID.lua"
koEngine.sortieIDFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_SortieID.lua"
koEngine.activeSortiesFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\ko_Sorties.lua"
koEngine.sessionID = -100				-- unique id of the server session, everytime the mission loads it's increasing it and saved to sessionIDFileName

-- load session id first
DataLoader = loadfile(koEngine.sessionIDFileName)
if DataLoader ~= nil then		-- File open?
	koEngine.sessionID = DataLoader()
	koEngine.sessionID = koEngine.sessionID + 1 
else
	koEngine.sessionID = 0
end

local exportData = "return "..koEngine.sessionID
local exportFile = assert(io.open(koEngine.sessionIDFileName, "w"))
exportFile:write(exportData)
exportFile:flush()
exportFile:close()
exportFile = nil

-- setup logfile
--koEngine.logFile = io.open(lfs.writedir()..[[Logs\ko_session]]..koEngine.sessionID..[[.log]], "w")
function koEngine.log(txt)
	--if koEngine.logFile then
	-- 	koEngine.logFile:write(string.format("%09.3f", tostring(timer.getTime())).."\t"..txt.."\n")
	--    koEngine.logFile:flush()
    --else
    --	env.info("LOG FAILED")
    --end
    env.info(txt)
end

if not MissionData then 
	MissionData = {}
else
	koEngine.log("MissionData is available")
end

----------------------------------------------------------------------------------------------------------
-- 										Definitions
----------------------------------------------------------------------------------------------------------

----------------------------------------------
--					Variables
----------------------------------------------

koEngine.debugOn = false				-- false for online testing!!
koEngine.lifeResetTime = 4				-- how many hours of mission-runtime till life-reset
koEngine.intelMessageDisplayTime = 30	-- how long should intel-messages be displayed
koEngine.troopPickupLimit = 10000 		-- pickup limit for pickupzones (no units available) -1 = unlimited
koEngine.attackRadius = 20000			-- radius in m that needs to be no enemys so underAttack can be set false
koEngine.saveTime = 1					-- interval in minutes to save the mission state! 
koEngine.mainLoopFrequency = 5			-- loop main every 5 seconds
koEngine.samLifeTime = 48				-- keep dropped sams alive for 1 day
koEngine.ejectedPilotLifetime = 72		-- ejected pilots should last 3 days
koEngine.maxEjectedPilots = 70			-- maximum pilots being saved
koEngine.crateLifetime = 48				-- ejected pilots should last 3 days

-- TODO convoy definitions
koEngine.convoyInterval = 20			-- convoy how often in minutes
koEngine.convoyMaxUnits = 15			-- how many units may be present to send a convoy?
koEngine.convoyCost = {					-- price per convoy in $
	['defensive'] = 10000,
	['groundcrew'] = 20000,
	--['LR-SAM'] = 20000,
	['offensive'] = 30000,
}

koEngine.convoyTypes = {
	['blue'] = {
		['defensive'] = {
			[1] = 'M-1 Abrams',
			[2] = 'Vulcan',
			[3] = 'M48 Chaparral',
			[4] = 'Tor 9A331',
		},
		['groundcrew'] = {
			[1] = 'M1097 Avenger',
			[2] = 'M1025 HMMWV',
			[3] = 'M 818',
			[4] = 'M978 HEMTT Tanker',
		},
		['offensive'] = {
			[1] = 'M-1 Abrams',
			[2] = 'Vulcan',
			[3] = 'M48 Chaparral',
			[4] = 'M-2 Bradley',
		},
		--[[['LR-SAM'] = {
			[1] = 'SA-11 Buk LN 9A310M1',
			[2] = 'SA-11 Buk CC 9S470M1',
			[3] = 'SA-11 Buk SR 9S18M1',
			[4] = 'M48 Chaparral',
			[5] = 'SA-11 Buk LN 9A310M1',
			[6] = 'SA-11 Buk LN 9A310M1',--]]
			--[[[1] = 'Hawk ln',	-- hawk doesnt move, need to work around, buk instead
			[2] = 'Hawk tr',
			[3] = 'Hawk sr',
			[4] = 'Hawk pcp',
			[5] = 'Hawk ln',
			[6] = 'Hawk ln',--]]
       	--},
	},
	['red'] = {
		['defensive'] = {
			[1] = 'T-90',
			[2] = 'ZSU-23-4 Shilka',
			[3] = 'Strela-10M3',
			[4] = 'Tor 9A331',
		},
		['groundcrew'] = {
			[1] = 'Strela-10M3',
			[2] = 'SKP-11',
			[3] = 'Ural-375',
			[4] = 'ATZ-10',
		},
		['offensive'] = {
			[1] = 'T-90',
			[2] = 'ZSU-23-4 Shilka',
			[3] = 'Strela-10M3',
			[4] = 'BMP-3',
		},
		--[[['LR-SAM'] = {
			[1] = 'SA-11 Buk LN 9A310M1',
			[2] = 'SA-11 Buk CC 9S470M1',
			[3] = 'SA-11 Buk SR 9S18M1',
			[4] = 'Strela-10M3',
			[5] = 'SA-11 Buk LN 9A310M1',
			[6] = 'SA-11 Buk LN 9A310M1',
       	},--]]
	},
}


koEngine.dropZoneTable = {}				-- list of all objective-zones
koEngine.PlayerData = {}				-- holds information about connected Clients (managed in ../Scripts/koSlotBlockGameGUI.lua)
koEngine.PlayerUnitList = {}			-- holds a list of units players are spawned in
koEngine.PlayersInZone = {}
koEngine.zoneUnitData = {}				-- all untis that should trigger objective Zones
koEngine.menuForGroup = {}				-- table that holds all groups that have radio menus already created!

koEngine.lastMainLoop = 0				-- keeps track of when the main loop was last run. used for restarting main()
koEngine.missionOver = false



if not koEngine.debugOn then
	env.setErrorMessageBoxEnabled(false)-- no error messages unless in debug mode!
end

local coalitionTable = {
	[0] = 'neutral',
	[1] = 'red',
	[2] = 'blue',
}

local coaNameTable = {
	['neutral'] = 0,
	['red'] = 1,
	['blue'] = 2,
}

local counterCoa = {
	["red"] = "blue",
	["blue"] = "red",
}

local unitCategoryTable = {
	[0] = "AIRPLANE",
	[1] = "HELICOPTER",
	[2] = "GROUND_UNIT",
	[3] = "SHIP",
	[4] = "STRUCTURE",
}

local eventTable = {
	[0] = "S_EVENT_INVALID",
	[1] = "S_EVENT_SHOT",
	[2] = "S_EVENT_HIT",
	[3] = "S_EVENT_TAKEOFF",
	[4] = "S_EVENT_LAND",
	[5] = "S_EVENT_CRASH",
	[6] = "S_EVENT_EJECTION",
	[7] = "S_EVENT_REFUELING",
	[8] = "S_EVENT_DEAD",
	[9] = "S_EVENT_PILOT_DEAD",
	[10] = "S_EVENT_BASE_CAPTURED",
	[11] = "S_EVENT_MISSION_START",
	[12] = "S_EVENT_MISSION_END",
	[13] = "S_EVENT_TOOK_CONTROL",
	[14] = "S_EVENT_REFUELING_STOP",
	[15] = "S_EVENT_BIRTH",
	[16] = "S_EVENT_HUMAN_FAILURE",
	[17] = "S_EVENT_ENGINE_STARTUP",
	[18] = "S_EVENT_ENGINE_SHUTDOWN",
	[19] = "S_EVENT_PLAYER_ENTER_UNIT",
	[20] = "S_EVENT_PLAYER_LEAVE_UNIT",
	[21] = "S_EVENT_PLAYER_COMMENT",
	[22] = "S_EVENT_SHOOTING_START",
	[23] = "S_EVENT_SHOOTING_END",
	[24] = "S_EVENT_MAX"
}


----------------------------------------------
-- 				utility functions
----------------------------------------------

---============================================================
-- add comma to separate thousands
-- 
function comma_value(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

---============================================================
-- rounds a number to the nearest decimal places
--
function round(val, decimal)
  if (decimal) then
    return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
  else
    return math.floor(val+0.5)
  end
end

--===================================================================
-- given a numeric value formats output with comma to separate thousands
-- and rounded to given decimal places
--
--
function format_num(amount, decimal, prefix, neg_prefix)
  local str_amount,  formatted, famount, remain

  decimal = decimal or 0  -- default 0 decimal places
  neg_prefix = neg_prefix or "-" -- default negative sign

  famount = math.abs(round(amount,decimal))
  famount = math.floor(famount)

  remain = round(math.abs(amount) - famount, decimal)

        -- comma to separate the thousands
  formatted = comma_value(famount)

        -- attach the decimal portion
  if (decimal > 0) then
    remain = string.sub(tostring(remain),3)
    formatted = formatted .. "." .. remain ..
                string.rep("0", decimal - string.len(remain))
  end

        -- attach prefix string e.g '$' 
  formatted = (prefix or "") .. formatted 

        -- if value is negative then format accordingly
  if (amount<0) then
    if (neg_prefix=="()") then
      formatted = "("..formatted ..")"
    else
      formatted = neg_prefix .. formatted 
    end
  end

  return formatted
end

-------------------------------------------------------------------------------------------------------------
--	mist.getDeadUnitsLOS = function(unitset1, altoffset1, unitset2, altoffset2, radius)
--	same as mist.getUnitsLOS but it accepts a dead/inactive unitset1!
mist.getDeadUnitsLOS = function(unitset1, altoffset1, unitset2, altoffset2, radius)
	radius = radius or math.huge
	local unit_info1 = {}
	local unit_info2 = {}
	
	if not unitset1 or not unitset2 then return {} end
	
	-- get the positions all in one step, saves execution time.
	for unitset1_ind = 1, #unitset1 do
		local unit1 = Unit.getByName(unitset1[unitset1_ind])
		if unit1 then
			unit_info1[#unit_info1 + 1] = {}
			unit_info1[#unit_info1]["unit"] = unit1
			unit_info1[#unit_info1]["pos"]  = unit1:getPosition().p
		end
	end
	
	for unitset2_ind = 1, #unitset2 do
		local unit2 = Unit.getByName(unitset2[unitset2_ind])
		if unit2 and unit2:isActive() == true then
			unit_info2[#unit_info2 + 1] = {}
			unit_info2[#unit_info2]["unit"] = unit2
			unit_info2[#unit_info2]["pos"]  = unit2:getPosition().p
		end
	end

	local LOS_data = {}
	-- now compute los
	for unit1_ind = 1, #unit_info1 do
		local unit_added = false
		for unit2_ind = 1, #unit_info2 do
			if radius == math.huge or (mist.vec.mag(mist.vec.sub(unit_info1[unit1_ind].pos, unit_info2[unit2_ind].pos)) < radius) then -- inside radius
				local point1 = { x = unit_info1[unit1_ind].pos.x, y = unit_info1[unit1_ind].pos.y + altoffset1, z = unit_info1[unit1_ind].pos.z}
				local point2 = { x = unit_info2[unit2_ind].pos.x, y = unit_info2[unit2_ind].pos.y + altoffset2, z = unit_info2[unit2_ind].pos.z}
				if land.isVisible(point1, point2) then
					if unit_added == false then
						unit_added = true
						LOS_data[#LOS_data + 1] = {}
						LOS_data[#LOS_data]['unit'] = unit_info1[unit1_ind].unit
						LOS_data[#LOS_data]['vis'] = {}
						LOS_data[#LOS_data]['vis'][#LOS_data[#LOS_data]['vis'] + 1] = unit_info2[unit2_ind].unit 
					else
						LOS_data[#LOS_data]['vis'][#LOS_data[#LOS_data]['vis'] + 1] = unit_info2[unit2_ind].unit 
					end
				end
			end
		end
	end
	
	return LOS_data
end

-------------------------------------------------------------------------------------------------------------
--	mist.getDeadUnitsLOS = function(unitset1, altoffset1, unitset2, altoffset2, radius)
--	same as mist.getUnitsLOS but it accepts a dead/inactive unitset1!
koEngine.getLOSUnitsFromPoint = function(point1, unitset, altoffset2, radius)
	radius = radius or math.huge
	
	if not unitset then return {} end
	
	local unit_info = {}
	
	
	-- get the positions all in one step, saves execution time.
	for unitset_ind = 1, #unitset do
		local unit = Unit.getByName(unitset[unitset_ind])
		if unit and unit:isActive() then
			unit_info[#unit_info + 1] = {}
			unit_info[#unit_info]["unit"] = unit
			unit_info[#unit_info]["pos"]  = unit:getPosition().p
			
			--koEngine.debugText("getting LOS from "..#unit_info.." units from point: "..koEngine.TableSerialization(point1).."\n unitPos = "..(koEngine.TableSerialization(unit_info[1].pos) or 0))
		end
	end
	
	

	local LOS_data = {}
	-- now compute los

	for unit_ind = 1, #unit_info do
		if radius == math.huge or (mist.vec.mag(mist.vec.sub(point1, unit_info[unit_ind].pos)) < radius) then -- inside radius
			--koEngine.debugText("unit is inside radius, "..mist.vec.mag(mist.vec.sub(point1, unit_info[unit_ind].pos)).."m away, checking los")
			local point2 = { x = unit_info[unit_ind].pos.x, y = unit_info[unit_ind].pos.y + altoffset2, z = unit_info[unit_ind].pos.z}
			if land.isVisible(point1, point2) then
					--koEngine.debugText("unit is within los!")
					LOS_data[#LOS_data + 1] = {}
					LOS_data[#LOS_data]['point'] = point1
					LOS_data[#LOS_data]['vis'] = {}
					LOS_data[#LOS_data]['vis'][#LOS_data[#LOS_data]['vis'] + 1] = unit_info[unit_ind].unit 
			end
		end
	end
	
	return LOS_data
end

function koEngine.getClockDirection(unit, pos2)
    -- Source: Helicopter Script - Thanks!

    local _playerPosition = unit:getPosition().p -- get position of helicopter
    local _relativePosition = mist.vec.sub(pos2, _playerPosition)

    local _playerHeading = mist.getHeading(unit) -- the rest of the code determines the 'o'clock' bearing of the missile relative to the helicopter

    local _headingVector = { x = math.cos(_playerHeading), y = 0, z = math.sin(_playerHeading) }

    local _headingVectorPerpendicular = { x = math.cos(_playerHeading + math.pi / 2), y = 0, z = math.sin(_playerHeading + math.pi / 2) }

    local _forwardDistance = mist.vec.dp(_relativePosition, _headingVector)

    local _rightDistance = mist.vec.dp(_relativePosition, _headingVectorPerpendicular)

    local _angle = math.atan2(_rightDistance, _forwardDistance) * 180 / math.pi

    if _angle < 0 then
        _angle = 360 + _angle
    end
    _angle = math.floor(_angle * 12 / 360 + 0.5)
    if _angle == 0 then
        _angle = 12
    end

    return _angle
end

-------------------
--[[ koEngine.outText()
-- outputs ingame text without time required to state (default 10 seconds)--]]
function koEngine.outText(text, displayTime, clearview)
	if displayTime == nil then
		displayTime = 10
	end

	koEngine.log("koEngine.outText: "..text)
	trigger.action.outText(text, displayTime, clearview)
end

-------------------
--[[ koEngine.outTextForCoalition()
-- outputs ingame text to coalition time without time required to state (default 10 seconds)--]]
function koEngine.outTextForCoalition(coalition, text, displayTime, clearview)
	koEngine.log("koEngine.outTextForCoalition: " ..coalitionTable[coalition] .. " '" .. text .. "'")
	if displayTime == nil then
		displayTime = 10
	end
	trigger.action.outTextForCoalition(coalition, text, displayTime, clearview)
end

-------------------
--[[ koEngine.outTextForGroup()
-- outputs ingame text to coalition time without time required to state (default 10 seconds)--]]
function koEngine.outTextForGroup(groupID, text, displayTime, clearview)
	koEngine.log("koEngine.outTextForGroup ('"..tostring(koEngine.PlayerUnitList[tostring(groupID)].playerName).."'): " .. text)
	displayTime = displayTime or 10
	
	trigger.action.outTextForGroup(groupID, text, displayTime, clearview)
end

-------------------
--[[ koEngine.debugText()
-- 
-- on/off set koEngine.debugOn = true in definitions
-- outputs ingame text without time required to state (default 10 seconds)
-- ALSO OUTPUTS IN dcs.log!--]]
function koEngine.debugText(text, displayTime, clearview)
	--if (koEngine.debugOn == false) then -- only run when debugmode
		--return
	--end
	
	if displayTime == nil then
		displayTime = 10
	end
	
	text = "koEngine.debugText:\t" .. text
	if koEngine.debugOn == true then 
		trigger.action.outText(text, displayTime, clearview) -- only run when debugmode
	end
	--koEngine.log(text)
	env.info(text)
end


--CiriBob's get groupID function
function getGroupId(_unit)
	local _unitDB =  mist.DBs.unitsById[tonumber(_unit:getID())]
    if _unitDB ~= nil and _unitDB.groupId then
        return _unitDB.groupId
    end

    return nil
end

--CiriBob's get groupName function
function getGroupName(_unit)
    local _unitDB =  mist.DBs.unitsById[tonumber(_unit:getID())]
    if _unitDB ~= nil and _unitDB.groupId then
        return _unitDB.groupName
    end

    return nil
end

-- not working for clients!!!
function getGroupFromUnit(_unit)
	local _groupName = getGroupName(_unit)
	koEngine.debugText("groupname = ".._groupName)
	return Group.getByName(_groupName)
end

-- ciribobs group-check functions
local function isGroupThere(_groupName)
	return Group.getByName(_groupName)
			and Group.getByName(_groupName):isExist()
			and #Group.getByName(_groupName):getUnits() >= 1
			and Group.getByName(_groupName):getUnits()[1]:isActive()
end

local function isAllOfGroupThere(_groupName)
	if not isGroupThere(_groupName) then
		return false
	end

	local _group = Group.getByName(_groupName)

	--check current group size is equal to actual group size
	if _group:getInitialSize() == _group:getSize() then
		return true
	else
		return false
	end
end


-- gets a spawngroup from the savegame and checks if it has losses
-- returns false if there is a loss
local function isAllOfSpawngroupThere(spawnGroup)
	if not isGroupThere(spawnGroup.name) then
		return false
	end

	-- get all alive units from the spawned group 
	local units = Group.getUnits(Group.getByName(spawnGroup.name))
	
	if not units then return false end
	
	-- run through all units in the spawntable
	for i, spawnUnit in pairs(spawnGroup.units) do
		local unitFound = false
		
		-- run through all alive-units to see if theres one unit missing
		for k, unit in pairs(units) do
			local unitName = unit:getName()
			if spawnUnit.name == unitName then
				unitFound = true
				break
			end
		end
		
		if not unitFound then
			return false
		end
	end

	return true
end



------------------------------------------------
--[[ string koEngine.TableSerialization(table)
--
-- makes string from table
-- taken from XComs blueflag
------------------------------------------------]]
 function koEngine.TableSerialization(t, i)													--function to turn a table into a string (works to transmutate strings, numbers and sub-tables)
	if not i then
		i = 0
	end
	if not t then 
		return "nil"
	end
	if type(t) == "string" then
		return "!String! t =" .. t
	end
	
	local text = "{\n"
	local tab = ""
	for n = 1, i + 1 do																	--controls the indent for the current text line
		tab = tab .. "\t"
	end
	for k,v in pairs(t) do
		if type(k) == "string" then
			text = text .. tab .. "['" .. k .. "']" .. " = "
			if type(v) == "string" then
				text = text .. "'" .. v .. "',\n"
			elseif type(v) == "number" then
				text = text .. v .. ",\n"
			elseif type(v) == "table" then
				text = text .. koEngine.TableSerialization(v, i + 1)
			elseif type(v) == "boolean" then
				text = text .. tostring(v) .. ",\n"
			end
		elseif type(k) == "number" then
			text = text .. tab .. "[" .. k .. "] = "
			if type(v) == "string" then
				text = text .. "'" .. v .. "',\n"
			elseif type(v) == "number" then
				text = text .. v .. ",\n"
			elseif type(v) == "table" then
				text = text .. koEngine.TableSerialization(v, i + 1)
			elseif type(v) == "boolean" then
				text = text .. tostring(v) .. ",\n"
			end	
		end
	end
	tab = ""
	for n = 1, i do																		--indent for closing bracket is one less then previous text line
		tab = tab .. "\t"
	end
	if i == 0 then
		text = text .. tab .. "}\n"														--the last bracket should not be followed by an comma
	else
		text = text .. tab .. "},\n"													--all brackets with indent higher than 0 are followed by a comma
	end
	return text
end






----------------------------------------------
--[[ koEngine.saveGame()
--
-- Saves the current game-state to .lua
-- (requires io,lfs to be sanitized)
----------------------------------------------
--export table every 5 minutes --]]
function koEngine.saveGame(doSchedule)
	koEngine.debugText("koEngine.saveGame()") --: writing savegame to: '" .. exportDir .. "'")
	
	if io == nil then 
		return
	end
	
	
	-------------------------------------------------------
	-- update the sams and save them too
	koEngine.updateDynamicSAMs()
	
	koEngine.debugText("Dynamic SAMs updated")
	
	-- update the timer in the savegame so we know the current dcs time externally
	MissionData.properties.timer = timer.getTime()
	
	-- send udp packet:
	koEngine.debugText("sending Savegame to GameGUI")
	--socket.try(koEngine.UDPSavegameSendSocket:sendto(koEngine.JSON:encode(MissionData).." \n", "127.0.0.1", koEngine.SAVEGAME_SEND_TO_PORT)) --]]
	koTCPSocket.send(MissionData, "Savegame")
	
	
	-- save the savegame
	local exportData = "local t = " .. koEngine.TableSerialization(MissionData) .. "return t"				--The second argument is the indent for the initial code line (which is zero)
	local exportDir = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\"
	
	
	--if not koEngine.debugOn then
		--koEngine.outText("The Mission status has been saved!")
	--end
	
	local exportFile = assert(io.open(koEngine.savegameFileName, "w"))
	exportFile:write(exportData)
	exportFile:flush()
	exportFile:close()
	exportFile = nil
	
	--koEngine.debugText("Mission Data Saved")
	
	--koScoreBoard.save()
		
	
	-- unnessesary but practical for development: keep track of koEngine.zoneUnitData in a file!
	--exportData = "local t = " .. koEngine.TableSerialization(koEngine.zoneUnitData) .. "return t"				--The second argument is the indent for the initial code line (which is zero)
	--exportFile = assert(io.open(exportDir.."ko_unit_data_dyn.lua", "w"))
	--exportFile:write(exportData)
	--exportFile:flush()
	--exportFile:close()
	--exportFile = nil
	
	if doSchedule == true then
		mist.scheduleFunction(koEngine.saveGame,{ true }, timer.getTime() + koEngine.saveTime*60)
	end
	
	koEngine.debugText("finished saving game")
end

function koEngine.loadPlayerList()
	--koEngine.debugText("loading player list")
	local DataLoader = loadfile(koEngine.playerListFileName)
	if DataLoader ~= nil then		-- File open?
		PlayerList = DataLoader()
	else
		koEngine.debugText("FATAL ERROR: could not load playerlist")
	end
end

function koEngine.loadPlayerData()
	--koEngine.debugText("loading player list")
	local DataLoader = loadfile(koEngine.playerListFileName)
	if DataLoader ~= nil then		-- File open?
		PlayerList = DataLoader()
	else
		koEngine.debugText("FATAL ERROR: could not load playerlist")
	end
	
	local DataLoader = loadfile(koEngine.playerDataFileName)
	if DataLoader ~= nil then		-- File open?
		koEngine.debugText("Loading from '"..koEngine.playerDataFileName.."' ... successful\n")
		koEngine.PlayerData = DataLoader()
	else
		koEngine.debugText("FATAL ERROR: Unable to load Player Data!")
	end
end



function koEngine.makeRadioMenu(event, groupID, playerName, unit)
	koEngine.debugText("makeRadioMenu("..groupID..", "..playerName..")")
	
	if not koEngine.menuForGroup[tostring(groupID)] then
		koEngine.debugText("creating new Radiomenu for group "..groupID)
		-- first Transport (CTLD by Ciribob)
		ctld.addF10MenuOptions(true)
		
		-- second CSAR (by Ciribob) -- CSAR is enabled for everyone
		if unitCategoryTable[event.initiator:getDesc().category] == "HELICOPTER" then
			--koEngine.debugText("adding medevac menu to HELICOPTER")
			csar.addMedevacMenuItem(event.initiator)
		end
		
		ewrs.buildF10Menu()
		
		-- third menu entry
		local intelCommandPath = missionCommands.addSubMenuForGroup(groupID, 'MISSION STATUS')
		missionCommands.addCommandForGroup(groupID, 'Show Nearest Objectives!',intelCommandPath, koEngine.outTextNearest ,{nil,groupID,false, unit})
		missionCommands.addCommandForGroup(groupID, 'All',intelCommandPath, koEngine.outTextIntel ,{nil,groupID,false, unit})
		missionCommands.addCommandForGroup(groupID, 'Primary targets',intelCommandPath, koEngine.outTextIntel ,{"primary",groupID,false, unit})
		missionCommands.addCommandForGroup(groupID, 'Secondary targets',intelCommandPath, koEngine.outTextIntel ,{"secondary",groupID,false, unit})
		missionCommands.addCommandForGroup(groupID, 'Communication targets',intelCommandPath, koEngine.outTextIntel ,{"communication",groupID,false, unit})
		missionCommands.addCommandForGroup(groupID, 'Aerodromes and FARPs',intelCommandPath, koEngine.outTextIntel ,{"strategic",groupID,false, unit})
		missionCommands.addCommandForGroup(groupID, 'Reorder Groundcrew at current FARP',intelCommandPath, koEngine.reorderGroundCrew, groupID)
		
		-- fourth menu entry
		local unitName = event.initiator:getName();
		local coalition = coalitionTable[unit:getCoalition()]
		--koEngine.debugText("coalition = "..coalition)
		local convoyCommandPath = missionCommands.addSubMenuForGroup(groupID, 'Convoys')
		missionCommands.addCommandForGroup(groupID, 'Convoy Status',convoyCommandPath, koEngine.outTextConvoyIntel, { playerName, groupID, coalition})
		missionCommands.addCommandForGroup(groupID, 'Request DEFENSIVE convoy \n    - cost: '..format_num(koEngine.convoyCost['defensive'])..'$', convoyCommandPath, koEngine.sendConvoy, { playerName, groupID, coalition, "defensive" })
		missionCommands.addCommandForGroup(groupID, 'Request GROUNDCREW convoy \n    - cost: '..format_num(koEngine.convoyCost['groundcrew'])..'$', convoyCommandPath, koEngine.sendConvoy, { playerName, groupID, coalition, "groundcrew" })
		--missionCommands.addCommandForGroup(groupID, 'Request LR-SAM convoy \n    - cost: '..format_num(koEngine.convoyCost['LR-SAM'])..'$', convoyCommandPath, koEngine.sendConvoy, { playerName, groupID, coalition, "LR-SAM" })
		--missionCommands.addCommandForGroup(groupID, 'Request OFFENSIVE convoy \n    - cost: '..format_num(koEngine.convoyCost['offensive'])..'$', convoyCommandPath, koEngine.sendConvoy, { playerName, groupID, coalition, "offensive" })
		--for target, convoy in pairs (MissionData.properties.convoys[coalition]) do
		--	missionCommands.addCommandForGroup(groupID, 'Convoy to '..target, convoyCommandPath, koEngine.sendConvoy, { playerName, groupID, coalition, unitName, target})
		--end
		
		
		if koEngine.debugOn then
			-- add cheat radiocommand if debug is on
			local missionCommandPath = missionCommands.addSubMenuForGroup(groupID, 'Mission Commands')
			missionCommands.addCommandForGroup(groupID, 'Save Game', missionCommandPath, koEngine.saveGame, {nil})
			missionCommands.addCommandForGroup(groupID, 'Send Red Convoy', missionCommandPath, koEngine.sendConvoy, { groupID, "red", "Inguri-Dam Fortification"})
			missionCommands.addCommandForGroup(groupID, 'Send Blue Convoy', missionCommandPath, koEngine.sendConvoy, { groupID, "blue", "Inguri-Dam Fortification"})
			missionCommands.addCommandForGroup(groupID, 'Destroy A2 Airdefense', missionCommandPath, koEngine.destroyGroup, "A2_red_Airdefense")
			missionCommands.addCommandForGroup(groupID, 'Destroy A2 Infantry', missionCommandPath, koEngine.destroyGroup, "A2_red_Infantry")
			missionCommands.addCommandForGroup(groupID, 'Destroy Fortification', missionCommandPath, koEngine.destroyObjective, "Inguri-Dam Fortification")
			missionCommands.addCommandForGroup(groupID, 'AI on', missionCommandPath, koEngine.switchAIOnOff, true)
			missionCommands.addCommandForGroup(groupID, 'AI off', missionCommandPath, koEngine.switchAIOnOff, false)
		end
		
		koEngine.menuForGroup[tostring(groupID)] = playerName
	else
		koEngine.debugText("radio menu was already created")
	end
end


-- switches onoff the entire AI at FARP groups
function koEngine.switchAIOnOff(onoff)
	local onOffString = "off"
	if onoff == true then onOffString = "on" end
	
	koEngine.debugText("switching AI "..onOffString)
	
	-----------------------------------------------------------------------------
	-- loop through Mission Data Cathegories
	for category, categoryTable in pairs(MissionData) do  -- objectiveName, objectiveNameT
		if type(categoryTable)=="table" and category ~= "properties" then
			for objectiveName, objectiveTable in pairs(categoryTable) do -- loop through every objective (FARP, Airport, Antenna, Bunker, Inguri-Dam)
				for groupName, spawnGroup in pairs(objectiveTable.groups) do
					Group.getByName(groupName):getController():setOnOff(onoff)	
				end
			end
		end
	end
end

function koEngine.makeDebugMenu(playerName)
	koEngine.log("client called in mission env!!")
	koEngine.debugText("makeDebugMenu() was called!!! "..tostring(playerName))
end

----------------------------------------------
--[[ koEngine.writeTableToFile()
-- 
-- writes a table to a file
-- useful for debug
-- uses XComs table serialization--]]
function koEngine.writeTableToFile(_table, _filename)
	local exportData = "local t = " .. koEngine.TableSerialization(_table, 0) .. "return t"				--The second argument is the indent for the initial code line (which is zero)
	local exportDir = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\"
	
	koEngine.debugText("saving table to file: ".._filename)
	
	
	local exportFile = assert(io.open(exportDir .. _filename, "w"))
	exportFile:write(exportData)
	exportFile:flush()
	exportFile:close()
	exportFile = nil
end


function koEngine.getPlayerNameFix(playerName)
	if not playerName then 
		return nil
	end
	
	local playerName = playerName:gsub("'"," ")
	playerName = playerName:gsub('"',' ')
	playerName = playerName:gsub('=','-')
	
	return playerName
end



----------------------------------------------------------------------------------------------------------
--													Functions
----------------------------------------------------------------------------------------------------------


------------------------------------------------
-- 	XComs message queing and timer functions--]]
msgHolder = {						-- table
	[0] = {},
	[1] = {},
	[2] = {},
}

msgOnAir = {						-- table
	[0] = 0,
	[1] = 0,
	[2] = 0,
}

function msgSender()	
	--koEngine.debugText("msgSender()")
	for i=0,2 do
		if msgOnAir[i] == 0 then
			if #msgHolder[i] ~= 0 then
				if i == 0 then
					koEngine.log("msgSender() sending message to all:\n"..msgHolder[i][1])
					trigger.action.outText(msgHolder[i][1],koEngine.intelMessageDisplayTime)
					table.remove(msgHolder[i],1)
					msgOnAir[i] = koEngine.intelMessageDisplayTime
				else
					koEngine.log("msgSender() sending message to "..coalitionTable[i].." Coalition:\n"..msgHolder[i][1])
					trigger.action.outTextForCoalition(i,msgHolder[i][1],koEngine.intelMessageDisplayTime)
					table.remove(msgHolder[i],1)
					msgOnAir[i] = koEngine.intelMessageDisplayTime
				end
			end
		else
			msgOnAir[i] = msgOnAir[i] - 1
		end
	end
	MissionData['properties']['campaignSecs'] = MissionData['properties']['campaignSecs']+1
	mist.scheduleFunction(msgSender,{},timer.getTime()+1)
end

function updateResetTime() 		--time updater
	if MissionData['properties']['restartTime'] > 0 then
		MissionData['properties']['restartTime'] = MissionData['properties']['restartTime'] - 1
	else
		MissionData['properties']['restartTime'] = koEngine.lifeResetTime*60
		MissionData['properties']['playerLimit'] = {}
		koEngine.outText("Player lives have been reset!", 15)
		koEngine.log("playerLives Reset!")
	end
	mist.scheduleFunction(updateResetTime,{},timer.getTime()+60)
end


function koEngine.getPlayerUCID(playerName)
	local playerNameFix = koEngine.getPlayerNameFix(playerName)
	local playerUcid = 0
	if playerNameFix ~= "AI" then
		for ucid, playerData in pairs(PlayerList) do
			if koEngine.getPlayerNameFix(playerData.name) == playerNameFix then
				koEngine.debugText("found player ucid in PlayerList!")
				playerUcid = ucid
			end
		end
		
		if playerUcid == 0 then
			koEngine.debugText("Did not find player in playerlist! looking it up in playerdata")
			
			-- load dynamic mission data:
			koEngine.loadPlayerData()
			if koEngine.PlayerData ~= nil then		
						
				for ucid, playerData in pairs(koEngine.PlayerData) do
					if not playerData.name then
						koEngine.debugText("this player has no name: ucid="..ucid..", table: "..koEngine.TableSerialization(playerData))
					elseif koEngine.getPlayerNameFix(playerData.name) == playerNameFix then
						koEngine.debugText("found player ucid in PlayerData!")
						playerUcid = ucid
					end
				end
			else
				koEngine.debugText("Unable to load Player Data, using playerNameFix")
				playerUcid = playerNameFix
			end
			
			if playerUcid == 0 then
				playerUcid = playerNameFix
			end
		end
	else
		playerUcid = playerNameFix	-- AI does not have ucid, so dont even look for it
	end
	
	koEngine.debugText("UCID = "..playerUcid)
	return playerUcid
end


--------------------------------------------
--	koEngine.outTextIntel
--------------------------------------------
--function to show information about Mission objectiveNameectives
function koEngine.outTextIntel(vars)
	koEngine.debugText("koEngine.outTextIntel() for groupID: "..tostring(vars[4]))
	
	if not vars then
		koEngine.debugText("FATAL ERROR: outTextIntel() did not get vars supplied")
		return
	end
	
	local priority = vars[1]
	local groupID = vars[2]
	local _return = vars[3]
	--local unit = vars[4]
	
	local group = mist.DBs.groupsById[groupID]
	local unit = Unit.getByName(group.units[1].unitName)
	local coalition = unit:getCoalition()
	local playerName = "ERROR"
	if group then
		playerName = unit:getPlayerName() or "ERROR"
		koEngine.debugText("worked: playerName = "..playerName)
	end
	
	local playerLives = MissionData.properties.playerLimit[koEngine.getPlayerNameFix(playerName)] or 0
	local livelimit = MissionData.properties.lifeLimit
	
	local msg = '_______________________________________________________________________________________________________'
	msg = msg .. '\n  STATUS REPORT:\n  ------------------------\n\n'
	
	msg = msg .. '  '..playerName..' you have used '..playerLives..'/'..livelimit..' lives\n'
	msg = msg .. '  You currently have '..format_num(koScoreBoard.getCashcountForPlayer(playerName))..'$\n'
	msg = msg .. '  Mobile SAM Systems deployed by '..coalitionTable[coalition]..': '..ctld.aaSystemsSpawned[coalition]..'/'..ctld.aaSystemLimit[coalition]..'\n\n'
	
	
	-- TODO: Intel outTextIntel
	-- look for objectives that match the priority
	for categoryName, categoryTable in pairs (MissionData) do
		if type(categoryTable)=="table" and categoryName ~= "properties" then
			
			if not priority then 
				msg = msg .. "\n  " .. categoryName .. ' Objectives:\n'
			end
			
			for objectiveName, objectiveTable in pairs(categoryTable) do
				if type(objectiveTable) == "table" then
					--koEngine.debugText("found a priority")
					if (priority  and objectiveTable.priority == priority) or not priority then
						local redFlag =  trigger.misc.getUserFlag('red'..objectiveName)
						local blueFlag = trigger.misc.getUserFlag('blue'..objectiveName)
					
						msg = msg..'  '..string.upper(objectiveTable.coa).." - "..objectiveName
						
						if objectiveTable.underAttack == true then
							msg = msg..' [UNDER ATTACK]'
						end
						
						--msg = msg..' '..tostring(redFlag)..'/'..tostring(blueFlag)
						
						if categoryName == "FARP" then
							msg = msg..' ('..objectiveTable.status..')'
							
							if priority and coalitionTable[coalition] == objectiveTable.coa then
								msg = msg..' - '
								
								local groundCrew = objectiveTable.groundCrew[coalitionTable[coalition]]
								if groundCrew then
									if groundCrew.hasATC and groundCrew.hasFuel and groundCrew.hasAmmo then
										msg = msg..' GroundOps are complete!'
									else
										local _and = ""
										if not groundCrew.hasATC then
											msg = msg..' [ATC]'
											_and = " and"
										end
										
										if not groundCrew.hasFuel then
											msg = msg.._and..' [Fuel Supply]'
											_and = " and"
										end
										
										if not groundCrew.hasAmmo then
											msg = msg.._and..' [Ammo Supply]'
											_and = " and"
										end
										
										if _and == "" then
											msg = msg..' is missing!'
										else
											msg = msg..' are missing!'
										end	
									end
								else
									msg = msg..' Objective has no GroundOps!'	
								end
								
								
							end
						end
						
						msg = msg..'\n'
					end
				end
			end
		end
	end
	
	msg = msg..'_______________________________________________________________________________________________________'
	
	if _return then
		return msg
	elseif koEngine.debugOn then
		koEngine.debugText(msg, koEngine.intelMessageDisplayTime)
	elseif groupID == nil then
		trigger.action.outText(msg, koEngine.intelMessageDisplayTime)
	else
		koEngine.log("Out Text Intel requested by: "..playerName..": "..msg)
		trigger.action.outTextForGroup(groupID, msg, koEngine.intelMessageDisplayTime)
	end
end

function koEngine.outTextNearest(vars)
	koEngine.debugText("koEngine.outTextNearest() for groupID: "..tostring(vars[2]))
	
	if not vars then
		koEngine.debugText("FATAL ERROR: outTextNearest() did not get vars supplied")
		return
	end
	
	local priority = vars[1]
	local groupID = vars[2]
	local _return = vars[3]
	--local unit = vars[4]
	
	local group = mist.DBs.groupsById[groupID]
	local unit = Unit.getByName(group.units[1].unitName)
	local coalition = unit:getCoalition()
	local playerPosition = unit:getPosition().p
	
	local playerName = "ERROR"
	if unit then
		playerName = unit:getPlayerName() or "ERROR"
		--koEngine.debugText("worked: playerName = "..playerName)
	end
	
	local playerLives = MissionData.properties.playerLimit[koEngine.getPlayerNameFix(playerName)] or 0
	local livelimit = MissionData.properties.lifeLimit
	
	local msg = '_______________________________________________________________________________________________________'
	msg = msg .. '\n\n  Nearest Objectives for '..playerName..':\n\n  -----------------------------------'
	
	-- TODO: Intel outTextNearest
	for categoryName, categoryTable in pairs(MissionData) do
		if type(categoryTable) == "table" and categoryName ~= "properties" then
			msg = msg.."\n  Nearest "..string.upper(categoryName)..":\n" 
			
			-- find nearest objective
			local nearestName = false
			local nearestDist = math.huge
			local nearestPos = {}
			
			for objectiveName, objectiveTable in pairs(categoryTable) do
				
				local objectivePosition = trigger.misc.getZone(objectiveName).point
				local dist = mist.vec.mag(mist.vec.sub(playerPosition, objectivePosition))
				if dist < nearestDist then
					nearestName = objectiveName
					nearestDist = dist
					nearestPos = objectivePosition 
				end
			end
			
			local objectiveTable = categoryTable[nearestName]
			
			local vec = {x = nearestPos.x - playerPosition.x, y = nearestPos.y - playerPosition.y, z = nearestPos.z - playerPosition.z}
			local heading = math.deg(mist.utils.getDir(vec, playerPosition))
			if heading < 0 then	heading = heading + 2*math.pi end  -- put heading in range of 0 to 2*pi
				
			msg = msg..'    '..string.upper(objectiveTable.coa).." - "..nearestName.." "
						
			if objectiveTable.underAttack == true then
				msg = msg..'[UNDER ATTACK]'
			end
			
			if categoryName == "Aerodrome" or categoryName == "FARP" then
				msg = msg..' - ('..objectiveTable.status..') '
				
				if coalitionTable[coalition] == objectiveTable.coa and categoryName == "FARP" then
					msg = msg..'-'
					
					local groundCrew = objectiveTable.groundCrew[coalitionTable[coalition]]
					if groundCrew then
						if groundCrew.hasATC and groundCrew.hasFuel and groundCrew.hasAmmo then
							msg = msg..' GroundOps are complete!'
						else
							local _and = false
							if not groundCrew.hasATC then
								msg = msg..' [ATC]'
								_and = true
							end
							
							if not groundCrew.hasFuel then
								msg = msg..' [Fuel Supply]'
								_and = true
							end
							
							if not groundCrew.hasAmmo then
								msg = msg..' [Ammo Supply]'
								_and = true
							end
							
							if not _and then
								msg = msg..' is missing!'
							else
								msg = msg..' are missing!'
							end	
						end
					else
						msg = msg..' [ATC] [FUEL SUPPLY] [AMMO SUPPLY] are missing!'	
					end
				end
			end
			msg = msg.."\n    BRA "..math.floor(heading).." for "..math.floor(nearestDist/1000).."km at your "..koEngine.getClockDirection(unit,nearestPos).." o'clock\n"
			
		end
	end	
	
	msg = msg .. '  -----------------------------------\n\n'
	msg = msg .. '  You have used '..playerLives..'/'..livelimit..' lives\n\n'
	msg = msg .. '  Mobile SAM Systems deployed by '..coalitionTable[coalition]..': '..ctld.aaSystemsSpawned[coalition]..'/'..ctld.aaSystemLimit[coalition]..'\n\n'
	msg = msg .. '  You currently have '..format_num(koScoreBoard.getCashcountForPlayer(playerName))..'$\n'
	msg = msg .. '_______________________________________________________________________________________________________'
	if _return then
		return msg
	elseif koEngine.debugOn then
		koEngine.debugText(msg, koEngine.intelMessageDisplayTime)
	elseif groupID == nil then
		trigger.action.outText(msg, koEngine.intelMessageDisplayTime)
	else
		koEngine.log("Out Text Intel requested by: "..playerName..": "..msg)
		trigger.action.outTextForGroup(groupID, msg, koEngine.intelMessageDisplayTime)
	end
end

function koEngine.outTextConvoyIntel(vars)
	local playerName = vars[1]
	local groupID = vars[2]
	local coalition = vars[3]
	
	local playerUnit = koEngine.PlayerUnitList[tostring(groupID)].unit
	local playerName = playerUnit:getPlayerName()
	
	if playerName == '' then
		koEngine.debugText("FATAL WARNING: playerName is empty String! Trying to find original player")
		-- try to find the player in PlayerUnitList
		for _groupID, player in pairs(koEngine.PlayerUnitList) do
			if tonumber(_groupID) == groupID then
				koEngine.debugText("found groupID in PlayerUnitList: playerName = '"..player.playerName.."'")
				playerName = player.playerName
			end	
		end
	end
	
	local msg = '_______________________________________________________________________________________________________'
	msg = msg .. '\n\n  You currently have '..format_num(koScoreBoard.getCashcountForPlayer(playerName))..'$\n'
	msg = msg .. '  -----------------------------------\n\n'
	msg = msg .. '  To send a defensive convoy you need '..format_num(koEngine.convoyCost['defensive'])..'$\n'
	msg = msg .. '  To send a groundcrew convoy you need '..format_num(koEngine.convoyCost['groundcrew'])..'$\n'
	--msg = msg .. '  To send a offensive convoy you need '..format_num(koEngine.convoyCost['offensive'])..'$\n'
	msg = msg .. '  \n'
	msg = msg .. '  A defensive convoy consists of one Tank, one AAA, one IR and one Radar guided SAM\n'
	msg = msg .. '  A groundcrew convoy consists of all 3 types of groundcrew and one IR guided SAM\n'
	--msg = msg .. '  A offensive convoy consists of one Tank, one ATM, one AAA and one IR guided SAM\n'
	--msg = msg .. '  - only the offensive convoy can be sent to enemy locations!\n'
	msg = msg .. '  \n'
	msg = msg .. '  The convoy should arrive about 20 minutes after requested\n'
	msg = msg .. '_______________________________________________________________________________________________________'
	
	koEngine.outTextForGroup(groupID, msg, koEngine.intelMessageDisplayTime)
end

function koEngine.getWindForUnit(unit)
	
	local windVec = atmosphere.getWindWithTurbulence(unit:getPoint() )
	local strength = math.sqrt(windVec.x * windVec.x + windVec.z * windVec.z) * 1.25
	local heading = math.atan2(windVec.z, windVec.x)		-- calculate heading in rad
	if heading < 0 then heading = heading + 2*math.pi end 	-- put heading in range of 0 to 2*pi
	heading = math.ceil(mist.utils.toDegree(heading))		-- convert to degrees
	if heading > 180 then heading = heading - 180 			-- wind from
	elseif heading <= 180 then heading = heading + 180 end
	
	return "from "..heading.." degrees at "..math.ceil(strength).."m/s"
end

function koEngine.updateDynamicSAMs()
	for i, sam in pairs(MissionData.properties.droppedSAMs) do
		--koEngine.debugText("checking sam: "..sam.groupName)
		
		-- check sams age, if too old destroy it
		local age = ((MissionData.properties.campaignSecs - sam.time)/60)/60 -- age from seconds in hours
		if age >= koEngine.samLifeTime then
			--koEngine.debugText("SAMs age is "..age.." hours, deleting "..sam.groupName)
			koEngine.outTextForCoalition(sam.coalition,"SAM '"..sam.groupName.."' has reached the end of its lifetime and has been destroyed!")
			
			-- if its not a manpad decrease the systems spawned in ctld
			if not sam.groupName:find("Igla") and not sam.groupName:find("Stinger") and not sam.groupName:find("EWR") and not sam.groupName:find("JTAC") then
				ctld.aaSystemsSpawned[sam.coalition] = ctld.aaSystemsSpawned[sam.coalition] - 1 -- decrease systems counter of ctld
			end
			
			sam.spawnedGroup:destroy()
			--MissionData.properties.droppedSAMs[i] = nil
			table.remove(MissionData.properties.droppedSAMs, i)			
			break
		end		
		
		-- check if all units are alive:
		if not isGroupThere(sam.groupName) then
			koEngine.debugText("unpacked SAM was destroyed, deleting it from the table")
			
			-- if its not a manpad decrease the systems spawned in ctld
			if not sam.groupName:find("Igla") and not sam.groupName:find("Stinger") and not sam.groupName:find("EWR") and not sam.groupName:find("JTAC") then
				ctld.aaSystemsSpawned[sam.coalition] = ctld.aaSystemsSpawned[sam.coalition] - 1 -- decrease systems counter of ctld
			end
			
			table.remove(MissionData.properties.droppedSAMs, i)	-- sam has died completely, delete it 
			
			break
		end
		
		
		-- if the group is there but has losses delete the unit lost
		if isGroupThere(sam.groupName) and not isAllOfGroupThere(sam.groupName) then
			--koEngine.debugText("Unpacked sam has losses")
			
			local units = Group.getUnits(sam.spawnedGroup)
			if not units then 
				koEngine.debugText("FATAL ERROR: could not get untis for "..sam.groupName)
			else
				for j, spawnUnit in pairs(sam.groupSpawnTable.units) do
					local unitFound = false
					-- now update the spawnUnit
					for k, unit in pairs(units) do
						local unitName = unit:getName()
						if spawnUnit.name == unitName then
							unitFound = true
							break
						end
					end
					
					if not unitFound then
						koEngine.debugText("Unit is dead, deleting it "..j)
						table.remove(sam.groupSpawnTable.units, j) -- if it doesnt exist anymore delete the unit from the table
					end
				end
			end
		end
		
		local units = Group.getUnits(sam.spawnedGroup)
		-- now update positions
		for k, unit in pairs(units) do
			if unit:isExist() then
				--koEngine.debugText("updating position for unit "..k)
				for j, spawnUnit in pairs(sam.groupSpawnTable.units) do
					if spawnUnit.name == unit:getName() then
						-- update unit position
						local point = unit:getPoint()
						spawnUnit.x = point.x
						spawnUnit.y = point.z
					end
				end
			end
		end
	end
end


function koEngine.updateConvoys()
	for i, convoy in pairs(MissionData.properties.spawnedConvoys) do
		--koEngine.debugText("checking convoy: "..convoy.groupName)
		
		-- check if all units are alive:
		if not isGroupThere(convoy.name) then
			koEngine.debugText("spawned convoy was destroyed, deleting it from the table")
			
			table.remove(MissionData.properties.spawnedConvoys, i)	-- sam has died completely, delete it 
			break
		end
		
		-- if the group is there but has losses delete the unit lost
		local group = Group.getByName(convoy.name)
		local units = Group.getUnits(group)
		
		if isGroupThere(convoy.name) and #units < #convoy.units then
			--koEngine.debugText("spawned convoy has losses")
			
			for j, convoyUnit in pairs(convoy.units) do
				local unitFound = false
				-- now update the spawnUnit
				for k, unit in pairs(units) do
					if convoyUnit.name == unit:getName() then
						unitFound = true
						break
					end
				end
				
				if not unitFound then
					koEngine.debugText("Unit is dead, deleting it "..j)
					table.remove(convoy.units, j) -- if it doesnt exist anymore delete the unit from the table
				end
			end
		end
		
		-- now update positions
		for k, unit in pairs(units) do
			if unit:isExist() then
				--koEngine.debugText("updating position for unit "..k)
				for j, spawnUnit in pairs(convoy.units) do
					if spawnUnit.name == unit:getName() then
						-- update unit position
						local point = unit:getPoint()
						spawnUnit.x = point.x
						spawnUnit.y = point.z
					end
				end
			end
		end
		
		--local zone = koEngine.isUnitInObjectiveZone(units[1])
		local inZone = mist.getUnitsInZones({ units[1]:getName() }, { convoy.targetZone })
		--koEngine.debugText("unitname: "..units[1]:getName())
		--koEngine.debugText(koEngine.TableSerialization(inZone))
		if inZone and #inZone > 0 then
			koEngine.debugText("koEngine.updateConvoys(): convoy '"..convoy.name.."' has reached '"..convoy.targetZone.."', moving it to objective table!")
			
			local objectiveTable = MissionData[koEngine.getObjectiveCategory(convoy.targetZone)][convoy.targetZone]
			convoy.route = nil										-- the convoy has arrived, route is not needed anymore
			objectiveTable.groups[convoy.name] = convoy				-- add the convoy to the objectives group-table
			objectiveTable.activeConvoyZone = objectiveTable.activeConvoyZone + 1
			if objectiveTable.activeConvoyZone > 4 then objectiveTable.activeConvoyZone = 1 end
			
			table.remove(MissionData.properties.spawnedConvoys, i)	-- remove the convoy from the convoys table
			
			-- now disperse the group!
			koEngine.disperseConvoyInZone(group, convoy.targetZone)
			
			koEngine.outTextForCoalition(coaNameTable[convoy.coalition], "Our convoy towards "..convoy.targetZone.." has reached its destination!")
		--else
			--koEngine.debugText("convoy not in zone")
		end
	end
end


--------------------------------------------
-- koEngine.updatePlayerInZones() - scheduled function
-- 
-- checks all players positions
--------------------------------------------
function koEngine.updatePlayersInZones()
	-----------------------------------------------------------------------------
	-- loop through Mission Data Cathegories
	for category, categoryTable in pairs(MissionData) do  -- objectiveName, objectiveNameT
		if type(categoryTable)=="table" and category ~= "properties" then
			for objectiveName, objectiveTable in pairs(categoryTable) do -- loop through every objective (FARP, Airport, Antenna, Bunker, Inguri-Dam)
						
				-----------------------------------------------------------------------------				
				-- check if any player is in a zone, and display a message
				for playerGroupID, player in pairs(koEngine.PlayerUnitList) do
					if player.unit:isExist() then
						local inZone = mist.getUnitsInZones({ player.unit:getName() }, { objectiveName }, 'sphere')
						if #inZone > 0 then
							koEngine.PlayersInZone[playerGroupID] = koEngine.PlayersInZone[playerGroupID] or {}
							if not koEngine.PlayersInZone[playerGroupID][objectiveName] then
								local message = '_______________________________________________________________________________________________________\n'
								message = message.."\nWelcome to '"..objectiveName.."'"
								message = message.."\n\nWind "..koEngine.getWindForUnit(player.unit)
								message = message..'\n_______________________________________________________________________________________________________'
								
								koEngine.outTextForGroup(tonumber(playerGroupID),message,15)
								koEngine.PlayersInZone[playerGroupID][objectiveName] = true
							end	
						else
							koEngine.PlayersInZone[playerGroupID] = koEngine.PlayersInZone[playerGroupID] or {}
							if koEngine.PlayersInZone[playerGroupID][objectiveName] then
								koEngine.outTextForGroup(tonumber(playerGroupID),"You are leaving '"..objectiveName.."'",15)
								koEngine.PlayersInZone[playerGroupID][objectiveName] = false
							end
						end
					else
						-- player does not exist anymore, close his sortie
						--koEngine.debugText("koEngine.refreshPlayersInZone() - Player '"..player.playerName.."' does not exist anymore, closing sortie!")
						--koScoreBoard.closeSortie(player.playerName)
						
						--koEngine.PlayerUnitList[playerGroupID] = nil
						
						if not koEngine.PlayerUnitList[playerGroupID].doesNotExist then
							koEngine.PlayerUnitList[playerGroupID].doesNotExist = true
							koEngine.debugText("koEngine.updatePlayersInZone() - Player '"..player.playerName.."' does not exist anymore")
						end
					end
				end 
			end
		end
	end
	
	mist.scheduleFunction(koEngine.updatePlayersInZones, {}, timer.getTime()+1)
end

function koEngine.updateCSAR()
	-- clean ejected pilots
	local numEjected = 0
	local oldestBirthtime = math.huge
	local oldestPilot = nil
	local oldestPilotIndex = nil
	
	-- count and find oldest
	for i, pilot in pairs(MissionData.properties.ejectedPilots) do
		numEjected = numEjected + 1

		if pilot.spawnTime < oldestBirthtime then 	-- if younger
			oldestBirthtime = pilot.spawnTime
			oldestPilot = pilot
			oldestPilotIndex = i
		end
	end
	
	-- if too many delete the oldest
	if numEjected > koEngine.maxEjectedPilots then
		koEngine.debugText("- numEjected limit reached, deleting ("..string.upper(coalitionTable[oldestPilot.side])..") Ejected "..oldestPilot.desc)
		table.remove(MissionData.properties.ejectedPilots, oldestPilotIndex)
		Group.getByName(oldestPilot.name):destroy()
	end
end

function koEngine.checkWinningConditions()
	if koEngine.missionOver then
		return
	end	

	local numObjectives = {
		red = 0,
		blue = 0,
		neutral = 0,
		contested = 0,
	}
	
	-- count objectives
	for category, categoryTable in pairs(MissionData) do  
		if category ~= "properties" then
			for objectiveName, objectiveTable in pairs(categoryTable) do
				numObjectives[objectiveTable.coa] = numObjectives[objectiveTable.coa] + 1 
			end
		end
	end
	
	local coas = { [1] = "red", [2] = "blue" }
	for i, coa in ipairs(coas) do
		if (numObjectives[coa] + numObjectives.contested) <= 2 then		-- also count contested objectives for both coalitions! 
			koEngine.debugText("koEngine.checkWinningConditions() - '"..coa.."' has only 2 objectives left. THEY LOST!")
			
			koEngine.missionOver = true
			
			local msg = "_______________________________________________________________________________________________________\n\n"
			msg = msg .. "  "..string.upper(coa).." TEAM HAS LOST THE BATTLE!\n"
			msg = msg .. "  ------------------------\n\n"
			msg = msg .. "  With only 2 "..coa.." Objectives left, the "..counterCoa[coa].." coalition is victorious!\n\n"
			msg = msg .. "  The mission is going to reset and restart automatically in one minute.\n"
			msg = msg .. "_______________________________________________________________________________________________________"
			koEngine.outText(msg ,60,true)
			
			local winMessage = {
				winner = counterCoa[coa],
				campaignSecs = MissionData.campaignSecs,
				numObjectives = numObjectives,
			}
			koTCPSocket.send(winMessage, "Victory")
			
			-- remove savegame, create a new one.
			timer.scheduleFunction(function()
				-- move savegame to backup folder
				koEngine.debugText("preparing restart after winning conditions are met ... backing up savegame")
				local backupFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\Savegame Victory Backup\\ko_Savegame_"..counterCoa[coa].."win_"..koEngine.sessionID..".lua"
				local backupFile = assert(io.open(backupFileName, "w"))
				backupFile:write(koEngine.TableSerialization(MissionData))
				backupFile:flush()
				backupFile:close()
				backupFile = nil
				
				koEngine.debugText("deleting savegame file")
				os.remove(koEngine.savegameFileName)
				
				-- set user flag to reload mission
				koEngine.debugText("setting user flag")
		        trigger.action.setUserFlag(1, true)
		    end, {}, timer.getTime() + 60)
		end
	end
	
	--koEngine.debugText(koEngine.TableSerialization(numObjectives))
end


--------------------------------------------
-- koEngine.main() - scheduled function
--------------------------------------------
function koEngine.main()
	--koEngine.debugText("koEngine.main()")
	
	-- try to send testmessage on udp
	--[[local testMsg = {
		test = "test",
	}
	koEngine.debugText("sending testmessage on UDP")
	socket.try(koEngine.UDPSendSocket:sendto(koEngine.JSON:encode(testMsg).." \n", "127.0.0.1", koEngine.GAMEGUI_SEND_TO_PORT))
	
	-- check if we receive testmessage from mission
	local received = koEngine.UDPGameGuiReceiveSocket:receive()
	
	if received then
		koEngine.debugText("client list received")
		local test = koEngine.JSON:decode(received)
	    if test then
	    	koEngine.debugText("test received: "..koEngine.TableSerialization(test))
		end
	end--]]
	
	
	-- check if a spawned sam has died first:
	koEngine.updateDynamicSAMs()
	koEngine.updateConvoys()
	koEngine.updateCSAR()
	koEngine.loadPlayerList()
	koEngine.checkWinningConditions()
	
	koTCPSocket.send(PlayerList,"PlayerList")
	
	local save = false
	
	
	
	-----------------------------------------------------------------------------
	-- loop through Mission Data Cathegories
	for category, categoryTable in pairs(MissionData) do  -- objectiveName, objectiveNameT
		if type(categoryTable)=="table" and category ~= "properties" then
			for objectiveName, objectiveTable in pairs(categoryTable) do -- loop through every objective (FARP, Airport, Antenna, Bunker, Inguri-Dam)
				local redFlag = false
				local blueFlag = false
				
				-- check which untis are in the location
				local redUnitsInZone = mist.getUnitsInZones(koEngine.zoneUnitData[category][objectiveName]['red']['units'], { objectiveName }, 'cylinder')
				if redUnitsInZone and #redUnitsInZone > 0 then
					redFlag = true
				end				
		
				local blueUnitsInZone = mist.getUnitsInZones(koEngine.zoneUnitData[category][objectiveName]['blue']['units'], { objectiveName }, 'cylinder')
				if blueUnitsInZone and #blueUnitsInZone > 0 then
					blueFlag = true
				end
								
				-----------------------------------------------------------------------------				
				-- check if any objectives status has changed
				-----------------------------------------------------------------------------
				
				-----------------------------------------------------------------------------
				-- neutral
				if not redFlag and not blueFlag and objectiveTable.coa ~= 'neutral' then
					local coaID = coaNameTable[objectiveTable.coa]	
					local opCoaID = coaNameTable[counterCoa[objectiveTable.coa]]
					
					koEngine.debugText(objectiveTable.coa.." Objective "..objectiveName.." has been closed!")
					table.insert(msgHolder[coaID],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  ------------\n\n  '..objectiveName..' is now NEUTRAL!\n  Our last defending forces have fallen at the objective!\n\n  -----\n  HELICOPTERS - Transport Units to '..objectiveName..' in order to re-occupy it!\n  FIGHTERS - Gain air superiority in the area around the Objective, fight off incoming hostile Helicopters.\n_______________________________________________________________________________________________________')
					table.insert(msgHolder[opCoaID],'_______________________________________________________________________________________________________\n\n  GOOD NEWS FROM THE FRONT!\n  ------------\n\n  '..objectiveName..' is now NEUTRAL!\n  Our forces have managed to win the battle at the objective.\n\n  -----\n  HELICOPTERS - Transport Units '..objectiveName..' in order to occupy it!\n  FIGHTERS - Fly CAP in the area to support Choppers while they try to occupy the Objective!\n_______________________________________________________________________________________________________')
					
					--remove zone of oposite coalition from PickupZones according to tasks coalition
					if category == 'Aerodrome' or category == 'FARP' or category == 'Bunker' or objectiveName == 'Inguri-Dam Fortification' then
						for i, zone in ipairs(ctld.pickupZones) do
							if zone[1]==objectiveName then
								koEngine.debugText("removing "..objectiveName.." from ctld.pickupZones")
								table.remove(ctld.pickupZones[i]) -- no pickup in closed objectives!
							end
						end
					elseif category == "Communication" then
						-- reduce ctld amount of available AA-Systems
						ctld.aaSystemLimit[coaNameTable[objectiveTable.coa]] = ctld.aaSystemLimit[coaNameTable[objectiveTable.coa]] - 1
						if ctld.aaSystemsSpawned[coaNameTable[objectiveTable.coa]] > ctld.aaSystemLimit[coaNameTable[objectiveTable.coa]] then
							koEngine.debugText("koEngine.main(): "..objectiveTable.coa.." "..objectiveName.." was lost, Too many sams spawned, destroying oldest")
							ctld.destroyOldestSam(coaNameTable[objectiveTable.coa])
						end
					end
					
					objectiveTable.status = 'closed'
					objectiveTable.coa = 'neutral'

					save = true -- save the game at the end of the function
					
				-----------------------------------------------------------------------------
				-- occupied!
				elseif (redFlag and not blueFlag and objectiveTable.coa ~= 'red') or (blueFlag and not redFlag and objectiveTable.coa ~= 'blue') then
					
					local winnerCoa = 0
					if redFlag then
					 	winnerCoa = "red"
					else
						winnerCoa = "blue"
					end
					
					local looserCoa = counterCoa[winnerCoa]
					
					koEngine.debugText(string.upper(winnerCoa).." Team occupied: " .. objectiveName .. "!")

					objectiveTable.coa = winnerCoa
					objectiveTable.underAttack = false
					
					local messageString1 = '_______________________________________________________________________________________________________\n\n  GOOD NEWS FROM THE FRONT!\n  Our forces now occupy '..objectiveName..'!\n  -------------------------\n\n  HELICOPTERS - Urgently transport more airdefenses to the area in order to defend it.\n  FIGHTERS - provide Combat Air Patrol and fight off incoming threats!\n_______________________________________________________________________________________________________'
					local messageString2 = '_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  The enemy now occupies '..objectiveName..'!\n  -------------------------\n\n  We need to gain air superiority in the area and try to recapture '..objectiveName..'.\n\n  -----\n  HELICOPTERS - Transport Units to the area!\n  FIGHTERS - provide Combat Air Patrol in the area!\n  ATTACKERS - Destroy all enemy forces at the objective!.\n_______________________________________________________________________________________________________'
					
					
					-- AERODROME
					-- will be open once occupied, there's plenty of infrastructure, farps will stay closed. 
					if category == "Aerodrome" then
						objectiveTable.status = "open"
						table.insert(ctld.pickupZones,{ objectiveName, 'trigger.smokeColor.'..objectiveTable.coa, koEngine.troopPickupLimit, 1, coaNameTable[objectiveTable.coa] })
										
					-- ANTENNA
					elseif category == "Communication" then
						koEngine.debugText("Red Team occupied Antenna! Checking for convoy")
						
						--[[local antennaDestroyed = trigger.misc.getUserFlag(objectiveName.."_destroyed")
						koEngine.debugText("checking flag: '"..objectiveName.."_destroyed', flag = "..tostring(antennaDestroyed))
						if antennaDestroyed == 1 or antennaDestroyed == true then
						end	--]]
						
						-- increase amount of available AA-Systems in CTLD
						ctld.aaSystemLimit[coaNameTable[objectiveTable.coa]] = ctld.aaSystemLimit[coaNameTable[objectiveTable.coa]] + 1
						messageString1 = messageString1 .. '\n\n  We now have one more SAM System available to be deployed in the wild!\n'
						messageString1 = messageString1 .. '\n_______________________________________________________________________________________________________'
						
						-- every player who placed a group will get a point
						local gotPoints = {}
						for groupName, groupTable in pairs(objectiveTable.groups) do
							if groupTable.playerName and not gotPoints[groupTable.playerName] then
								gotPoints[groupTable.playerName] = true
								koScoreBoard.addCashToPlayer(groupTable.playerName, 3000, "capturing an Antenna")
							end
						end
					elseif category == "Main Targets" then
						-- every player who placed a group will get a point
						local gotPoints = {}
						for groupName, groupTable in pairs(objectiveTable.groups) do
							if groupTable.playerName and not gotPoints[groupTable.playerName] then
								gotPoints[groupTable.playerName] = true
								koScoreBoard.addCashToPlayer(groupTable.playerName, 5000, "capturing a Main Objective")
							end
						end
						
						messageString1 = messageString1 .. '_______________________________________________________________________________________________________'
					end
					
					table.insert(msgHolder[coaNameTable[winnerCoa]], messageString1)
					table.insert(msgHolder[coaNameTable[looserCoa]], messageString2)
					
					--remove/add zone of oposite coalition from PickupZones according to tasks coalition
					if category == 'Aerodrome' or category == 'FARP' or category == 'Bunker' or objectiveName == 'Inguri-Dam Fortification' then
						koEngine.debugText("inserting "..objectiveName.." into ctld.pickupZones")
						table.insert(ctld.pickupZones,{ objectiveName, 'trigger.smokeColor.'..objectiveTable.coa, koEngine.troopPickupLimit, 1, coaNameTable[objectiveTable.coa] })
					end
					
					save = true	-- update the savegame file so koSlotBlockGameGUI.lua has current data to work properly	
					
					
				-----------------------------------------------------------------------------
				-- contested!
				elseif redFlag and blueFlag then
					objectiveTable.coa = "contested"
					objectiveTable.underAttack = true
					
					local messageString = '_______________________________________________________________________________________________________\n\n'
					
					messageString = messageString.. '  NEWS FROM THE FRONT!\n'
					messageString = messageString.. '  "'..objectiveName..'" is contested!\n'
					messageString = messageString.. '  -------------------------\n\n'
					
					messageString = messageString.. '  Groundunits of both coalitions are fighting at the Objectives.\n'
					messageString = messageString.. '  FIGHTERS - Try to establish air-superiority in the Area to support strikers!\n'
					messageString = messageString.. '  STRIKERS - Please be extra cautious as to which unit you engage, they may be friendly!\n'
					messageString = messageString.. '  ... Teamkills are expensive on this server!\n'
					
					messageString = messageString.. '_______________________________________________________________________________________________________'
				end
				
				
				--------------------------------------------------------
				-- cleanup section
				--------------------------------------------------------
				
				objectiveTable.groundCrew = { red={}, blue={} }
				--------------------------------------------------------
				-- check objective groups for losses
				for groupName, spawnGroup in pairs(objectiveTable.groups) do
					--koEngine.debugText("checking spawnGroup: "..spawnGroup.groupName)
					
					local currentGroupDestroyed = false
					local group = Group.getByName(spawnGroup.name)
					
					if not group then
						koEngine.debugText("group '"..tostring(spawnGroup.name).."' is invalid before alivecheck, deleting group from spawntable")
						currentGroupDestroyed = true
						objectiveTable.groups[groupName] = nil	-- spawnGroup has died completely, delete it
					end
					
					--koEngine.debugText("spawnGroup = "..koEngine.TableSerialization(spawnGroup))
					local groupCoa = spawnGroup.coalition
					
					
					-- TODO rework groundcrew (mainloop)
					-- check if all units are alive:
					if not isGroupThere(spawnGroup.name) then
						koEngine.debugText("group '"..spawnGroup.name.."' at objective was destroyed, deleting it from the table")

						for i, unit in pairs(group:getUnits()) do
							if ctld.groundCrewUnitTypes[unit:getTypeName()] and group:getCoalition() == coaNameTable[objectiveTable.coa] then
								koEngine.debugText(objectiveTable.coa.." groundcrew was destroyed!!")
								
								local type = ctld.groundCrewUnitTypes[unit:getTypeName()]
								-- Group has been killed notify players
								--if not objectiveTable.underAttack then
								if groupCoa == 'red' then
									table.insert(msgHolder[1],'_______________________________________________________________________________________________________\n\n  WE ARE UNDER ATTACK!\n  '..category..' '..objectiveName..' is under attack!\n  ------------\n\n  Our '..type..' groundcrew has been destroyed!\n\n_______________________________________________________________________________________________________')
									table.insert(msgHolder[2],'_______________________________________________________________________________________________________\n\n  WE ARE ATTACKING!\n  Our forces are attacking '..category..' '..objectiveName..'!\n  ------------\n\n  The enemy '..type..' groundcrew has been destroyed!\n\n_______________________________________________________________________________________________________')
								elseif groupCoa == 'blue' then
									table.insert(msgHolder[2],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  '..category..' '..objectiveName..' is under attack!\n  ------------\n\n  Our '..type..' groundcrew has been destroyed!\n\n_______________________________________________________________________________________________________')
									table.insert(msgHolder[1],'_______________________________________________________________________________________________________\n\n  GOOD NEWS FROM THE FRONT!\n  Our forces are attacking '..category..' '..objectiveName..'!\n  ------------\n\n  The enemy '..type..' groundcrew has been destroyed!\n\n_______________________________________________________________________________________________________')
								end
								--end
								
								objectiveTable.groundCrew[groupCoa]['has'..type] = nil
								
							elseif not objectiveTable.underAttack then
								koEngine.debugText("objective now under attack")
								if groupCoa == 'red' then
									table.insert(msgHolder[1],'_______________________________________________________________________________________________________\n\n  WE ARE UNDER ATTACK!\n  '..category..' '..objectiveName..' is under attack!\n  ------------\n\n  '..spawnGroup.name..' has been destroyed!\n\n_______________________________________________________________________________________________________')
									table.insert(msgHolder[2],'_______________________________________________________________________________________________________\n\n  WE ARE ATTACKING!\n  Our forces are attacking '..category..' '..objectiveName..'!\n  ------------\n\n  Enemy '..spawnGroup.name..' has been destroyed!\n\n_______________________________________________________________________________________________________')
								elseif groupCoa == 'blue' then
									table.insert(msgHolder[2],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  '..category..' '..objectiveName..' is under attack!\n  ------------\n\n  '..spawnGroup.name..' has been destroyed!\n\n_______________________________________________________________________________________________________')
									table.insert(msgHolder[1],'_______________________________________________________________________________________________________\n\n  GOOD NEWS FROM THE FRONT!\n  Our forces are attacking '..category..' '..objectiveName..'!\n  ------------\n\n  Enemy '..spawnGroup.name..' has been destroyed!\n\n_______________________________________________________________________________________________________')
								end
							end
						end
						
						objectiveTable.groups[groupName] = nil	-- spawnGroup has died completely, delete it
						objectiveTable.underAttack = true
						objectiveTable.lastTimeEnemiesSeen = timer.getTime()
						currentGroupDestroyed = true
					
					-- if the group is there but has losses delete the unit lost
					elseif not isAllOfSpawngroupThere(spawnGroup) then
						--koEngine.debugText("group '"..spawnGroup.name.."' at objective has losses")
						
						local units = Group.getUnits(group)
						if not units then 
							koEngine.debugText("FATAL ERROR: could not get units for "..spawnGroup.groupName)
						else
							for j, spawnUnit in pairs(spawnGroup.units) do
								local unitFound = false
								-- now update the spawnUnit
								for k, unit in pairs(units) do
									if unit:isExist() and spawnUnit.name == unit:getName() then
										unitFound = true
										break
									end
								end
								
								if not unitFound then
									koEngine.debugText("Unit '"..spawnUnit.name.."' is dead, deleting it "..j)
									table.remove(spawnGroup.units, j) -- if it doesnt exist anymore delete the unit from the table
									
									if not objectiveTable.underAttack then
										if objectiveTable.coa == 'red' then
											table.insert(msgHolder[1],'_______________________________________________________________________________________________________\n\n  WE ARE UNDER ATTACK!\n  '..category..' '..objectiveName..' is under attack!\n  ------------\n\n  Our '..spawnUnit.type..' has been destroyed!\n\n_______________________________________________________________________________________________________')
											table.insert(msgHolder[2],'_______________________________________________________________________________________________________\n\n  WE ARE ATTACKING!\n  Our forces are attacking '..category..' '..objectiveName..'!)\n  ------------\n\n  If you can, go to the Objective and support your Allies!\n\n_______________________________________________________________________________________________________')
										elseif objectiveTable.coa == 'blue' then
											table.insert(msgHolder[2],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  '..category..' '..objectiveName..' is under attack!)\n  ------------\n\n  Our '..spawnUnit.type..' has been destroyed!\n\n_______________________________________________________________________________________________________')
											table.insert(msgHolder[1],'_______________________________________________________________________________________________________\n\n  GOOD NEWS FROM THE FRONT!\n  Our forces are attacking '..category..' '..objectiveName..'!)\n  ------------\n\n  If you can, go to the Objective and support your Allies!!\n\n_______________________________________________________________________________________________________')
										end
										
										koEngine.debugText(objectiveName.." is now UNDER ATTACK!")
									end
									
									objectiveTable.underAttack = true
									objectiveTable.lastTimeEnemiesSeen = timer.getTime()
								end
							end
						end
					end
					
					
					--------------------------------------------------------
					-- group has no losses
					if not currentGroupDestroyed then
						local units = Group.getUnits(group)
						
						-- now update positions and groundcrew status
						for k, unit in pairs(units) do
							if unit:isExist() then
								-- checking for groundcrew
								local groundcrewType = ctld.groundCrewUnitTypes[unit:getTypeName()] 
								--koEngine.debugText("groudcrewType = "..tostring(groundcrewType))
								if groundcrewType then
									objectiveTable.groundCrew[groupCoa]['has'..groundcrewType ] = true
								end
							
								--koEngine.debugText("updating position for unit "..k)
								for j, spawnUnit in pairs(spawnGroup.units) do
									if spawnUnit.name == unit:getName() then
										-- update unit position
										local point = unit:getPoint()
										spawnUnit.x = point.x
										spawnUnit.y = point.z
									end
								end
							end
						end
					end
				end
				
				
				--koEngine.debugText("checking FARP open/closed: objectiveTable.groundCrew = "..koEngine.TableSerialization(objectiveTable.groundCrew))
							
				--------------------------------------------------------
				-- check if FARP is closed
				if category == 'FARP' and objectiveTable.status == "open"  then
					-- close the farp if its contested
					if objectiveTable.coa == "contested" then
						objectiveTable.status = "closed"
						table.insert(msgHolder[1],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  '..objectiveName..' is CONTESTED!\n  ------------\n\n  The FARP is now CLOSED!\n\n_______________________________________________________________________________________________________')
						table.insert(msgHolder[2],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  '..objectiveName..' is CONTESTED!\n  ------------\n\n  The FARP is now CLOSED!\n\n_______________________________________________________________________________________________________')
					
					-- check if the objectives groundcrew is complete
					elseif not objectiveTable.groundCrew[objectiveTable.coa].hasATC and not objectiveTable.groundCrew[objectiveTable.coa].hasFuel and not objectiveTable.groundCrew[objectiveTable.coa].hasAmmo then
						koEngine.debugText(objectiveName.." has been closed!")
						objectiveTable.status = "closed"
						-- Group has been killed notify players
						table.insert(msgHolder[coaNameTable[objectiveTable.coa]],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  '..objectiveName..' had all groundcrew units destroyed!\n  ------------\n\n  The FARP is now CLOSED!\n\n_______________________________________________________________________________________________________')
						table.insert(msgHolder[coaNameTable[counterCoa[objectiveTable.coa]]],'_______________________________________________________________________________________________________\n\n  GOOD NEWS FROM THE FRONT!\n  Our forces have destroyed all groundcrew units at '..objectiveName..'!\n  ------------\n\n  The FARP is now closed!\n\n_______________________________________________________________________________________________________')
					end
				elseif category =='FARP' and objectiveTable.coa ~= 'neutral' and objectiveTable.coa ~= 'contested' and objectiveTable.status == "closed" then
					--koEngine.debugText("objectiveTable.coa = "..objectiveTable.coa)
					if objectiveTable.groundCrew[objectiveTable.coa].hasATC and objectiveTable.groundCrew[objectiveTable.coa].hasFuel and objectiveTable.groundCrew[objectiveTable.coa].hasAmmo then
						koEngine.debugText(objectiveName.." is now open!")
						objectiveTable.status = "open"
						-- Group has been killed notify players
						table.insert(msgHolder[coaNameTable[objectiveTable.coa]],'_______________________________________________________________________________________________________\n\n  GOOD NEWS FROM THE FRONT!\n  '..objectiveName..' now has complete groundcrew!\n  ------------\n\n  The FARP is now OPEN!\n\n_______________________________________________________________________________________________________')
						table.insert(msgHolder[coaNameTable[counterCoa[objectiveTable.coa]]],'_______________________________________________________________________________________________________\n\n  BAD NEWS FROM THE FRONT!\n  The enemy has deployed a complete set of groundcrew at '..objectiveName..'!\n  ------------\n\n  The FARP is now OPEN!\n\n_______________________________________________________________________________________________________')
					end
				end
				
				
				--------------------------------------------------------
				-- check if Objective is still under ATTACK
				if objectiveTable.underAttack then
					-- check if enemies are nearby and save the time.
					 
					local allEnemyAirUnits
					if objectiveTable.coa ~= "neutral" and objectiveTable.coa ~= "contested" then
						allEnemyAirUnits = mist.makeUnitTable({'['..counterCoa[objectiveTable.coa]..'][helicopter]','['..counterCoa[objectiveTable.coa]..'][plane]'})
					else
						allEnemyAirUnits = mist.makeUnitTable({'[red][helicopter]','[red][plane]','[blue][helicopter]','[blue][plane]'})
					end
					local zonePoint = trigger.misc.getZone(objectiveName).point
					zonePoint.y = land.getHeight({x = zonePoint.x, y = zonePoint.z}) + 9	-- offset the height above ground
					local enemiesNear = koEngine.getLOSUnitsFromPoint(zonePoint, allEnemyAirUnits, 0, koEngine.attackRadius)
					--koEngine.debugText("enemiesNear = "..koEngine.TableSerialization(enemiesNear))
							
					if enemiesNear and #enemiesNear > 0 then	-- we have enemies near! 
						--koEngine.debugText("there are "..#enemiesNear.." enemies near "..objectiveName)
						objectiveTable.lastTimeEnemiesSeen = timer.getTime()
					else
						if objectiveTable.lastTimeEnemiesSeen then
							if(timer.getTime() - objectiveTable.lastTimeEnemiesSeen) >= 600 then
								koEngine.debugText("there have not been any enemies spottet near "..objectiveName.."since 10 minutes, not under Attack anymore!")
								objectiveTable.underAttack = false	-- not under attack if the last time an enemy was seen is longer than x seconds ago
								objectiveTable.lastTimeEnemiesSeen = nil
							end
						end
					end
				end
				
				
				
				--------------------------------------------------------
				--  check if we can switch off AI
				--
				-- 
				--[[-- 
				local allEnemyAirUnits = mist.makeUnitTable({'['..counterCoa[objectiveTable.coa]..'][helicopter]','['..counterCoa[objectiveTable.coa]..'][plane]'})
				local enemiesNear = mist.getDeadUnitsLOS(mist.makeUnitTable({"[g]"..groupName}), 2, allEnemyAirUnits, 0, 100)
				
				local group = Group.getByName(groupName)
				local controller = group:getController()
				
				if not enemiesNear or enemiesNear and #enemiesNear ~= 0 then	-- objective can only be under attack if enemies are within midrange los. 
					koEngine.debugText("switching off AI for "..groupName)
					controller:setOnOff(false)
				else
					koEngine.debugText("switching on AI for "..groupName)
					controller:setOnOff(true)
				end--]]
			
			end
		end
	end
	
	--update missionRuntime.
	MissionData['properties']['missionRuntime'] = timer.getAbsTime() - timer.getTime0()
	mist.scheduleFunction(koEngine.main,{}, timer.getTime() + koEngine.mainLoopFrequency)
	koEngine.lastMainLoop = timer.getTime()
	
	if save then
		koEngine.saveGame()	-- update the savegame file so koSlotBlockGameGUI.lua has current data to work properly
	end
end

-------------------------------------------
-- helper function to ensure the main loop is running, if it stopped running due to a bug it will be restarted
function koEngine.checkMainLoop()
	mist.scheduleFunction(koEngine.checkMainLoop, {}, timer.getTime() + 10)
	
	local timepassed = timer.getTime() - koEngine.lastMainLoop
	
	if timepassed > 10 then
		koEngine.debugText("FATAL ERROR: main loop has stopped, restarting it!")
		koEngine.main()
	end
	
	timepassed = timer.getTime() - koScoreBoard.lastMainLoop
	
	if timepassed > 10 then
		koEngine.debugText("FATAL ERROR: scoreboard main loop has stopped, restarting it!")
		koScoreBoard.main()
	end
end



function koEngine.destroyGroup(groupName)
	koEngine.debugText("koEngine.destroyGroup('"..groupName.."'")
	
	local groupUnits = mist.makeUnitTable({"[g]"..groupName})
	if groupUnits and #groupUnits > 0 then
		for groupUnits_ind = 1, #groupUnits do
			local unit = Unit.getByName(groupUnits[groupUnits_ind])
			if unit and unit:isActive() == true then
				 mist.scheduleFunction(trigger.action.explosion, {unit:getPoint(), 100 }, timer.getTime()+groupUnits_ind/4)
			end
		end
		koEngine.debugText("requested explosions at unit locations, standby")
	else
		koEngine.debugText("group '"..groupName.."'not found, could not destroy")
	end
end

function koEngine.destroyObjective(objectiveName)
	local objectiveTable = MissionData[koEngine.getObjectiveCategory(objectiveName)][objectiveName]
	for groupType, groupTable in pairs(koEngine.zoneUnitData[objectiveName][objectiveTable.coa]) do
		if groupType == 'groups' then
			for groupIndex, groupName in pairs(groupTable) do
				koEngine.destroyGroup(groupName)
			end
		end
	end
end

-----------------------------------------------
-- 	koEngine.ctldCallback(event)
--[[	CTLD Callback
--
-- 	whenever someone loads, unloads or drops something from transport
-- 	event format:
-- 		unit = _heli,				[string]		- unit that did the action 
--      unloaded = "dropped_droops",	[number] unitID or [table] containing units (see below)
--		action = "dropped_troops"	[string]		- what did he do
--										- "unload_troops_zone" (returns table for "unloaded")
--										- "unload_troops"
--										- "dropped_troops"

--	depending on the value of action, unloaded is either a number or a table.  
-- 		unloaded [table]	- units that were dropped
--							- side [num]
--							- groupId [num]
--							- country [num]
--							- groupName [string]
--							- units [table of units]
--										- # [table]
--												- type [string]
--												- name [string]
--												- unitId [num] 
-------------------------------------------------]]
function koEngine.ctldCallback(event) 
	koEngine.debugText("koEngine.ctldCallback() was called, action = "..event.action..", player = "..tostring(event.unit:getPlayerName()), 10)
	
	-- check the contents of event
	if event ~= nil and event.unit:getPlayerName() ~= nil then
		local zone = koEngine.isUnitInObjectiveZone(event.unit)
		
		-- hoverpickup
		if event.action == "hoverpickup" then
			koEngine.debugText("player loadeda vehicle - adding score")
			-- choppers deserve a score!
			
			
			local newScore = {
				achievment = "hoverpickup",
				unitGroupID = getGroupId(event.unit),
				unitCategory = unitCategoryTable[event.unit:getDesc().category],
				unitType = event.unit:getTypeName(),
				unitName = event.unit:getName(),
				droppedUnit = event.crate,
				zone = zone,
				side = coalitionTable[event.unit:getCoalition()],
			}
			koScoreBoard.insertScoreForPlayer(event.unit:getPlayerName(), newScore)
		
		-- hoverpickup
		elseif event.action == "crate_safely_unhooked" or event.action == "crate_safely_dropped" or event.action == "crate_dropped_on_ground" then
			koEngine.debugText("player loadeda vehicle - adding score")
			-- choppers deserve a score!
			
			if event.zone then
				event.action = event.action.."_inzone"
			end
			
			local newScore = {
				achievment = event.action,
				unitGroupID = getGroupId(event.unit),
				unitCategory = unitCategoryTable[event.unit:getDesc().category],
				unitType = event.unit:getTypeName(),
				unitName = event.unit:getName(),
				droppedUnit = event.crate,
				zone = zone,
				side = coalitionTable[event.unit:getCoalition()],
			}
			koScoreBoard.insertScoreForPlayer(event.unit:getPlayerName(), newScore)
			
		
		
		---------------------------------------------
		--[[ if the player has unpacked crates:
		--
		-- crates look like this:
			event.crate = {
				['crateUnit'] = {
					['id_'] = 8001161,
				},
				['details'] = {
					['side'] = 2,
					['weight'] = 315,
					['cratesRequired'] = 1,
					['unit'] = 'M1025 HMMWV',
					['desc'] = 'FARP ATC - HMMV M1025',
				}
			}
		--]]
		elseif event.action == "unpack" then
			--koEngine.debugText("event = "..koEngine.TableSerialization(event))
			
			local playerName = koEngine.getPlayerNameFix(event.unit:getPlayerName()) or "AI"
			local playerUCID = koEngine.getPlayerUCID(playerName)
			local unitDesc = event.crate.details.desc		-- the spawned from the crate units name
			local dropzone = koEngine.isUnitInObjectiveZone(event.unit)
			local spawnedGroupName = event.spawnedGroup:getName()
			
			koEngine.debugText("player unpacked cargo, unitDesc = "..unitDesc..", dropzone = "..tostring(dropzone))
			
			--------------------------------------------
			-- dropped in a DROPZONE!
			--------------------------------------------
			if dropzone then -- if in a dropzone we're interested
				--koEngine.debugText("player is on dropzone: '"..dropzone.."', adding '"..spawnedGroupName.."' to spawnGroups")
				
				-- add crate to the zoneUnitData!
				local category = koEngine.getObjectiveCategory(dropzone)
				local coalition = coalitionTable[event.unit:getCoalition()]
				local objectiveTable = MissionData[category][dropzone]
				
				-- save the spawntable to the objectives groups so it would respawn on restart!
				objectiveTable.groups[spawnedGroupName] = ctld.spawnedCrateGroups[spawnedGroupName]
				objectiveTable.groups[spawnedGroupName].playerName = playerName
				objectiveTable.groups[spawnedGroupName].playerUCID = playerUCID
				objectiveTable.groups[spawnedGroupName].playerCategory = unitCategoryTable[event.unit:getDesc().category]
				objectiveTable.groups[spawnedGroupName].playerType = event.unit:getTypeName()
				objectiveTable.groups[spawnedGroupName].coalition = coalition
				
				-- add group to zoneUnitData for unitCheck check
				if not koEngine.zoneUnitData[category][dropzone][coalition] then 
					koEngine.zoneUnitData[category][dropzone][coalition] = {}
					koEngine.zoneUnitData[category][dropzone][coalition].groups = {}
					koEngine.zoneUnitData[category][dropzone][coalition].units = {}
				end
				
				table.insert(koEngine.zoneUnitData[category][dropzone][coalition].groups, spawnedGroupName)
				
				for i, unit in pairs(event.spawnedGroup:getUnits()) do
					table.insert(koEngine.zoneUnitData[category][dropzone][coalition].units, unit:getName())
				end
				
				-- choppers deserve a score!
				if objectiveTable.coa == "neutral" then
					-- choppers deserve a score!
					local newScore = {
						achievment = "neutral_base_occupied",
						unitGroupID = getGroupId(event.unit),
						unitCategory = unitCategoryTable[event.unit:getDesc().category],
						unitType = event.unit:getTypeName(),
						unitName = event.unit:getName(),
						droppedUnit = event.crate.details.desc,
						zone = dropzone,
						side = coalitionTable[event.unit:getCoalition()],
					}
					koScoreBoard.insertScoreForPlayer(playerName, newScore)
				else
					local newScore = {
						unitGroupID = getGroupId(event.unit),
						unitCategory = unitCategoryTable[event.unit:getDesc().category],
						unitType = event.unit:getTypeName(),
						unitName = event.unit:getName(),
						achievment = "cargo_unpacked_in_zone",
						droppedUnit = event.crate.details.desc,
						zone = dropzone,
						side = coalitionTable[event.unit:getCoalition()],
					}
					koScoreBoard.insertScoreForPlayer(playerName, newScore)
				end
				
				koEngine.saveGame()
				
				--------------------------------------------
				-- Ground Unit Check
				-- 
				-- handles opened or closed
				--------------------------------------------
				
				--check unitprefix
				local lastIndex
				if unitDesc:find(" ") then	lastIndex = unitDesc:find(" ")-1
				else lastIndex = unitDesc:len()	end				
				local unitPrefix = unitDesc:sub(1, lastIndex)
					
				------------------------------
				-- is GROUNDCREW, 
				if unitPrefix == "Groundcrew" then
					-- check if the objectives groundcrew is complete
					local groundcrewComplete = true		
					if category == "FARP" then 
						if objectiveTable.groundCrew then 
							if not objectiveTable.groundCrew.hasATC or not objectiveTable.groundCrew.hasFuel or not objectiveTable.groundCrew.hasAmmo then
								koEngine.debugText("It's a FARP and the Ground Crew is missing or has losses")
								groundcrewComplete = false
							end
						else
							groundcrewComplete = false
						end
					end
					
					--if category == "FARP" and objectiveTable.status == "open" and  groundcrewComplete then
					--	koEngine.outTextForGroup(getGroupId(event.unit), "This FARP already is fully equiped with groundCrew!\nThe Unit will be considered a standard unit just standing around. Sorry", 10)
					if category == "FARP" then
						--koEngine.debugText("dropped a crate at a neutral objective! containing '"..event.crate.details.desc.."'")
						objectiveTable.groundCrew = objectiveTable.groundCrew or {}
						
						local unitType = unitDesc:sub(unitDesc:find(" ")+1, unitDesc:len())
												
						--koEngine.debugText("We have Groundcrew! unitTypePrefix = '"..unitType.."'")
						
						-- TODO Groundcrew CTLD Callback						
						-- start status message					
						local msg= "_______________________________________________________________________________________________________\n" 
						msg = msg.."  SUPPLY UPDATE\n  -------------\n\n"
						msg = msg.."  "..playerName.."(".. event.unit:getTypeName() ..") Supplied "..unitType.." to "..dropzone.."\n"
						
						--	only do this for those 3 unit-types
						if unitType == "ATC" or unitType == "Fuel" or unitType == "Ammo" then
							koEngine.debugText(unitType.." Vehicle got spawned at a neutral Farp!")
							
							-- add a little info that this unit is in fact groundcrew and what type
							ctld.spawnedCrateGroups[spawnedGroupName].isGroundCrew = unitType
							
							objectiveTable.groundCrew[coalition]['has'..unitType] = true				-- save the fact that a red unit has placed an ATC etc. ...
														
							msg = msg.."  - "..unitType.." is now available for the "..coalition.." Coalition at "..dropzone.."!\n"
							
							local groundCrew = objectiveTable.groundCrew[coalition] 
							if groundCrew.hasATC then
								
								if groundCrew.hasFuel then
									msg = msg.."  - you are now able to refuel at this location!"
								end
								if groundCrew.hasAmmo then
									msg = msg.."  - you are now able to Rearm at this location!"
								end
								if groundCrew.hasFuel and groundCrew.hasAmmo then
									msg = msg.."  Groundcrew at "..zone.." is now complete!"
								end
							end
							
							-- choppers deserve a score!
							local newScore = {
								unitGroupID = getGroupId(event.unit),
								unitCategory = unitCategoryTable[event.unit:getDesc().category],
								unitType = event.unit:getTypeName(),
								unitName = event.unit:getName(),
								achievment = "farp_groundcrew_supplied",
								targetType = unitType,
								side = coalitionTable[event.unit:getCoalition()],
							}
							koScoreBoard.insertScoreForPlayer(playerName, newScore)
						end	
						
						msg = msg .. "\n_______________________________________________________________________________________________________\n"
						table.insert(msgHolder[coaNameTable[coalition]], msg) 
						-- end status message
										
						-- now check if groundcrew is complete
						local nowOpen = false
						if objectiveTable.groundCrew.hasATC == "red" and objectiveTable.groundCrew.hasFuel == "red" and objectiveTable.groundCrew.hasAmmo == "red" then
							nowOpen = true
						elseif objectiveTable.groundCrew.hasATC == "blue" and objectiveTable.groundCrew.hasFuel == "blue" and objectiveTable.groundCrew.hasAmmo == "blue" then
							nowOpen = true
						end
						
						----------------------------------------------------------
						-- the neutral farp was opened!!!
						if objectiveTable.status ~= "open" and nowOpen then
							koEngine.debugText("Farp_opened!")
							msg = "_______________________________________________________________________________________________________\n" 
							msg = msg.."  "..dropzone.." is now OPEN for the "..string.upper(coalition).." Team!\n"
							msg = msg.."  -------------\n\n"
							msg = msg.."  they can now spawn and fully operate from "..dropzone.."\n"
							msg = msg.."\n_______________________________________________________________________________________________________\n" 
							
							
							objectiveTable.status = "open"
							objectiveTable.coa = coalitionTable[event.unit:getCoalition()]

							-- make the dropzone active for pickup!
							table.insert(ctld.pickupZones,{ dropzone, 'trigger.smokeColor.'..objectiveTable.coa, koEngine.troopPickupLimit, 1, 2 })
							
							-- choppers deserve a score!
							local newScore = {
								unitGroupID = getGroupId(event.unit),
								unitCategory = unitCategoryTable[event.unit:getDesc().category],
								unitType = event.unit:getTypeName(),
								unitName = event.unit:getName(),
								achievment = "neutral_farp_opened",
								--droppedCrate = event.crate,
								--spawnedGroup = event.spawnedGroup,
								side = coalitionTable[event.unit:getCoalition()],
							}
							koScoreBoard.insertScoreForPlayer(playerName, newScore)
							
							table.insert(msgHolder[0], msg)
						end
					end
					
					return
				end
				
				return
			else
				------------------------------------------------------------------------
				--	NOT IN A DROPZONE
				------------------------------------------------------------------------

				koEngine.debugText("player is NOT in a dropzone")
					
				--	keep track of unpacked sams to respawn them and collect scores for the unpacker!
				if not MissionData.properties.droppedSAMs then MissionData.properties.droppedSAMs = {} end
				
				local playerName = koEngine.getPlayerNameFix(event.unit:getPlayerName())
				local gname = spawnedGroupName
								
				local newSAM = {
					playerName = playerName,
					playerUCID = koEngine.getPlayerUCID(playerName),
					playerCategory = unitCategoryTable[event.unit:getDesc().category],
					playerType = event.unit:getTypeName(),
					coalition = event.unit:getCoalition(),
					groupID = event.spawnedGroup:getID(),
					groupName = spawnedGroupName,
					spawnedGroup = event.spawnedGroup,
					groupSpawnTable = ctld.spawnedCrateGroups[spawnedGroupName],
					time = MissionData.properties.campaignSecs, -- mark the time when the sam was added!
				}
				table.insert(MissionData.properties.droppedSAMs, newSAM)
						
				--koEngine.debugText(koEngine.TableSerialization(mist.DBs.groupsByName))
				
				-- choppers deserve a score!
				local newScore = {
					unitGroupID = getGroupId(event.unit),
					unitCategory = unitCategoryTable[event.unit:getDesc().category],
					unitType = event.unit:getTypeName(),
					unitName = event.unit:getName(),
					achievment = "crate_deployed",
					droppedUnit = event.crate.details.desc,
					--deployedSam = newSAM,
					samName = spawnedGroupName,
					--spawnedGroup = event.spawnedGroup,
					side = coalitionTable[event.unit:getCoalition()],
				}
				koScoreBoard.insertScoreForPlayer(event.unit:getPlayerName(), newScore)
				return
				
				--koEngine.saveGame()
			end
			
		---------------------------------------------
		--[[ if the player has repaired crates:
		--
		-- 
		
		--]]
		elseif event.action == "repair" or event.action == "rearm" then
			koEngine.debugText("crate was "..event.action.."ed!") -- event = "..koEngine.TableSerialization(event))
			
			local spawnedGroupName = event.spawnedGroup:getName()
			
			local samTable = false
			-- find the old sam
			for i, sam in pairs(MissionData.properties.droppedSAMs) do
				if sam.spawnedGroup == event.replacedGroup then
					koEngine.debugText("found the old repaired (now destroyed) group in droppedSAMs!")
					samTable = sam
					
					-- now update the sam table
					samTable.playerName = koEngine.getPlayerNameFix(event.unit:getPlayerName())
					samTable.playerUCID = koEngine.getPlayerUCID(event.unit:getPlayerName())
					samTable.playerType = event.unit:getTypeName()
					samTable.groupID = event.spawnedGroup:getID()
					samTable.groupName = spawnedGroupName
					samTable.spawnedGroup = event.spawnedGroup
					samTable.groupSpawnTable = ctld.spawnedCrateGroups[spawnedGroupName]
					break
				end
			end
			
			if not samTable then
				if event.zone then
					koEngine.debugText("checking units in zone"..event.zone)
					local groups = koEngine.getObjectiveByName(event.zone).groups
					for groupName, sam in pairs(groups) do
						koEngine.debugText("comparing groupName: "..groupName.." with replacedGroupName: "..event.replacedGroupName)
						if groupName == event.replacedGroupName then
							koEngine.debugText("found the old repaired (now destroyed) group in objective!")
							
							groups[groupName] = nil -- we can delete the old saved-sam, as it was destroy()ed during repair
							groups[spawnedGroupName] = ctld.spawnedCrateGroups[spawnedGroupName]
							groups[spawnedGroupName].playerName = koEngine.getPlayerNameFix(event.unit:getPlayerName())
							groups[spawnedGroupName].playerUCID = koEngine.getPlayerUCID(event.unit:getPlayerName())
							groups[spawnedGroupName].playerType = event.unit:getTypeName()
							samTable = groups[spawnedGroupName]
							
							-- add group to zoneUnitData for unitCheck check
							local category = koEngine.getObjectiveCategory(event.zone)
							local coalition = coalitionTable[event.unit:getCoalition()]
							
							if not koEngine.zoneUnitData[category][event.zone][coalition] then 
								koEngine.zoneUnitData[category][event.zone][coalition] = {}
								koEngine.zoneUnitData[category][event.zone][coalition].groups = {}
								koEngine.zoneUnitData[category][event.zone][coalition].units = {}
							end
							
							table.insert(koEngine.zoneUnitData[category][event.zone][coalition].groups, spawnedGroupName)
							
							for i, unit in pairs(event.spawnedGroup:getUnits()) do
								table.insert(koEngine.zoneUnitData[category][event.zone][coalition].units, unit:getName())
							end
							
							break
						end
					end
				else
					koEngine.debugText("not in a zone, can't look further")
				end
			end
			
			-- if still no samTable then throw error!
			if not samTable then
				koEngine.debugText("FATAL ERROR: could not find repaired sam table!")
				return
			end
			
			koEngine.debugText(event.action.." finished, adding score")
			-- choppers deserve a score!
			local achievment = ""
			if event.action == "repair" then
				achievment = "repaired_sam"
			elseif event.action == "rearm" then
				achievment = "rearmed_sam"
			end
			
			local newScore = {
				unitGroupID = getGroupId(event.unit),
				unitCategory = unitCategoryTable[event.unit:getDesc().category],
				unitType = event.unit:getTypeName(),
				achievment = achievment,
				samName = spawnedGroupName,
				side = coalitionTable[event.unit:getCoalition()],
			}
			koScoreBoard.insertScoreForPlayer(event.unit:getPlayerName(), newScore)
		end

	else 
		koEngine.debugText("WARNING: koEngine.ctldCallback(): no event!")
		return
	end
		
end

function koEngine.getObjectiveCategory(_objectiveName)
	for categoryName, categoryTable in pairs(MissionData) do
		for objectiveName, objectiveTable in pairs(categoryTable) do
			if objectiveName == _objectiveName then
				return categoryName
			end
		end
	end
	
	koEngine.debugText("WARNING: koEngine.getObjectiveCategory('".._objectiveName.."' failed!")
	return nil
end

function koEngine.getObjectiveByName(_objectiveName)
	for categoryName, categoryTable in pairs(MissionData) do
		for objectiveName, objectiveTable in pairs(categoryTable) do
			if objectiveName == _objectiveName then
				return objectiveTable
			end
		end
	end
	
	koEngine.debugText("WARNING: koEngine.getObjectiveByName('".._objectiveName.."' failed!")
	return nil
end

---------------------------------------
-- string isUnitInObjectiveZone(unit)
-- check if the unit is in a capture-zone
function koEngine.isUnitInObjectiveZone(unit)
	-- find if the player is in a dropzone
	for _, dropzone in pairs(koEngine.dropZoneTable) do
		local unitsInZone = mist.getUnitsInZones({ unit:getName() }, { dropzone })
		for __, currentUnit in pairs(unitsInZone) do
			-- yes unit is in czone
			if currentUnit:getID() == unit:getID() then
				koEngine.debugText("koEngine.isUnitInObjectiveZone("..unit:getName()..") - unit is in "..dropzone)
				return dropzone
			end
		end
	end
	koEngine.debugText("koEngine.isUnitInObjectiveZone("..unit:getName()..") - unit is not in a zone")
	return nil
end



--------------------------------------------
-- koEngine.eventHandler() - scheduled function
--------------------------------------------
--
-- checks BIRTH, TAKEOFF and LANDING events
-- to keep track of player lives
local eventHandler = {}
function eventHandler:onEvent(event)
	if event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT or event.id == world.event.S_EVENT_BASE_CAPTURED then
		return
	end
	
	koEngine.debugText("koEngine.eventHandler("..eventTable[event.id]..")"..tostring(event.id), 1)
	
	if event.id == world.event.S_EVENT_MISSION_END then
		
		for ucid, sortie in pairs(koScoreBoard.activeSorties) do
			koEngine.debugText("found active Sortie for player "..sortie.playerName..", closing it")
			koScoreBoard.closeSortie(sortie.playerName, "Mission End")
		end
		
		koTCPSocket.send({ status = "restarting" }, "restart")
		
		koTCPSocket.forceTransmit()	-- try to send it right away
		--koTCPSocket.saveBuffer() -- called inside forceTransmit()
		return
	end
	
	--------------------------------------
	--
	--if koEngine.debugText("koEngine.eventHandler("..eventTable[event.id]..")"..tostring(event.id), 1) then
		--koEngine.debugText("event: "..koEngine.TableSerialization(event))
		--koEngine.debugText("event Base Captured: placeName: "..event.place:getName())
		--if event.initiator then
			--koEngine.debugText("initiatorName: "..event.initiator:getName()..", type: "..event.initiator:getTypeName())
		--else
			--koEngine.debugText("no iniator")
		--end
		
		--return
	--end
	
	--[[if event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT then
		local playerName
		if event.initiator then
			playerName = event.initiator:getPlayerName() or "nil"
		else
			playerName = "no initiator"
		end
		
		
		--koEngine.debugText("event: "..koEngine.TableSerialization(event))
		-- close the previous sortie to calculate airtime
		local playerName = koEngine.getPlayerNameFix(playerName)
		local sortie = koScoreBoard.activeSorties[playerName]
		if sortie then
			koEngine.debugText("Player "..playerName.." left unit. Event = "..koEngine.TableSerialization(event))
			sortie.airTime = timer.getTime() - sortie.takeOffTime
			sortie.endReason = "left unit"
			koScoreBoard.insertScoreForPlayer(playerName, sortie)
			koScoreBoard.activeSorties[playerName] = nil
			
			return
		end
	end--]]
	
	--check that there's an initiator
	--if event.initiator and event.initiator:isExist() then
	if event.initiator then
		if Object.getCategory(event.initiator) ~= Object.Category.UNIT then 
			koEngine.debugText("event initiator is not a unit! returning")
			return 
		end	
		
		-- no playername means AI
		local playerName = event.initiator:getPlayerName()
		
		-- not interested in AI here
		if not playerName then 
			koEngine.debugText("AI, returning")
			return 		-- only run if not AI, no player name is AI
		end
		
		if playerName == '' then
			koEngine.debugText("FATAL WARNING: playerName is empty String! Trying to find original player")
			
			-- try to find the player in PlayerUnitList
			for groupID, player in pairs(koEngine.PlayerUnitList) do
				if tonumber(groupID) == getGroupId(event.initiator) then
					koEngine.debugText("found groupID in PlayerUnitList: playerName = '"..player.playerName.."'")
					playerName = player.playerName
				elseif player.unit == event.iniator then
					-- found the player
					playerName = player.playerName
					koEngine.debugText("found playername for empty-string Player in PlayerUnitList")
				end	
			end
		end 
		
		--create vars
		local ownGroupID = getGroupId(event.initiator) if not ownGroupID then koEngine.debugText("FATAL ERROR: initiator has no groupId!") return end	-- uses ciribobs getGroupId, defined in koEngine
		local playerUnitName = event.initiator:getName() if not playerUnitName then koEngine.debugText("FATAL ERROR: initiator has no name!") return end	
		local playerNameFix = koEngine.getPlayerNameFix(playerName)
		local playerUCID = koEngine.getPlayerUCID(playerName)
		local coalition = coalitionTable[event.initiator:getCoalition()]

		--------------------------------------
		--	BIRTH event
		--	- make the radio menu
		--	- debug functions
		if event.id == world.event.S_EVENT_BIRTH then
			koEngine.debugText("Player '"..playerName.."' has entered "..coalition.."("..event.initiator:getTypeName()..") '"..playerUnitName.."'")
			
			koEngine.PlayerUnitList[tostring(ownGroupID)] = {
				unit = event.initiator,
				playerName = playerName,
				playerUCID = playerUCID,
				playerUnitName = playerUnitName,
				playerUnitCategory = unitCategoryTable[event.initiator:getDesc().category],
				playerUnitType = event.initiator:getTypeName(),
				side = coalition,
			}
			koEngine.debugText("PlayerUnitList["..tostring(ownGroupID).."] = "..koEngine.TableSerialization(koEngine.PlayerUnitList[tostring(ownGroupID)]))
			
			koEngine.debugText("creating radio-menu")
			-- create menu items
			koEngine.makeRadioMenu(event, ownGroupID, playerName, event.initiator)
			
			local zone = koEngine.isUnitInObjectiveZone(event.initiator)
			
			-- check if old sortie was not closed (respawned?)
			if koScoreBoard.getActiveSortie(playerName) then
				koScoreBoard.closeSortie(playerName)
			end				
			
			-- open a new sortie
			local newSortie = koScoreBoard.newSortie(playerName)
			newSortie.type = event.initiator:getTypeName()
			newSortie.unitName = playerUnitName
			newSortie.unitCategory = unitCategoryTable[event.initiator:getDesc().category]
			newSortie.unitType = event.initiator:getTypeName()
			newSortie.side = coalition
			newSortie.zone = zone
			newSortie.birthTime = timer.getTime()
			
			-- if its a heli make sure to start CSAR stuff (by Ciribob) --
			if unitCategoryTable[event.initiator:getDesc().category] == "HELICOPTER" then
				koEngine.debugText("adding medevac menu to HELICOPTER")
				
				for _, _heliName in pairs(csar.csarUnits) do
	                if _heliName == event.initiator:getName() then
	                    -- add back the status script
						koEngine.debugText("found heli in csarUnits")
						
	                    for _woundedName, _groupInfo in pairs(csar.woundedGroups) do
	                    	koEngine.debugText("_woundedName = ".._woundedName)
		                    	if Group.getByName(_woundedName) and Group.getByName(_woundedName):isExist() then 
		                    		
			                    	local _woundedGroup = csar.getWoundedGroup(_woundedName)
			                    	if csar.checkGroupNotKIA(_woundedGroup, _woundedName, event.initiator, _heliName) then
				                    	local _woundedLeader = _woundedGroup[1]
				                    	local _lookupKeyHeli = event.initiator:getID() .. "_" .. _woundedLeader:getID()
				                    	csar.enemyCloseMessage[_lookupKeyHeli] = false -- start fresh
				                    else
				                    	koEngine.debugText("csar: preparing heli after spawn: group _woundedName: '".._woundedName.."' is KIA")
			                    	end
			                    else
			                    	koEngine.debugText("csar: preparing heli after spawn: group _woundedName: '".._woundedName.."' does not exist")
		                    	end
	                    	
                            -- queue up script and chedule timer to check when to pop smoke
                            koEngine.debugText("CSAR: scheduling checkWoundedGroupStatus()")
                            timer.scheduleFunction(csar.checkWoundedGroupStatus, { _heliName, _woundedName }, timer.getTime() + 5)
                        end
	                end
	            end
			end
			
			--[[koEngine.debugText("sending groupID to GameGui")
			-- send groupID to GameGui
			local groupData = {
				groupID = ownGroupID,
				name = playerName,
			}
			socket.try(koEngine.UDPSavegameSendSocket:sendto(koEngine.JSON:encode(groupData).." \n", "127.0.0.1", koEngine.SAVEGAME_SEND_TO_PORT)) --]]
			
			--koEngine.outTextForGroup(ownGroupID,"_______________________________________________________________________________________________________\n\n  Wind "..koEngine.getWindForUnit(event.initiator).."\n_______________________________________________________________________________________________________",30)
		end
		
		--------------------------------------
		--	TAKEOFF event
		--check event when unit takeoff
		if event.id == world.event.S_EVENT_TAKEOFF then
			
			
			-- check if player is valid!
		
			koEngine.debugText("player is valid")
			MissionData['properties']['playerLimit'][playerNameFix] = MissionData['properties']['playerLimit'][playerNameFix] or 0
			
			--koEngine.debugText(koEngine.TableSerialization(event))

			local placeName = "in the field"
			local placeCallsign = ""
			local placeCategory = "grass"
			
			if event.place then
				placeCallsign = event.place:getCallsign()
			end

			-- check if player is in a zone
			local zone = koEngine.isUnitInObjectiveZone(event.initiator)	
			if zone then
				placeName = zone
				placeCategory = koEngine.getObjectiveCategory(zone)
			end
			
			koEngine.debugText(playerName.."("..event.initiator:getTypeName()..") took off from "..placeName)
			
			--player tookoff take limit if the player is in a zone
			if zone then
				for pName,limit in pairs(MissionData['properties']['playerLimit']) do
					if pName == playerNameFix then
						koEngine.debugText("Player has taken off from Zone, removing live from "..playerNameFix)
						MissionData['properties']['playerLimit'][playerNameFix] = limit+1
					end
				end
				
				local msg = "_______________________________________________________________________________________________________\n\n"
				msg = msg .. "  Have a good flight "..playerName.."\n\n"
				msg = msg .. "  You took off from "..placeName.."/"..placeCallsign.."/"..placeCategory..".\n\n"
				msg = msg .. '  You currently have '..format_num(koScoreBoard.getCashcountForPlayer(playerName))..'$\n'
				msg = msg .. "  Lives - "..MissionData['properties']['playerLimit'][playerNameFix].."/"..MissionData['properties']['lifeLimit'].."\n"
				msg = msg .. "  Land your aircraft on a base to get your life back.\n"
				msg = msg .. "_______________________________________________________________________________________________________\n"
				
				koEngine.outTextForGroup(ownGroupID,msg,30)
			end
			
			-- #choppersdeserveascore!
			local newScore = {
				unitGroupID = getGroupId(event.initiator),
				unitCategory = unitCategoryTable[event.initiator:getDesc().category],
				unitType = event.initiator:getTypeName(),
				unitName = playerUnitName,
				timestamp = event.time,
				timer = timer.getTime(),
				achievment = "takeoff",
				place = placeName,
				placeCategory = placeCategory,
				side = coalition,
			}
			koScoreBoard.insertScoreForPlayer(playerName, newScore)
		end
		
		--------------------------------------
		--	LAND event
		--check event when unit lands
		if event.id == world.event.S_EVENT_LAND then
			
			--koEngine.debugText(koEngine.TableSerialization(event))

			local validLanding = true
			local placeName = "in the field"
			local placeCallsign = ""
			local placeCategory = "grass"
			
			if event.place then
				placeCallsign = event.place:getCallsign()
			end
			
			-- check if player is in a zone
			local zone = koEngine.isUnitInObjectiveZone(event.initiator)
			if zone then
				placeName = zone
				placeCategory = koEngine.getObjectiveCategory(zone)
			end	
			
			koEngine.debugText(playerName.."("..event.initiator:getTypeName()..") landed at "..placeName)
			
			local newScore = {
				unitGroupID = getGroupId(event.initiator),
				unitCategory = unitCategoryTable[event.initiator:getDesc().category],
				unitType = event.initiator:getTypeName(),
				unitName = playerUnitName,
				timestamp = event.time,
				achievment = "landing",
				place = placeName,
				placeCategory = placeCategory,
				side = coalition,  
				timer = timer.getTime(),
			}
			
			--player landed take limit if the player is in a zone
			if zone then
				if MissionData['properties']['playerLimit'] and MissionData['properties']['playerLimit'][playerNameFix] then
					--player landed put back limit
					for pName,limit in pairs(MissionData['properties']['playerLimit']) do
						if pName == playerNameFix then
							koEngine.debugText("Player has landed in Zone, adding live to "..playerNameFix)
							MissionData['properties']['playerLimit'][playerNameFix] = limit-1
							break
						end
					end
					
					local msg = "_______________________________________________________________________________________________________\n\n"
					msg = msg .. "  Good to have you back "..playerName.."\n\n"
					msg = msg .. "  You have landed at "..placeName.."/"..placeCallsign.."/"..placeCategory..".\n\n"
					msg = msg .. '  You currently have '..format_num(koScoreBoard.getCashcountForPlayer(playerName))..'$\n'
					msg = msg .. "  Lives - "..MissionData['properties']['playerLimit'][playerNameFix].."/"..MissionData['properties']['lifeLimit'].."\n"
					msg = msg .. "  Land your aircraft on a base to get your life back.\n"
					msg = msg .. "_______________________________________________________________________________________________________\n"
					
					koEngine.outTextForGroup(ownGroupID, msg, 30)
				end
			elseif not event.place and event.initiator:getDesc().category ~= Unit.Category.HELICOPTER then -- when airplanes land off airport
				newScore.achievment = "emergencylanding"
			end
			
			koScoreBoard.insertScoreForPlayer(playerName, newScore)

			koEngine.saveGame()
		end
	else
		if event.initiator then
			koEngine.debugText("initiator does not exist!")
		else
			koEngine.debugText("there is no initiator")
		end
	end
end


-- sends a convoy to the players current location
function koEngine.sendConvoy(vars)
	--local playerName = vars[1]
	local groupID = vars[2]
	local coalition = vars[3]		-- 'red'/'blue'
	local convoyType = vars[4] or "defensive"
	
	
	--local zone = vars[5]
	local playerUnit = koEngine.PlayerUnitList[tostring(groupID)].unit
	local playerName = playerUnit:getPlayerName()
	
	if playerName == '' then
		koEngine.debugText("FATAL WARNING: playerName is empty String! Trying to find original player")
		-- try to find the player in PlayerUnitList
		for _groupID, player in pairs(koEngine.PlayerUnitList) do
			if tonumber(_groupID) == groupID then
				koEngine.debugText("found groupID in PlayerUnitList: playerName = '"..player.playerName.."'")
				playerName = player.playerName
			end	
		end
	end
	
	local playerNameFix = koEngine.getPlayerNameFix(playerName)
	local zone = koEngine.isUnitInObjectiveZone(playerUnit)
	
	koEngine.debugText("koEngine.sendConvoy('"..coalition.."', '"..tostring(zone).."')")
	--koEngine.debugText("playerUnit:isExist() = "..tostring(playerUnit:isExist()))
	
	-- player needs to be in the zone
	if not zone then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  You are currently not in a Zone!\n  You need to be in the Zone you want a convoy to be sent to!\n_______________________________________________________________________________________________________", 15)
		return
	end
	
	local objectiveTable = koEngine.getObjectiveByName(zone)
	
	if zone and not MissionData.properties.convoys[coalition][zone] then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  There are no convoys to "..zone.." available, sorry!\n_______________________________________________________________________________________________________", 15)
		return
	end
	
	
	-- convoys can only be sent to friendly coalitions
	local category = koEngine.getObjectiveCategory(zone)
	if MissionData[category][zone].coa ~= coalition and convoyType ~= "offensive" then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  You can only send "..convoyType.." convoys to friendly Objectives! \n  "..zone.." is "..MissionData[koEngine.getObjectiveCategory(zone)][zone].coa.."!\n_______________________________________________________________________________________________________", 15)
		return
	elseif MissionData[category][zone].coa == coalition and convoyType == "offensive" then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  You can only send "..convoyType.." convoys to enemy Objectives! \n  "..zone.." is "..MissionData[koEngine.getObjectiveCategory(zone)][zone].coa.."!\n_______________________________________________________________________________________________________", 15)
		return
	elseif MissionData[category][zone].coa == "neutral" then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  You cannot send convoys to neutral Objectives! \n  "..zone.." is "..MissionData[koEngine.getObjectiveCategory(zone)][zone].coa.."!\n_______________________________________________________________________________________________________", 15)
		return
	end
	
	if convoyType == "groundcrew" and category ~= "FARP" then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  Groundcrew can only be ordered to friendly FARPs! \n  "..zone.." is not a FARP!\n_______________________________________________________________________________________________________", 15)
		return
	end
	
	-- check if the player has enough points to send a convoy:
	if koScoreBoard.getCashcountForPlayer(playerName) < koEngine.convoyCost[convoyType] then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  You don't have enough cash to send a "..convoyType.." convoy!\n\n  Get more tasks done to earn cash!\n  You currently have "..format_num(koScoreBoard.getCashcountForPlayer(playerName)).."$, "..koEngine.convoyCost[convoyType].."$ are needed to send a convoy!\n\n  check the webtool at tawdcs.net to find out how _______________________________________________________________________________________________________", 15)
		return
	end
	
	if MissionData[category][zone]['underAttack'] then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  "..zone.." is UNDER ATTACK!\n\n  You cannot send convoys to objectives that are under attack! \n_______________________________________________________________________________________________________", 15)
		return
	end
	
	if MissionData[category][zone]['coa'] == "contested" then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  "..zone.." is CONTESTED!\n\n  You cannot send convoys to objectives that are occupied by both sides! \n_______________________________________________________________________________________________________", 15)
		return
	end
		
	if MissionData[category][zone]['last'..coalition..'ConvoySentTime'] then
		local timeSinceLastConvoy = timer.getTime() - MissionData[category][zone]['last'..coalition..'ConvoySentTime']  -- in seconds
		koEngine.debugText("timeSinceLastConvoy = "..timeSinceLastConvoy) 
		if timeSinceLastConvoy < koEngine.convoyInterval*60 then
			local timeSinceMin = math.floor(timeSinceLastConvoy/60)
			koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  You can only send convoys to an Objective every "..tostring(koEngine.convoyInterval).." minutes! \n  A convoy has already been sent "..timeSinceMin.." minutes ago!\n_______________________________________________________________________________________________________", 15)
			return
		end
	end
	
	-- check if the objective is already full
	local totalUnitsInZone = 0
	
	-- count units in objective
	local unitsInZone = mist.getUnitsInZones(koEngine.zoneUnitData[category][zone][coalition]['units'], { zone }, 'cylinder')
	if unitsInZone then
		totalUnitsInZone = #unitsInZone
		--koEngine.debugText("there are "..#unitsInZone.." units in zone ".. zone)
	end
	
	-- count units on the way to the objective
	for i, convoy in pairs(MissionData.properties.spawnedConvoys) do
		if convoy.targetZone == zone and convoy.coalition == objectiveTable.coa then
			totalUnitsInZone = totalUnitsInZone + #convoy.units
		end
	end
	
	--koEngine.debugText("there are currently "..totalUnitsInZone.." units in or on the way to the objective")
	 
	-- if they are too many - no convoy
	if totalUnitsInZone > koEngine.convoyMaxUnits  and convoyType ~= "offensive"  then
		koEngine.outTextForGroup(groupID,"_______________________________________________________________________________________________________\n\n  Objective "..zone.." is already strong enough\n\n  You cannot send any more convoys to this location.\n_______________________________________________________________________________________________________", 15)
		return
	end
	
	
	-- TODO convoy request
	
	-----------------------------------------------
	--[[ convoy template 
	-- 
	-- ['Convoy'] = {
		['visible'] = false,
		['country'] = 2,
		['hidden'] = false,
		['units'] = {
			[1] = {
				['type'] = 'M-1 Abrams',
				['name'] = 'Russian Factory blue Convoy #001/1',
				['playerCanDrive'] = false,
				['skill'] = 'Excellent',
			},
		},
		['coalition'] = 'blue',
		['name'] = 'Russian Factory blue Convoy #001',
		['category'] = 2,
		['task'] = {
		},
	}--]]
	
	-- spawn convoy!
	local convoyGroup = mist.utils.deepCopy(MissionData.properties.convoys[coalition][zone])
	local convoyIdx = koEngine.getHighestGroupIndexForPlayer(playerName)+1
	if convoyType == "groundcrew" 	then convoyGroup.name = playerNameFix.."s Groundcrew Convoy #"..convoyIdx
	elseif convoyType== "offensive" then convoyGroup.name = playerNameFix.."s Offensive Convoy #"..convoyIdx
									else convoyGroup.name = playerNameFix.."s Convoy #"..convoyIdx end
	
	convoyGroup.targetZone = zone
	convoyGroup.convoyType = convoyType
	convoyGroup.playerName = playerNameFix
	convoyGroup.playerUCID = koEngine.getPlayerUCID(playerName)
	convoyGroup.playerCategory = unitCategoryTable[playerUnit:getDesc().category]
	convoyGroup.playerType = "Convoy"
	convoyGroup.visible = false
	convoyGroup.hidden = false
	convoyGroup.category = 2
	convoyGroup.coalition = coalition
	convoyGroup.task = {}
	convoyGroup.groupId = nil	-- let mist reassign the groupID to prevent trouble
	
	local unitTypes = koEngine.convoyTypes[coalition][convoyType]
	koEngine.debugText("unitTypes = "..koEngine.TableSerialization(unitTypes))
	koEngine.debugText("convoyGroup.units = "..koEngine.TableSerialization(convoyGroup.units))
	for i, unitType in ipairs(unitTypes) do
		--convoyGroup.units[i] = convoyGroup.units[i] or {}
		local unit = convoyGroup.units[i]
		koEngine.debugText("preparing unit #"..i)
		
		if not unit then
			koEngine.debugText("one more unit than intended, calculating pos by adding vectors")
			convoyGroup.units[i] = {}
			unit = convoyGroup.units[i]
			local lastUnit = convoyGroup.units[i-1]
			local prevLastUnit = convoyGroup.units[i-2]
			-- calculate position from last unit
			local distanceVector = {
				x = lastUnit.x - prevLastUnit.x,
				y = lastUnit.y - prevLastUnit.y,
			}
			
			unit.x = lastUnit.x + distanceVector.x
			unit.y = lastUnit.y + distanceVector.y
			unit.heading = lastUnit.heading
		end
		 
		unit.unitId = nil		-- let mist reassign
		unit.playerCanDrive = false
		unit.skill = "Excellent"
		unit.type = koEngine.convoyTypes[coalition][convoyType][i]
		--koEngine.debugText("inserting ["..i.."] = '"..unit.type.."' into convoy")		
		if convoyType == "groundcrew" 	then unit.name = playerNameFix.."s Convoy #"..convoyIdx.." Groundcrew "..unit.type.." #"..i
										else unit.name = playerNameFix.."s Convoy #"..convoyIdx.." "..unit.type.." #"..i end
	
	end
	
	--koEngine.debugText("convoyGroup = "..koEngine.TableSerialization(convoyGroup,0))
	
	local mistGroup = mist.dynAdd(mist.utils.deepCopy(convoyGroup))		-- use a deepcopy for respawn, or the table will be sanitized an unable to use dynAdd() again!
					
	if not mistGroup then
		koEngine.debugText("FATAL ERROR: convoy could not be spawned by mist.dynAdd()!")
	else
		koEngine.debugText("Convoy '"..convoyGroup.name.."' to '"..zone.."' was spawned")
		
		MissionData.properties.numSpawnedConvoys[coalition] = MissionData.properties.numSpawnedConvoys[coalition]+1
		table.insert(MissionData.properties.spawnedConvoys, convoyGroup)
		
		-- insert into zoneUnitData for zone-coalition checking
		local category = koEngine.getObjectiveCategory(zone)
		
		table.insert(koEngine.zoneUnitData[category][zone][coalition].groups, convoyGroup.name)
						
		for i, unit in pairs(Group.getByName(convoyGroup.name):getUnits()) do
			table.insert(koEngine.zoneUnitData[category][zone][coalition].units, unit:getName())
		end
		
		-- deduct the points the convoy costs: 
		koScoreBoard.deductCashFromPlayer(playerName, koEngine.convoyCost[convoyType])
		MissionData[category][zone]['last'..coalition..'ConvoySentTime'] = timer.getTime()
		
		koEngine.outTextForCoalition(coaNameTable[coalition],"_______________________________________________________________________________________________________\n\n  "..playerName.." has requested a "..convoyType.." convoy towards "..zone.."\n  expected ETA is about 20 minutes.\n\n  You have "..format_num(koScoreBoard.getCashcountForPlayer(playerName)).."$ left\n_______________________________________________________________________________________________________", 15)
		
		local newScore = {
				achievment = convoyType.."_convoy_deployed",
				playerName = playerNameFix,
				playerUCID = koEngine.getPlayerUCID(playerName),
				unitCategory = unitCategoryTable[playerUnit:getDesc().category],
				unitType = playerUnit:getTypeName(),
				unitName = playerUnit:getName(),
				side = coalitionTable[playerUnit:getCoalition()],
				targetName = zone,
				targetType = category,
				targetSide = coalitionTable[playerUnit:getCoalition()],
				timer = timer.getTime(),
			}
		koScoreBoard.insertScoreForPlayer(playerName, newScore)
	end
end

function koEngine.getHighestGroupIndexForPlayer(playerName)
	playerName = koEngine.getPlayerNameFix(playerName)
	-- find the highest index of sams that the player already spawned. 
	local numSams = 1
	-- check dropped sams
	for i, sam in pairs(MissionData.properties.droppedSAMs) do
		if sam.playerName == playerName then
			local samIndex = sam.groupName:find("#") or -2
			local samDigit = tonumber(sam.groupName:sub(samIndex+1, -1))
			if samDigit > numSams then
				numSams = samDigit
			end
		end
	end
	
	-- check convoys
	for i, convoy in pairs(MissionData.properties.spawnedConvoys) do
		if convoy.playerName == playerName then
			local samIndex = convoy.name:find("#") or -2
			local samDigit = tonumber(convoy.name:sub(samIndex+1, -1))
			if samDigit > numSams then
				numSams = samDigit
			end
		end
	end
	
	-- check objective groups
	for categoryName, categoryTable in pairs(MissionData) do
		if type(categoryTable) == "table" and categoryName ~= "properties" then
			for objectiveName, objectiveTable in pairs(categoryTable) do
				for groupName, groupTable in pairs (objectiveTable.groups) do
					if groupTable.playerName == playerName then
						--koEngine.debugText("checking "..groupName)
						local samIndex = groupName:find("#") or -2
						local samDigit = tonumber(groupName:sub(samIndex+1, -1))
						if samDigit and samDigit > numSams then
							numSams = samDigit
						end
					end
				end
			end
		end
	end
	
	koEngine.debugText("ctld.getHighestGroupIndexForPlayer("..playerName.."): numSams = "..numSams)
	return numSams
end

-- called via radio command, thats why groupID is supplied
function koEngine.reorderGroundCrew(groupID)
	koEngine.debugText("koEngine.reorderGroundCrew("..groupID..")")
	
	local playerUnit = koEngine.PlayerUnitList[tostring(groupID)].unit
	local zone = koEngine.isUnitInObjectiveZone(playerUnit)
	local coalition = coalitionTable[playerUnit:getCoalition()]
	if not zone or not zone:find("FARP") then
		koEngine.outTextForGroup(groupID, "Ground Crew can only be reordered at FARPs!\n In order to use this command, you need to be inside the FARP-Zone!")
		return
	else
		koEngine.debugText(" - player is in Zone "..zone)
	end
	
	
	
	local objectiveTable = koEngine.getObjectiveByName(zone)
	local zoneDetails = trigger.misc.getZone(zone) -- returns: { point, radius }
	local zoneCenter = zoneDetails.point
	zoneCenter.y = land.getHeight({ x = zoneCenter.x, y = zoneCenter.z })
	
	local helperZone = zone
	local formation = 'vee'
	
	local radius
	
	-- look for triggerzone named "'FARP Name' Groundcrew 'red/blue'"
	local gcHelperzoneName = zone.." Groundcrew "..coalition
	local convHelperzoneName = zone.." Convoy "..objectiveTable.activeConvoyZone
	
	helperZone = trigger.misc.getZone(gcHelperzoneName) or trigger.misc.getZone(convHelperzoneName) or helperZone
	
	if helperZone == zone then -- no additonal helper-triggerzone, calculate radmonly within zone and 100m to keep groundcrew near
		koEngine.debugText("FATAL WARNING: no helperZone at "..zone)
			
		zoneCenter = { x=0, y=0, z=0 } -- reset zonecenter, new center is between red farps
		local numFarps = 0
		for i, airbase in pairs(world.getAirbases()) do
			if  airbase:getDesc().category == Airbase.Category.HELIPAD and airbase:getCoalition() == group:getCoalition() then
				if airbase:getName():find(zone) then
					zoneCenter.x = zoneCenter.x +  airbase:getPoint().x
					zoneCenter.z = zoneCenter.z +  airbase:getPoint().z
					numFarps = numFarps + 1 
				end
			end
		end	
		if numFarps == 0 then
			koEngine.debugText("not at farp!")
			zoneCenter = zoneDetails.point
		else
			zoneCenter.x = zoneCenter.x / numFarps
			zoneCenter.z = zoneCenter.z / numFarps
			zoneCenter.y = land.getHeight({ x = zoneCenter.x, y = zoneCenter.z })
		end
		
		radius = 100
	else
		koEngine.debugText("helperZone found")
		
		zoneCenter = {
			x = helperZone.point.x,
			z = helperZone.point.z,
			y = land.getHeight({ x = helperZone.point.x, y = helperZone.point.z }),
		}
		radius = helperZone.radius
	end
	
	koEngine.debugText("radius is "..radius.."m")
	
	-- loop through all groundCrew units at the objective
	for groupName, spawnTable in pairs(objectiveTable.groups) do
	
		if groupName:find("Groundcrew") then
			local group = Group.getByName(groupName)
			koEngine.debugText("reordering "..groupName)
			
			-- get random point within that zone
			local destination = koEngine.getRandomPointInRadius(radius)
			destination.x = destination.x + zoneCenter.x
			destination.z = destination.z + zoneCenter.z
			destination.y = land.getHeight({ x = destination.x, y = destination.z })
			
			koEngine.debugText("destination = "..koEngine.TableSerialization(destination))
		
			local path = {}
			
			table.insert(path, mist.ground.buildWP(group:getUnit(1):getPoint(), 'Off Road', 50))
			table.insert(path, mist.ground.buildWP(destination, formation, 50))
			
			local mission = {
				id = 'Mission',
				params = {
					route = {
						points = path
					},
			    },
			}
			
			local _controller = group:getController();
			_controller:resetTask()	-- reset the old path, just in case
			
			-- delayed 2 second to work around bug
			timer.scheduleFunction(function(_arg)
			    local group = (_arg[1])
			
			    if group ~= nil then
			    	koEngine.debugText("activating delayed path for "..group:getName())
			        local _controller = group:getController();
			        Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO)
			        Controller.setOption(_controller, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)
			        _controller:setTask(_arg[2])
			    end
			end
			    , {group, mission}, timer.getTime() + 5)
		end
	end
end

function koEngine.disperseConvoyInZone(group, zone) 
	koEngine.debugText("koEngine.disperseConvoyInZone("..tostring(group:getName())..", "..zone..")")
	local objectiveTable = koEngine.getObjectiveByName(zone)
	local zoneDetails = trigger.misc.getZone(zone) -- returns: { point, radius }
	local zoneCenter = zoneDetails.point
	zoneCenter.y = land.getHeight({ x = zoneCenter.x, y = zoneCenter.z })
	
	local helperZone = zone
	--local formation = 'On Road'
	local formation = 'vee'
	
	--koEngine.debugText("zoneCenter = "..koEngine.TableSerialization(zoneCenter))
	
		
	local radius
	-- GROUNDCREW
	--if group:getName():find("Groundcrew") then
	--koEngine.debugText("dispersing convoy, looking for zone in category: "..tostring(koEngine.getObjectiveCategory(zone)))
	
	--formation = 'On Road' 
	-- look for triggerzone named "'FARP Name' Groundcrew 'red/blue'"
	local gcHelperzoneName = zone.." Groundcrew "..coalitionTable[group:getCoalition()]
	local convHelperzoneName = zone.." Convoy "..objectiveTable.activeConvoyZone
	--koEngine.debugText("gcHelperzoneName = "..gcHelperzoneName)
	--koEngine.debugText("convHelperzoneName = "..convHelperzoneName)
	
	if group:getName():find("Groundcrew") and zone:find("FARP") then
		helperZone = trigger.misc.getZone(gcHelperzoneName) or trigger.misc.getZone(convHelperzoneName) or helperZone
	else
		helperZone = trigger.misc.getZone(convHelperzoneName) or helperZone
	end
	
	
	if helperZone == zone then -- no additonal helper-triggerzone, calculate radmonly within zone and 100m to keep groundcrew near
		koEngine.debugText("No helperZone at "..zone.." disperse cancelled")
		
		return
			
		--[[zoneCenter = { x=0, y=0, z=0 } -- reset zonecenter, new center is between red farps
		local numFarps = 0
		for i, airbase in pairs(world.getAirbases()) do
			if  airbase:getDesc().category == Airbase.Category.HELIPAD and airbase:getCoalition() == group:getCoalition() then
				if airbase:getName():find(zone) then
					zoneCenter.x = zoneCenter.x +  airbase:getPoint().x
					zoneCenter.z = zoneCenter.z +  airbase:getPoint().z
					numFarps = numFarps + 1 
				end
			end
		end	
		if numFarps == 0 then
			koEngine.debugText("not at farp!")
			zoneCenter = zoneDetails.point
		else
			zoneCenter.x = zoneCenter.x / numFarps
			zoneCenter.z = zoneCenter.z / numFarps
			zoneCenter.y = land.getHeight({ x = zoneCenter.x, y = zoneCenter.z })
		end
		
		radius = 100--]]
	else
		koEngine.debugText("helperZone found")
		
		zoneCenter = {
			x = helperZone.point.x,
			z = helperZone.point.z,
			y = land.getHeight({ x = helperZone.point.x, y = helperZone.point.z }),
		}
		radius = helperZone.radius
	end
	
	--koEngine.debugText("zoneCenter = "..koEngine.TableSerialization(zoneCenter))
	
	-- TODO Breakup Groundcrew!
	local spawnGroup = objectiveTable.groups[group:getName()]
	if spawnGroup and #spawnGroup.units > 1 then
		koEngine.debugText("spawnGroup with multiple units detected, breaking up Group")
		
		for i, unit in pairs(spawnGroup.units) do
			local newSpawnGroup = mist.utils.deepCopy(spawnGroup)
			local type = ctld.groundCrewUnitTypes[unit.type] 
			local groupIndex = koEngine.getHighestGroupIndexForPlayer(spawnGroup.playerName)+1
			if type then
				koEngine.debugText("preparing Groundcrew "..type)
				newSpawnGroup.name = spawnGroup.playerName.."s Groundcrew "..type.."#"..groupIndex
				unit.name = spawnGroup.playerName.."s Groundcrew "..type.."U#"..groupIndex
			else
				--koEngine.debugText("not groundcrew")
				newSpawnGroup.name = spawnGroup.playerName.."s Objective Defense #"..groupIndex
				unit.name = spawnGroup.playerName.."s Objective Defense U#"..groupIndex
			end
			
			newSpawnGroup.units = {}
			table.insert(newSpawnGroup.units, unit)
			
			local mistGroup = mist.dynAdd(mist.utils.deepCopy(newSpawnGroup))
			local newGroup = Group.getByName(newSpawnGroup.name)
				
			 -- check it up!
			if not mistGroup then
				koEngine.debugText("\n\nFATAL ERROR!\t\t\tsplitting of "..spawnGroup.name.." failed:\n"..koEngine.TableSerialization(newSpawnGroup))
				return
			else
				koEngine.debugText("'"..newSpawnGroup.name.."' was spawned (split group successfull), adding objectivetable and setting path")
				objectiveTable.groups[newSpawnGroup.name] = newSpawnGroup
				
				local destination = koEngine.getRandomPointInRadius(radius)
				
				-- distribute convoys over multiple convoy-zones
				if group:getName():find("Convoy") and not group:getName():find("Groundcrew") then
					local convHelperzoneName = zone.." Convoy "..objectiveTable.activeConvoyZone
					helperZone = trigger.misc.getZone(convHelperzoneName)
					
					if helperZone then
						zoneCenter = {
							x = helperZone.point.x,
							z = helperZone.point.z,
							y = land.getHeight({ x = helperZone.point.x, y = helperZone.point.z }),
						}
						radius = helperZone.radius
					end
					
					objectiveTable.activeConvoyZone = objectiveTable.activeConvoyZone + 1
					if objectiveTable.activeConvoyZone > 4 then objectiveTable.activeConvoyZone = 1 end
				end
			
				destination.x = destination.x + zoneCenter.x
				destination.z = destination.z + zoneCenter.z
				destination.y = land.getHeight({ x = destination.x, y = destination.z })
			
				
				local path = {}
				table.insert(path, mist.ground.buildWP(newGroup:getUnit(1):getPoint(), 'On Road', 50))
				table.insert(path, mist.ground.buildWP(destination, formation, 50))
				
				local mission = {
					id = 'Mission',
					params = {
						route = {
							points = path
						},
				    },
				}
				
				local _controller = newGroup:getController();
				_controller:resetTask()	-- reset the old path, just in case
				
				-- delayed 5 second to work around bug
				timer.scheduleFunction(function(_arg)
				    local group = (_arg[1])
				    if group ~= nil then
				    	koEngine.debugText("activating delayed path for "..group:getName())
				        local _controller = group:getController();
				        Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO)
				        Controller.setOption(_controller, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)
				        _controller:setTask(_arg[2])
				    end
				end , {newGroup, mission}, timer.getTime() + 5)
				
				
				local coalition = coalitionTable[group:getCoalition()]
				
				table.insert(koEngine.zoneUnitData[koEngine.getObjectiveCategory(zone)][zone][coalition].groups, mistGroup.name)
				
				for i, unit in pairs(newGroup:getUnits()) do
					table.insert(koEngine.zoneUnitData[koEngine.getObjectiveCategory(zone)][zone][coalition].units, unit:getName())
				end
			end
		end
		
		koEngine.debugText("cleaning groupTable from Convoy")
		koEngine.debugText("- groupName = '"..tostring(group:getName()).."'")
		objectiveTable.groups[group:getName()] = nil
		group:destroy()
		
		koEngine.debugText("finsihed") 
		
		return
	end
	
	-- offensive convoy
	--[[elseelse
		local helperzoneName = zone.." Groundcrew "..coalitionTable[group:getCoalition()]
		
		--formation = 'On Road'
		koEngine.debugText("convHelperzoneName = "..helperzoneName)
		helperZone = trigger.misc.getZone(helperzoneName) or trigger.misc.getZone(helperzoneName)
		
		if not helperZone then
			radius = zoneDetails.radius*0.6
		else
			koEngine.debugText("helperzone found!")
		
			zoneCenter = {
				x = helperZone.point.x,
				z = helperZone.point.z,
				y = land.getHeight({ x = helperZone.point.x, y = helperZone.point.z }),
			}
			radius = helperZone.radius
		end
	
		-- normal convoy, check helperzone
		local gcHelperzoneName = zone.." Convoy "..objectiveTable.activeConvoyZone
		koEngine.debugText("gcHelperzoneName = "..gcHelperzoneName)
		helperZone = trigger.misc.getZone(gcHelperzoneName)
		
		--formation = 'On Road'
		
		if not helperZone then
			radius = zoneDetails.radius*0.6
		else
			koEngine.debugText("helperzone found!")
		
			zoneCenter = {
				x = helperZone.point.x,
				z = helperZone.point.z,
				y = land.getHeight({ x = helperZone.point.x, y = helperZone.point.z }),
			}
			radius = helperZone.radius
		end
	end--]]
	
	
	
	koEngine.debugText("radius is "..radius.."m")
	
	-- get random point within that zone
	local destination = koEngine.getRandomPointInRadius(radius)
	destination.x = destination.x + zoneCenter.x
	destination.z = destination.z + zoneCenter.z
	destination.y = land.getHeight({ x = destination.x, y = destination.z })
	
	koEngine.debugText("destination = "..koEngine.TableSerialization(destination))

	local path = {}
	
	table.insert(path, mist.ground.buildWP(group:getUnit(1):getPoint(), 'Off Road', 50))
	table.insert(path, mist.ground.buildWP(destination, formation, 50))
	
	local mission = {
		id = 'Mission',
		params = {
			route = {
				points = path
			},
	    },
	}
	
	local _controller = group:getController();
	_controller:resetTask()	-- reset the old path, just in case
	
	-- delayed 2 second to work around bug
	timer.scheduleFunction(function(_arg)
	    local group = (_arg[1])
	
	    if group ~= nil then
	    	koEngine.debugText("activating delayed path for "..group:getName())
	        local _controller = group:getController();
	        Controller.setOption(_controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO)
	        Controller.setOption(_controller, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)
	        _controller:setTask(_arg[2])
	    end
	end
	    , {group, mission}, timer.getTime() + 5)
end

 function koEngine.removeCrate(crateName)
 	koEngine.debugText("koEngine.removeCrate('"..crateName.."')")
 	
 	for i, crate in pairs(MissionData.properties.droppedCrates) do
 		if crate.name == crateName then
 			koEngine.debugText("- crate "..crateName.." was removed from the cratelist")
 			table.remove(MissionData.properties.droppedCrates,i)
 			return
 		end
 	end
 end
 
-- calculate random point within zone
-- random a and b. If b < a, swap them. Your point is (b*R*cos(2*pi*a/b), b*R*sin(2*pi*a/b)).
 function koEngine.getRandomPointInRadius(radius) 
	local a = math.random()
	local b = math.random()
	if b < a then 
		local c = a
		a = b
		b = c
	end
	return { x = b*(radius)*math.cos(2*math.pi*a/b), y = 0, z = b*(radius)*math.sin(2*math.pi*a/b)}
 end


----------------------------------------------------------------------------------------------------------
-- 									Runtime
----------------------------------------------------------------------------------------------------------

koEngine.debugText("\n-----------------------\nstarting koEngine!\n-----------------------")


----------------------------------------------
-- koEngine.loadMissionData()
-- 
-- check if theres a savegame available
----------------------------------------------
function koEngine.loadMissionData()
	-- load dynamic mission data:
	koEngine.debugText("attempting to load savegame at "..koEngine.savegameFileName)
	local DataLoader = loadfile(koEngine.savegameFileName)
	if DataLoader ~= nil then		-- File open?
		koEngine.debugText("Loading from '"..koEngine.savegameFileName.."' successful\nRunning Mission from Saved-File, creating backup!")
		
		MissionData = DataLoader()
		
		local backupFileName = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\Savegame Backup\\ko_Savegame_Backup_"..koEngine.sessionID..".lua"
		local backupFile = assert(io.open(backupFileName, "w"))
		backupFile:write(koEngine.TableSerialization(MissionData))
		backupFile:flush()
		backupFile:close()
		backupFile = nil
	else
		koEngine.debugText("Dynamic Mission Data not found, Starting a new Game")
	end
end


----------------------------------------------
-- koEngine.collectUnitDataFromME()
-- 
-- retrieve all groups and units related to Mission-Zones from the Mission Editor and save it into koEngine.zoneUnitData
----------------------------------------------
function koEngine.collectUnitDataFromME()
	koEngine.debugText("populating koEngine.zoneUnitData")
	for categoryName, categoryTable in pairs(MissionData) do
		if type(categoryTable)=="table" and categoryName ~= "properties" then
			for objectiveName, objectiveTable in pairs(categoryTable) do
				koEngine.zoneUnitData[objectiveName] = {}
								
				-- get units from ME and loop them
				for unitName,unitTable in pairs(mist.DBs.MEunitsByName) do
					-- check if shortname matches
					if string.sub(unitTable.groupName,1,string.len(objectiveName.."_"))==objectiveName.."_" then
						-- "Vehicle" no Client
						if unitTable.category=='vehicle' and unitTable.skill ~= "Client" then
							if not koEngine.zoneUnitData[objectiveName][unitTable.coalition] then
								koEngine.zoneUnitData[objectiveName][unitTable.coalition] = {}								
								koEngine.zoneUnitData[objectiveName][unitTable.coalition]['units'] = {}
								koEngine.zoneUnitData[objectiveName][unitTable.coalition]['groups'] = {}
							end
							
							table.insert(koEngine.zoneUnitData[objectiveName][unitTable.coalition]['units'],unitName)
							local gTest = 0
							for i,v in ipairs(koEngine.zoneUnitData[objectiveName][unitTable.coalition]['groups']) do
								if unitTable.groupName == v then
									gTest=1
								end
							end
							if gTest==0 then
								table.insert(koEngine.zoneUnitData[objectiveName][unitTable.coalition]['groups'],unitTable.groupName)
							end
						end
					end
				end
			end
		end
	end
	koEngine.debugText("END populating units table")
end


----------------------------------------------
-- koEngine.updateSlotIDs()
-- 
-- update Slot IDs for slot blocking
-- gets the slotIDs from ME and saves them in the SaveGame file
----------------------------------------------
function koEngine.updateSlotIDs()
	koEngine.debugText("koEngine.updateSlotIDs()")
	for categoryName, categoryTable in pairs(MissionData) do
		if type(categoryTable)=="table" and categoryName ~= "properties" then
			for objectiveName, objectiveTable in pairs(categoryTable) do
				-- get units from ME and loop them
				MissionData[categoryName][objectiveName]['slotIDs'] = {}
				MissionData[categoryName][objectiveName]['slotIDTypes'] = nil
								
				for unitName,unitTable in pairs(mist.DBs.MEunitsByName) do
					-- groups need to have the objective name they belong to in front of the name!
					if string.sub(unitTable.groupName,1,string.len(objectiveName))==objectiveName then
						if unitTable.skill == "Client" then
							MissionData[categoryName][objectiveName]['slotIDs'][tostring(unitTable.unitId)] = {
								name = unitTable.unitName,
								type = unitTable.type,
							}
						end
					end
				end
			end
		end
	end
	koEngine.debugText("END populating units table")
end


function koEngine.spawnObjectives()
	koEngine.debugText("koEngine.spawnObjectives()")

	-- initialize CTLD aaSystemLimit and synchronize them to the amount of Antennas	
	ctld.aaSystemLimit = { [1] = 0,	[2] = 0, }
	
	for category, categoryTable in pairs(MissionData) do 
		-- loop through all OBJECTIVES
		if type(categoryTable) == "table" and category ~= "properties" then
			koEngine.debugText("\tspawning "..category)
			
			koEngine.zoneUnitData[category] = {}
			for objective, objectiveTable in pairs(categoryTable) do
				koEngine.debugText("\t\tspawning units in "..objective)	
				
				koEngine.zoneUnitData[category][objective] = {}
				objectiveTable.underAttack = false -- cant be under attack at mission start
				objectiveTable.lastredConvoySentTime = nil -- no convoy sent yet after restart
				objectiveTable.lastblueConvoySentTime = nil -- no convoy sent yet after restart
				objectiveTable.activeConvoyZone = 0
				objectiveTable.groundCrew = { red={}, blue={} }
				
				--[[if not objectiveTable.posX then
					koEngine.debugText("adding position to objective "..objective)
					local objectivePosition = trigger.misc.getZone(objective).point
					objectiveTable.posX = objectivePosition.x
					objectiveTable.posY = objectivePosition.z
				end--]]
				 
				--populate pickupZones according to coalition control.
				if category == 'Aerodrome' or category == 'FARP' or category == "Bunker" or objective == "Inguri-Dam Fortification" then
					if objectiveTable.coa == 'red' then
						table.insert(ctld.pickupZones,{ objective, 'trigger.smokeColor.'..objectiveTable.coa, koEngine.troopPickupLimit, 1, 1 })
					elseif objectiveTable.coa == 'blue' then
						table.insert(ctld.pickupZones,{ objective, 'trigger.smokeColor.'..objectiveTable.coa, koEngine.troopPickupLimit, 1, 2 })
					end
				elseif category == 'Communication' and objectiveTable.coa ~= 'neutral' and objectiveTable.coa ~= 'contested' then
					koEngine.debugText("\t\t\t - increasing CTLD aaSystemLimit for "..objectiveTable.coa)
					ctld.aaSystemLimit[coaNameTable[objectiveTable.coa]] = ctld.aaSystemLimit[coaNameTable[objectiveTable.coa]] + 1
				end
				
				-- keep track of all dropzones 		
				table.insert(koEngine.dropZoneTable, objective)
				
				-- create flag-funcs and prepare zoneUnitData!
				local coalitionTable = { [1]="red", [2]="blue", }
				for i, coalition in pairs(coalitionTable) do
					if not koEngine.zoneUnitData[category][objective][coalition] then
						koEngine.zoneUnitData[category][objective][coalition] = {}
						koEngine.zoneUnitData[category][objective][coalition].groups = {}
						koEngine.zoneUnitData[category][objective][coalition].units = {}
					end
				end
				
				-- reset the groundCrew before we respawn everything, if theres groundCrew, it will be set in the loop below
				objectiveTable.groundCrew = { red={}, blue={} }
				objectiveTable.groundUnits = nil -- can be removed later
				
				-- go through the groups and spawn them
				for groupName, groupSpawnTable in pairs(objectiveTable.groups) do
					koEngine.debugText("\t\t\tspawning '"..groupName.."'")
					
					if #groupSpawnTable.units == 0 then
						objectiveTable.groups[groupName] = nil
					else
						-- delete the group and unitIDs first!
						groupSpawnTable.groupId = nil
						for i, unit in pairs(groupSpawnTable.units) do	
							unit.unitId = nil	
							unit.playerCanDrive = false
						end
						
						local disperseAfterSpawn = false 
						if string.find(groupSpawnTable.name, "Convoy") then --and groupSpawnTable.route then
							--koEngine.debugText("found convoy stuck on original route, dispersing it")
							disperseAfterSpawn = true
							objectiveTable.activeConvoyZone = objectiveTable.activeConvoyZone + 1
							if objectiveTable.activeConvoyZone > 4 then objectiveTable.activeConvoyZone = 1 end
							groupSpawnTable.route = nil
						end
						
						-- spawn it!
						local mistGroup = mist.dynAdd(mist.utils.deepCopy(groupSpawnTable))
						
						 -- check it up!
						if not mistGroup then
							koEngine.debugText("FATAL ERROR!\t\t\tspawn of "..groupName.." failed:\n"..koEngine.TableSerialization(groupSpawnTable))
						else
							
							--activate by moving and so we can set ROE and Alarm state, from CTLD
							--[[local group = Group.getByName(mistGroup.name)
							local _dest = group:getUnit(1):getPoint()
						    _dest = { x = _dest.x + 0.5, _y = _dest.y + 0.5, z = _dest.z + 0.5 }
						    ctld.orderGroupToMoveToPoint(group:getUnit(1), _dest)--]]
	    				
	    					-- save coalition in groupspawntable
							local group = Group.getByName(groupName)
							local coalition = coalitionTable[group:getCoalition()]
							groupSpawnTable.coalition = coalition
							
							table.insert(koEngine.zoneUnitData[category][objective][coalition].groups, groupSpawnTable.name)
							
							--koEngine.debugText("checking if "..group:getName().." is groundcrew")
							for i, unit in pairs(group:getUnits()) do
								table.insert(koEngine.zoneUnitData[category][objective][coalition].units, unit:getName())
								
								-- TODO Groundcrew spawnObjectives
								local groundCrewType = ctld.groundCrewUnitTypes[unit:getTypeName()]
								 
								if groundCrewType then
									koEngine.debugText("\t\t\t\n unit "..unit:getTypeName().." is Groundcrew!")
									disperseAfterSpawn = true	-- make sure groundcrew goes to it's optimium location on the pad
									objectiveTable.groundCrew[coalitionTable[Group.getByName(groupName):getCoalition()]]["has"..groundCrewType] = true
									groupSpawnTable.isGroundCrew = groundCrewType
								end
							end 
							
	
							local aaTemplate = ctld.getAATemplate(groupSpawnTable.units[1].type) 
							if aaTemplate then
								koEngine.debugText("\t\t\t - found repairable aaTemplate, telling ctld")
								ctld.completeAASystems[group:getName()] = ctld.getAASystemDetails(group, aaTemplate)
							end
							
						    timer.scheduleFunction(function(group)
						        if group then
						            local controller = group:getController();
						            Controller.setOption(controller, AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO)
						            Controller.setOption(controller, AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE)
						        end
						    end, group, timer.getTime() + 2)
							
							
							if disperseAfterSpawn then
								-- schedule disperseConvoyInZone for later to work around a bug
								timer.scheduleFunction(function(_args)
							        koEngine.disperseConvoyInZone(_args[1], _args[2])
							    end, { group, objective }, timer.getTime() + 5)
							end
							
							-- check and enable JTAC
							if groupName:find("JTAC") then
								koEngine.debugText("\t\t\t - we found a JTAC! enabling ...")
		 						ctld.JTACAutoLase(mistGroup.name, 1688)
		 					end
		 					
		 					-- TODO enable EWR Frequency and Callsign
		 					-- check and enable EWR
							if groupName:find("EWR") then
								koEngine.debugText("\t\t\t - we found an EWR! enabling ...")
		 						ctld.addEWRTask(group)
		 					end
						end
					end
				end
			end
		end
	end
	
	koEngine.debugText("Objectives Spawned, ctld.aaSystemLimit = "..koEngine.TableSerialization(ctld.aaSystemLimit))
	--koEngine.log("zoneUnitData: \n"..koEngine.TableSerialization(koEngine.zoneUnitData))	
end

function koEngine.spawnDroppedSams()
	local _status, _result = pcall(function()
		koEngine.debugText("spawning "..#MissionData.properties.droppedSAMs.." dropped SAMS")
	
		if #MissionData.properties.droppedSAMs > 0 then
			koEngine.debugText("we have sams to check")
			-- lets spawn some of those sams
			for i, sam in pairs(MissionData.properties.droppedSAMs) do
				koEngine.debugText("checking "..sam.groupName)
				-- check age of sam: 
				local age = ((MissionData.properties.campaignSecs - sam.time)/60)/60 -- age in hours
				if age >= koEngine.samLifeTime then
					koEngine.debugText("SAMs is older than the limit, deleting it "..sam.groupName)
					MissionData.properties.droppedSAMs[i] = nil
				else
					koEngine.debugText("SAMs age is "..age.." hours, respawning "..sam.groupName)
					
					-- find out what kind of unit to get the AA Template from CTLD
					local unitType = false
					for i, unit in pairs(sam.groupSpawnTable.units) do
						if unit then
							unitType = unit.type
							break
						end
					end
					
					if not unitType then koEngine.debugText("could not find unit type!") end
					
					
					
					-- delte it's from spawntable and let mist assign a new one!
					sam.groupSpawnTable.groupId = nil
					for i, unit in pairs(sam.groupSpawnTable.units) do 
						unit.unitId = nil
						unit.playerCanDrive = false 
					end
					
					local _mistGroup = mist.dynAdd(mist.utils.deepCopy(sam.groupSpawnTable))		-- use a deepcopy for respawn, or the table will be sanitized an unable to use dynAdd() again!
					
					if _mistGroup == false then
						koEngine.debugText("FATAL ERROR: SAM WAS NOT SPAWNED BY mist.dynAdd()!")
					else
						local _spawnedGroup = Group.getByName(_mistGroup.name)
						local _spawnedUnit = false
						for i, unit in pairs(_spawnedGroup:getUnits()) do
							_spawnedUnit = unit
							break
						end
						
						if not _spawnedUnit then
							koEngine.debugText("spawn failed, no unit found")
							return
						end
						
						local _dest = _spawnedUnit:getPoint()
					    _dest = { x = _dest.x + 0.5, _y = _dest.y + 0.5, z = _dest.z + 0.5 }
					
					    ctld.orderGroupToMoveToPoint(_spawnedUnit, _dest)
					    sam.spawnedGroup = _spawnedGroup
					    
					    sam.groupSpawnTable.coalition = coalitionTable[_spawnedGroup:getCoalition()]
					    
					    		    
					    local coa = sam.coalition
					    
					    -- if its not a manpad increase AA Systems!
					    local unitType = _spawnedUnit:getTypeName()
					    if not unitType:find("Igla") and not unitType:find("Stinger") and not unitType:find("EWR") and not unitType:find("JTAC")then
					    	koEngine.debugText(unitType.." is No Manpad, increasing ctld.aaSystemsSpawned")
							ctld.aaSystemsSpawned[coa] = ctld.aaSystemsSpawned[coa] + 1
							
							-- let ctld know whe spawned an AA System (so repairing and rearming works)
							local aaTemplate = ctld.getAATemplate(unitType) -- todo: needs sam.groupSpawnTable.units[1].type
							if aaTemplate then
					    		koEngine.debugText("aaTemplate found: "..koEngine.TableSerialization(aaTemplate))
					    		ctld.completeAASystems[_spawnedGroup:getName()] = ctld.getAASystemDetails(_spawnedGroup, aaTemplate)
					    	else
					    		koEngine.debugText("no aaTemplate found")
					    	end
						end
						
						
						-- check and enable JTAC
						if _mistGroup.name:find("JTAC") then
							koEngine.debugText("we found a JTAC! enabling ...")
	 						ctld.JTACAutoLase(_mistGroup.name, 1688)
	 					end
	 					
	 					-- check and enable JTAC
						if _mistGroup.name:find("EWR") then
							koEngine.debugText("we found an EWR! enabling ...")
	 						ctld.addEWRTask(Group.getByName(_mistGroup.name))
	 					end
					end
				end		
			end
		end
		
		koEngine.debugText("end spawning dropped SAMS")
	
	end)
	
	if (not _status) then
        koEngine.log(string.format("FATAL ERROR: koEngine.spawnDroppedSams() %s", _result))
    end
end

function koEngine.spawnEjectedPilots() 
	MissionData.properties.droppedCrates = MissionData.properties.droppedCrates or {}
	koEngine.debugText("koEngine.spawnEjectedPilots() - spawning "..#MissionData.properties.ejectedPilots.." ejected Pilots")
	
	-- remove me after a while!
	koEngine.debugText("sanitizing ejected Pilots")
	local rawPilots = mist.utils.deepCopy(MissionData.properties.ejectedPilots)
	MissionData.properties.ejectedPilots = {}
	for i, ejectedPilot in pairs(rawPilots) do
		table.insert(MissionData.properties.ejectedPilots, ejectedPilot)
	end
	-- end removeme
	local _status, _result = pcall(function()
		for i, ejectedPilot in pairs(MissionData.properties.ejectedPilots) do
			local age = ((MissionData.properties.campaignSecs - ejectedPilot.spawnTime)/60)/60 -- age in hours
			--koEngine.debugText("- ejected Pilot: "..ejectedPilot.playerName..", age: "..age)
			if age > koEngine.ejectedPilotLifetime then
				koEngine.debugText("  Pilot is older than the limit, deleting "..ejectedPilot.playerName)
				table.remove(MissionData.properties.ejectedPilots, i)
			else
				ejectedPilot.groupId = nil	-- let mist reassign the groupID to prevent trouble
				for _, unit in pairs(ejectedPilot.units) do unit.unitId = nil end
				
				--koEngine.debugText("spawning ejected Pilot: "..koEngine.TableSerialization(ejectedPilot))
				koEngine.debugText("spawning ejected Pilot: "..ejectedPilot.playerName)
								
				local dynGroup = mist.dynAdd(mist.utils.deepCopy(ejectedPilot))
				--koEngine.debugText("dynGroup: "..koEngine.TableSerialization(dynGroup))
				local _spawnedGroup = Group.getByName(dynGroup.name)
	
			    -- Turn off AI
			    trigger.action.setGroupAIOff(_spawnedGroup)
			    csar.addSpecialParametersToGroup(_spawnedGroup)
			    csar.woundedGroups[_spawnedGroup:getName()] = {  side = ejectedPilot.side,  desc = ejectedPilot.desc, player = ejectedPilot.playerName }
			    csar.initSARForPilot(_spawnedGroup, ejectedPilot.playerName)
		    end
		end
	end)
	
	if (not _status) then
		koEngine.log(string.format("FATAL ERROR: koEngine.spawnEjectedPilots(): %s", _result))
        --env.error(string.format("FATAL ERROR: koEngine.spawnEjectedPilots(): %s", _result))
    end
end

function koEngine.spawnDroppedCrates() 
	koEngine.debugText("koEngine.spawnDroppedCrates() - spawning "..#MissionData.properties.droppedCrates.." dropped Crates")
	local _status, _result = pcall(function()
		for i, droppedCrate in pairs(MissionData.properties.droppedCrates) do
			local age = ((MissionData.properties.campaignSecs - droppedCrate.spawnTime)/60)/60 -- age in hours
			koEngine.debugText("- ejected Pilot: "..droppedCrate.playerName..", age: "..age)
			if age > koEngine.crateLifetime then
				koEngine.debugText("  Crate is older than the limit, deleting "..droppedCrate.playerName.."s "..droppedCrate.name)
				MissionData.properties.droppedCrates[i] = nil
			else
				ctld.spawnCrateStatic(droppedCrate.country, nil, droppedCrate.point, droppedCrate.name, droppedCrate.weight,droppedCrate.side, droppedCrate.zone)
		    end
		end
	end)
	
	if (not _status) then
		koEngine.log(string.format("FATAL ERROR: koEngine.spawnDroppedCrates(): %s", _result))
    end
end

function koEngine.spawnConvoys() 
	koEngine.debugText("spawning "..#MissionData.properties.spawnedConvoys.." convoys")
	local _status, _result = pcall(function()
	
		if #MissionData.properties.spawnedConvoys > 0 then
			for i, spawnedConvoy in pairs(MissionData.properties.spawnedConvoys) do
				spawnedConvoy.groupId = nil	-- let mist reassign the groupID to prevent trouble
				for i, unit in pairs(spawnedConvoy.units) do unit.unitId = nil end
				
				--koEngine.debugText("spawning ejected Pilot: "..koEngine.TableSerialization(ejectedPilot))
				koEngine.debugText("spawning convoy: "..spawnedConvoy.name)
								
				local dynGroup = mist.dynAdd(mist.utils.deepCopy(spawnedConvoy))
				--koEngine.debugText("dynGroup: "..koEngine.TableSerialization(dynGroup))
				if not dynGroup then
					koEngine.debugText("FATAL ERROR: could not spawn convoy '"..spawnedConvoy.name.."'")
				else
					local category = koEngine.getObjectiveCategory(spawnedConvoy.targetZone)
					table.insert(koEngine.zoneUnitData[category][spawnedConvoy.targetZone][spawnedConvoy.coalition].groups, spawnedConvoy.name)
									
					for i, unit in pairs(Group.getByName(spawnedConvoy.name):getUnits()) do
						table.insert(koEngine.zoneUnitData[category][spawnedConvoy.targetZone][spawnedConvoy.coalition].units, unit:getName())
					end
				end
			end
		end  
	end)
	
	if (not _status) then
        koEngine.log(string.format("FATAL ERROR: koEngine.spawnConvoys() %s", _result))
    end
end


-----------------------------------------
-- populate helicopters into CTLD table
function koEngine.populateHelisToCTLD()
	koEngine.debugText("populating transport helicopters into CTLD")
	for i, helicopter in pairs(mist.DBs.MEunitsByCat['helicopter']) do
		--koEngine.debugText("adding type: "..helicopter.type)
		if helicopter.type == 'UH-1H' or helicopter.type == 'Mi-8MT' or helicopter.type=='Ka-50' or helicopter.type=='S342L' or helicopter.type=='SA342M' then
			table.insert(ctld.transportPilotNames,helicopter.unitName)
		end
	end
end


-------------------------------------------------------------------------------------------------------------
--											 Callbacks 
-------------------------------------------------------------------------------------------------------------
koTCPSocket.loadBuffer()

koEngine.loadMissionData()
koEngine.spawnObjectives()
koEngine.spawnDroppedSams()
koEngine.spawnEjectedPilots()
koEngine.spawnDroppedCrates() 
koEngine.spawnConvoys() 
koEngine.updateSlotIDs()
koEngine.populateHelisToCTLD()
--koScoreBoard.loadScoreBoardFile() -- obsolete
koScoreBoard.loadSortiesFile()

MissionData.properties.startTimer = timer.getTime()

--koTCPSocket.serverName = MissionData.properties.serverName
--koTCPSocket.txbufRaw = '{"type":"intro","serverName":"'..MissionData.properties.serverName..'"}'
--koTCPSocket.startConnection()

--koEngine.collectUnitDataFromME()
--koEngine.spawnMissionData()

koEngine.debugText("Starting Callbacks\n")

ctld.addCallback(koEngine.ctldCallback)		-- callback whenever someone loads or unloads transport
world.addEventHandler(eventHandler)
world.addEventHandler(koScoreBoard.eventHandler)

mist.scheduleFunction(koEngine.updatePlayersInZones, {}, timer.getTime()+1)
mist.scheduleFunction(koEngine.main, {}, timer.getTime() + 10)
mist.scheduleFunction(koScoreBoard.main, {}, timer.getTime() + koScoreBoard.loopFreq)
mist.scheduleFunction(koEngine.checkMainLoop, {}, timer.getTime() + 11)
mist.scheduleFunction(koEngine.saveGame, {true}, timer.getTime() + 1)
msgSender()
updateResetTime()

-- reset open sories once loaded
koEngine.debugText("checking open sorties")

for ucid, sortie in pairs(koScoreBoard.activeSorties) do
	koEngine.debugText("found active Sortie for player "..sortie.playerName..", closing it")
	koScoreBoard.closeSortie(sortie.playerName, "Mission Restart")
end


koEngine.debugText("\n-----------------------\nkoEngine is running!\n-----------------------")

--[[local strippedConvoys = {}
for coa, convoys in pairs(MissionData.properties.convoys) do
	strippedConvoys[coa] = strippedConvoys[coa] or {}
	
	for objective, convoy in pairs(convoys) do
		strippedConvoys[coa][objective] = {}
		strippedConvoys[coa][objective].country = convoy.country
		strippedConvoys[coa][objective].route = convoy.route
		strippedConvoys[coa][objective].units = {}
		
		for i, unit in pairs(convoy.units) do
			local unit = {
				x = unit.x,
				y = unit.y,
				heading = unit.heading,
			}
			strippedConvoys[coa][objective].units[i] = unit
		end
	end
end

local exportData = "local t = " .. koEngine.TableSerialization(strippedConvoys) .. "return t"	
local exportDir = lfs.writedir() .. "Missions\\The Kaukasus Offensive\\"


--if not koEngine.debugOn then
	--koEngine.outText("The Mission status has been saved!")
--end

local exportFile = assert(io.open(exportDir.."strippedConvoys.lua", "w"))
exportFile:write(exportData)
exportFile:flush()
exportFile:close()
exportFile = nil--]]



