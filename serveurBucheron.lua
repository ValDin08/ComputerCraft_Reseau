--Déclaration des variables
	--Globales
	local ServerVersion	=	"2.0"		--Version du serveur
	
	--Réseau
	local LocalID			=	11			--ID du serveur
	local TurtleID			=	16			--ID de la turtle
	local ChestRelayID		=	17			--ID du relais coffres
	local ModemSide			=	"back"		--Côté du modem sur la serveur
	local TurtleConnected		=	false		--Turtle atteignable et connecté au serveur
	local ServerRequest		=	false		--Requête du serveur à envoyer à la turtle
	local TurtleRequest		=	false		--Requête de la turtle reçue par le serveur
	local ServerAuthorizing		=	false		--Serveur connecté à la turtle et autorisant le travail
	local TurtleAuthorized		=	false		--Turtle a reçu l'autorisation de travailler
	local ChestRelayConnected	=	false		--Relais des coffres connecté au serveur
	
	local ID, Message							--Message reçu depuis RedNET

	--Infos turtle
	local TurtleLastPosition	=	{0, 0, 0}	--Dernière position connue de la turtle
	local TurtleLastOrientation	=	0			--Dernière orientation connue de la turtle
	local LastOrientationString 	= 	""			--Dernière orientation connue de la turtle convertie en string
	local HarvestedTrees		=	0			--Nombre d'arbres abattus sur le tir en cours
	local CurrentFuelLevel		=	0			--Niveau de carburant actuel

	--Infos relais
	local FuelChestFillingLevel	=	0			--Niveau de remplissage du coffre tampon de carburant
	local WoodChestFillingLevel	=	0			--Niveau de remplissage du coffre stock des buches


--Programme
print("Version serveur : "..ServerVersion..".")
rednet.open(ModemSide)

while true do
	ID, Message = rednet.receive(15)
	
	--Vérification si le message provient bien de la turtle liée au serveur
	if ID == TurtleID then
		--Demande de la turtle de connexion au serveur
		if Message.RequestID == 1 then
			--Connexion accordée
			rednet.send(TurtleID, {AnswerID = 101})
			if not TurtleConnected then
				TurtleConnected = true
				print("Connexion établie à turtle ID #"..TurtleID..".")
			end
		
		--Demande de la turtle de démarrer le travail
		elseif Message.RequestID == 2 then
			--Autorisation accordée
			if ServerAuthorizing then
				rednet.send(TurtleID, {AnswerID = 102})
				if not TurtleAuthorized then
					print("Autorisation de travail accordée à turtle ID #"..TurtleID..".")
					TurtleAuthorized = true
				end
			--Autorisation révoquée
			elseif not ServerAuthorizing and TurtleAuthorized then
				print("Autorisation de travail révoquée à turtle ID #"..TurtleID..".")
				TurtleAuthorized = false
			--Interdiction de travail
			else
				print("Interdiction de travail pour turtle ID #"..TurtleID..".")
			end
		
		--Réception d'une trame de statut de la turtle
		elseif Message.RequestID == 110 then
			TurtleLastPosition = Message.CurrentTurtlePosition
			TurtleLastOrientation = Message.TurtleOrientation
			
			if TurtleLastOrientation == 1 then LastOrientationString = "Nord"
			elseif TurtleLastOrientation == 2 then LastOrientationString = "Sud"
			elseif TurtleLastOrientation == 3 then LastOrientationString = "Est"
			else LastOrientationString = "Ouest"
			end
			
			CurrentFuelLevel = Message.FuelLevel
			
			if HarvestedTrees < Message.TreeHarvestedCurrentRun then
				print("Nombre d'arbres abattus : "..HarvestedTrees..".")
				HarvestedTrees = Message.TreeHarvestedCurrentRun
				print("Carburant restant dans le réservoir : "..CurrentFuelLevel..".")
			end
		end

	elseif ID == ChestRelayID then
	--Demande du relais de connexion au serveur
		if Message.RequestID == 1 then
			--Connexion accordée
			rednet.send(ChestRelayID, {AnswerID = 101})
			if not ChestRelayConnected then
				ChestRelayConnected = true
				print("Connexion établie au relais #"..ChestRelayID..".")
			end
		elseif Message.RequestID == 3 then
			--Envoi d'une requête d'informations au relais coffres
			rednet.send(ChestRelayID, {RequestID = 30})
			ID, Message = rednet.receive(5)
			if ID == ChestRelayID then
				if FuelChestFillingLevel ~= Message.CurrentLeftChestFilling or WoodChestFillingLevel ~= Message.CurrentRightChestFilling then
					FuelChestFillingLevel = Message.CurrentLeftChestFilling
					WoodChestFillingLevel = Message.CurrentRightChestFilling
					print("Niveau de remplissage des coffres : Carburant = "..FuelChestFillingLevel.."%, Buches = "..WoodChestFillingLevel.."%.")
				end
			end
		end

	--Turtle déconnectée du serveur
	elseif not ID and TurtleConnected then
		TurtleConnected = false
		ServerAuthorizing = false
		print("Perte de communication probable avec turtle ID #"..TurtleID..", attente d'une nouvelle requête de la turtle.")
		print("Dernière position de la turtle connue : x = "..TurtleLastPosition[1]..", y = "..TurtleLastPosition[2]..", z = "..TurtleLastPosition[3]..", se déplaçant vers : "..LastOrientationString..".")
	
	
	--Partenaire inconnu essayant de communiquer
	elseif ID and (ID ~= TurtleID or ID ~= ChestRelayID) then
		print("Partenaire inconnu, le firewall bloque le message.")
	end
	
	--Autorisation de travail accordée à la turtle
	if WoodChestFillingLevel < 100 then
		ServerAuthorizing = true
	else
		ServerAuthorizing = false
	end		

end
