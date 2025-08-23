local PixelLink = {}
local serverRef = nil

local lastMessageID = 0

-- FUNCTIONS
    -- Messages traceability
    local function nextMessageID()
        lastMessageID = lastMessageID + 1
        return lastMessageID
    end
	
	-- Starting PixelLink server mode
		function PixelLink.setServer(ref)
			serverRef = ref
		end

    -- Sending messages
        -- Simple send (fire and forget)
            function PixelLink.send(msgType, srcType, dstID, payload)
				print("Simple sending in progress...")
                local message = {
                    msgID = nextMessageID(),
                    msgType = msgType,
                    srcType = srcType,
                    srcID   = os.getComputerID(),
                    dstID   = dstID,
                    ts      = os.epoch("utc"),
                    payload = payload
                }
                    if dstID then                        
                        rednet.send(dstID, message) -- Envoi en Simplecast

                    else
                        rednet.broadcast(message) -- Envoi en Broadcast
                    end

            end

        -- Send with answer expectation
            function PixelLink.request(msgType, srcType, dstID, payload, timeout)
				print("Request sending in progess...")
                local message = {
                    msgID = nextMessageID(),
                    msgType = msgType,
                    srcType = srcType,
                    srcID   = os.getComputerID(),
                    dstID   = dstID,
                    ts      = os.epoch("utc"),
                    payload = payload
                }
                -- Request sending
                rednet.send(dstID, message)

                -- Waiting for answer (5 seconds by default)
                local t = timeout or 5
                local id, receivedMessage = rednet.receive(t)

                -- Check if an answer has been received from the correct source
                if id == dstID and type(receivedMessage) == "table" then -- Check if the received message is a table
                    -- According to the received message
                    if receivedMessage.msgType == "auth" then -- Authorization request
                        return true, receivedMessage.payload

                    elseif receivedMessage.msgType == "command" then -- Command request
                        return true, receivedMessage.payload

                    elseif receivedMessage.msgType == "connect" then -- Connection request
                        return true

                    else -- Unknown type
                        return false, receivedMessage

                    end

                else
                    -- No answer or wrong ID
                    return false, nil

                end

            end


    -- Receiving messages
        function PixelLink.receive(srcType, timeout)
            -- Waiting for messages (30 seconds by default)
			print("Waiting for message...")
            local t = timeout or 30
            local id, receivedMessage = rednet.receive(t) -- Waiting a message
            if type(receivedMessage) == "table" then -- Check if message is a table
                if receivedMessage.msgType == "connect" then -- Connection request
                    serverRef.updateHMI(receivedMessage) -- Updating HMI and server datas
                    payload = {}
                    PixelLink.send("connect", srcType, id, payload) -- Envoi de la réponse de connexion
                    return true, receivedMessage

                elseif receivedMessage.msgType == "auth" then -- Work authorization request
                    local authorization = serveur_ref.authorization()
                    payload = {authorization = authorization}
                    PixelLink.send("auth", srcType, id, payload) -- Sending authorization status
                    return true, receivedMessage

                elseif receivedMessage.msgType == "status" then -- Status received
                    serverRef.updateHMI(receivedMessage) -- Updating HMI and server datas
                    return true, receivedMessage

                else
                    return false

                end

            end

        end

return PixelLink
