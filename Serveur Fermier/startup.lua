-- DECLARATION DES VARIABLES
	-- Globales
		local METIER  		= "Serveur"
		local Serveur 		= require("Serveur")
		local PixelLink 	= require("PixelLink")

    -- IDs et réseau
        local ModemSide                 = "back"                -- Côté du modem RedNet

    -- Ecran & commandes
        local ScreenSide           = "bottom"                     -- Position de l'écran (doit être identique à Serveur.lua)
        local HMI                  = peripheral.wrap(ScreenSide) -- Connexion de l'écran (messages de démarrage uniquement,
                                                                   -- l'affichage courant est ensuite géré par Serveur.displayHMI())

--PROGRAMME
	-- Liaison entre Serveur et PixelLink
		PixelLink.setServeur(Serveur)

	-- Affichage de la version sur la console et ouverture de la connexion à RedNet
	-- Les versions viennent uniquement de Serveur.lua (Serveur.Version) : c'est la seule source
	-- de vérité, affichée aussi bien ici qu'à l'écran par Serveur.displayHMI().
		HMI.setBackgroundColor(colors.black)
		HMI.clear()
		print("Bienvenue sur le serveur Fermier.")
		print("Version serveur : "..Serveur.Version.server..".")
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

    -- Boucle réseau : réception des messages PixelLink et rafraîchissement périodique de l'IHM
        local function NetworkLoop()
            while true do
                local receivedDatas, Datas = PixelLink.receive("server", 2)  -- On attend 2s max entre checks

                if receivedDatas then
                    Serveur.updateLastSeen(Datas.srcID)
					print("Message "..Datas.msgID.." reçu. Traitement terminé.")

                end

                -- Vérifie les timeouts de chaque entité (état géré et affiché par le module Serveur)
                Serveur.checkTimeouts()

                Serveur.displayHMI()

            end
        end

    -- Boucle tactile : écoute des appuis sur l'écran et déclenche la commande correspondante.
    -- NB : "side" est l'identifiant réseau utilisé pour joindre l'écran (ScreenSide, car branché
    -- directement sur un côté de l'ordinateur). S'il est relié via un modem filaire, remplacer la
    -- comparaison ci-dessous par le nom réseau du moniteur (peripheral.getName(HMI) dans Serveur.lua).
        local function TouchLoop()
            while true do
                local event, side, x, y = os.pullEvent("monitor_touch")
                if side == ScreenSide then
                    Serveur.handleTouch(x, y)
                end
            end
        end

    -- Les deux boucles tournent en parallèle : la réception réseau ne doit jamais bloquer les appuis écran
        parallel.waitForAny(NetworkLoop, TouchLoop)
