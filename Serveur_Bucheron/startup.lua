-- DECLARATION DES VARIABLES
	-- Globales	
		local ServerVersion = "4.0a03"
		local TurtleVersion = "4.0a02"
		local METIER  		= "Serveur"
		local Serveur 		= require("Serveur")
		local PixelLink 	= require("PixelLink")

    -- IDs et réseau
        local LocalID                   = os.getComputerID()    -- ID du serveur
        local TurtleID                  = 16                    -- ID de la turtle
        local FuelRelayID               = 0                     -- ID du relais carburant
        local HarvestRelayID            = 17                    -- ID du relais bois (à compléter si utilisé)
        local ModemSide                 = "back"                -- Côté du modem RedNet
        local TurtleConnected           = false                 -- Turtle connectée
        local TurtleAuthorized          = false                 -- Turtle autorisée à récolter
        local FuelRelayConnected        = false                 -- Relais carburant connecté
        local HarvestRelayConnected     = false                 -- Relais récoltes connecté
        local MasterServerIsPresent     = false                 -- Serveur principal présent sur l'installation
        local MasterServerID            = 0                     -- ID du serveur principal, si présent sur l'installation

        -- Timeout de connexion
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


    -- Infos turtle
        local TurtleLastPosition    = {0, 0, 0} -- Dernière position connue de la turtle (x,y,z)
        local TurtleLastOrientation = 0         -- Dernière orientation connue de la turtle (1 = Nord / 2 = Sud / 3 = Est / 4 = Ouest)
        local LastOrientationString = ""        -- Dernière orientation connue de la turtle (convertie en string)
        local HarvestCycle          = 0         -- Nombre de cycles de récolte
        local CurrentFuelLevel      = 0         -- Niveau de carburant actuel de la turtle
        local CurrentInventoryLevel = {0, 0}    -- Niveau de l'inventaire de la turtle (matière de base, matière récoltée - extensible)

    -- Infos relais
        local FuelChestFillingLevel     = 0 -- Niveau de remplissage du coffre à carburant
        local HarvestChestFillingLevel  = 0 -- Niveau de remplissage du coffre de récoltes

    -- Ecran & commandes
        local ScreenSide           = "left"                      -- Position de l'écran
        local RedstoneInputSide    = "bottom"                    -- Position de l'entrée TOR
        local HMI                  = peripheral.wrap(ScreenSide) -- Connexion de l'écran

--PROGRAMME
	-- Liaison entre Serveur et PixelLink
		PixelLink.setServeur(Serveur)
		Serveur.setPixelLink(PixelLink)

	-- Affichage de la version sur la console et ouverture de la connexion à RedNet
		HMI.setBackgroundColor(colors.black)
		HMI.clear()
		print("Bienvenue sur le serveur Bucheron.")
		print("Version serveur : "..ServerVersion..".")
		print("Ce serveur nécessite un module PixeLink.")
		if PixelLink then
			print("PixelLink présent, le serveur peut démarrer")

		else
			print("PixelLink introuvable, le serveur ne peut pas démarrer. Installez le module PixelLink, puis redémarrez via Ctrl + R.")
			os.sleep(2)
			return

		end
		
		print("Démarrage serveur en cours...")
		os.sleep(2)

		print("Démarrage de la connexion sécurisée...")
		rednet.open(ModemSide)
		os.sleep(2)

		print("Démarrage écran...")
		HMI.setCursorPos(1,1)
		HMI.write("Démarrage écran en cours...")
		os.sleep(2)
		Serveur.displayHMI()
		os.sleep(2)

	-- Vérification si besoin de se connecter au serveur principal
		if MasterServerIsPresent then
			print("Connexion au serveur principal en cours...")
			os.sleep(2)
			local payload = { }
			local ServerConnected = PixelLink.request("connect", "server", MasterServerID, payload)
			if ServerConnected then print("Serveur principal connecté avec succès!") else print("Serveur principal non atteignable.") end
			
		end

    -- Boucle principale
        while true do
            local receivedDatas, Datas = PixelLink.receive("server", 2)  -- On attend 2s max entre checks

            if receivedDatas then
                Serveur.updateLastSeen(Datas.srcID)
				print("Message "..Datas.msgID.." reçu. Traitement terminé.")

            end

            -- Vérifie TimeOuts de chaque entité
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
