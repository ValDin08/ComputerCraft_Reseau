-- VARIABLE DECLARATION
    -- Globals
		local ServerVersion = "4.0b01"
		local TurtleVersion = "4.0a03"
		local Job   		= "Server"
		local PixelLinkRef  = nil

    -- IDs and network
        local Serveur                   = {}
        local LocalID                   = os.getComputerID()    -- Server ID
        local TurtleID                  = 16                    -- Turtle ID
        local FuelRelayID               = 0                     -- Fuel relay ID
        local HarvestRelayID            = 17                    -- Wood relay ID (to be completed if used)
        local ModemSide                 = "back"                -- Side of the RedNet modem
        local TurtleConnected           = false                 -- Turtle connected
        local TurtleAuthorized          = false                 -- Turtle authorized to work
        local FuelRelayConnected        = false                 -- Fuel relay connected
        local HarvestRelayConnected     = false                 -- Harvest relay connected
        local MasterServerIsPresent     = false                 -- Main server present in the installation
        local MasterServerID            = 0                     -- Main server ID, if present

        -- Connection timeouts
            local TimeOuts = {
                turtle      = 30,
                fuelRelay   = 60,
                harvestRelay= 60
            }

            local LastSeen = {
                turtle      = 0,
                fuelRelay   = 0,
                harvestRelay= 0
            }


    -- Turtle info
        local TurtleLastPosition    = {0, 0, 0} -- Last known turtle position (x,y,z)
        local TurtleLastOrientation = 0         -- Last known turtle orientation (1 = North / 2 = South / 3 = East / 4 = West)
        local LastOrientationString = ""        -- Last known turtle orientation (converted to string)
        local HarvestCycle          = 0         -- Number of harvesting cycles
        local CurrentFuelLevel      = 0         -- Current turtle fuel level
        local CurrentInventoryLevel = {0, 0}    -- Turtle inventory level (raw material, harvested material - extensible)

    -- Relay info
        local FuelChestFillingLevel     = 0 -- Fuel chest filling level
        local HarvestChestFillingLevel  = 0 -- Harvest chest filling level

    -- Screen & controls
        local ScreenSide           = "left"                      -- Screen position
        local RedstoneInputSide    = "bottom"                    -- TOR input position
        local HMI                  = peripheral.wrap(ScreenSide) -- Screen connection


-- FUNCTIONS
	-- Connect to a server
		function Serveur.ConnectToServer()
            local payload = {}
            ServerConnected = PixelLink.request("connect", "server", ServerID, payload)
            if ServerConnected then print("Main server connected") else print("Main server disconnected") end

        end

	-- PixelLink reference setup for server
		function Serveur.setPixelLink(ref)
			PixelLinkRef = ref
			
		end

    -- Convert orientation ID into a usable string
        local function orientationToString(orientation)
            if orientation == 1 then return "North"
            elseif orientation == 2 then return "South"
            elseif orientation == 3 then return "East"
            elseif orientation == 4 then return "West"
            else return "Unknown" end
        end

    -- Display relay connection status (adaptable depending on number of relays)
        local function printRelayStatus()
            print("Relay Status: Fuel ["..tostring(FuelRelayConnected).."] / Wood ["..tostring(HarvestRelayConnected).."]")

        end

    -- Authorization to start the turtle
        function Serveur.authorization()
            return (HarvestChestFillingLevel < 95 and not rs.getInput(RedstoneInputSide))
        
        end

    -- Utility function to refresh LastSeen according to received msg
        function Serveur.updateLastSeen(srcID)
            if srcID == TurtleID then 
                LastSeen.turtle = os.clock()

            elseif srcID == FuelRelayID then                 
                LastSeen.fuelRelay = os.clock()

            elseif srcID == HarvestRelayID then 
                LastSeen.harvestRelay = os.clock()

            end

        end

    -- Manage display on screen
        function Serveur.displayHMI()
            -- Clear screen
                HMI.clear() 

            -- Display version information
                HMI.setCursorPos(1,1) 
                HMI.setTextScale(0.5)
                HMI.setBackgroundColor(colors.black)
                HMI.write("Server: "..ServerVersion.." / Turtle: "..TurtleVersion)

            -- Display Turtle connection state
                HMI.setCursorPos(1,2)
                HMI.write("Turtle connected: ")

                if TurtleConnected then 
                    HMI.setBackgroundColor(colors.green) HMI.write("YES")
                    
                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NO") 

                end

            -- Display Turtle work authorization
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,3)
                HMI.write("Turtle authorized to work: ")

                if TurtleAuthorized then 
                    HMI.setBackgroundColor(colors.green) HMI.write("YES")

                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NO") 

                end

            -- Display Turtle information
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,4)
                HMI.write("Turtle position: "..TurtleLastPosition[1]..", "..TurtleLastPosition[2]..", "..TurtleLastPosition[3])
                HMI.setCursorPos(1,5)
                HMI.write("Heading: "..LastOrientationString)
                HMI.setCursorPos(1,6)
                HMI.write("Fuel left = "..CurrentFuelLevel)
                HMI.setCursorPos(1,7)
                HMI.write("Trees cut: "..HarvestCycle)

            -- Display fuel relay status
                HMI.setCursorPos(1,8)
                HMI.write("Fuel relay: ")
                if FuelRelayConnected then 
                    HMI.setBackgroundColor(colors.green) HMI.write("YES") 

                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NO") 

                end

            -- Display harvest relay status
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,9)
                HMI.write("Wood relay: ")
                if HarvestRelayConnected then 
                    HMI.setBackgroundColor(colors.green) HMI.write("YES") 
                    
                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NO") 

                end

            -- Display harvest chest filling level
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,10)
                if HarvestChestFillingLevel > 50 and HarvestChestFillingLevel < 85 then 
                    HMI.setBackgroundColor(colors.yellow)

                elseif HarvestChestFillingLevel >= 85 then 
                    HMI.setBackgroundColor(colors.red)

                elseif HarvestChestFillingLevel <=50 then 
                    HMI.setBackgroundColor(colors.green) 

                end

                HMI.write("Wood chest = "..HarvestChestFillingLevel.."%")

            -- Display fuel chest filling level
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,11)
                if FuelChestFillingLevel >= 10 and FuelChestFillingLevel < 45 then 
                    HMI.setBackgroundColor(colors.yellow)

                elseif FuelChestFillingLevel < 10 then 
                    HMI.setBackgroundColor(colors.red)

                elseif FuelChestFillingLevel >= 45 then 
                    HMI.setBackgroundColor(colors.green) 

                end

                HMI.write("Fuel chest = "..FuelChestFillingLevel.."%")
                HMI.setBackgroundColor(colors.black)
    
        end

    -- Refresh displayed variables
        function Serveur.updateHMI(receivedMessage)
            if receivedMessage.msgType == "connect" then -- Connection request received
                if receivedMessage.srcID == TurtleID then -- Turtle connection
				    print("Connection request received from a Turtle")
                    TurtleConnected = true

                elseif receivedMessage.srcID == FuelRelayID then -- Fuel relay connection
				    print("Connection request received from fuel relay")
                    FuelRelayConnected = true

                elseif receivedMessage.srcID == HarvestRelayID then -- Harvest relay connection
				    print("Connection request received from harvest relay")
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

                elseif receivedMessage.srcID == FuelRelayID then
					print("Status received from fuel relay")
                    FuelRelayConnected = true
					if receivedMessage.payload and receivedMessage.payload.inventory.chestFilling then
						FuelChestFillingLevel = math.floor(receivedMessage.payload.inventory.chestFilling)
						
					end

                elseif receivedMessage.srcID == HarvestRelayID then
					print("Status received from harvest relay")
                    HarvestRelayConnected = true
					if receivedMessage.payload and receivedMessage.payload.inventory.chestFilling then
						HarvestChestFillingLevel = math.floor(receivedMessage.payload.inventory.chestFilling)
						
					end

                end
				
				TurtleAuthorized = Serveur.authorization()


                Serveur.displayHMI() -- Update HMI

            end

            return true

        end

	return Serveur
