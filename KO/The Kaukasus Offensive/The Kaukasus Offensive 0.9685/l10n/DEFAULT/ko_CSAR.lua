-- CSAR Script for DCS Ciribob - 2015
-- Version 1.8.3 - 17/01/2016
-- DCS 1.94
-- Removed Ejection support for  Huey and mi-8

csar = {}

-- SETTINGS FOR MISSION DESIGNER vvvvvvvvvvvvvvvvvv
csar.csarUnits = {



} -- List of all the MEDEVAC _UNIT NAMES_ (the line where it says "Pilot" in the ME)!

csar.bluemash = {

} -- The unit that serves as MASH for the blue side

csar.redmash = {

} -- The unit that serves as MASH for the red side

csar.disableIfNoEjection = false -- if true disables aircraft even if the pilot doesnt eject

csar.destructionHeight = 150 -- height in meters an aircraft will be destroyed at if the aircraft is disabled

csar.disableCSARAircraft = true -- if set to TRUE then if a CSAR heli crashes or is shot down, it'll have to be rescued by another CSAR Heli!

csar.enableForAI = false -- set to false to disable AI units from being rescued.

csar.enableSlotBlocking = false -- if set to true, you need to put the csarSlotBlockGameGUI.lua
-- in C:/Users/<YOUR USERNAME>/DCS/Scripts for 1.5 or C:/Users/<YOUR USERNAME>/DCS.openalpha/Scripts for 2.0
-- For missions using FLAGS and this script, make sure that all mission value numbers are higher than 1000 to ensure
-- the scripts dont conflict

csar.bluesmokecolor = 3 -- Color of smokemarker for blue side, 0 is green, 1 is red, 2 is white, 3 is orange and 4 is blue
csar.redsmokecolor = 3 -- Color of smokemarker for red side, 0 is green, 1 is red, 2 is white, 3 is orange and 4 is blue

csar.requestdelay = 2 -- Time in seconds before the survivors will request Medevac

csar.coordtype = 4 -- Use Lat/Long DDM (0), Lat/Long DMS (1), MGRS (2), Bullseye imperial (3) or Bullseye metric (4) for coordinates.
csar.coordaccuracy = 1 -- Precision of the reported coordinates, see MIST-docs at http://wiki.hoggit.us/view/GetMGRSString
-- only applies to _non_ bullseye coords

csar.immortalcrew = false -- Set to true to make wounded crew immortal
csar.invisiblecrew = true -- Set to true to make wounded crew insvisible

csar.messageTime = 30 -- Time to show the intial wounded message for in seconds

csar.loadDistance = 60 -- configure distance for pilot to get in helicopter in meters.

csar.allowFARPRescue = true --allows pilot to be rescued by landing at a FARP or Airbase

-- SETTINGS FOR MISSION DESIGNER ^^^^^^^^^^^^^^^^^^^*

-- Sanity checks of mission designer
assert(mist ~= nil, "\n\n** HEY MISSION-DESIGNER! **\n\nMiST has not been loaded!\n\nMake sure MiST 4.0.57 or higher is running\n*before* running this script!\n")

csar.addedTo = {}

csar.downedPilotCounterRed = 0
csar.downedPilotCounterBlue = 0

csar.woundedGroups = {} -- contains the new group of units
csar.inTransitGroups = {} -- contain a table for each SAR with all units he has with the
-- original name of the killed group

csar.smokeMarkers = {} -- tracks smoke markers for groups
csar.heliVisibleMessage = {} -- tracks if the first message has been sent of the heli being visible

csar.heliCloseMessage = {} -- tracks heli close message  ie heli < 500m distance

csar.enemyCloseMessage = {}

csar.max_units = 6 --number of pilots that can be carried

csar.hoverStatus = {} -- tracks status of a helis hover above a downed pilot

csar.playerEjects = {} -- tracks player ejects and stops double huey eject

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

function csar.tableLength(T)

    if T == nil then
        return 0
    end


    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function csar.pilotsOnboard(_heliName)
    local count = 0
    if csar.inTransitGroups[_heliName] then
        for _, _group in pairs(csar.inTransitGroups[_heliName]) do
            count = count + 1
        end
    end
    return count
end

-- Handles all world events
csar.eventHandler = {}
function csar.eventHandler:onEvent(_event)
    local status, err = pcall(function(_event)

        if _event == nil or _event.initiator == nil then
            return false

		-- entered event is handled by koEngine!
        elseif _event.id == 15 then --player entered unit
        	--koEngine.debugText("csar.eventHandler(S_EVENT_BIRTH)")

			-- done in koEngine now
            --if _event.initiator:getName() and (_event.initiator:getTypeName() == "Mi-8MT" or  _event.initiator:getTypeName() == "UH-1H") then
            --    csar.addMedevacMenuItem(_event.initiator)
            --end
			
            -- if its a sar heli, re-add check status script
            --[[for _, _heliName in pairs(csar.csarUnits) do

                if _heliName == _event.initiator:getName() then
                    -- add back the status script
					koEngine.debugText("found heli in csarUnits")
					
                    for _woundedName, _groupInfo in pairs(csar.woundedGroups) do

                        if _groupInfo.side == _event.initiator:getCoalition() then

                            --env.info(string.format("Schedule Respawn %s %s",_heliName,_woundedName))
                            -- queue up script
                            -- Schedule timer to check when to pop smoke
                            koEngine.debugText("CSAR: scheduling checkWoundedGroupStatus()")
                            timer.scheduleFunction(csar.checkWoundedGroupStatus, { _heliName, _woundedName }, timer.getTime() + 5)
                        end
                    end
                end
            end--]]

            return true

        elseif (_event.id == 9) then
            -- Pilot dead

            env.info("Event unit - Pilot Dead")

            local _unit = _event.initiator

            if _unit == nil then
                return -- error!
            end

        --    if (_event.initiator:getTypeName() == "Mi-8MT" or  _event.initiator:getTypeName() == "UH-1H") then
        --        return
        --    end

            --trigger.action.outTextForCoalition(_unit:getCoalition(), "MAYDAY MAYDAY! " .._unit:getTypeName() .. " shot down. No Chute!", 10)

            return

        elseif world.event.S_EVENT_EJECTION == _event.id then

            koEngine.debugText("csar.onEvent(): Ejected")

            local _unit = _event.initiator

            if _unit == nil then
                return -- error!
            end

            --if (_event.initiator:getTypeName() == "Mi-8MT" or  _event.initiator:getTypeName() == "UH-1H") then
            --    return
            --end


            if _unit:getPlayerName() == nil then
                return
            end


			-- check if player ejected inside a zone
            local _zone = koEngine.isUnitInObjectiveZone(_unit)
            --{ inZone = true, name = _zoneName,coalition = _coa};
            if _zone then
            	if coaNameTable[koEngine.getObjectiveByName(_zone).coa] == _unit:getCoalition() then 
	            	koEngine.debugText("player ejected in a friendly zone!")
	            	-- TODO give back live!
	            	
	            	local playerName = _unit:getPlayerName() 
	            	if not playerName then
	            		return
	            	end
	            	
	            	--player landed put back life
					if not MissionData.properties.playerLimit then
						env.info("FATAL ERROR: MissionData not available in CSAR!")
						return
					end
					
					local playerNameFix = koEngine.getPlayerNameFix(playerName)
					if MissionData.properties.playerLimit[playerNameFix] then
						MissionData.properties.playerLimit[playerNameFix] = MissionData.properties.playerLimit[playerNameFix]-1
					--else
						--env.info("FATAL ERROR: could not find playerLimit for "..tostring(playerNameFix))
					end
					
					koEngine.debugText("Ignore ejection, landed at a friendly zone ".._zone..", player "..playerName.." got one life back")
					
					if csar.inTransitGroups[_unit:getName()] then 
						-- player ejected but has rescued pilots on board
						-- since he is over a zone and ejected rescue the other pilots too!
						csar.rescuePilots(_unit)
					end
					
	                return -- probably landed at an airfield
                end
            end
            --end

            --  check to see if the pilot ejected a short period ago
            local _time = csar.playerEjects[ _unit:getPlayerName()]

            if _time ~= nil and timer.getTime() - _time < 5 then
                env.info("Ignore! double ejection")
                csar.playerEjects[ _unit:getPlayerName()] = timer.getTime()
                return
            end


			koEngine.debugText("csar: valid ejection")
			
            csar.playerEjects[ _unit:getPlayerName()] = timer.getTime()

            koEngine.outTextForCoalition(_unit:getCoalition(), "MAYDAY MAYDAY! " .. _unit:getPlayerName() .. " (".._unit:getTypeName()..") is going down. Chute Spotted!", 10)

            -- Generate DESCRIPTION text
            local _text = " "
            if _unit:getPlayerName() ~= nil then
                _text =  "Pilot "..koEngine.getPlayerNameFix(_unit:getPlayerName()).." (".._unit:getTypeName()..")"
            else
                _text = "AI Pilot of ".._unit:getName().." - ".._unit:getTypeName()
            end

            local _unitDetails = { side = _unit:getCoalition(),  desc = _text, player = koEngine.getPlayerNameFix(_unit:getPlayerName()), country = _unit:getCountry(), point = _unit:getPoint(), type = _unit:getTypeName() }

            timer.scheduleFunction(csar.delayedSpawn, _unitDetails, timer.getTime() + 30)

            return true

        elseif world.event.S_EVENT_LAND == _event.id then

            if csar.allowFARPRescue then

                --  env.info("Landing")

                local _unit = _event.initiator

                if _unit == nil then
                    --    env.info("Unit Nil on Landing")
                    return -- error!
                end

                local _place = _event.place
				local zone = koEngine.isUnitInObjectiveZone(_unit)
				
                if not _place and not zone then
                    --  env.info("Landing Place Nil")
                    return -- error!
                end
                
            	--{ inZone = true, name = _zoneName,coalition = _coa};
            
                -- Coalition == 3 seems to be a bug... unless it means contested?!
                if zone or _place:getCoalition() == _unit:getCoalition() or _place:getCoalition() == 0 or _place:getCoalition() == 3 then
                    csar.rescuePilots(_unit)
                    --env.info("Rescued")
                    --   env.info("Rescued by Landing")
                --else
                	--trigger.action.outTextForGroup(csar.getGroupId(_event.initiator), "CSAR: Pilots cannot be rescued at "..(_place:getName()or "this place"), 15)
                    --   env.info("Cant Rescue ")

                    --  env.info(string.format("airfield %d, unit %d",_place:getCoalition(),_unit:getCoalition()))
                end
            end

            return true

        end
    end, _event)
    if (not status) then
        koEngine.log(string.format("CSAR: Error while handling event %s", err),false)
    end
end

function csar.delayedSpawn(_args)
	koEngine.debugText("csar.delayedSpawn")

    local _spawnedGroup = csar.spawnGroup(_args)
    csar.addSpecialParametersToGroup(_spawnedGroup)

    csar.woundedGroups[_spawnedGroup:getName()] = {  side = _args.side,  desc = _args.desc, player = _args.player }

    csar.initSARForPilot(_spawnedGroup,_args.player)

end


function csar.heightDiff(_unit)

    local _point = _unit:getPoint()

    return _point.y - land.getHeight({ x = _point.x, y = _point.z })
end



csar.addSpecialParametersToGroup = function(_spawnedGroup)
		
    -- Immortal code for alexej21
    local _setImmortal = {
        id = 'SetImmortal',
        params = {
            value = true
        }
    }
    -- invisible to AI, Shagrat
    local _setInvisible = {
        id = 'SetInvisible',
        params = {
            value = true
        }
    }

    local _controller = _spawnedGroup:getController()

    if (csar.immortalcrew) then
        Controller.setCommand(_controller, _setImmortal)
    end

    if (csar.invisiblecrew) then
        Controller.setCommand(_controller, _setInvisible)
    end
end

function csar.spawnGroup(_args)
	koEngine.debugText("csar.spawnGroup() _args = "..koEngine.TableSerialization(_args))
	local _id = mist.getNextGroupId()
	local _groupName
	local unitName
	local numEjects = 1
	if MissionData then 
		-- check previous ejected pilots
		for i, ejectedPilot in pairs(MissionData.properties.ejectedPilots) do
			--koEngine.debugText("looking at "..ejectedPilot.name)
			if ejectedPilot.playerName == _args.player then
				local ejectIndex = ejectedPilot.name:find("#") or -2
				koEngine.debugText("ejectIndex = "..ejectIndex)
				local ejectDigit = tonumber(ejectedPilot.name:sub(ejectIndex+1, -1))
				koEngine.debugText("ejectDigit = "..ejectDigit)
				if ejectDigit > numEjects then
					numEjects = ejectDigit
				end
			end
		end
		
		numEjects = numEjects + 1
		
		_groupName = _args.player.." Ejected ".._args.type.." #"..numEjects
		unitName = _args.player.." Ejected U#"..numEjects
		koEngine.debugText("csar.spawnGroup(): MissionData available, groupName = ".._groupName)
	else
		koEngine.debugText("no MissionData available")
		_groupName = _args.player.." Ejected #".._id
		unitName = _args.player.." Ejected U#"..mist.getNextUnitId()
	end
	
	koEngine.debugText("_groupName = ".._groupName)
	
    local _group = {
        ["visible"] = false,
        --["groupId"] =_id,
        ["hidden"] = false,
        ["units"] = {},
        ["name"] = _groupName,
        ["task"] = {},
    }

    if _args.side == 2 then
        _group.units[1] = csar.createUnit(_args.point.x + 50, _args.point.z + 50, 120, "Soldier M4", unitName)
    else
        _group.units[1] = csar.createUnit(_args.point.x + 50, _args.point.z + 50, 120, "Infantry AK", unitName)
    end

    _group.category = Group.Category.GROUND;
    _group.country = _args.country
    _group.playerName = _args.player
    _group.side = _args.side
    _group.desc = _args.desc
    _group.spawnTime = MissionData.properties.campaignSecs
    
    koEngine.debugText("csar.spawnGroup: _group = "..koEngine.TableSerialization(_group))
    
    MissionData.properties.ejectedPilots = MissionData.properties.ejectedPilots or {}
    table.insert(MissionData.properties.ejectedPilots,mist.utils.deepCopy(_group))
    

    local _spawnedGroup = Group.getByName(mist.dynAdd(_group).name)

    -- Turn off AI
    trigger.action.setGroupAIOff(_spawnedGroup)

    return _spawnedGroup
end


function csar.createUnit(_x, _y, _heading, _type, _name)

    --local _id = mist.getNextUnitId();

    --local _name = string.format("Ejected Pilot #%s", _digit)

    local _newUnit = {
        ["y"] = _y,
        ["type"] = _type,
        ["name"] = _name,
        --["unitId"] = _id,
        ["heading"] = _heading,
        ["playerCanDrive"] = false,
        ["skill"] = "Excellent",
        ["x"] = _x,
    }

    return _newUnit
end

function csar.initSARForPilot(_downedGroup,_playerName)
	koEngine.debugText("initSARForPilot ".._playerName)

    local _leader = _downedGroup:getUnit(1)

    local _coordinatesText = csar.getPositionOfWounded(_downedGroup)

    local
    _text = string.format("%s requests SAR at %s",
        _playerName, _coordinatesText)

    -- Loop through all the medevac units
    for x, _heliName in pairs(csar.csarUnits) do
        local _status, _err = pcall(function(_args)
            local _unitName = _args[1]
            local _woundedSide = _args[2]
            local _medevacText = _args[3]
            local _leaderPos = _args[4]
            local _groupName = _args[5]
            local _group = _args[6]

            local _heli = csar.getSARHeli(_unitName)

            -- queue up for all SAR, alive or dead, we dont know the side if they're dead or not spawned so check
            --coalition in scheduled smoke

            if _heli ~= nil then

                -- Check coalition side
                if (_woundedSide == _heli:getCoalition()) then
                    -- Display a delayed message
                    timer.scheduleFunction(csar.delayedHelpMessage, { _unitName, _medevacText, _groupName }, timer.getTime() + csar.requestdelay)

                    -- Schedule timer to check when to pop smoke
                    timer.scheduleFunction(csar.checkWoundedGroupStatus, { _unitName, _groupName }, timer.getTime() + 1)
                end
            else
                --env.warning(string.format("Medevac unit %s not active", _heliName), false)

                -- Schedule timer for Dead unit so when the unit respawns he can still pickup units
                --timer.scheduleFunction(medevac.checkStatus, {_unitName,_groupName}, timer.getTime() + 5)
            end
        end, { _heliName, _leader:getCoalition(), _text, _leader:getPoint(), _downedGroup:getName(), _downedGroup })

        if (not _status) then
            env.warning(string.format("Error while checking with medevac-units %s", _err))
        end
    end
end

function csar.checkWoundedGroupStatus(_argument)

    local _status, _err = pcall(function(_args)
        local _heliName = _args[1]
        local _woundedGroupName = _args[2]

        local _woundedGroup = csar.getWoundedGroup(_woundedGroupName)
        local _heliUnit = csar.getSARHeli(_heliName)

        if csar.woundedGroups[_woundedGroupName] == nil then
            return
        end

        if _heliUnit == nil then
        	koEngine.debugText("csar.checkWoundedGroupStatus(): _heliUnit == nil! STOPPED")
            return
        end

        --if csar.woundedGroups[_woundedGroupName].side ~= _heliUnit:getCoalition() then
        	--koEngine.debugText("csar.checkWoundedGroupStatus(): wrong side! Trying anyway")
            --return --wrong side!
        --end

        if csar.checkGroupNotKIA(_woundedGroup, _woundedGroupName, _heliUnit, _heliName) then
            local _woundedLeader = _woundedGroup[1]
            local _lookupKeyHeli = _heliUnit:getID() .. "_" .. _woundedLeader:getID() --lookup key for message state tracking

            local _distance = csar.getDistance(_heliUnit:getPoint(), _woundedLeader:getPoint())
            
           --koEngine.debugText("csar.checkWoundedGroupStatus for ".._woundedGroupName..", distance = ".._distance)

            if _distance < 3000 then
				-- helper function for finding enemy pilot without smoke and flare
				if not (csar.woundedGroups[_woundedGroupName].side == _heliUnit:getCoalition()) then
					koEngine.debugText("enemy pilot within 3000m")
					local _lookupKeyHeli = _heliUnit:getID() .. "_" .. _woundedLeader:getID() --lookup key for message state tracking
					
					if not csar.enemyCloseMessage[_lookupKeyHeli] then
						koEngine.debugText("starting close messages for enemy pilot")
						csar.checkCloseEnemyPilot(_args)
						csar.enemyCloseMessage[_lookupKeyHeli] = true
					end
				end
				
                if csar.checkCloseWoundedGroup(_distance, _heliUnit, _heliName, _woundedGroup, _woundedGroupName) == true then
                    -- we're close, reschedule
                    timer.scheduleFunction(csar.checkWoundedGroupStatus, _args, timer.getTime() + 1)
                end

            else
                csar.heliVisibleMessage[_lookupKeyHeli] = nil

                --reschedule as units arent dead yet , schedule for a bit slower though as we're far away
                timer.scheduleFunction(csar.checkWoundedGroupStatus, _args, timer.getTime() + 15)
            end
        end
    end, _argument)

    if not _status then

        koEngine.log(string.format("CSAR: Error checkWoundedGroupStatus %s", _err))
    end
end

function csar.popSmokeForGroup(_woundedGroupName, _woundedLeader)
    -- have we popped smoke already in the last 5 mins
    local _lastSmoke = csar.smokeMarkers[_woundedGroupName]
    if _lastSmoke == nil or timer.getTime() > _lastSmoke then

        local _smokecolor
        if (_woundedLeader:getCoalition() == 2) then
            _smokecolor = csar.bluesmokecolor
        else
            _smokecolor = csar.redsmokecolor
        end
        trigger.action.smoke(_woundedLeader:getPoint(), _smokecolor)

        csar.smokeMarkers[_woundedGroupName] = timer.getTime() + 300 -- next smoke time
    end
end

function csar.pickupUnit(_heliUnit,_pilotName,_woundedGroup,_woundedGroupName)
	
    local _woundedLeader = _woundedGroup[1]
    local friendly = (csar.woundedGroups[_woundedGroupName].side == _heliUnit:getCoalition())

    -- GET IN!
    local _heliName = _heliUnit:getName()
    local _heliPlayerName = _heliUnit:getPlayerName() or "AI"
    local _groups = csar.inTransitGroups[_heliName]
    local _unitsInHelicopter = csar.pilotsOnboard(_heliName)

    -- init table if there is none for this helicopter
    if not _groups then
        csar.inTransitGroups[_heliName] = {}
        _groups = csar.inTransitGroups[_heliName]
    end

    -- if the heli can't pick them up, show a message and return
    if _unitsInHelicopter + 1 > csar.max_units then
        csar.displayMessageToSAR(_heliUnit, string.format("%s, %s. We're already crammed with %d guys! Sorry!",
            _pilotName, _heliName, _unitsInHelicopter, _unitsInHelicopter), 10)
        return true
    end

    csar.inTransitGroups[_heliName][_woundedGroupName] =
    {
        woundedGroup = _woundedGroupName,
        side = csar.woundedGroups[_woundedGroupName].side,
        desc = csar.woundedGroups[_woundedGroupName].desc,
        player = csar.woundedGroups[_woundedGroupName].player
        -- FIXED
    }

    Group.destroy(_woundedLeader:getGroup())
    
    -- remove the group from MissionData
    for i, ejectedPilot in pairs(MissionData.properties.ejectedPilots) do
    	if _woundedGroupName == ejectedPilot.name then
    		koEngine.debugText("ko_CSAR: removing pilot "..ejectedPilot.name.." from MissionData")
    		table.remove(MissionData.properties.ejectedPilots,i)
    	end
    end

    csar.displayMessageToSAR(_heliUnit, string.format("%s: Hey %s I'm in! Get to the MASH ASAP! ", _pilotName, _heliPlayerName), 10)
    
    if not friendly then
    	koEngine.outTextForCoalition(csar.woundedGroups[_woundedGroupName].side, csar.woundedGroups[_woundedGroupName].desc.." has been captured as POW by the enemy!")
    	
    	local newScore = {
			achievment = "csar_enemy_pickup",
			unitGroupID = getGroupId(_heliUnit),
			unitCategory = unitCategoryTable[_heliUnit:getDesc().category],
			unitType = _heliUnit:getTypeName(),
			unitName = _heliUnit:getName(),
			targetName = _pilotName,
			side = coalitionTable[_heliUnit:getCoalition()],
		}
		koScoreBoard.insertScoreForPlayer(_heliPlayerName, newScore)
    else
        local newScore = {
			achievment = "csar_friendly_pickup",
			unitGroupID = getGroupId(_heliUnit),
			unitCategory = unitCategoryTable[_heliUnit:getDesc().category],
			unitType = _heliUnit:getTypeName(),
			unitName = _heliUnit:getName(),
			targetName = _pilotName,
			side = coalitionTable[_heliUnit:getCoalition()],
		}
		koScoreBoard.insertScoreForPlayer(_heliPlayerName, newScore)
	end
    

    timer.scheduleFunction(csar.scheduledSARFlight,
        {
            heliName = _heliUnit:getName(),
            groupName = _woundedGroupName
        },
        timer.getTime() + 1)

    return true
end

function csar.checkCloseEnemyPilot(_argument)
    local _status, _err = pcall(function(_args)
    	koEngine.debugText("csar.checkCloseEnemyPilot(".._args[1]..", ".._args[2]..")")
        local _heliName = _args[1]
        local _woundedGroupName = _args[2]
        local _woundedGroup 
        if _woundedGroupName then
        	_woundedGroup = csar.getWoundedGroup(_woundedGroupName)
        end
        local _heliUnit = csar.getSARHeli(_heliName)
      
        
        if not _woundedGroup or #_woundedGroup < 1 then
        	koEngine.debugText("no wounded group, returning")
        	return
        end
        
        if not _heliUnit then
        	koEngine.debugText("csar.checkCloseEnemyPilot('".._heliName.."', '".._woundedGroupName.."') stopped no heli unit")
            --csar.enemyCloseMessage[_lookupKeyHeli] = false	-- cannot set false without heli!
            return
        end
        
        local _woundedLeader = _woundedGroup[1]
        local _lookupKeyHeli = _heliUnit:getID() .. "_" .. _woundedLeader:getID() --lookup key for message state tracking  
        
        if not csar.woundedGroups[_woundedGroupName]and not csar.checkGroupNotKIA(_woundedGroup, _woundedGroupName, _heliUnit, _heliName) then
        	koEngine.debugText("csar.checkCloseEnemyPilot() stopped")
            csar.enemyCloseMessage[_lookupKeyHeli] = false
            return
        end
       
        local playerName = _heliUnit:getPlayerName()
        local _pilotName = csar.woundedGroups[_woundedGroupName].desc
        
        local _distance = csar.getDistance(_heliUnit:getPoint(), _woundedLeader:getPoint())

        if _distance < 3000 and _distance > 500 then
        	local oClock = tostring(koEngine.getClockDirection(_heliUnit,_woundedGroup[1]:getPosition().p)).." o'clock for "..(math.floor(_distance/100)*100).."m"
        	csar.displayMessageToSAR(_heliUnit, string.format("%s: Enemy downed pilot %s should be near at our %s! Too bad enemys dont pop smoke ...", playerName, _pilotName, oClock), 10)
           
            -- we're not that close, reschedule slower
            timer.scheduleFunction(csar.checkCloseEnemyPilot, _args, timer.getTime() + 15)

        elseif _distance < 500 then
        	local oClock = tostring(koEngine.getClockDirection(_heliUnit,_woundedGroup[1]:getPosition().p)).." o'clock for "..(math.floor(_distance/10)*10).."m"
        	csar.displayMessageToSAR(_heliUnit, string.format("%s: Enemy downed pilot %s is really near now! check %s", playerName, _pilotName, oClock), 5)
        	
            -- we're super close, reschedule faster
            timer.scheduleFunction(csar.checkCloseEnemyPilot, _args, timer.getTime() + 5)
        else
        	csar.enemyCloseMessage[_lookupKeyHeli] = false
        end
        
    end, _argument)

    if not _status then
        koEngine.log(string.format("CSAR: Error checkCloseEnemyPilot %s", _err))
    end

end

-- Helicopter is within 3km
function csar.checkCloseWoundedGroup(_distance, _heliUnit, _heliName, _woundedGroup, _woundedGroupName)

    local _woundedLeader = _woundedGroup[1]
    local _lookupKeyHeli = _heliUnit:getID() .. "_" .. _woundedLeader:getID() --lookup key for message state tracking

    local _pilotName = csar.woundedGroups[_woundedGroupName].desc

    local _reset = true
    
    local friendly = (csar.woundedGroups[_woundedGroupName].side == _heliUnit:getCoalition())

	-- only friendlies pop smoke!
	if friendly then
    	csar.popSmokeForGroup(_woundedGroupName, _woundedLeader)
    end

    if not csar.heliVisibleMessage[_lookupKeyHeli] then

		if friendly then
        	csar.displayMessageToSAR(_heliUnit, string.format("%s: %s. I hear you! Damn that thing is loud! Land or hover by the smoke.", _heliUnit:getPlayerName(),_pilotName), 30)
        	
        	 --mark as shown for THIS heli and THIS group
        	csar.heliVisibleMessage[_lookupKeyHeli] = true
        end       
    end

    if (_distance < 500) then

        if csar.heliCloseMessage[_lookupKeyHeli] == nil then

			if friendly then
	        	csar.displayMessageToSAR(_heliUnit, string.format("%s: %s. You're close now! Land or hover at the smoke.", _heliUnit:getPlayerName(), _pilotName), 10)
	        	
	        	--mark as shown for THIS heli and THIS group
           		csar.heliCloseMessage[_lookupKeyHeli] = true
	        end
        end

        -- have we landed close enough?
        if csar.inAir(_heliUnit) == false then

            -- if you land on them, doesnt matter if they were heading to someone else as you're closer, you win! :)
            if (_distance < csar.loadDistance) then

                return csar.pickupUnit(_heliUnit,_pilotName,_woundedGroup,_woundedGroupName)
            end
        else

            local _unitsInHelicopter = csar.pilotsOnboard(_heliName)

            if  csar.inAir(_heliUnit) and _unitsInHelicopter + 1 <= csar.max_units then

                if _distance < 8.0  then

                    --check height!
                    local _height = _heliUnit:getPoint().y - _woundedLeader:getPoint().y

                    if _height  <= 30.0 then

                        local _time = csar.hoverStatus[_lookupKeyHeli]

                        if _time == nil then
                            csar.hoverStatus[_lookupKeyHeli] = 5
                            _time = 5
                        else
                            _time = csar.hoverStatus[_lookupKeyHeli] - 1
                            csar.hoverStatus[_lookupKeyHeli] = _time
                        end

                        if _time > 0 then
                            csar.displayMessageToSAR(_heliUnit, "Hovering above " .. _pilotName .. ". \n\nHold hover for " .. _time .. " seconds to winch them up. \n\nIf the countdown stops you're too far away!", 10,true)
                        else
                            csar.hoverStatus[_lookupKeyHeli] = nil
                            return csar.pickupUnit(_heliUnit,_pilotName,_woundedGroup,_woundedGroupName)
                        end
                        _reset = false
                    else
                        csar.displayMessageToSAR(_heliUnit, "Too high to winch " .. _pilotName .. " \nReduce height and hover for 5 seconds!", 5,true)
                    end
                end
            end
        end
    end

    if _reset then
        csar.hoverStatus[_lookupKeyHeli] = nil
    end

    return true
end



function csar.checkGroupNotKIA(_woundedGroup, _woundedGroupName, _heliUnit, _heliName)

    local _details = csar.woundedGroups[_woundedGroupName]

    if _details == nil then
        return false
    end

    -- check if unit has died or been picked up
    if #_woundedGroup == 0 and _heliUnit ~= nil then

        local inTransit = false

        for _currentHeli, _groups in pairs(csar.inTransitGroups) do

            if _groups[_woundedGroupName] then
                local _group = _groups[_woundedGroupName]
                --if _group.side == _heliUnit:getCoalition() then
                    inTransit = true

                    csar.displayToAllSAR(string.format("Pilot %s has been picked up by %s", _details.player, _currentHeli), _heliUnit:getCoalition(), _heliName)

                    break
                --end
            end
        end


        --display to all sar
        if inTransit == false then
            --DEAD

            csar.displayToAllSAR(string.format("Pilot %s KIA!", _details.player), _heliUnit:getCoalition(), _heliName)
        end

        --     medevac.displayMessageToSAR(_heliUnit, string.format("%s: %s is dead", _heliName,_woundedGroupName ),10)

        --stops the message being displayed again
        csar.woundedGroups[_woundedGroupName] = nil

        return false
    end

    --continue
    return true
end


function csar.scheduledSARFlight(_args)

    local _status, _err = pcall(function(_args)

        local _heliUnit = csar.getSARHeli(_args.heliName)
        local _woundedGroupName = _args.groupName

        if (_heliUnit == nil) then

            --helicopter crashed?
            -- Put intransit pilots back
            --TODO possibly respawn the guys
            local _rescuedGroups = csar.inTransitGroups[_args.heliName]

            if _rescuedGroups ~= nil then

                -- enable pilots again
                for _, _rescueGroup in pairs(_rescuedGroups) do

                   -- csar.enableAircraft(_rescueGroup.originalUnit)
                end

            end

            csar.inTransitGroups[_args.heliName] = nil

            return
        end

        if csar.inTransitGroups[_heliUnit:getName()] == nil or csar.inTransitGroups[_heliUnit:getName()][_woundedGroupName] == nil then
            -- Groups already rescued
            return
        end

        -- end
        --queue up
        timer.scheduleFunction(csar.scheduledSARFlight,
            {
                heliName = _heliUnit:getName(),
                groupName = _woundedGroupName
            },
            timer.getTime() + 5)
    end, _args)
    if (not _status) then
        koEngine.log(string.format("CSAR: Error in scheduledSARFlight\n\n%s", _err))
    end
end

local unitCategoryTable = {
	[0] = "AIRPLANE",
	[1] = "HELICOPTER",
	[2] = "GROUND_UNIT",
	[3] = "SHIP",
	[4] = "STRUCTURE",
}

local coalitionTable = {
	[0] = 'neutral',
	[1] = 'red',
	[2] = 'blue',
}

function csar.rescuePilots(_heliUnit)
	koEngine.debugText("csar.rescuePilots()")
    local _rescuedGroups = csar.inTransitGroups[_heliUnit:getName()]

    if _rescuedGroups == nil  then
        -- Groups already rescued
        return
    end

    csar.inTransitGroups[_heliUnit:getName()] = nil

    local _txt = string.format("%s: The pilots have been taken to the\nmedical clinic. Good job!", _heliUnit:getPlayerName())
    local coalition = coalitionTable[_heliUnit:getCoalition()]


    local _message = "------------------------------\n".._heliUnit:getPlayerName().." Rescued:"
    local cashCollected = 0
    
    -- enable pilots again
    for i, _rescueGroup in pairs(_rescuedGroups) do
		koEngine.debugText("CSAR: player ".._rescueGroup.player.." got rescued!")
		local playerName = koEngine.getPlayerNameFix(_rescueGroup.player)
		-- TODO insert callback here!
        if MissionData then
        	--koEngine.debugText("_rescueGroup = "..koEngine.TableSerialization(_rescueGroup))
        	--koEngine.debugText("_heliUnit:getCoalition() = ".._heliUnit:getCoalition())
        	if _heliUnit:getCoalition() == _rescueGroup.side then
        		-- pilot was rescued
        		-- handout some cash
        	
	        	if not MissionData.properties.playerLimit[playerName] or MissionData.properties.playerLimit[playerName] < 1 then
	        		MissionData.properties.playerLimit[playerName] = 0	-- set playerlimit to zero if it wasnt set or is already 0 to avoid negative lives
	        	else        	
	            	MissionData.properties.playerLimit[playerName] = MissionData.properties.playerLimit[playerName] - 1;
	            end
	            
	            koEngine.debugText("Upped live for rescued "..playerName)
	            
	            local newScore = {
					rescuedPlayer = _rescueGroup.player,
					achievment = "pilot_rescued",
					unitType = _heliUnit:getTypeName(),
					unitName = _heliUnit:getName(),
					unitCategory = unitCategoryTable[_heliUnit:getCategory()],
					targetName = playerName,
					targetSide = _rescueGroup.side,
					side = coalitionTable[_heliUnit:getCoalition()],
				}
				koScoreBoard.insertScoreForPlayer(_heliUnit:getPlayerName(), newScore)
				cashCollected = cashCollected + koScoreBoard.cashForAchievement[newScore.achievment].value
				
				_message = _message.."\n    ".._rescueGroup.player..": "..format_num(koScoreBoard.cashForAchievement[newScore.achievment].value).."$"
			else
				-- enemy pilot was captured as POW
				koEngine.debugText(""..playerName.."was captured as POW")
				
				local newScore = {
					rescuedPlayer = _rescueGroup.player,
					achievment = "pilot_captured",
					unitType = _heliUnit:getTypeName(),
					unitName = _heliUnit:getName(),
					unitCategory = unitCategoryTable[_heliUnit:getCategory()],
					targetName = playerName,
					targetSide = _rescueGroup.side,
					side = coalitionTable[_heliUnit:getCoalition()],
				}
				koScoreBoard.insertScoreForPlayer(_heliUnit:getPlayerName(), newScore)
				cashCollected = cashCollected + koScoreBoard.cashForAchievement[newScore.achievment].value
				
				_message = _message.."\n    ".._rescueGroup.player..": "..format_num(koScoreBoard.cashForAchievement[newScore.achievment].value).."$ (captured as POW)"
			end
		else
			koEngine.debugText("CSAR FATAL ERROR: no MissionData available")
        end

        --_message = _message.."\n".._rescueGroup.player

       -- csar.enableAircraft(_rescueGroup.originalUnit)
    end
    
    _message = _message.."\n\n  you have received "..cashCollected.."$ for your efforts.\n  your current cashpile is now "..koScoreBoard.getCashcountForPlayer(_heliUnit:getPlayerName()).." points \n  You can use it to request Convoys!\n"

    csar.displayMessageToSAR(_heliUnit, _txt, 10)

    koEngine.outTextForCoalition(_heliUnit:getCoalition(), _message, 15)

    -- env.info("Rescued")
end


function csar.getSARHeli(_unitName)

    local _heli = Unit.getByName(_unitName)

    if _heli ~= nil and _heli:isActive() and _heli:getLife() > 0 then

        return _heli
    end

    return nil
end


-- Displays a request for medivac
function csar.delayedHelpMessage(_args)
    local status, err = pcall(function(_args)
        local _heliName = _args[1]
        local _text = _args[2]
        local _injuredGroupName = _args[3]

        local _heli = csar.getSARHeli(_heliName)

        if _heli ~= nil and #csar.getWoundedGroup(_injuredGroupName) > 0 then
            csar.displayMessageToSAR(_heli, _text, csar.messageTime)


            local _groupId = csar.getGroupId(_heli)

            if _groupId then
                trigger.action.outSoundForGroup(_groupId, "l10n/DEFAULT/CSAR.ogg")
            end

        else
            koEngine.log("CSAR: No Active Heli or Group DEAD")
        end
    end, _args)

    if (not status) then
        koEngine.log(string.format("CSAR: Error in delayedHelpMessage "))
    end

    return nil
end

function csar.displayMessageToSAR(_unit, _text, _time,_clear)

    local _groupId = csar.getGroupId(_unit)

    if _groupId then
        if _clear == true then
            trigger.action.outTextForGroup(_groupId, _text, _time,_clear)
        else
            trigger.action.outTextForGroup(_groupId, _text, _time)
        end
    end

end

function csar.getWoundedGroup(_groupName)
    local _status, _result = pcall(function(_groupName)

        local _woundedGroup = {}
        local group = Group.getByName(_groupName)
        if group then
	        local _units = group:getUnits()
	
	        for _, _unit in pairs(_units) do
	
	            if _unit ~= nil and _unit:isActive() and _unit:getLife() > 0 then
	                table.insert(_woundedGroup, _unit)
	            end
	        end
        end

        return _woundedGroup
    end, _groupName)

    if (_status) then
        return _result
    else
        env.warning(string.format("csar.getWoundedGroup failed! Returning empty table.%s",_result), false)
        return {} --return empty table
    end
end


function csar.convertGroupToTable(_group)

    local _unitTable = {}

    for _, _unit in pairs(_group:getUnits()) do

        if _unit ~= nil and _unit:getLife() > 0 then
            table.insert(_unitTable, _unit:getName())
        end
    end

    return _unitTable
end

function csar.getPositionOfWounded(_woundedGroup)

    local _woundedTable = csar.convertGroupToTable(_woundedGroup)

    local _coordinatesText = ""
    if csar.coordtype == 0 then -- Lat/Long DMTM
    _coordinatesText = string.format("%s", mist.getLLString({ units = _woundedTable, acc = csar.coordaccuracy, DMS = 0 }))

    elseif csar.coordtype == 1 then -- Lat/Long DMS
    _coordinatesText = string.format("%s", mist.getLLString({ units = _woundedTable, acc = csar.coordaccuracy, DMS = 1 }))

    elseif csar.coordtype == 2 then -- MGRS
    _coordinatesText = string.format("%s", mist.getMGRSString({ units = _woundedTable, acc = csar.coordaccuracy }))

    elseif csar.coordtype == 3 then -- Bullseye Imperial
    _coordinatesText = string.format("bullseye %s", mist.getBRString({ units = _woundedTable, ref = coalition.getMainRefPoint(_woundedGroup:getCoalition())  }))

    else -- Bullseye Metric --(medevac.coordtype == 4)
    _coordinatesText = string.format("bullseye %s KM", mist.getBRString({ units = _woundedTable, ref = coalition.getMainRefPoint(_woundedGroup:getCoalition()),  metric = 1 }))
    end

    return _coordinatesText
end

function csar.getBearing(_heli,_woundedGroup)

    local _woundedTable = csar.convertGroupToTable(_woundedGroup)

    return string.format("%s", mist.getBRString({ units = _woundedTable, ref = _heli:getPoint(), metric = 1 }))

end

-- Displays all active MEDEVACS/SAR
function csar.displayActiveSAR(_unitName)
    local _msg = "Nearest 15 Active MEDEVAC/SAR:"

    local _heli = csar.getSARHeli(_unitName)

    if _heli == nil then
        return
    end

    local _heliSide = _heli:getCoalition()

    local _csarList = {}

    for _groupName, _value in pairs(csar.woundedGroups) do

        local _woundedGroup = csar.getWoundedGroup(_groupName)

        --if #_woundedGroup > 0 and (_woundedGroup[1]:getCoalition() == _heliSide) then
        if #_woundedGroup > 0 then

            local _coordinatesText = csar.getBearing(_heli, _woundedGroup[1]:getGroup())

            local _distance = csar.getDistance(_heli:getPoint(), _woundedGroup[1]:getPoint())
            local isEnemy = ""
			if _woundedGroup[1]:getCoalition() ~= _heliSide then
				isEnemy = "Enemy "
			end
            table.insert(_csarList, {dist = _distance, msg = string.format("%s%s - %s Km", isEnemy, _value.desc, _coordinatesText)})
        end
    end

    local function sortDistance(a,b)
        return a.dist < b.dist
    end
    table.sort(_csarList, sortDistance)

    local _count = 1
    for _,_line in pairs(_csarList) do
        _msg = _msg .."\n".._line.msg
        _count = _count+1

        if _count > 15 then
            break;
        end
    end

    csar.displayMessageToSAR(_heli, _msg, 20)
end


function csar.getClosestDownedPilot(_heli)

    local _side = _heli:getCoalition()

    local _closetGroup = nil
    local _shortestDistance = -1
    local _distance = 0
    local _closetGroupInfo = nil

    for _woundedName, _groupInfo in pairs(csar.woundedGroups) do

        local _tempWounded = csar.getWoundedGroup(_woundedName)

        -- check group exists and not moving to someone else
        if #_tempWounded > 0 and (_tempWounded[1]:getCoalition() == _side) then

            _distance = csar.getDistance(_heli:getPoint(), _tempWounded[1]:getPoint())

            if _distance ~= nil and (_shortestDistance == -1 or _distance < _shortestDistance) then


                _shortestDistance = _distance
                _closetGroup = _tempWounded[1]
                _closetGroupInfo = _groupInfo

            end
        end
    end

    return {pilot=_closetGroup,distance=_shortestDistance,groupInfo=_closetGroupInfo}
end

function csar.signalFlare(_unitName)

    local _heli = csar.getSARHeli(_unitName)

    if _heli == nil then
        return
    end

    local _closet =  csar.getClosestDownedPilot(_heli)

    if _closet ~= nil and _closet.pilot ~= nil and _closet.distance < 5000.0 then

        local _clockDir = csar.getClockDirection(_heli,_closet.pilot)

        local _msg = string.format("%s - %.3fM - Popping Signal Flare at your %s ",  _closet.groupInfo.desc, _closet.distance,_clockDir)
        csar.displayMessageToSAR(_heli, _msg, 20)

        trigger.action.signalFlare(_closet.pilot:getPoint(),1, 0 )
    else
        csar.displayMessageToSAR(_heli, "No Pilots within 5KM", 20)
    end

end

function csar.displayToAllSAR(_message, _side, _ignore)
	koEngine.debugText("csar.displayToAllSAR(".._message..")")
    for _, _unitName in pairs(csar.csarUnits) do

        local _unit = csar.getSARHeli(_unitName)

        if _unit ~= nil and _unit:getCoalition() == _side then

            if _ignore == nil or _ignore ~= _unitName then
                csar.displayMessageToSAR(_unit, _message, 10)
            end
        else
            -- env.info(string.format("unit nil %s",_unitName))
        end
    end
end



function csar.checkOnboard(_unitName)
    local _unit = csar.getSARHeli(_unitName)

    if _unit == nil then
        return
    end

    --list onboard pilots

    local _inTransit =  csar.inTransitGroups[_unitName]

    if _inTransit == nil or  csar.tableLength(_inTransit) == 0 then
        csar.displayMessageToSAR(_unit, "No Rescued Pilots onboard", 30)
    else

        local _text = "Onboard - RTB to FARP/Airfield or MASH: "

        for _,_onboard  in pairs(csar.inTransitGroups[_unitName]) do
            _text = _text .."\n".._onboard.desc
        end

        csar.displayMessageToSAR(_unit,_text , 30)
    end
end


-- Adds menuitem to all medevac units that are active
function csar.addMedevacMenuItem(_unit)
    local _unitName = _unit:getName()

    if _unit ~= nil then

        local _groupId = csar.getGroupId(_unit)

        if _groupId then
            
            if csar.addedTo[tostring(_groupId)] == nil then

                table.insert(csar.csarUnits, _unit:getName())

                csar.addedTo[tostring(_groupId)] = true

                local _rootPath = missionCommands.addSubMenuForGroup(_groupId, "CSAR")

                missionCommands.addCommandForGroup(_groupId, "List Active CSAR", _rootPath,  csar.displayActiveSAR,
                    _unitName)

                missionCommands.addCommandForGroup(_groupId, "Check Onboard", _rootPath, csar.checkOnboard,_unitName)

                missionCommands.addCommandForGroup(_groupId, "Request Signal Flare", _rootPath, csar.signalFlare,_unitName)
            end
        end

    end

    return
end

--get distance in meters assuming a Flat world
function csar.getDistance(_point1, _point2)

    local xUnit = _point1.x
    local yUnit = _point1.z
    local xZone = _point2.x
    local yZone = _point2.z

    local xDiff = xUnit - xZone
    local yDiff = yUnit - yZone

    return math.sqrt(xDiff * xDiff + yDiff * yDiff)
end




function csar.inAir(_heli)

    if _heli:inAir() == false then
        return false
    end

    -- less than 5 cm/s a second so landed
    -- BUT AI can hold a perfect hover so ignore AI
    if mist.vec.mag(_heli:getVelocity()) < 0.05 and _heli:getPlayerName() ~= nil then
        return false
    end
    return true
end

function csar.getClockDirection(_heli, _crate)

    -- Source: Helicopter Script - Thanks!

    local _position = _crate:getPosition().p -- get position of crate
    local _playerPosition = _heli:getPosition().p -- get position of helicopter
    local _relativePosition = mist.vec.sub(_position, _playerPosition)

    local _playerHeading = mist.getHeading(_heli) -- the rest of the code determines the 'o'clock' bearing of the missile relative to the helicopter

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

function csar.getGroupId(_unit)

    local _unitDB =  mist.DBs.unitsById[tonumber(_unit:getID())]
    if _unitDB ~= nil and _unitDB.groupId then
        return _unitDB.groupId
    end

    return nil
end



-- Schedule timer to add radio item
--timer.scheduleFunction(csar.addMedevacMenuItem, nil, timer.getTime() + 5)

world.addEventHandler(csar.eventHandler)

env.info("CSAR event handler added")