
package.path  = package.path..";.\\LuaSocket\\?.lua;"
package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"


local JSON = loadfile("Scripts\\JSON.lua")()
local socket = require("socket")

local SR_Autokicker = {}

SR_Autokicker.dcsClientList = {}
SR_Autokicker.srsClientList = nil

SR_Autokicker.kickTime = 5 			-- how long can a player be connected without SRS before he gets kicked from the server?

-- UDP Declaration
SR_Autokicker.JSON = JSON
SR_Autokicker.CL_RECEIVE_PORT = 9086	-- SR clientlist port
SR_Autokicker.GroupID_RECEIVE_PORT = 6007	-- SR groupid receive port
SR_Autokicker.MESSAGE_SEND_PORT = 6001	-- SR message send port

SR_Autokicker.UDPClientListReceiveSocket = socket.udp()
SR_Autokicker.UDPClientListReceiveSocket:setsockname("*", SR_Autokicker.CL_RECEIVE_PORT)
SR_Autokicker.UDPClientListReceiveSocket:settimeout(.0001) --receive timer

SR_Autokicker.UDPGroupIDReceiveSocket = socket.udp()
SR_Autokicker.UDPGroupIDReceiveSocket:setsockname("*", SR_Autokicker.GroupID_RECEIVE_PORT)
SR_Autokicker.UDPGroupIDReceiveSocket:settimeout(.0001) --receive timer

SR_Autokicker.UDPMessageSendSocket = socket.udp()

--SR_Autokicker.SRS_ClientList_JSON = [[C:\Program Files\DCS-SimpleRadio-Standalone\clients-list.json]]
SR_Autokicker.SRS_ClientList_JSON = [[C:\Program Files\DCS-SimpleRadio-Standalone\clients-list.json]]

function msgToGroup(groupID, msg, duration, clearview)
	net.log("msgToGroup()")
	net.log("msg = "..msg)
	net.log('functioncall = "trigger.action.outTextForGroup('..tostring(groupID)..', "'..msg..'", '..tostring(duration)..', '..tostring(clearview)..')"')
	clearview = clearview or false
	duration = duration or 10
	net.dostring_in('server', 'trigger.action.outTextForGroup('..tostring(groupID)..', "'..msg..'", '..tostring(duration)..', '..tostring(clearview)..')')
end

function msgToServer(msg)
	net.dostring_in('server', 'trigger.action.outText("'..msg..'", 15)')
end

SR_Autokicker.onPlayerConnect = function(playerID)
	net.log("SR_Autokicker.onPlayerConnect("..playerID..")")
	
	if playerID == net.get_server_id() then
		return
	end
	
	local player = net.get_player_info(playerID)
	player.connectTime = DCS.getRealTime()
	player.onSRS = false
	SR_Autokicker.dcsClientList[playerID] = player
	
	--net.log("playerConnected: dcsClientList = "..TableSerialization(SR_Autokicker.dcsClientList))
end

SR_Autokicker.onPlayerDisconnect = function(playerID)
	net.log("SR_Autokicker.onPlayerDisconect("..playerID..") - removing playerID from SR_Autokicker.dcsClientList")
	
	SR_Autokicker.dcsClientList[playerID] = nil
end

SR_Autokicker.lastFrameCheck = 0
SR_Autokicker.frameCheckInterval = 60 		-- run the loop every 60 seconds to check if all clients are connected to SRS
SR_Autokicker.onSimulationFrame = function()
	--net.log("onSimulationFrame() - trying to receive")
	
	-- receive client list from srs
	local clReceived = SR_Autokicker.UDPClientListReceiveSocket:receive()
	if clReceived then
		net.log("client list received")
		
	    local srClientList = SR_Autokicker.JSON:decode(clReceived)
	    if srClientList then
	    	--msgToServer("clientList: "..TableSerialization(srClientList))
	    	net.log("clientList: "..TableSerialization(srClientList))
		end
	end
	
	-- receive groupID from mission side for bigger message
	local groupIdReceived = SR_Autokicker.UDPGroupIDReceiveSocket:receive()
	if groupIdReceived then
		local groupData = SR_Autokicker.JSON:decode(groupIdReceived)
		
		net.log("groupID ("..groupData.groupID..") for '"..groupData.name.."' received")
		
		-- add groupID to dcsClientData
		for playerID, player in pairs(SR_Autokicker.dcsClientList) do
			if player.name == groupData.name then
				net.log("player found in clientlist")
				player.groupID = groupData.groupID
			end
		end
	end
	
	-- check client-status every minute, and only if we have fresh client-data from SRS
	if DCS.getModelTime() > 1 and (DCS.getRealTime() - SR_Autokicker.lastFrameCheck) > SR_Autokicker.frameCheckInterval then
		SR_Autokicker.lastFrameCheck = DCS.getRealTime()
		
		net.log("loading clientlist from SRS")
		
		-- since we dont receive UDP clientlist yet, load the json file from SRS Root
		local clientListJSON = SR_Autokicker.loadFile(SR_Autokicker.SRS_ClientList_JSON)
		if clientListJSON then
			SR_Autokicker.srsClientList = SR_Autokicker.JSON:decode(clientListJSON)
			net.log("there are "..#SR_Autokicker.srsClientList.." players connected")
			
			--net.log("clientList = "..TableSerialization(SR_Autokicker.srsClientList))
			
			local radioList = {}
			
			-- loop through all players and check if they are on SRS, and warn those who are not
			for id, player in pairs(SR_Autokicker.dcsClientList) do
				player.onSRS = false
				
				-- check if player is on SRS:
				--net.log("SR_Autokicker.srsClientList = "..TableSerialization(SR_Autokicker.srsClientList))
				for i, srClient in ipairs(SR_Autokicker.srsClientList) do
					if player.name == srClient.Name then
						net.log("Player '"..player.name.."' is connected to SRS - good boy!")
						player.onSRS = true
						player.connectTime = DCS.getRealTime()
						
						if srClient.RadioInfo then
							--net.log("Radio Info: "..TableSerialization(srClient.RadioInfo))
							local radioData = {}
							radioData.name = player.name
							radioData.ucid = player.ucid
							radioData.cId = player.id
							radioData.selected = srClient.RadioInfo.selected		-- index of selected radio
							radioData.radios = {}
							
							local numRadios = 0
							for i, radio in ipairs(srClient.RadioInfo.radios) do
								if numRadios <= 8 and radio.freq > 1 and not radioData.radios[radio.freq] then
									local selected = 0
									local realRadioIndex = i-1									
									if realRadioIndex == srClient.RadioInfo.selected then	-- count +1 because json counts from 0 and lua from 1
										selected = 1
									end
									
									net.log("freq = "..radio.freq..", Idx = "..realRadioIndex..", selIdx = "..srClient.RadioInfo.selected..", selected = "..selected)
									
									local radio = {
										id = i,
										modulation = radio.modulation,
										name = radio.name,
										selected = selected,
										frequency = radio.freq,
									}
									table.insert(radioData.radios, radio)
									
									numRadios = numRadios + 1
								end
							end
							
							table.insert(radioList, radioData)
						else
							net.log("no radioInfo for "..player.name..", maybe not initialized yet? skipped udp message ...")
						end
					end
				end
				
				-- player is not connected to SRS!
				if not player.onSRS then
					net.log("player '"..player.name.."' is not connected to SRS, sending warning message")
					
					-- lets check how long he is already connected
					local timeConnected = math.floor((DCS.getRealTime() - player.connectTime) / 60)  -- time connected in minutes
					local timeTillKick = SR_Autokicker.kickTime - timeConnected
					
					if timeConnected > SR_Autokicker.kickTime then
						-- user has exceeded his time without SRS, kicking
						net.log("kicking "..player.name..", he was not connected to SRS for "..timeConnected.." minutes ...")
						net.kick(id, player.name..": You have been kicked because you are not connected to Simple Radio Standalone (SRS)!\n\nSimple Radio is a very simple 3rd-Party Software by Ciribob, which enables you to use your aircrafts radio with voice!\nAll you need to do is install it, and open it. It will automatically connect to the server. Once in the game switch on your \naircrafts Radio, tune it to 251MHz AM, and you can listen and talk!\n\nSince this Server heavily relies on the Team working together, we cannot let you fly without being reachable on Radio. \nIt is fine if you dont want to talk, but we require you to listen at the very least, and respond in the chat.\n\nThank you very much for your understanding! You'll find a download link at http://ko.tawdcs.net, right below the map!")
					end
					
					local msg = "You are not connected to Simple Radio! SRS is mandatory on this server! You have "..tostring(timeTillKick).." minutes to connect to SRS, or you will be kicked"
					local bigMsg = "_______________________________________________________________________________________________________\n\n"
					
					bigMsg = bigMsg.."  You are not connected to Simple Radio Standalone (SRS)!\n"
					bigMsg = bigMsg.."  -----------------------------------------------------\n\n"
					bigMsg = bigMsg.."  In case you never heard of SRS, it is a very simple piece of software made by Ciribob \n"
					bigMsg = bigMsg.."  it brings voice-communication to your aircrafts Radio!\n\n"
					
					bigMsg = bigMsg.."  Since this Server heavily relies on Teamplay, we need you to communicate!\n"
					bigMsg = bigMsg.."  If you are not on SRS, you will have trouble keeping up with your team, \n" 
					bigMsg = bigMsg.."  thats why we decided to enforce SRS on this Server\n\n"
					
					bigMsg = bigMsg.."  SRS is very simple to use. All you need to do is install it and launch the client.\n"
					bigMsg = bigMsg.."  It should connect automatically and requires minimum setup!\n"
					bigMsg = bigMsg.."  Please connect to SRS IP 108.61.74.179, If it dont connect automatically.\n"
					bigMsg = bigMsg.."  We apologize for the inconvenience, but we are also certain you will like it!\n\n"
					
					bigMsg = bigMsg.."  please check out http://ko.tawdcs.org, you will find a download link at the bottom of that page!\n\n"
					
					bigMsg = bigMsg.."  If you do not connect to SRS within "..timeTillKick.." minutes, you will be kicked\n"
					bigMsg = bigMsg.."_______________________________________________________________________________________________________\n" 
				
					
					if player.groupID then
						--msgToGroup(player.groupID, bigMsg, 60, true)
						
						net.log("sending message via UDP")
						local message = {
							type = "message",
							groupID = player.groupID,
							msg = bigMsg,
						}
						socket.try(SR_Autokicker.UDPMessageSendSocket:sendto(SR_Autokicker.JSON:encode(message).." \n", "127.0.0.1", SR_Autokicker.MESSAGE_SEND_PORT))
					end
					
					net.send_chat_to(msg, id, net.get_server_id())
					
					player.wasWarned = true
					
				-- send a nice thankyou message if the player has been warned prior to connection
				elseif player.wasWarned then
					local msg = "Thank you for using Simple Radio!"
					
					if player.groupID then
						msgToGroup(player.groupID, msg, 15, false)
					end
					
					net.send_chat_to(msg, id, net.get_server_id())
					
					player.wasWarned = false
				end
			end
			
			local srsPlayerData = {
				type = "srsPlayerData",
				data = radioList,
			}
			socket.try(SR_Autokicker.UDPMessageSendSocket:sendto(SR_Autokicker.JSON:encode(srsPlayerData).." \n", "127.0.0.1", SR_Autokicker.MESSAGE_SEND_PORT))
			--net.log("SR_Autokicker.dcsClientList = "..TableSerialization(SR_Autokicker.dcsClientList))
		end
	end
end

function SR_Autokicker.loadFile(filename)
	local f = io.open(filename, "rb")
	local data
	
	if f then
		data = f:read("*all")
	    f:close()
		f = nil
	else
		net.log("could not load "..filename)
	end
    
    if data then 
		net.log("successfully loaded: "..filename)
	else
		net.log("could not load: "..filename)
	end
	
	return data
end

function TableSerialization(t, i)	 --function to turn a table into a string (works to transmutate strings, numbers and sub-tables)
	i = i or 0
	
	if not t then return "nil" end
	
	local text = "{\n"
	local tab = ""
	for n = 1, i + 1 do	 --	controls the indent for the current text line
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
	for n = 1, i do		--indent for closing bracket is one less then previous text line
		tab = tab .. "\t"
	end
	if i == 0 then
		text = text .. tab .. "}\n" --the last bracket should not be followed by an comma
	else
		text = text .. tab .. "},\n"	 --all brackets with indent higher than 0 are followed by a comma
	end
	return text
end

DCS.setUserCallbacks(SR_Autokicker)
net.log("SRS Autokicker initialized")
--net.dostring_in('server', 'trigger.action.outText("'..tostring(DCS.getModelTime())..'", 15)')