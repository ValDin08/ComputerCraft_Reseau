--Déclaration des variables
	--Globales
	local ServerVersion			=	"1.0"		--Version du serveur
	
	--Réseau
	local LocalID				=	11			--ID du serveur
	local TurtleID				=	16			--ID de la turtle
	local ModemSide				=	"back"		--Côté du modem sur la serveur
	local TurtleConnected		=	false		--Turtle atteignable et connecté au serveur
	local ServerRequest			=	false		--Requête du serveur à envoyer à la turtle
	local TurtleRequest			=	false		--Requête de la turtle reçue par le serveur
	local ServerAuthorizing		=	false		--Serveur connecté à la turtle et autorisant le travail
	
	local ID, Message							--Message reçu depuis RedNET

	local TurtleLastPosition	=	{0, 0, 0}	--Dernière position connue de la turtle
	local TurtleLastOrientation	=	0			--Dernière orientation connue de la turtle
	local LastOrientationString = 	""			--Dernière orientation connue de la turtle convertie en string
	local HarvestedTrees		=	0			--Nombre d'arbres abattus sur le tir en cours
	local CurrentFuelLevel		=	0			--Niveau de carburant actuel


--Programme
print("Version serveur : "..ServerVersion..".")
rednet.open(ModemSide)

while true do
	ID, Message = rednet.receive(20)
	
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
			rednet.send(TurtleID, {AnswerID = 102})
			if not ServerAuthorizing then
				ServerAuthorizing = true
				print("Autorisation de travail accordée à turtle ID #"..TurtleID..".")
			end
		
		--Réception d'une trame de statut de la turtle
		elseif Message.RequestID == 10 then
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
	
	--Turtle non connectée au serveur
	elseif not ID and TurtleConnected then
		TurtleConnected = false
		ServerAuthorizing = false
		print("Perte de communication probable avec turtle ID #"..TurtleID..", attente d'une nouvelle requête de la turtle.")
		print("Dernière position de la turtle connue : x = "..TurtleLastPosition[1]..", y = "..TurtleLastPosition[2]..", z = "..TurtleLastPosition[3]..", se déplaçant vers : "..LastOrientationString..".")
	
	
	--Partenaire inconnu essayant de communiquer
	elseif ID and ID ~= TurtleID then
		print("Partenaire inconnu, le firewall bloque le message.")
	end
	
	
end
