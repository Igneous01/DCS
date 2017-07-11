AmbushTable = {}
for i = 1, 5 do
	table.insert(AmbushTable, ZONE:New("AmbushZone" .. tostring(i)))
end
NumInfantrySquads = math.random(3, 6)
NumVehicles = math.random(1, 4)
NumMANPADS = math.random(0, 1)
-- randomly remove 3 elements from the ambush table, units will spawn from 2 randomly picked zones out of 5
table.remove(AmbushTable, math.random(#AmbushTable))
table.remove(AmbushTable, math.random(#AmbushTable))
table.remove(AmbushTable, math.random(#AmbushTable))



for i = 1, NumInfantrySquads do
	local spawn_inf = SPAWN:New("InsA")
						:InitRandomizeZones(AmbushTable)
						:SpawnWithIndex(i)
end

for i = 1, NumVehicles do
	local spawn_inf = SPAWN:New("InsB")
						:InitRandomizeZones(AmbushTable)
						:SpawnWithIndex(i)
end

for i = 1, NumMANPADS do
	local spawn_inf = SPAWN:New("InsC")
						:InitRandomizeZones(AmbushTable)
						:SpawnWithIndex(i)
end
	
	  
	