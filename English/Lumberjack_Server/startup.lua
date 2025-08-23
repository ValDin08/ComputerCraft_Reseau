-- VARIABLE DECLARATION
	-- Globals	
		local ServerVersion = "4.0a03"
		local TurtleVersion = "4.0a02"
		local Job     		= "Server"
		local Server 		= require("Server")
		local PixelLink 	= require("PixelLink")

    -- IDs and network
        local LocalID                   = os.getComputerID()    -- Server ID
        local TurtleID                  = 16                    -- Turtle ID
        local FuelRelayID               = 0                     -- Fuel relay ID
        local HarvestRelayID            = 17                    -- Wood relay ID (to be completed if used)
        local ModemSide                 = "back"                -- Side of the RedNet modem
        local TurtleConnected           = false                 -- Turtle connected
        local TurtleAuthorized          = false                 -- Turtle authorized to harvest
        local FuelRelayConnected        = false                 -- Fuel relay connected
        local HarvestRelayConnected     = false                 -- Harvest relay connected
        local MasterServerIsPresent     = false                 -- Main server present in the installation
        local MasterServerID            = 0                     -- Main server ID, if present in the installation

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
        local HarvestCycle          = 0         -- Number of harvest cycles
        local CurrentFuelLevel      = 0         -- Current fuel level of the turtle
        local CurrentInventoryLevel = {0, 0}    -- Turtle inventory level (raw material, harvested material - extensible)

    -- Relay info
        local FuelChestFillingLevel     = 0 -- Fuel chest filling level
        local HarvestChestFillingLevel  = 0 -- Harvest chest filling level

    -- Screen & controls
        local ScreenSide           = "left"                      -- Screen position
        local RedstoneInputSide    = "bottom"                    -- TOR input position
        local HMI                  = peripheral.wrap(ScreenSide) -- Screen connection

-- PROGRAM
	-- Link between Server and PixelLink
		PixelLink.setServeur(Serveur)
		Serveur.setPixelLink(PixelLink)

	-- Display version in the console and open RedNet connection
		HMI.setBackgroundColor(colors.black)
		HMI.clear()
		print("Welcome to the Lumberjack Server.")
		print("Server version: "..ServerVersion..".")
		print("This server requires a PixelLink module.")
		if PixelLink then
			print("PixelLink present, server can start")

		else
			print("PixelLink not found, server cannot start. Install PixelLink module, then restart with Ctrl + R.")
			os.sleep(2)
			return

		end
		
		print("Starting server...")
		os.sleep(2)

		print("Starting secure connection...")
		rednet.open(ModemSide)
		os.sleep(2)

		print("Starting screen...")
		HMI.setCursorPos(1,1)
		HMI.write("Starting screen...")
		os.sleep(2)
		Serveur.displayHMI()
		os.sleep(2)

	-- Check if connection to the main server is needed
		if MasterServerIsPresent then
			print("Connecting to the main server...")
			os.sleep(2)
			local payload = { }
			local ServerConnected = PixelLink.request("connect", "server", MasterServerID, payload)
			if ServerConnected then print("Main server successfully connected!") else print("Main server unreachable.") end
			
		end

    -- Main loop
        while true do
            local receivedDatas, Datas = PixelLink.receive("server", 2)  -- Wait max 2s between checks

            if receivedDatas then
                Serveur.updateLastSeen(Datas.srcID)
				print("Message "..Datas.msgID.." received. Processing done.")

            end

            -- Check timeouts for each entity
            local now = os.clock()
            if now - LastSeen.turtle > TimeOuts.turtle then
                TurtleConnected = false

            else
                TurtleConnected = true

            end

            if now - LastSeen.fuelRelay > TimeOuts.fuelRelay then
                FuelRelayConnected = false

            else
                FuelRelayConnected = true

            end

            if now - LastSeen.harvestRelay > TimeOuts.harvestRelay then
                HarvestRelayConnected = false

            else
                HarvestRelayConnected = true

            end

            Serveur.displayHMI()

        end
