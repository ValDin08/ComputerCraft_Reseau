local PixelLink = {}
local serverRef = nil

local lastMessageID = 0

-- FUNCTIONS
    -- Message traceability
    local function nextMessageID()
        lastMessageID = lastMessageID + 1
        return lastMessageID
    end

	-- Enabling PixelLink for the server
		function PixelLink.setServer(ref)
			serverRef = ref
		end

    -- Message sending functions
        -- Simple send (fire and forget)
            function PixelLink.send(msgType, srcType, dstID, payload, replyTo)
				print("Simple send in progress...")
                local message = {
                    msgID = nextMessageID(),
                    msgType = msgType,
                    srcType = srcType,
                    srcID   = os.getComputerID(),
                    dstID   = dstID,
                    ts      = os.epoch("utc"),
                    payload = payload,
                    replyTo = replyTo -- msgID of the message being replied to, if any
                }
                    if dstID then
                        rednet.send(dstID, message) -- Send in Unicast

                    else
                        rednet.broadcast(message) -- Send in Broadcast
                    end

            end

        -- Send and wait for a reply
            function PixelLink.request(msgType, srcType, dstID, payload, timeout)
				print("Sending a request...")
                local message = {
                    msgID = nextMessageID(),
                    msgType = msgType,
                    srcType = srcType,
                    srcID   = os.getComputerID(),
                    dstID   = dstID,
                    ts      = os.epoch("utc"),
                    payload = payload
                }
                -- Send the request
                rednet.send(dstID, message)

                -- Wait for a reply for a given time (5 seconds by default), ignoring any message that
                -- doesn't match THIS request (another sender, or a reply to a different request),
                -- without giving up the wait before the timeout actually elapses
                local t = timeout or 5
                local deadline = os.clock() + t

                while os.clock() < deadline do
                    local id, receivedMessage = rednet.receive(deadline - os.clock())

                    if id == nil then
                        break -- Timeout elapsed, no valid reply received
                    end

                    -- Check that the reply really comes from the right source and answers this request
                    if id == dstID and type(receivedMessage) == "table" and receivedMessage.replyTo == message.msgID then
                        -- Depending on the reply type
                        if receivedMessage.msgType == "auth" then -- Authorization request
                            return true, receivedMessage.payload

                        elseif receivedMessage.msgType == "command" then -- Command request
                            return true, receivedMessage.payload

                        elseif receivedMessage.msgType == "connect" then -- Connection request
                            return true

                        else -- Unknown type
                            return false, receivedMessage

                        end
                    end
                    -- Otherwise: message unrelated to this request, keep waiting for the remaining time
                end

                -- No valid reply received before the timeout expired
                return false, nil

            end


    -- Message receiving functions
        function PixelLink.receive(srcType, timeout)
            -- Wait for a message for a given time (30 seconds by default)
			print("Waiting for message...")
            local t = timeout or 30
            local id, receivedMessage = rednet.receive(t) -- Wait for a message
            if type(receivedMessage) == "table" then -- Check that the received message is indeed a table
                if receivedMessage.msgType == "connect" then -- Connection request
                    serverRef.updateHMI(receivedMessage) -- Update the HMI and server data
                    local payload = {}
                    PixelLink.send("connect", srcType, id, payload, receivedMessage.msgID) -- Send the connection reply
                    return true, receivedMessage

                elseif receivedMessage.msgType == "auth" then -- Work authorization request
                    local authorization = serverRef.authorization()
                    -- The pending command (touchscreen button) travels here: it's the only channel
                    -- through which the server can reach the turtle, which always polls first.
                    local payload = {authorization = authorization, command = serverRef.PendingCommand}
                    PixelLink.send("auth", srcType, id, payload, receivedMessage.msgID) -- Send the work authorization reply
                    return true, receivedMessage

                elseif receivedMessage.msgType == "status" then -- Status received
                    serverRef.updateHMI(receivedMessage) -- Update the HMI and server data
                    return true, receivedMessage

                else
                    return false

                end

            end

        end

return PixelLink
