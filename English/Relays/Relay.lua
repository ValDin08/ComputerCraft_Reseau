-- VARIABLES DECLARATION
	-- Globals
		local RelayVersion	=	"2.1"	    -- Current program version

		-- This instance's configuration, passed as arguments from startup.lua
		-- (shell.run("Relay", hostname, display_name, chest_side)): the program stays identical
		-- for every relay, only this instantiation changes (fuel, logs, etc.)
		local RelayHostname, RelayName, ChestSide = ...
		RelayName = RelayName or "Relay"		-- Display name (logs/console)
		ChestSide = ChestSide or "front"		-- Side the monitored chest is on

	-- Network
		local LocalID			=	os.getComputerID()	-- Relay ID
		local ServerID			=	nil					-- Server ID, resolved dynamically at startup (cf PROGRAM)
		local ServerHostname	=	"bucheron_server"	-- Server's service name on the PixelLink network
		local ModemSide			=	"right"				-- Modem side on the relay
		local ServerConnected	=	false				-- Server reachable and connected to the relay
		local PixelLink 		=	require("PixelLink")

    -- Chest(s)
        local Chest = {
            ChestSide     = ChestSide, -- Side the chest is on
            SlotQty       = 0,  -- Slots in the chest
            ChestSize     = 0,  -- Total chest size
            ChestFilling  = 0,  -- Chest filling level (%)
            ChestItemQty  = 0   -- Item quantity in the chest
        }

-- FUNCTIONS
    -- Chest filling percentage calculation. Each occupied slot's real capacity comes from
    -- item.maxCount (that specific item's own stack size), not a fixed 64 assumption — an item that
    -- doesn't stack to 64 (or a modded chest behaving differently) would otherwise skew the result.
    -- For an empty slot, we don't yet know what will go there: 64 remains the default assumption.
        local function ChestFillingPercentage(Chest)
            Chest.SlotQty = peripheral.call(Chest.ChestSide, "size")
            Chest.ChestItemQty = 0
            Chest.ChestSize = 0

            for i = 1, Chest.SlotQty do
                local item = peripheral.call(Chest.ChestSide, "getItemDetail", i)
                if item then
                    Chest.ChestItemQty = Chest.ChestItemQty + item.count
                    Chest.ChestSize = Chest.ChestSize + item.maxCount

                else
                    Chest.ChestSize = Chest.ChestSize + 64

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

    -- Sending status to the server
        function StatusToServer(Chest)
            local payload = {
                relayName   = RelayName,
                relayID     = LocalID,
                inventory   = {
                    chestCapacity = Chest.ChestSize,
                    chestItemsQty = Chest.ChestItemQty,
                    chestFilling  = Chest.ChestFilling
                    },
                }

            PixelLink.send("status", "relay", ServerID, payload)

        end

-- PROGRAM
    -- Displaying relay version in the console and opening the RedNet connection
        print("Welcome to your relay '"..RelayName.."'.")
        print("Relay version: "..RelayVersion..".")
        print("This relay requires a PixelLink module.")
        if PixelLink then
            print("PixelLink present, the relay can start")

        else
            print("PixelLink not found, the relay cannot start. Install the PixelLink module, then restart with Ctrl + R.")
            os.sleep(2)
            return

        end

        print("Starting the relay...")
        os.sleep(2)

        print("Starting the secure connection...")
        rednet.open(ModemSide)
        os.sleep(2)

        -- Resolve the server by name rather than a hardcoded ID
        print("Resolving server '"..ServerHostname.."'...")
        while not ServerID do
            ServerID = PixelLink.resolve(ServerHostname)
            if not ServerID then
                print("Server '"..ServerHostname.."' not found, retrying in 5s.")
                os.sleep(5)
            end
        end
        print("Server resolved: ID #"..ServerID)

        -- Announce this relay under its own name, so the server can find it
        if RelayHostname then
            print("Announcing the relay under the name '"..RelayHostname.."'...")
            PixelLink.host(RelayHostname)
        else
            print("No announcement name provided (missing argument in startup.lua): this relay won't be discoverable by name.")
        end

    -- Main loop
        while true do
            -- Sending server connection request
            ConnectToServer()

            -- Refreshing the chest count
            ChestFillingPercentage(Chest)

            -- If the server is connected, sending a status message
            if ServerConnected then
                print("Server connected, sending relay information.")
                StatusToServer(Chest)

            else
                print("Server not reachable, retrying in 10s.")

            end

            -- Waiting 10s before re-checking server connection and sending a status message
            os.sleep(10)

        end
