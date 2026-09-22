-- VARIABLE DECLARATION
	-- Globals
		local Job     		= "Server"
		local Server 		= require("Server")
		local PixelLink 	= require("PixelLink")

    -- IDs and network
        local ModemSide                 = "back"                -- RedNet modem side
        local MasterServerIsPresent     = false                 -- Main server present in the installation
        local MasterServerID            = 0                     -- Main server ID, if present

    -- Screen & controls
        local ScreenSide           = "left"                      -- Screen position
        local HMI                  = peripheral.wrap(ScreenSide) -- Screen connection (startup messages only,
                                                                   -- the live display is then handled by Server.displayHMI())

-- PROGRAM
	-- Link between Server and PixelLink
		PixelLink.setServer(Server)
		Server.setPixelLink(PixelLink)

	-- Display the version in the console and open the RedNet connection
	-- Versions come only from Server.lua (Server.Version): it's the single source of truth,
	-- shown both here and on screen by Server.displayHMI().
		HMI.setBackgroundColor(colors.black)
		HMI.clear()
		print("Welcome to the Lumberjack Server.")
		print("Server version: "..Server.Version.server..".")
		print("This server requires a PixelLink module.")
		if PixelLink then
			print("PixelLink present, the server can start")

		else
			print("PixelLink not found, the server cannot start. Install the PixelLink module, then restart with Ctrl + R.")
			os.sleep(2)
			return

		end

		print("Starting the server...")
		os.sleep(2)

		print("Starting the secure connection...")
		rednet.open(ModemSide)
		os.sleep(2)

		print("Starting the screen...")
		HMI.setCursorPos(1,1)
		HMI.write("Starting the screen...")
		os.sleep(2)
		Server.displayHMI()
		os.sleep(2)

	-- Check whether a connection to a main server is needed
		if MasterServerIsPresent then
			print("Connecting to the main server...")
			os.sleep(2)
			local connected = Server.connectToMasterServer(MasterServerID)
			if connected then print("Main server successfully connected!") else print("Main server unreachable.") end

		end

    -- Network loop: receives PixelLink messages and periodically refreshes the HMI
        local function NetworkLoop()
            while true do
                local receivedDatas, Datas = PixelLink.receive("server", 2)  -- Wait up to 2s between checks

                if receivedDatas then
                    Server.updateLastSeen(Datas.srcID)
					print("Message "..Datas.msgID.." received. Processing complete.")

                end

                -- Check the timeouts for each entity (state managed and displayed by the Server module)
                Server.checkTimeouts()

                Server.displayHMI()

            end
        end

    -- Touch loop: listens for screen taps and triggers the matching command.
    -- NOTE: "side" is the network identifier used to reach the screen (ScreenSide, since it's wired
    -- directly to a side of the computer). If it's connected through a wired modem, replace the
    -- comparison below with the monitor's network name (peripheral.getName(HMI) in Server.lua).
        local function TouchLoop()
            while true do
                local event, side, x, y = os.pullEvent("monitor_touch")
                if side == ScreenSide then
                    Server.handleTouch(x, y)
                end
            end
        end

    -- Both loops run in parallel: the network reception must never block screen touches
        parallel.waitForAny(NetworkLoop, TouchLoop)
