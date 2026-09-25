-- DECLARATION DES VARIABLES
	-- Globales
		local RelayVersion	=	"2.1"	    -- Version actuelle du programme

		-- Configuration de cette instance, passée en argument depuis startup.lua
		-- (shell.run("Relais", hostname, nom_affiché, côté_du_coffre)) : le programme reste identique
		-- pour tous les relais, seule cette instanciation change (carburant, buches, etc.)
		local RelayHostname, RelayName, ChestSide = ...
		RelayName = RelayName or "Relais"		-- Nom affiché (logs/console)
		ChestSide = ChestSide or "front"		-- Côté où se situe le coffre surveillé

	-- Réseau
		local LocalID			=	os.getComputerID()	-- ID du relais
		local ServerID			=	nil					-- ID du serveur, résolu dynamiquement au démarrage (cf PROGRAMME)
		local ServerHostname	=	"bucheron_server"	-- Nom de service du serveur sur le réseau PixelLink
		local ModemSide			=	"right"				-- Côté du modem sur le relais
		local ServerConnected	=	false				-- Serveur atteignable et connecté au relais
		local PixelLink 		=	require("PixelLink")

    -- Coffre(s)
        local Chest = {
            ChestSide     = ChestSide, -- Côté où se situe le coffre
            SlotQty       = 0,  -- Nombre de slots dans le coffre
            ChestSize     = 0,  -- Taille totale du coffre
            ChestFilling  = 0,  -- Remplissage du coffre (%)
            ChestItemQty  = 0   -- Nombre d'items dans le coffre
        }

-- FONCTIONS
    -- Calcul du pourcentage de remplissage du coffre. La capacité réelle de chaque slot occupé vient
    -- de item.maxCount (taille de stack propre à CET item), pas d'une hypothèse fixe à 64 — un item
    -- qui ne stack pas à 64 (ou un coffre moddé au comportement différent) fausserait sinon le calcul.
    -- Pour un slot vide, on ne sait pas encore ce qui ira dedans : 64 reste l'hypothèse par défaut.
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
                    chestCapacity = Chest.ChestSize,
                    chestItemsQty = Chest.ChestItemQty,
                    chestFilling  = Chest.ChestFilling
                    },
                }

            PixelLink.send("status", "relay", ServerID, payload)

        end

-- PROGRAMME
    -- Affichage de la version sur la console et ouverture de la connexion à RedNet
        print("Bienvenue sur votre relais '"..RelayName.."'.")
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

        -- Résolution du serveur par nom plutôt qu'un ID codé en dur
        print("Résolution du serveur '"..ServerHostname.."'...")
        while not ServerID do
            ServerID = PixelLink.resolve(ServerHostname)
            if not ServerID then
                print("Serveur '"..ServerHostname.."' introuvable, nouvelle tentative dans 5s.")
                os.sleep(5)
            end
        end
        print("Serveur résolu : ID #"..ServerID)

        -- Annonce de ce relais sous son propre nom, pour que le serveur puisse le trouver
        if RelayHostname then
            print("Annonce du relais sous le nom '"..RelayHostname.."'...")
            PixelLink.host(RelayHostname)
        else
            print("Aucun nom d'annonce fourni (argument manquant dans startup.lua) : ce relais ne sera pas découvrable par nom.")
        end

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
