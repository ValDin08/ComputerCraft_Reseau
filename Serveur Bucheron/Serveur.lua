--[[Serveur : Bucheron
Version : 4.0a02

Patchnote : 
1.0 : Version de base du serveur de la turtle bucheron.
Gestion de l'autorisation de fonctionnement de la turtle, si celle ci perd la communication avec le serveur, elle arrête de fonctionner.
Reception d'une trame basique de statut de la turtle.

2.0 : Intégration d'un PC relais coffre donnant conditionnant l'autorisation de travail de la turtle.

3.0 : Ajout d'un écran IHM pour supervision de la turtle.
Gestion de l'autorisation de production via serveur relais coffre ET signal redstone TOR devant IHM.
3.1 : Utilisation de deux relais au lieu d'un.

4.0 : Intégration de PixelLink.
Modification du programme en conséquence.

******************************************************************************************************************************************************************************************************************************************************]]
-- DECLARATION DES VARIABLES
    -- Globales
		local ServerVersion = "4.0a04"
		local TurtleVersion = "4.0a03"
		local METIER  		= "Serveur"
		local PixelLink_ref = nil

    -- IDs et réseau
        local Serveur                   = {}
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


-- FONCTIONS
	-- Connexion à un serveur
		function Serveur.ConnectToServer()
            local payload = {}
            ServerConnected = PixelLink.request("connect", "server", ServerID, payload)
            if ServerConnected then print("Serveur principal connecté") else print("Serveur principal déconnecté") end

        end

	-- Mise en fonction PixelLink pour serveur
		function Serveur.setPixelLink(ref)
			PixelLink_ref = ref
			
		end

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
        function Serveur.authorization()
            return (HarvestChestFillingLevel < 95 and not rs.getInput(RedstoneInputSide))
        
        end

    -- Fonction utilitaire pour actualiser lastSeen selon le msg reçu
        function Serveur.updateLastSeen(srcID)
            if srcID == TurtleID then 
                LastSeen.turtle = os.clock()

            elseif srcID == FuelRelayID then                 
                LastSeen.fuelRelay = os.clock()

            elseif srcID == HarvestRelayID then 
                LastSeen.harvestRelay = os.clock()

            end

        end

    -- Gestion de l'affichage sur l'écran
        function Serveur.displayHMI()
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
        function Serveur.updateHMI(receivedMessage)
            if receivedMessage.msgType == "connect" then -- Message de connexion reçu
                if receivedMessage.srcID == TurtleID then -- Connexion de la Turtle
				print("Demande de connexion reçue d'une Turtle")
                    TurtleConnected = true

                elseif receivedMessage.srcID == FuelRelayID then -- Connexion du relais de carburant
				print("Demande de connexion reçue du relais carburant")
                    FuelRelayConnected = true

                elseif receivedMessage.srcID == HarvestRelayID then -- Connexion du relais de récoltes
				print("Demande de connexion reçue du relais récoltes")
                    HarvestRelayConnected = true

                end

            elseif receivedMessage.msgType == "status" then -- Message de statut reçu
                if receivedMessage.srcID == TurtleID then -- Statut de la Turtle
					print("Statut reçu d'une Turtle")
                    TurtleConnected = true
                    TurtleLastPosition = receivedMessage.payload.pos
                    TurtleLastOrientation = receivedMessage.payload.orientation
                    HarvestCycle = receivedMessage.payload.cycles
                    CurrentFuelLevel = receivedMessage.payload.fuel
                    CurrentInventoryLevel[1] = receivedMessage.payload.inventory.rawMaterial
                    CurrentInventoryLevel[2] = receivedMessage.payload.inventory.harvestedMaterial
					LastOrientationString = orientationToString(TurtleLastOrientation)

                elseif receivedMessage.srcID == FuelRelayID then
					print("Statut reçu du relais carburant")
                    FuelRelayConnected = true
					if receivedMessage.payload and receivedMessage.payload.inventory.chestFilling then
						FuelChestFillingLevel = math.floor(receivedMessage.payload.inventory.chestFilling)
						
					end

                elseif receivedMessage.srcID == HarvestRelayID then
					print("Statut reçu du relais récoltes")
                    HarvestRelayConnected = true
					if receivedMessage.payload and receivedMessage.payload.inventory.chestFilling then
						HarvestChestFillingLevel = math.floor(receivedMessage.payload.inventory.chestFilling)
						
					end

                end
				
				TurtleAuthorized = Serveur.authorization()


                Serveur.displayHMI() -- Mise à jour de l'IHM

            end

            return true

        end

	return Serveur
