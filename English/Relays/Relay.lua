-- VARIABLES DECLARATION
	-- Globals
		local RelayVersion	=	"2.0"	    -- Current program version
		local RelayName     =	"Fuel"	-- Relay name
		
	-- Network
		local LocalID			=	os.getComputerID()	-- Relay ID
		local ServerID			=	11					-- Relay ID
		local ModemSide			=	"right"				-- Modem side
		local ServerConnected	=	false				-- Server reachable
		local PixelLink 		=	require("PixelLink")

    -- Chest(s)
        local Chest = {
            ChestSide     = "", -- Side of the chest
            SlotQty       = 0,  -- Slots in the chest
            ChestSize     = 0,  -- Total chest size
            ChestFilling  = 0,  -- Filling chest (%)
            ChestItemQty  = 0   -- Item quantity in chest
        }

-- FUNCTION
    -- Chest filling percentage calculation
        local function ChestFillingPercentage (Chest)
            Chest.SlotQty = peripheral.call(Chest.ChestSide, "size")
            Chest.ChestSize = SlotQty * 64
            Chest.ChestItemQty = 0

            for i = 1, SlotQty do
                local item = peripheral.call(Chest.ChestSide, "getItemDetail", i)
                if item then
                    Chest.ChestsItemQty = Chest.ChestsItemQty + item.count

                end

            end

            Chest.ChestFilling = (Chest.ChestItemQty / Chest.ChestSize) * 100

        end

-- PIXELLINK
    -- Server connection
        function ConnectToServer()
            local payload = {}
            ServerConnected = PixelLink.request("connect", "relay", ServerID, payload)
            if ServerConnected then print("Server connected") else print("Server disconnected") end

        end

    -- Sending status to server
        function StatusToServer(Chest)
            local payload = {
                relayName   = RelayName,
                relayID     = LocalID,
                inventory   = {
                    chestCapacity = Chest.ChestSize
                    chestItemsQty = Chest.ChestsItemQty
                    chestFilling  = Chest.ChestFilling
                    },
                }
            
            PixelLink.send("status", "relay", ServerID, payload)

        end

-- PROGRAM
    -- Displaying relay version and openning RedNet communication
        print("Welcome on the relay.")
        print("Relay version : "..RelayVersion..".")
        print("This relay requires PixeLink module.")
        if PixelLink then
            print("PixelLink present, relay can start.")

        else
            print("PixelLink missing, unable to start the relay. Install PixelLink module, then reboot the relay.")
            os.sleep(2)
            return

        end
        
        print("Starting relay...")
        os.sleep(2)

        print("Starting secured connection...")
        rednet.open(ModemSide)
        os.sleep(2)

    -- Main loop
        while true do
            -- Sending server connection request
            ConnectToServer()

            -- Refreshing chest filling
            ChestFillingPercentage(Chest)

            -- If server is connected, sending a status message
            if ServerConnected then
                print("Server connected, sending relay informations.")
                StatusToServer(Chest)

            else
                print("Server not reachable, retry in 10s.")

            end

            -- Waiting for 10s before retesting server connection and sending a status message
            os.sleep(10)

        end
