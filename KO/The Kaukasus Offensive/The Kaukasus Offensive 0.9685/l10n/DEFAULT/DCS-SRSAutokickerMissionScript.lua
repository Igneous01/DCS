----------------------------------------------------------------------------------------------------------
-- 	DCS-SRSAutokickerMissionScript
-- 	
-- 	Provides messaging functionality, so player gets a proper big message before he gets kicked
----------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------
-- JSON/UDP declaration
package.path  = package.path..";.\\LuaSocket\\?.lua;"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"

local JSON = loadfile("Scripts\\JSON.lua")()
local socket = require("socket")

-- UDP Declaration
SRSAutoKickerMissionScript = {}
SRSAutoKickerMissionScript.MESSAGE_RECEIVE_PORT = 6001
SRSAutoKickerMissionScript.UDPMessageReceiveSocket = socket.udp()
SRSAutoKickerMissionScript.UDPMessageReceiveSocket:setsockname("*", SRSAutoKickerMissionScript.MESSAGE_RECEIVE_PORT)
SRSAutoKickerMissionScript.UDPMessageReceiveSocket:settimeout(.0001) --receive timer

SRSAutoKickerMissionScript.GROUPID_SEND_TO_PORT = 6007
SRSAutoKickerMissionScript.UDPGroupIDSendSocket = socket.udp()

----------------------------------------------------------------------------------------------------------
-- Eventhandler
-- to send a message the client side needs to know the groupID
local eventHandler = {}
function eventHandler:onEvent(event)
	--sends the groupid if a client enters a unit, so we can display a proper message in the topright corner
	if event.initiator and event.initiator:isExist() and event.id == world.event.S_EVENT_BIRTH then
		if Object.getCategory(event.initiator) ~= Object.Category.UNIT then 
			return 
		end	
		
		-- no playername means AI
		local playerName = event.initiator:getPlayerName()
		local ownGroupID = getGroupId(event.initiator) 
		
		if not ownGroupID or not playerName then 
			return 
		end

		env.info("sending groupID to serverside")
		
		-- send groupID to GameGui
		local groupData = {
			groupID = ownGroupID,
			name = playerName,
		}
		socket.try(SRSAutoKickerMissionScript.UDPGroupIDSendSocket:sendto(JSON:encode(groupData).." \n", "127.0.0.1", SRSAutoKickerMissionScript.GROUPID_SEND_TO_PORT))
	end
end
world.addEventHandler(eventHandler)

function messageReceiver()
	mist.scheduleFunction(messageReceiver, {}, timer.getTime() + 1)	
	
	-- receive groupID from mission side for bigger message
	local jsonMsg = SRSAutoKickerMissionScript.UDPMessageReceiveSocket:receive()
	if jsonMsg then
		env.info("packet received!")
		
		local msgData = JSON:decode(jsonMsg)
		
		--env.info("data received: "..TableSerialization(msgData))

		if msgData.type == "message" then
			env.info("message for groupID: "..msgData.groupID..", message = '"..msgData.msg.."'")
			
			trigger.action.outTextForGroup(msgData.groupID, msgData.msg, 60, true)
		
		elseif msgData.type == "srsPlayerData" then
			env.info("srs Player Data received")
			
			if koTCPSocket then
				env.info("sending playerdata via TCPSocket")
				koTCPSocket.send(msgData.data, msgData.type)
			end
		end
	end
end
mist.scheduleFunction(messageReceiver, {}, timer.getTime() + 1)

function getGroupId(_unit)
	local _unitDB =  mist.DBs.unitsById[tonumber(_unit:getID())]
    if _unitDB ~= nil and _unitDB.groupId then
        return _unitDB.groupId
    end

    return nil
end

function TableSerialization(t, i)													--function to turn a table into a string (works to transmutate strings, numbers and sub-tables)
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
				text = text .. TableSerialization(v, i + 1)
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
				text = text .. TableSerialization(v, i + 1)
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

env.info("DCS-SRSAutokickerMissionScript loaded!")