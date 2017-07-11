
-- Init Dead Bridges Checks
do
  local vars = {}
  vars.zones = { 'DestroyBridge1ZoneA' }
  vars.flag = 10
  mist.flagFunc.mapobjs_dead_zones(vars)
end

do
  local vars = {}
  vars.zones = { 'DestroyBridge2ZoneA' }
  vars.flag = 11
  mist.flagFunc.mapobjs_dead_zones(vars)
end

do
  local vars = {}
  vars.zones = { 'DestroyBridge1ZoneB' }
  vars.flag = 12
  mist.flagFunc.mapobjs_dead_zones(vars)
end






-- Spawn CAP
do
  G_CapLimit = 4
  G_CapGroups = 10
  -- these are late activation groups setup in mission editor (group names)
  local CAPTemplateTable = { "Template CAP 1", "Template CAP 2", "Template CAP 3", "Template CAP 4", "Template CAP 5" }	

  local SpawnSukhumi = SPAWN:New( "SpawnSukhumi" )
    :InitLimit( G_CapLimit, G_CapGroups )			-- variables set in mission init trigger
    :InitRandomizeRoute( 2, 1, 20000, 10000 )		-- randomizes some waypoints (wp to start randomizing, wp to stop randomizing (this is the lastwp number - this value), wp radius, height
    :InitRandomizeTemplate( CAPTemplateTable )	-- select random fromm collection of templates
    :InitRepeatOnEngineShutDown()					-- respawn when engines shutdown on rtb
    :SpawnScheduled( 1200, 0.80 )					-- spawn every 16 to 20 minutes
    
  local SpawnGudauta = SPAWN:New( "SpawnGudauta" )
    :InitLimit( G_CapLimit, G_CapGroups )			-- variables set in mission init trigger
    :InitRandomizeRoute( 2, 1, 20000, 10000 )		-- randomizes some waypoints (wp to start randomizing, wp to stop randomizing (this is the lastwp number - this value), wp radius, height
    :InitRandomizeTemplate( CAPTemplateTable )	-- select random fromm collection of templates
    :InitRepeatOnEngineShutDown()					-- respawn when engines shutdown on rtb
    :SpawnScheduled( 1200, 0.80)					-- spawn every 16 to 20 minutes
    
    env.info("OPERATION_TANGUERAY: Russian CAP Spawns Configured")
end







-- Spawn Ground Assault Convoys
do
-- these are late activation groups setup in mission editor (group names)
local TemplateTable = { "Template Convoy 1", "Template Convoy 2", "Template Convoy 3", "Template Convoy 4", "Template Convoy 5" }	

local SpawnArmorConvoy = SPAWN:New( "SpawnConvoy" )
  :InitLimit( 15, 4 )	-- 15 concurrent alive units, 4 groups max to spawn
  :InitRandomizeTemplate( TemplateTable ) 	-- select random fromm collection of templates
  :SpawnScheduled( 900, .5 )				-- spawn every 7.5 to 15 minutes
  
  env.info("OPERATION_TANGUERAY: Russian Armored Convoys Spawning")
end

do
  -- Task Russian Fleet Attack Waypoint
  local RUFleetGroup = GROUP:FindByName("RU Fleet")
  RUFleetGroup:Activate()
  --RUFleetGroup:TaskRouteToZone(ZONE:New("FleetAtkZone"), true, 55, "Turning point" )
  env.info("OPERATION_TANGUERAY: Russian Fleet Spawned and WP Given")
end

--env.info("OPERATION_TANGUERAY: Flag 41: " .. tostring(trigger.misc.getUserFlag("41")))
--env.info("OPERATION_TANGUERAY: Flag 42: " .. tostring(trigger.misc.getUserFlag("42")))






-- Artillery Continuous fire mission
do
  -- set flag 4 to true for testing purposes
  trigger.action.setUserFlag("4", true)
  env.info("OPERATION_TANGUERAY: Flag 4: " .. tostring(trigger.misc.getUserFlag("4")))
  
  firemission1 = false
  firemission2 = false
  
  timer.scheduleFunction(
    function(args, time)
      if not firemission1 and not firemission2 then
        env.info("OPERATION_TANGUERAY: Artillery Fire - both flags are false - this is fresh start")
        trigger.action.setUserFlag("41", 1)
        firemission1 = true
      elseif firemission1 then
        env.info("OPERATION_TANGUERAY: Artillery Fire - 41 is true, deactivating and setting 42")
        trigger.action.setUserFlag("42", 1)
        firemission1 = false
        firemission2 = true
      elseif firemission2 then
        env.info("OPERATION_TANGUERAY: Artillery Fire - 42 is true, deactivating and setting 41")
        trigger.action.setUserFlag("41", 1)
        firemission2 = false
        firemission1 = true
      end
      return time + 300
    end, 
    {}, 
    timer.getTime() + 5)
    env.info("OPERATION_TANGUERAY: Artillery Fire Mission Timer Script Starting")
end




-- SLOT BLOCK
do
  trigger.action.setUserFlag("SSB",100) -- initializes slot block
  
  function DisableSlots()
    trigger.action.setUserFlag("Batumi Widow 1-1", 100)
    trigger.action.setUserFlag("Batumi Widow 1-2", 100)
    trigger.action.setUserFlag("Batumi Punisher 1-1", 100)
    trigger.action.setUserFlag("Batumi Punisher 1-2", 100)
    trigger.action.setUserFlag("Batumi Rattler 1-1", 100)
    trigger.action.setUserFlag("Batumi Rattler 1-2", 100)
    trigger.action.setUserFlag("Batumi Anura 1-1", 100)
    trigger.action.setUserFlag("Batumi Anura 1-2", 100)
    trigger.action.setUserFlag("Batumi Toad 1-1", 100)
    trigger.action.setUserFlag("Batumi Toad 1-2", 100)
    trigger.action.setUserFlag("Batumi Ghost 1-1", 100)
    trigger.action.setUserFlag("Batumi Ghost 1-2", 100)
    trigger.action.setUserFlag("Batumi Ghost 1-3", 100)
    trigger.action.setUserFlag("Batumi Ghost 1-4", 100)
    trigger.action.setUserFlag("Batumi Archer 1-1", 100)
    trigger.action.setUserFlag("Batumi Archer 1-2", 100)
    trigger.action.setUserFlag("Batumi Archer 1-3", 100)
    trigger.action.setUserFlag("Batumi Archer 1-4", 100)
  end
  
  function EnableSlots()
    trigger.action.setUserFlag("Batumi Widow 1-1", 0)
    trigger.action.setUserFlag("Batumi Widow 1-2", 0)
    trigger.action.setUserFlag("Batumi Punisher 1-1", 0)
    trigger.action.setUserFlag("Batumi Punisher 1-2", 0)
    trigger.action.setUserFlag("Batumi Rattler 1-1", 0)
    trigger.action.setUserFlag("Batumi Rattler 1-2", 0)
    trigger.action.setUserFlag("Batumi Anura 1-1", 0)
    trigger.action.setUserFlag("Batumi Anura 1-2", 0)
    trigger.action.setUserFlag("Batumi Toad 1-1", 0)
    trigger.action.setUserFlag("Batumi Toad 1-2", 0)
    trigger.action.setUserFlag("Batumi Ghost 1-1", 0)
    trigger.action.setUserFlag("Batumi Ghost 1-2", 0)
    trigger.action.setUserFlag("Batumi Ghost 1-3", 0)
    trigger.action.setUserFlag("Batumi Ghost 1-4", 0)
    trigger.action.setUserFlag("Batumi Archer 1-1", 0)
    trigger.action.setUserFlag("Batumi Archer 1-2", 0)
    trigger.action.setUserFlag("Batumi Archer 1-3", 0)
    trigger.action.setUserFlag("Batumi Archer 1-4", 0)
  end
  
  env.info("OPERATION_TANGUERAY: SlotBlock turned on")
end






-- NO FLY ZONE
do
  InNoFlyZoneTime = 0
  TurkishCAPSpawnID = 1
  SpawnTurkeyCAP = SPAWN:New( "SpawnTurkeyCAP" )
  NOFLYZONE = ZONE:New("NoFlyZone")
  
  function IsInNoFlyZone(args, time)
    env.info("OPERATION_TANGUERAY - IsInNoFlyZone called")
    local _bGroups = coalition.getGroups(2, Group.Category.AIRPLANE)
    env.info("OPERATION_TANGUERAY - IsInNoFlyZone - Num Groups : " .. tostring(#_bGroups))
    local _inZone = false
    local _gName = ""
    local _z = NOFLYZONE
    for i = 1, #_bGroups do
      if _bGroups[i]:isExist() then
        env.info("OPERATION_TANGUERAY - IsInNoFlyZone - unit exists")
        local _units = _bGroups[i]:getUnits()
        env.info("OPERATION_TANGUERAY - IsInNoFlyZone - unit count " .. tostring(#_units))
        for k = 1, #_units do
          local _pos = _units[k]:getPoint()
          if _z:IsVec3InZone(_pos) and _units[k]:isActive() then
            env.info("Blue Coalition Unit inside no fly zone")
            _gName = _bGroups[i]:getName()
            _inZone = true
            break
          end
        end
      end
      if _inZone then
        break
      end
    end
    
    if _inZone then
      env.info("OPERATION_TANGUERAY - Inside zone")
      InNoFlyZoneTime = InNoFlyZoneTime + 30
      trigger.action.outTextForCoalition(2, "--ALERT-- [" .. _gName .. "] are entering an exclusive no fly zone, turn around or you will be shot down!", 30)
    else
      InNoFlyZoneTime = 0
    end
    
    if InNoFlyZoneTime >= 120 then
      trigger.action.outTextForCoalition(2, "--ALERT-- You have been warned multiple times - we will intercept and shoot you down!", 30)
      -- spawn turkish f16s
      SpawnTurkeyCAP:SpawnWithIndex(TurkishCAPSpawnID)
      TurkishCAPSpawnID = TurkishCAPSpawnID + 1 -- increment the ID
      InNoFlyZoneTime = 0 -- reset this timer
      env.info("OPERATION_TANGUERAY - Turkish CAP Spawned")
    end
    
    return time + 5
  end
  
  timer.scheduleFunction(IsInNoFlyZone, {}, timer.getTime() + 5)
  
  env.info("OPERATION_TANGUERAY - IsInNoFlyZone scheduled")
end




-- ACTIVATE RU BATTLEGROUP
do
  timer.scheduleFunction(function(args, time)
      if trigger.misc.getUserFlag("10") == 0 or
         trigger.misc.getUserFlag("11") == 0 or
         trigger.misc.getUserFlag("12") == 0 then
        env.info("OPERATION_TANGUERAY - Not all bridges destroyed - activating group ai")
        --trigger.action.setUserFlag("5", 1)
        GROUP:FindByName("RU BattleGroup 2")
          :TaskRouteToZone(ZONE:New("AtkZone"), true, 60, "Turning point" )
          
        trigger.action.outTextForCoalition(2, "--ALERT-- Russian Battlegroup north of Kobuleti has begun mobilizing!", 30)
      end
      
      return nil
      end, {}, timer.getTime() + 30)
  
end