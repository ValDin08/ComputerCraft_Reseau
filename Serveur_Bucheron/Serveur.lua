-- DECLARATION DES VARIABLES
    -- Globales
		local ServerVersion = "5.0-alpha02"
		local TurtleVersion = "5.0-alpha02"
		local METIER  		= "Serveur"
		local PixelLinkRef  = nil

    -- IDs et réseau
        local Serveur                   = {}
        local LocalID                   = os.getComputerID()    -- ID du serveur
        Serveur.Version                 = { server = ServerVersion, turtle = TurtleVersion } -- Source unique des versions, exposée à Startup.lua
        local TurtleID                  = 16                    -- ID de la turtle
        local FuelRelayID               = nil                   -- ID du relais carburant, résolu dynamiquement au démarrage (cf startup.lua, Serveur.setRelayIDs)
        local HarvestRelayID            = nil                   -- ID du relais bois, résolu dynamiquement au démarrage (cf startup.lua, Serveur.setRelayIDs)
        local ModemSide                 = "back"                -- Côté du modem RedNet
        local TurtleConnected           = false                 -- Turtle connectée
        local TurtleAuthorized          = false                 -- Turtle autorisée à récolter
        local FuelRelayConnected        = false                 -- Relais carburant connecté
        local HarvestRelayConnected     = false                 -- Relais récoltes connecté
        local MasterServerIsPresent     = false                 -- Serveur principal présent sur l'installation
        local MasterServerID            = 0                     -- ID du serveur principal, si présent sur l'installation

        -- Autorisation de travail manuelle (remplace l'ancien levier physique branché sur redstone).
        -- Verrouillée par défaut à chaque démarrage/redémarrage du serveur : l'opérateur doit
        -- l'activer volontairement à l'écran, comme il l'aurait fait en actionnant le levier.
        Serveur.ManualAuthorization = false

        -- Commande en attente d'application par la turtle (bouton tactile) : {id=, type=}.
        -- Transmise via la prochaine réponse d'autorisation ("auth"), et effacée uniquement quand
        -- la turtle en a accusé réception (ackCommandId dans son statut) — jamais à l'aveugle.
        Serveur.PendingCommand = nil

        -- Dernier défaut remonté par la turtle, affiché à l'écran jusqu'à acquittement manuel ou
        -- écrasement par un nouveau statut (identique ou différent).
        Serveur.TurtleLastError = ""

        -- Timeout de connexion
            local TimeOuts = {
                turtle      = 30,
                fuelRelay   = 60,
                harvestRelay= 60
            }

            -- Initialisé à -math.huge (et non 0) pour que rien ne soit considéré "connecté"
            -- tant qu'aucun message n'a réellement été reçu depuis le démarrage du serveur
            local LastSeen = {
                turtle      = -math.huge,
                fuelRelay   = -math.huge,
                harvestRelay= -math.huge
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
        local HMI                  = peripheral.wrap(ScreenSide) -- Connexion de l'écran

    -- Boutons tactiles (zones cliquables recalculées à chaque affichage, cf drawButtons/handleTouch)
        local Buttons = {} -- Liste de {x1,y1,x2,y2,action=function()}


-- FONCTIONS
	-- Connexion à un serveur principal (optionnel, cf MasterServerIsPresent dans Startup.lua)
		function Serveur.connectToMasterServer(masterServerID)
            local payload = {}
            local connected = PixelLinkRef.request("connect", "server", masterServerID, payload)
            if connected then print("Serveur principal connecté") else print("Serveur principal déconnecté") end
            return connected

        end

	-- Mise en fonction PixelLink pour serveur
		function Serveur.setPixelLink(ref)
			PixelLinkRef = ref

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

    -- Autorisation de démarrage de la turtle : sécurité automatique (coffre bois) ET autorisation
    -- manuelle donnée à l'écran (remplace l'ancien levier physique sur redstone)
        function Serveur.authorization()
            return (HarvestChestFillingLevel < 95) and Serveur.ManualAuthorization

        end

    -- Résolution (et nouvelle tentative périodique) des relais par nom. Un relais qui démarre après
    -- le serveur, ou qu'on redémarre indépendamment plus tard, ne doit pas rester injoignable pour
    -- toujours : sans ça, une seule tentative ratée au boot (course au démarrage entre deux
    -- ordinateurs physiques distincts) bloquait le relais définitivement jusqu'au redémarrage manuel
    -- du serveur. Ne retente qu'au bout de RelayRetryInterval secondes : rednet.lookup attend une
    -- réponse, on ne veut pas bloquer la boucle réseau à chaque passage.
        local RelayRetryInterval = 30 -- secondes
        local LastRelayRetryAttempt = -math.huge

        function Serveur.retryMissingRelays()
            if FuelRelayID and HarvestRelayID then return end -- déjà tout résolu, rien à faire
            if PixelLinkRef == nil then return end

            local now = os.clock()
            if now - LastRelayRetryAttempt < RelayRetryInterval then return end
            LastRelayRetryAttempt = now

            if not FuelRelayID then
                FuelRelayID = PixelLinkRef.resolve("bucheron_fuel_relay")
                if FuelRelayID then print("Relais carburant retrouvé : ID #"..FuelRelayID) end
            end

            if not HarvestRelayID then
                HarvestRelayID = PixelLinkRef.resolve("bucheron_harvest_relay")
                if HarvestRelayID then print("Relais bois retrouvé : ID #"..HarvestRelayID) end
            end
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

    -- Vérification des timeouts de connexion (turtle / relais)
    -- Doit être appelée régulièrement par la boucle principale (Startup.lua) : c'est ici, et
    -- uniquement ici, que vit l'état de connexion réellement affiché par displayHMI().
        function Serveur.checkTimeouts()
            local now = os.clock()
            TurtleConnected       = (now - LastSeen.turtle)        <= TimeOuts.turtle
            FuelRelayConnected    = (now - LastSeen.fuelRelay)     <= TimeOuts.fuelRelay
            HarvestRelayConnected = (now - LastSeen.harvestRelay)  <= TimeOuts.harvestRelay
        end

    -- COMMANDES OPERATEUR (déclenchées par les boutons tactiles)
        -- Bascule de l'autorisation manuelle de travail (remplace le levier physique)
        function Serveur.toggleAuthorization()
            Serveur.ManualAuthorization = not Serveur.ManualAuthorization
            print("Autorisation manuelle : "..(Serveur.ManualAuthorization and "ACTIVEE" or "COUPEE"))
        end

        -- Acquittement du dernier défaut affiché (réapparaît si la turtle le signale de nouveau
        -- dans un prochain statut, identique ou différent)
        function Serveur.acknowledgeFault()
            Serveur.TurtleLastError = ""
        end

        -- Dépose d'une commande à destination de la turtle : transmise via la prochaine réponse
        -- d'autorisation ("auth"), et conservée jusqu'à accusé de réception explicite (ackCommandId
        -- dans le statut turtle) — jamais effacée à l'aveugle pour ne pas perdre la commande.
        local function issueCommand(cmdType)
            Serveur.PendingCommand = { id = os.epoch("utc"), type = cmdType }
            print("Commande émise vers la turtle : "..cmdType)
        end

        -- Force une resynchronisation immédiate de la turtle (re-connexion + statut immédiat),
        -- utile si l'affichage semble périmé alors que la liaison rednet est en réalité toujours bonne
        function Serveur.forceReconnect()
            issueCommand("resync")
        end

        -- Force un ravitaillement en carburant à la prochaine sortie de la turtle (jamais en pleine
        -- coupe d'un arbre : la turtle ne teste ses besoins qu'entre deux actions atomiques)
        function Serveur.forceRefuel()
            issueCommand("forceRefuel")
        end

        -- Force une dépose des buches à la prochaine sortie de la turtle
        function Serveur.forceEmpty()
            issueCommand("forceEmpty")
        end

    -- AFFICHAGE : configuration (à ajuster ici si besoin, sans toucher au reste du code)
        local TextScale        = 0.5 -- 0.5 = texte le plus petit possible = le plus de place disponible
        local ButtonGridCols   = 4
        local ButtonGridRows   = 2
        local ButtonCellHeight = 4   -- lignes par case de bouton (bordure haute, texte, bordure basse)

    -- AFFICHAGE : petits utilitaires
        local function writeAt(x, y, text, bg, fg)
            HMI.setBackgroundColor(bg or colors.black)
            HMI.setTextColor(fg or colors.white)
            HMI.setCursorPos(x, y)
            HMI.write(text)
        end

        -- Écrit un libellé suivi d'une valeur mise en couleur juste après (ex: "Turtle connectée : OUI").
        -- Repositionne via getCursorPos() plutôt que via la longueur du libellé en octets : les
        -- accents ("connectée", "autorisée") comptent plusieurs octets en UTF-8 et décaleraient sinon
        -- la valeur affichée.
        local function writeLabelValue(x, y, label, value, valueColor)
            writeAt(x, y, label, colors.black, colors.white)
            local nx, ny = HMI.getCursorPos()
            writeAt(nx, ny, value, valueColor or colors.black, colors.white)
        end

        -- Écrit `text` centré dans [x1,x2] sur la ligne y, fond `bg` colorant toute la zone.
        -- Tronque le texte s'il est plus long que la zone : ne déborde JAMAIS sur la case voisine
        -- (c'est ce qui causait le chevauchement des libellés de boutons).
        local function writeCentered(x1, x2, y, text, bg, fg)
            local zoneWidth = x2 - x1 + 1
            if zoneWidth < 1 then return end
            if #text > zoneWidth then text = text:sub(1, zoneWidth) end
            HMI.setBackgroundColor(bg)
            HMI.setTextColor(fg or colors.white)
            HMI.setCursorPos(x1, y)
            HMI.write(string.rep(" ", zoneWidth))
            HMI.setCursorPos(x1 + math.floor((zoneWidth - #text) / 2), y)
            HMI.write(text)
        end

        -- Cadre ASCII simple (+, -, |) sur la zone [x1,y1]-[x2,y2]
        local function drawBox(x1, y1, x2, y2, bg, fg)
            local width = x2 - x1 + 1
            if width < 2 or y2 < y1 then return end
            HMI.setBackgroundColor(bg or colors.black)
            HMI.setTextColor(fg or colors.white)
            HMI.setCursorPos(x1, y1)
            HMI.write("+"..string.rep("-", width - 2).."+")
            for y = y1 + 1, y2 - 1 do
                HMI.setCursorPos(x1, y)
                HMI.write("|"..string.rep(" ", width - 2).."|")
            end
            if y2 > y1 then
                HMI.setCursorPos(x1, y2)
                HMI.write("+"..string.rep("-", width - 2).."+")
            end
        end

    -- Définition des boutons de la grille, par case "ligne_colonne". Une case absente de cette table
    -- est dessinée comme réservée (vide, non cliquable) : c'est là qu'on ajoutera de futures commandes.
        local function buttonDefs()
            return {
                ["1_1"] = { label = { Serveur.ManualAuthorization and "STOPPER" or "AUTORISER" },
                            color = Serveur.ManualAuthorization and colors.red or colors.green,
                            action = Serveur.toggleAuthorization },
                ["1_2"] = { label = { "RECONNEXION" },
                            color = colors.blue,
                            action = Serveur.forceReconnect },
                ["1_3"] = { label = { "FORCER", "RAVITAILLEMENT" },
                            color = colors.cyan,
                            action = Serveur.forceRefuel },
                ["2_1"] = { label = { "ACQUITTER" },
                            color = (Serveur.TurtleLastError ~= "") and colors.orange or colors.gray,
                            action = Serveur.acknowledgeFault },
                ["2_3"] = { label = { "FORCER", "VIDANGE" },
                            color = colors.brown,
                            action = Serveur.forceEmpty },
            }
        end

    -- Dessine la grille de boutons tactiles (ButtonGridCols x ButtonGridRows) à partir de la ligne
    -- `gridTop`, et mémorise les zones cliquables. S'adapte à la largeur réelle de l'écran.
        local function drawButtonGrid(gridTop)
            Buttons = {}
            local width = select(1, HMI.getSize())
            local cellWidth = math.floor(width / ButtonGridCols)
            local defs = buttonDefs()

            for row = 1, ButtonGridRows do
                local y1 = gridTop + (row - 1) * ButtonCellHeight
                local y2 = y1 + ButtonCellHeight - 1

                for col = 1, ButtonGridCols do
                    local x1 = (col - 1) * cellWidth + 1
                    local x2 = (col == ButtonGridCols) and width or (col * cellWidth)
                    local def = defs[row.."_"..col]

                    if def then
                        drawBox(x1, y1, x2, y2, colors.black, colors.white)
                        for y = y1 + 1, y2 - 1 do
                            writeCentered(x1 + 1, x2 - 1, y, "", def.color, colors.white)
                        end
                        local nLines = #def.label
                        local firstLineY = y1 + 1 + math.floor(((y2 - y1 - 1) - nLines) / 2)
                        for i, textLine in ipairs(def.label) do
                            writeCentered(x1 + 1, x2 - 1, firstLineY + i - 1, textLine, def.color, colors.white)
                        end
                        table.insert(Buttons, { x1 = x1, y1 = y1, x2 = x2, y2 = y2, action = def.action })
                    else
                        -- Case réservée : cadre vide, non cliquable
                        drawBox(x1, y1, x2, y2, colors.black, colors.gray)
                        writeCentered(x1 + 1, x2 - 1, y1 + math.floor((y2 - y1) / 2), "RESERVE", colors.black, colors.gray)
                    end
                end
            end
        end

    -- Gestion de l'affichage sur l'écran
        function Serveur.displayHMI()
            -- L'échelle de texte doit être fixée AVANT tout calcul de mise en page (HMI.getSize() en
            -- dépend) et avant tout dessin — sinon la grille de boutons se dessine à l'ancienne
            -- échelle et déborde sur les cases voisines (c'était le bug observé à l'écran).
                HMI.setTextScale(TextScale)
                HMI.clear()
                HMI.setBackgroundColor(colors.black)
                HMI.setTextColor(colors.white)

                local width, height = HMI.getSize()
                local gridHeight = ButtonGridRows * ButtonCellHeight
                local gridTop    = height - gridHeight + 1

                local line = 1
                local function nextLine(extraGap)
                    line = line + 1 + (extraGap or 0)
                end

                writeAt(1, line, "Serveur: "..ServerVersion.." / Turtle : "..TurtleVersion); nextLine(1)

                writeLabelValue(1, line, "Turtle connectée : ", TurtleConnected and "OUI" or "NON",
                    TurtleConnected and colors.green or colors.red); nextLine()

                writeLabelValue(1, line, "Turtle autorisée à travailler : ", TurtleAuthorized and "OUI" or "NON",
                    TurtleAuthorized and colors.green or colors.red); nextLine(1)

                writeAt(1, line, "Position turtle : "..TurtleLastPosition[1]..", "..TurtleLastPosition[2]..", "..TurtleLastPosition[3]); nextLine()
                writeAt(1, line, "Allant vers : "..LastOrientationString); nextLine()
                writeAt(1, line, "Carburant restant : "..CurrentFuelLevel); nextLine()
                writeAt(1, line, "Nombre d'arbres abattus : "..HarvestCycle); nextLine(1)

                writeLabelValue(1, line, "Relais carburant : ", FuelRelayConnected and "OUI" or "NON",
                    FuelRelayConnected and colors.green or colors.red); nextLine()

                writeLabelValue(1, line, "Relais bois : ", HarvestRelayConnected and "OUI" or "NON",
                    HarvestRelayConnected and colors.green or colors.red); nextLine(1)

                local woodColor = colors.green
                if HarvestChestFillingLevel >= 85 then woodColor = colors.red
                elseif HarvestChestFillingLevel > 50 then woodColor = colors.yellow end
                writeAt(1, line, "Coffre buches : "..HarvestChestFillingLevel.."%", colors.black, woodColor); nextLine()

                local fuelColor = colors.green
                if FuelChestFillingLevel < 10 then fuelColor = colors.red
                elseif FuelChestFillingLevel < 45 then fuelColor = colors.yellow end
                writeAt(1, line, "Coffre carburant : "..FuelChestFillingLevel.."%", colors.black, fuelColor); nextLine(1)

                if Serveur.TurtleLastError ~= "" then
                    writeAt(1, line, "Défaut turtle : "..Serveur.TurtleLastError, colors.red, colors.white)
                else
                    writeAt(1, line, "Défaut turtle : aucun")
                end
                nextLine()

                if Serveur.PendingCommand then
                    writeAt(1, line, "Commande en attente : "..Serveur.PendingCommand.type, colors.yellow, colors.black)
                else
                    writeAt(1, line, "Commande en attente : aucune")
                end

            -- Grille de boutons tactiles
                drawButtonGrid(gridTop)

            HMI.setBackgroundColor(colors.black)
            HMI.setTextColor(colors.white)

        end

    -- Distribution d'un événement tactile vers le bouton concerné (appelé depuis Startup.lua)
        function Serveur.handleTouch(x, y)
            for _, button in ipairs(Buttons) do
                if x >= button.x1 and x <= button.x2 and y >= button.y1 and y <= button.y2 then
                    button.action()
                    Serveur.displayHMI() -- Retour visuel immédiat, sans attendre le prochain cycle réseau
                    return
                end
            end
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

                    -- Dernier défaut remonté par la turtle (persiste à l'écran jusqu'à acquittement)
                    if receivedMessage.payload.errors and receivedMessage.payload.errors[1] and receivedMessage.payload.errors[1] ~= "" then
                        Serveur.TurtleLastError = receivedMessage.payload.errors[1]
                    end

                    -- Accusé de réception d'une commande en attente : on ne l'efface QUE si la turtle
                    -- confirme avoir traité CETTE commande précise (comparaison par id)
                    if Serveur.PendingCommand and receivedMessage.payload.ackCommandId == Serveur.PendingCommand.id then
                        print("Commande '"..Serveur.PendingCommand.type.."' confirmée appliquée par la turtle")
                        Serveur.PendingCommand = nil
                    end

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

