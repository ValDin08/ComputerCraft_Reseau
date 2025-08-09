-- DECLARATION DES VARIABLES
	-- Globales
		local RelayVersion	=	"2.0"	    -- Version actuelle du programme
		local RelayName     =	"Carburant"	-- Nom du relais
		
	-- Réseau
		local LocalID			=	os.getComputerID()	-- ID du relais
		local ServerID			=	11					-- ID du serveur
		local ModemSide			=	"right"				-- Côté du modem sur la turtle
		local ServerConnected	=	false				-- Serveur ateignable et connecté au relais
		local PixelLink 		=	require("PixelLink")

    -- Coffre(s)
        local Chest = {
            ChestSide     = "", -- Côté où se situe le coffre
            SlotQty       = 0,  -- Nombre de slots dans le coffre
            ChestSize     = 0,  -- Taille totale du coffre
            ChestFilling  = 0,  -- Remplissage du coffre (%)
            ChestItemQty  = 0   -- Nombre d'items dans le coffre
        }

-- FONCTIONS
    -- Calcul du pourcentage de remplissage du coffre
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
    -- Connexion au serveur
        function ConnectToServer()
            local payload = {}
            ServerConnected = PixelLink.request("connect", "relay", ServerID, payload)
            if ServerConnected then print("Serveur connecté") else print("Serveur déconnecté") end

        end

    -- Envoi du statut du relais
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

-- PROGRAMME
    -- Affichage de la version sur la console et ouverture de la connexion à RedNet
        print("Bienvenue sur votre relais.")
        print("Version relais : "..RelayVersion..".")
        print("Ce relais nécessite un module PixeLink.")
        if PixelLink then
            print("PixelLink présent, le relais peut démarrer")

        else
            print("PixelLink introuvable, le relais ne peut pas démarrer. Installez le module PixelLink, puis redémarrez via Ctrl + R.")
            os.sleep(2)
            return

        end
        
        print("Démarrage relais en cours...")
        os.sleep(2)

        print("Démarrage de la connexion sécurisée...")
        rednet.open(ModemSide)
        os.sleep(2)

    --Boucle principale
        while true do
            -- Envoi de la demande de connexion au serveur
            ConnectToServer()

            -- Actualisation du comptage du coffre
            ChestFillingPercentage(Chest)

            -- Si le serveur est connecté, on envoie une trame de statut
            if ServerConnected then
                print("Serveur connecté, envoi des informations du relais.")
                StatusToServer(Chest)

            else
                print("Serveur non accessible, nouvelle tentative dans 10s.")

            end

            -- Attente 10s avant de revérifier la connexion au serveur et de renvoyer un statut
            os.sleep(10)

        end
