function Dump(o)
   if type(o) == 'table' then
	  local s = '{ '
	  for k,v in pairs(o) do  
		 if type(k) ~= 'number' then k = '"'..k..'"' end
		 s = s .. '['..k..'] = ' .. Dump(v) .. ','
	  end
	  return s .. '} '
   else
	  return tostring(o)
   end
end

UnitList = { "EWR 55G6", "BUK SR1", "Tor", "SA-3 SR", "Osa", "Tunguska" }
PlayerList = { "IggyZ", "Samael", "Groundhog", "Dperk", "Carpa", "Wenky", "Mayko", "Clueless" }

function detect_report()
  for i = 1, #UnitList do
    env.info("Looping for AI Unit " .. UnitList[i])
    local u = Unit.getByName(UnitList[i])
    if u then
      local targets = Controller.getDetectedTargets(u)
      if targets then
        for x = 1, #targets do
          local obj = targets[x].object
          if obj then
            env.info("Looping targets for AI Unit " .. UnitList[i] .. " target: " .. tostring(obj.id_))
            for p = 1, #PlayerList do
              local playerObj = Unit.getByName(PlayerList[p])
              if playerObj then
                env.info("Player ID: " .. tostring(playerObj.id_) .. " target ID: " .. tostring(obj.id_))
                if playerObj.id_ == obj.id_ then
                  trigger.action.outTextForCoalition(coalition.side.BLUE, "Aircraft : " .. PlayerList[p] .. " detected by " .. UnitList[i], 5)
                  break
                end
              end
            end
          end
        end
      end
    end
  end  
end

DetectScheduler = SCHEDULER:New( nil, detect_report, {}, 1, 5)


--env.info("Unit Dump: " .. Dump(Unit.getByName("KA50")))