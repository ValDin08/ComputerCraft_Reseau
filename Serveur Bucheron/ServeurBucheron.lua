-- DECLARATION DES VARIABLES
    -- Globales
        local ServerVersion = "4.0a02"
        local TurtleVersion = "4.0a02"

    -- IDs et réseau
        local server                    = {}
        local LocalID                   = os.getComputerID()    -- ID du serveur
        local TurtleID                  = 16                    -- ID de la turtle
        local FuelRelayID               = 17                    -- ID du relais carburant
        local HarvestRelayID            = 0                     -- ID du relais bois (à compléter si utilisé)
        local ModemSide                 = "back"                -- Côté du modem RedNet
        local TurtleConnected           = false                 -- Turtle connectée
        local TurtleAuthorized          = false                 -- Turtle autorisée à récolter
        local FuelRelayConnected        = false                 -- Relais carburant connecté
        local HarvestRelayConnected     = false                 -- Relais récoltes connecté
        local PixelLink 		= require("PixelLink")  -- Module PixelLink nécessaire
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


-- FONCTIONS
    -- Conversion de l'ID d'orientation à un string exploitable
        local function orientationToString(orientation)
            if orientation == 1 then return "Nord"
            elseif orientation == 2 then return "Sud"
            elseif orientation == 3 then return "Est"
            elseif orientation == 4 then return "Ouest"
            else return "Inconnue" end
        end

    -- Affichage de l'état de connexion du ou des relais (à moduler en fonction du nombre de relais)
        local function printRelayStatus()
            print("Etat Relais: Carburant ["..tostring(FuelRelayConnected).."] / Bois ["..tostring(HarvestRelayConnected).."]")

        end

    -- Autorisation de démarrage de la turtle
        function server.authorization()
            return (HarvestChestFillingLevel < 95 and not rs.getInput(RedstoneInputSide))
        
        end

    -- Fonction utilitaire pour actualiser lastSeen selon le msg reçu
        local function updateLastSeen(srcID)
            if srcID == TurtleID then 
                lastSeen.turtle = os.clock()

            elseif srcID == FuelRelayID then                 
                lastSeen.fuelRelay = os.clock()

            elseif srcID == HarvestRelayID then 
                lastSeen.harvestRelay = os.clock()

            end

        end

    -- Gestion de l'affichage sur l'écran
        local function displayHMI()
            -- Nettoyage écran
                HMI.clear() 

            -- Affichage informations versions
                HMI.setCursorPos(1,1) 
                HMI.setTextScale(0.5)
                HMI.setBackgroundColor(colors.black)
                HMI.write("Serveur: "..ServerVersion.." / Turtle : "..TurtleVersion)

            -- Affichage état connexion Turtle
                HMI.setCursorPos(1,2)
                HMI.write("Turtle connectée : ")

                if TurtleConnected then 
                    HMI.setBackgroundColor(colors.green) HMI.write("OUI")
                    
                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NON") 

                end

            -- Affichage état autorisation de travail de la Turtle
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,3)
                HMI.write("Turtle autorisée à travailler : ")

                if TurtleAuthorized then 
                    HMI.setBackgroundColor(colors.green) HMI.write("OUI")

                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NON") 

                end

            -- Affichage des informations de la turtle
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,4)
                HMI.write("Position turtle : "..TurtleLastPosition[1]..", "..TurtleLastPosition[2]..", "..TurtleLastPosition[3])
                HMI.setCursorPos(1,5)
                HMI.write("Allant vers : "..LastOrientationString)
                HMI.setCursorPos(1,6)
                HMI.write("Carburant restant = "..CurrentFuelLevel)
                HMI.setCursorPos(1,7)
                HMI.write("Nombre d'arbres abattus : "..HarvestCycle)

            -- Affichage de l'état du relais carburant
                HMI.setCursorPos(1,8)
                HMI.write("Relais carburant : ")
                if FuelRelayConnected then 
                    HMI.setBackgroundColor(colors.green) HMI.write("OUI") 

                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NON") 

                end

            -- Affichage de l'état du relais récoltes
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,9)
                HMI.write("Relais bois : ")
                if HarvestRelayConnected then 
                    HMI.setBackgroundColor(colors.green) HMI.write("OUI") 
                    
                else 
                    HMI.setBackgroundColor(colors.red) HMI.write("NON") 

                end

            -- Affichage du remplissage du coffre de récoltes
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,10)
                if HarvestChestFillingLevel > 50 and HarvestChestFillingLevel < 85 then 
                    HMI.setBackgroundColor(colors.yellow)

                elseif HarvestChestFillingLevel >= 85 then 
                    HMI.setBackgroundColor(colors.red)

                elseif HarvestChestFillingLevel <=50 then 
                    HMI.setBackgroundColor(colors.green) 

                end

                HMI.write("Coffre buches = "..HarvestChestFillingLevel.."%")

            -- Affichage du remplissage du coffre de carburant
                HMI.setBackgroundColor(colors.black)
                HMI.setCursorPos(1,11)
                if FuelChestFillingLevel >= 10 and FuelChestFillingLevel < 45 then 
                    HMI.setBackgroundColor(colors.yellow)

                elseif FuelChestFillingLevel < 10 then 
                    HMI.setBackgroundColor(colors.red)

                elseif FuelChestFillingLevel >= 45 then 
                    HMI.setBackgroundColor(colors.green) 

                end

                HMI.write("Coffre carburant = "..FuelChestFillingLevel.."%")
                HMI.setBackgroundColor(colors.black)
    
        end

    -- Rafraichissement des variables affichées
        function server.updateHMI(receivedMessage)
            if receivedMessage.msgType == "connect" then -- Message de connexion reçu
                if receivedMessage.srcID == TurtleID then -- Connexion de la Turtle
                    TurtleConnected = true

                elseif receivedMessage.srcID == FuelRelayID then -- Connexion du relais de carburant
                    FuelRelayConnected = true

                elseif receivedMessage.srcID == HarvestRelayID then -- Connexion du relais de récoltes
                    HarvestRelayConnected = true

                end

            elseif receivedMessage.msgType == "status" then -- Message de statut reçu
                if receivedMessage.srcID == TurtleID then -- Statut de la Turtle
                    TurtleLastPosition = receivedMessage.payload.pos
                    TurtleLastOrientation = receivedMessage.payload.orientation
                    HarvestCycle = receivedMessage.payload.cycles
                    CurrentFuelLevel = receivedMessage.payload.fuel
                    CurrentInventoryLevel[1] = receivedMessage.payload.inventory.rawMaterial
                    CurrentInventoryLevel[2] = receivedMessage.payload.inventory.harvestedMaterial

                elseif receivedMessage.srcID == FuelRelayID then
                    FuelChestFillingLevel = receivedMessage.payload.chestInventory

                elseif receivedMessage.srcID == HarvestRelayID then
                    HarvestChestFillingLevel = receivedMessage.payload.chestInventory

                end


                displayHMI() -- Mise à jour de l'IHM

            end

            return true

        end

-- PROGRAMME
    -- Affichage de la version sur la console et ouverture de la connexion à RedNet
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
        HMI.setBackgroundColor(colors.black)
        HMI.clear()
        HMI.setCursorPos(1,1)
        HMI.write("Démarrage écran en cours...")
        os.sleep(2)
        displayHMI()
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
            local receivedData, id = PixelLink.receive("server")
            
            if not receivedData then -- Aucune données reçue dans le temps imparti, 
                TurtleConnected = false
                FuelRelayConnected = false
                HarvestRelayConnected = false

                updateHMI()

            else
                updateLastSeen(id)
        end

        while true do
            local receivedData = PixelLink.receive("server", 2)  -- On attend 2s max entre checks

            if receivedData then
                updateLastSeen(receivedData.srcID)

            end

            -- Vérifie timeouts de chaque entité
            local now = os.clock()
            if now - lastSeen.turtle > TIMEOUTS.turtle then
                TurtleConnected = false

            else
                TurtleConnected = true

            end

            if now - lastSeen.fuelRelay > TIMEOUTS.fuelRelay then
                FuelRelayConnected = false

            else
                FuelRelayConnected = true

            end

            if now - lastSeen.harvestRelay > TIMEOUTS.harvestRelay then
                HarvestRelayConnected = false

            else
                HarvestRelayConnected = true

            end

            updateHMI()

        end
