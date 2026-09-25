-- VARIABLE DECLARATION
    -- Globals
		local ServerVersion = "5.0-alpha02"
		local TurtleVersion = "5.0-alpha02"
		local Job  			= "Server"
		local PixelLinkRef  = nil

    -- IDs and network
        local Server                     = {}
        local LocalID                   = os.getComputerID()    -- Server ID
        Server.Version                  = { server = ServerVersion, turtle = TurtleVersion } -- Single source of truth for versions, exposed to startup.lua
        local TurtleID                  = 16                    -- Turtle ID
        local FuelRelayID               = nil                   -- Fuel relay ID, resolved dynamically at startup (cf setRelayIDs / retryMissingRelays)
        local HarvestRelayID            = nil                   -- Wood relay ID, resolved dynamically at startup (cf setRelayIDs / retryMissingRelays)
        local ModemSide                 = "back"                -- RedNet modem side
        local TurtleConnected           = false                 -- Turtle connected
        local TurtleAuthorized          = false                 -- Turtle authorized to harvest
        local FuelRelayConnected        = false                 -- Fuel relay connected
        local HarvestRelayConnected     = false                 -- Harvest relay connected
        local MasterServerIsPresent     = false                 -- Main server present in the installation
        local MasterServerID            = 0                     -- Main server ID, if present in the installation

        -- Manual work authorization (replaces the old physical redstone lever). Locked by default on
        -- every server start/restart: the operator must turn it on deliberately from the screen.
        Server.ManualAuthorization = false

        -- Command pending application by the turtle (touchscreen button): {id=, type=}.
        -- Sent via the next authorization ("auth") reply, and cleared only once the turtle has
        -- acknowledged it (ackCommandId in its status) — never blindly cleared.
        Server.PendingCommand = nil

        -- Last fault reported by the turtle, displayed on screen until manually acknowledged or
        -- overwritten by a new status (same fault or a different one).
        Server.TurtleLastError = ""

        -- Connection timeouts
            local TimeOuts = {
                turtle      = 30,
                fuelRelay   = 60,
                harvestRelay= 60
            }

            -- Initialized to -math.huge (not 0) so that nothing is considered "connected" until a real
            -- message has actually been received since the server started
            local LastSeen = {
                turtle      = -math.huge,
                fuelRelay   = -math.huge,
                harvestRelay= -math.huge
            }


    -- Turtle info
        local TurtleLastPosition    = {0, 0, 0} -- Last known turtle position (x,y,z)
        local TurtleLastOrientation = 0         -- Last known turtle orientation (1 = North / 2 = South / 3 = East / 4 = West)
        local LastOrientationString = ""        -- Last known turtle orientation (converted to a string)
        local HarvestCycle          = 0         -- Number of harvest cycles
        local CurrentFuelLevel      = 0         -- Current fuel level of the turtle
        local CurrentInventoryLevel = {0, 0}    -- Turtle inventory level (raw material, harvested material - extensible)

    -- Relay info
        local FuelChestFillingLevel     = 0 -- Fuel chest filling level
        local HarvestChestFillingLevel  = 0 -- Harvest chest filling level

    -- Screen & controls
        local ScreenSide           = "left"                      -- Screen position
        local HMI                  = peripheral.wrap(ScreenSide) -- Screen connection

    -- Touchscreen buttons (clickable zones recalculated on every display, cf drawButtonGrid/handleTouch)
        local Buttons = {} -- List of {x1,y1,x2,y2,action=function()}


-- FUNCTIONS
	-- Connect to a main server (optional, cf MasterServerIsPresent in startup.lua)
		function Server.connectToMasterServer(masterServerID)
            local payload = {}
            local connected = PixelLinkRef.request("connect", "server", masterServerID, payload)
            if connected then print("Main server connected") else print("Main server disconnected") end
            return connected

        end

	-- PixelLink reference setup for the server
		function Server.setPixelLink(ref)
			PixelLinkRef = ref

		end

    -- Convert an orientation ID into a usable string
        local function orientationToString(orientation)
            if orientation == 1 then return "North"
            elseif orientation == 2 then return "South"
            elseif orientation == 3 then return "East"
            elseif orientation == 4 then return "West"
            else return "Unknown" end
        end

    -- Display relay connection status (adaptable depending on the number of relays)
        local function printRelayStatus()
            print("Relay status: Fuel ["..tostring(FuelRelayConnected).."] / Wood ["..tostring(HarvestRelayConnected).."]")

        end

    -- Authorization to start the turtle: automatic safety (wood chest) AND manual authorization given
    -- on screen (replaces the old physical redstone lever)
        function Server.authorization()
            return (HarvestChestFillingLevel < 95) and Server.ManualAuthorization

        end

    -- Resolution (and periodic retry) of relays by name. A relay that starts after the server, or
    -- gets restarted independently later, must not stay unreachable forever: without this, a single
    -- failed attempt at boot (a startup race between two separate physical computers) would leave
    -- the relay unreachable until the server itself was manually restarted. Only retries once every
    -- RelayRetryInterval seconds: rednet.lookup waits for a reply, we don't want to stall the
    -- network loop on every pass.
        local RelayRetryInterval = 30 -- seconds
        local LastRelayRetryAttempt = -math.huge

        function Server.retryMissingRelays()
            if FuelRelayID and HarvestRelayID then return end -- already resolved, nothing to do
            if PixelLinkRef == nil then return end

            local now = os.clock()
            if now - LastRelayRetryAttempt < RelayRetryInterval then return end
            LastRelayRetryAttempt = now

            if not FuelRelayID then
                FuelRelayID = PixelLinkRef.resolve("bucheron_fuel_relay")
                if FuelRelayID then print("Fuel relay found: ID #"..FuelRelayID) end
            end

            if not HarvestRelayID then
                HarvestRelayID = PixelLinkRef.resolve("bucheron_harvest_relay")
                if HarvestRelayID then print("Wood relay found: ID #"..HarvestRelayID) end
            end
        end

    -- Utility function to refresh lastSeen based on the received message
        function Server.updateLastSeen(srcID)
            if srcID == TurtleID then
                LastSeen.turtle = os.clock()

            elseif srcID == FuelRelayID then
                LastSeen.fuelRelay = os.clock()

            elseif srcID == HarvestRelayID then
                LastSeen.harvestRelay = os.clock()

            end

        end

    -- Checking connection timeouts (turtle / relays)
    -- Must be called regularly by the main loop (startup.lua): this is where, and only where, the
    -- connection state actually shown by displayHMI() lives.
        function Server.checkTimeouts()
            local now = os.clock()
            TurtleConnected       = (now - LastSeen.turtle)        <= TimeOuts.turtle
            FuelRelayConnected    = (now - LastSeen.fuelRelay)     <= TimeOuts.fuelRelay
            HarvestRelayConnected = (now - LastSeen.harvestRelay)  <= TimeOuts.harvestRelay
        end

    -- OPERATOR COMMANDS (triggered by the touchscreen buttons)
        -- Toggle manual work authorization (replaces the physical lever)
        function Server.toggleAuthorization()
            Server.ManualAuthorization = not Server.ManualAuthorization
            print("Manual authorization: "..(Server.ManualAuthorization and "ON" or "OFF"))
        end

        -- Acknowledge the last fault shown (reappears if the turtle reports it again in a later
        -- status, whether the same fault or a different one)
        function Server.acknowledgeFault()
            Server.TurtleLastError = ""
        end

        -- Queue a command for the turtle: sent via the next authorization ("auth") reply, and kept
        -- until explicitly acknowledged (ackCommandId in the turtle's status) — never blindly cleared,
        -- so a command is never silently lost.
        local function issueCommand(cmdType)
            Server.PendingCommand = { id = os.epoch("utc"), type = cmdType }
            print("Command sent to the turtle: "..cmdType)
        end

        -- Force an immediate turtle resync (reconnect + immediate status), useful if the display looks
        -- stale while the rednet link is actually still fine
        function Server.forceReconnect()
            issueCommand("resync")
        end

        -- Force a fuel restock on the turtle's next exit (never mid-tree: the turtle only checks its
        -- needs between two atomic actions)
        function Server.forceRefuel()
            issueCommand("forceRefuel")
        end

        -- Force a wood drop-off on the turtle's next exit
        function Server.forceEmpty()
            issueCommand("forceEmpty")
        end

    -- DISPLAY: small utilities
        local function writeAt(x, y, text, bg, fg)
            HMI.setBackgroundColor(bg or colors.black)
            HMI.setTextColor(fg or colors.white)
            HMI.setCursorPos(x, y)
            HMI.write(text)
        end

        -- Writes a label followed by a color-highlighted value right after it (e.g. "Turtle connected: YES").
        -- Repositions via getCursorPos() rather than the label's byte length: accented characters take
        -- several bytes in UTF-8 and would otherwise shift the value.
        local function writeLabelValue(x, y, label, value, valueColor)
            writeAt(x, y, label, colors.black, colors.white)
            local nx, ny = HMI.getCursorPos()
            writeAt(nx, ny, value, valueColor or colors.black, colors.white)
        end

        -- Writes `text` centered in [x1,x2] on line y, with background `bg` covering the whole zone.
        -- Truncates the text if it's longer than the zone: it never overflows into the neighboring cell
        -- (this is what caused the button labels to overlap).
        local function writeCentered(x1, x2, y, text, bg, fg)
            local zoneWidth = x2 - x1 + 1
            if zoneWidth < 1 then return end
            if #text > zoneWidth then text = text:sub(1, zoneWidth) end
            HMI.setBackgroundColor(bg)
            HMI.setTextColor(fg or colors.white)
            HMI.setCursorPos(x1, y)
            HMI.write(string.rep(" ", zoneWidth))
            HMI.setCursorPos(x1 + math.floor((zoneWidth - #text) / 2), y)
            HMI.write(text)
        end

        -- Simple ASCII frame (+, -, |) over the [x1,y1]-[x2,y2] zone
        local function drawBox(x1, y1, x2, y2, bg, fg)
            local width = x2 - x1 + 1
            if width < 2 or y2 < y1 then return end
            HMI.setBackgroundColor(bg or colors.black)
            HMI.setTextColor(fg or colors.white)
            HMI.setCursorPos(x1, y1)
            HMI.write("+"..string.rep("-", width - 2).."+")
            for y = y1 + 1, y2 - 1 do
                HMI.setCursorPos(x1, y)
                HMI.write("|"..string.rep(" ", width - 2).."|")
            end
            if y2 > y1 then
                HMI.setCursorPos(x1, y2)
                HMI.write("+"..string.rep("-", width - 2).."+")
            end
        end

    -- Button grid definitions, keyed by "row_col". A missing cell is drawn as reserved (empty, not
    -- clickable) — that's where future commands will be added.
        local function buttonDefs()
            return {
                ["1_1"] = { label = { Server.ManualAuthorization and "STOP" or "AUTHORIZE" },
                            color = Server.ManualAuthorization and colors.red or colors.green,
                            action = Server.toggleAuthorization },
                ["1_2"] = { label = { "RECONNECT" },
                            color = colors.blue,
                            action = Server.forceReconnect },
                ["1_3"] = { label = { "FORCE", "REFUEL" },
                            color = colors.cyan,
                            action = Server.forceRefuel },
                ["2_1"] = { label = { "ACKNOWLEDGE" },
                            color = (Server.TurtleLastError ~= "") and colors.orange or colors.gray,
                            action = Server.acknowledgeFault },
                ["2_3"] = { label = { "FORCE", "EMPTY" },
                            color = colors.brown,
                            action = Server.forceEmpty },
            }
        end

    -- Draws the touchscreen button grid (4 x 2) starting at line `gridTop`, and remembers the
    -- clickable zones. Adapts to the screen's actual width.
        local function drawButtonGrid(gridTop)
            Buttons = {}
            local width = select(1, HMI.getSize())
            local cellWidth = math.floor(width / 4)
            local defs = buttonDefs()
            local rows, cols = 2, 4

            for row = 1, rows do
                local y1 = gridTop + (row - 1) * 4
                local y2 = y1 + 4 - 1

                for col = 1, cols do
                    local x1 = (col - 1) * cellWidth + 1
                    local x2 = (col == cols) and width or (col * cellWidth)
                    local def = defs[row.."_"..col]

                    if def then
                        drawBox(x1, y1, x2, y2, colors.black, colors.white)
                        for y = y1 + 1, y2 - 1 do
                            writeCentered(x1 + 1, x2 - 1, y, "", def.color, colors.white)
                        end
                        local nLines = #def.label
                        local firstLineY = y1 + 1 + math.floor(((y2 - y1 - 1) - nLines) / 2)
                        for i, textLine in ipairs(def.label) do
                            writeCentered(x1 + 1, x2 - 1, firstLineY + i - 1, textLine, def.color, colors.white)
                        end
                        table.insert(Buttons, { x1 = x1, y1 = y1, x2 = x2, y2 = y2, action = def.action })
                    else
                        -- Reserved cell: empty frame, not clickable
                        drawBox(x1, y1, x2, y2, colors.black, colors.gray)
                        writeCentered(x1 + 1, x2 - 1, y1 + math.floor((y2 - y1) / 2), "RESERVED", colors.black, colors.gray)
                    end
                end
            end
        end

    -- Managing the on-screen display
        function Server.displayHMI()
            -- The text scale must be set BEFORE any layout calculation (HMI.getSize() depends on it)
            -- and before any drawing — otherwise the button grid is drawn at the old scale and
            -- overflows into neighboring cells.
                HMI.setTextScale(0.5)
                HMI.clear()
                HMI.setBackgroundColor(colors.black)
                HMI.setTextColor(colors.white)

                local width, height = HMI.getSize()
                local gridHeight = 2 * 4
                local gridTop    = height - gridHeight + 1

                local line = 1
                local function nextLine(extraGap)
                    line = line + 1 + (extraGap or 0)
                end

                writeAt(1, line, "Server: "..ServerVersion.." / Turtle: "..TurtleVersion); nextLine(1)

                writeLabelValue(1, line, "Turtle connected: ", TurtleConnected and "YES" or "NO",
                    TurtleConnected and colors.green or colors.red); nextLine()

                writeLabelValue(1, line, "Turtle authorized to work: ", TurtleAuthorized and "YES" or "NO",
                    TurtleAuthorized and colors.green or colors.red); nextLine(1)

                writeAt(1, line, "Turtle position: "..TurtleLastPosition[1]..", "..TurtleLastPosition[2]..", "..TurtleLastPosition[3]); nextLine()
                writeAt(1, line, "Heading: "..LastOrientationString); nextLine()
                writeAt(1, line, "Fuel left: "..CurrentFuelLevel); nextLine()
                writeAt(1, line, "Trees cut: "..HarvestCycle); nextLine(1)

                writeLabelValue(1, line, "Fuel relay: ", FuelRelayConnected and "YES" or "NO",
                    FuelRelayConnected and colors.green or colors.red); nextLine()

                writeLabelValue(1, line, "Wood relay: ", HarvestRelayConnected and "YES" or "NO",
                    HarvestRelayConnected and colors.green or colors.red); nextLine(1)

                local woodColor = colors.green
                if HarvestChestFillingLevel >= 85 then woodColor = colors.red
                elseif HarvestChestFillingLevel > 50 then woodColor = colors.yellow end
                writeAt(1, line, "Wood chest: "..HarvestChestFillingLevel.."%", colors.black, woodColor); nextLine()

                local fuelColor = colors.green
                if FuelChestFillingLevel < 10 then fuelColor = colors.red
                elseif FuelChestFillingLevel < 45 then fuelColor = colors.yellow end
                writeAt(1, line, "Fuel chest: "..FuelChestFillingLevel.."%", colors.black, fuelColor); nextLine(1)

                if Server.TurtleLastError ~= "" then
                    writeAt(1, line, "Turtle fault: "..Server.TurtleLastError, colors.red, colors.white)
                else
                    writeAt(1, line, "Turtle fault: none")
                end
                nextLine()

                if Server.PendingCommand then
                    writeAt(1, line, "Pending command: "..Server.PendingCommand.type, colors.yellow, colors.black)
                else
                    writeAt(1, line, "Pending command: none")
                end

            -- Touchscreen button grid
                drawButtonGrid(gridTop)

            HMI.setBackgroundColor(colors.black)
            HMI.setTextColor(colors.white)

        end

    -- Dispatch a touch event to the matching button (called from startup.lua)
        function Server.handleTouch(x, y)
            for _, button in ipairs(Buttons) do
                if x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2 then
                    button.action()
                    Server.displayHMI() -- Immediate visual feedback, without waiting for the next network cycle
                    return
                end
            end
        end

    -- Refreshing the displayed variables
        function Server.updateHMI(receivedMessage)
            if receivedMessage.msgType == "connect" then -- Connection message received
                if receivedMessage.srcID == TurtleID then -- Turtle connection
					print("Connection request received from a Turtle")
                    TurtleConnected = true

                elseif receivedMessage.srcID == FuelRelayID then -- Fuel relay connection
					print("Connection request received from the fuel relay")
                    FuelRelayConnected = true

                elseif receivedMessage.srcID == HarvestRelayID then -- Harvest relay connection
					print("Connection request received from the harvest relay")
                    HarvestRelayConnected = true

                end

            elseif receivedMessage.msgType == "status" then -- Status message received
                if receivedMessage.srcID == TurtleID then -- Turtle status
					print("Status received from a Turtle")
                    TurtleConnected = true
                    TurtleLastPosition = receivedMessage.payload.pos
                    TurtleLastOrientation = receivedMessage.payload.orientation
                    HarvestCycle = receivedMessage.payload.cycles
                    CurrentFuelLevel = receivedMessage.payload.fuel
                    CurrentInventoryLevel[1] = receivedMessage.payload.inventory.rawMaterial
                    CurrentInventoryLevel[2] = receivedMessage.payload.inventory.harvestedMaterial
					LastOrientationString = orientationToString(TurtleLastOrientation)

                    -- Last fault reported by the turtle (stays on screen until acknowledged)
                    if receivedMessage.payload.errors and receivedMessage.payload.errors[1] and receivedMessage.payload.errors[1] ~= "" then
                        Server.TurtleLastError = receivedMessage.payload.errors[1]
                    end

                    -- Acknowledgement of a pending command: only cleared if the turtle confirms it
                    -- processed THIS exact command (compared by id)
                    if Server.PendingCommand and receivedMessage.payload.ackCommandId == Server.PendingCommand.id then
                        print("Command '"..Server.PendingCommand.type.."' confirmed applied by the turtle")
                        Server.PendingCommand = nil
                    end

                elseif receivedMessage.srcID == FuelRelayID then
					print("Status received from the fuel relay")
                    FuelRelayConnected = true
					if receivedMessage.payload and receivedMessage.payload.inventory.chestFilling then
						FuelChestFillingLevel = math.floor(receivedMessage.payload.inventory.chestFilling)

					end

                elseif receivedMessage.srcID == HarvestRelayID then
					print("Status received from the harvest relay")
                    HarvestRelayConnected = true
					if receivedMessage.payload and receivedMessage.payload.inventory.chestFilling then
						HarvestChestFillingLevel = math.floor(receivedMessage.payload.inventory.chestFilling)

					end

                end

				TurtleAuthorized = Server.authorization()


                Server.displayHMI() -- Update the HMI

            end

            return true

        end

	return Server
