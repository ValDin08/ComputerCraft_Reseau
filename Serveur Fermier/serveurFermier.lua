--Déclaration des variables
	--Globales
	local ServerVersion			=	"1.0"			--Version du serveur
	local TurtleVersion			=	"0.0"			--Version de la turtle
	
	--Réseau
	local LocalID				      =	12			--ID du serveur
	local TurtleID				    =	8			--ID de la turtle
	local ChestRelayID			  =	0			--ID du relais coffres
	local ModemSide				    =	"back"		--Côté du modem sur la serveur
	local TurtleConnected		  =	false		--Turtle atteignable et connecté au serveur
	local ServerRequest			  =	false		--Requête du serveur à envoyer à la turtle
	local TurtleRequest			  =	false		--Requête de la turtle reçue par le serveur
	local ServerAuthorizing		=	false		--Serveur connecté à la turtle et autorisant le travail
	local TurtleAuthorized		=	false		--Turtle a reçu l'autorisation de travailler
	local ChestRelayConnected	=	false		--Relais des coffres connecté au serveur
	
	local ID, Message							--Message reçu depuis RedNET

	--Infos turtle
	local TurtleLastPosition	  =	{0, 0, 0}	--Dernière position connue de la turtle
	local TurtleLastOrientation	=	0			--Dernière orientation connue de la turtle
	local LastOrientationString = ""			--Dernière orientation connue de la turtle convertie en string
	local HarvestedHays			    =	0			--Nombre de blés récoltés sur le tir en cours
	local CurrentFuelLevel		  =	0			--Niveau de carburant actuel

	--Infos relais
	local FuelChestFillingLevel	=	0			--Niveau de remplissage du coffre tampon de carburant
	local WoodChestFillingLevel	=	0			--Niveau de remplissage du coffre stock des buches

	--Ecran
	local ScreenSide			=	"bottom"	--Côté de l'écran
	
	--Commandes
	local RedstoneInputSide		=	"right"		--Côté de l'entrée du signal redstone	

--Programme
print("Version serveur : "..ServerVersion..".")
rednet.open(ModemSide)
local HMI = peripheral.wrap(ScreenSide)

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
				rednet.send(TurtleID, {AnswerID = 202})
				print("Autorisation de travail révoquée à turtle ID #"..TurtleID..".")
				TurtleAuthorized = false
			--Interdiction de travail
			else
				rednet.send(TurtleID, {AnswerID = 202})
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
			
			if HarvestedHays < Message.HayHarvestedCurrentRun then
				print("Nombre d'arbres abattus : "..HarvestedHays..".")
				HarvestedHays = Message.HayHarvestedCurrentRun
				print("Carburant restant dans le réservoir : "..CurrentFuelLevel..".")
			end
			
			TurtleVersion = Message.ProgramVersion
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
	if WoodChestFillingLevel < 100 and not rs.getInput(RedstoneInputSide) then
		ServerAuthorizing = true
	else
		ServerAuthorizing = false
	end		

	--Gestion de l'écran
	HMI.clear()
	HMI.setCursorPos(1,1)
	HMI.setTextScale(0.5)
	
	HMI.setBackgroundColor(colors.black)
	
	HMI.write("Serveur: "..ServerVersion.." / Turtle : "..TurtleVersion)
	
	--Affichage de l'état de connexion de la turtle
	HMI.setCursorPos(1,2)
	HMI.write("Turtle connectée : ")
	if TurtleConnected then
		HMI.setBackgroundColor(colors.green)
		HMI.write("OUI")
	else
		HMI.setBackgroundColor(colors.red)
		HMI.write("NON")
	end
	HMI.setBackgroundColor(colors.black)
	
	--Affichage de l'état de fonctionnement de la turtle
	HMI.setCursorPos(1,3)
	HMI.write("Turtle autorisée à travailler : ")
	if TurtleAuthorized then
		HMI.setBackgroundColor(colors.green)
		HMI.write("OUI")
	else
		HMI.setBackgroundColor(colors.red)
		HMI.write("NON")
	end
	HMI.setBackgroundColor(colors.black)
	
	--Affichage de la position de la turtle
	HMI.setCursorPos(1,4)
	HMI.write("Position turtle : "..TurtleLastPosition[1]..", "..TurtleLastPosition[2]..", "..TurtleLastPosition[3])
	HMI.setCursorPos(1,5)
	HMI.write("Allant vers : "..LastOrientationString)
	
	--Affichage du carburant restant
	HMI.setCursorPos(1,6)
	HMI.write("Carburant restant = "..CurrentFuelLevel)
	
	--Affichage du nombre d'arbres coupés
	HMI.setCursorPos(1,7)
	HMI.write("Quantité de blé récoltée : "..HarvestedHays)	
	
	--Affichage de l'état de connexion au relais
	HMI.setCursorPos(1,8)
	HMI.write("Relais connecté : ")
	if ChestRelayConnected then
		HMI.setBackgroundColor(colors.green)
		HMI.write("OUI")
	else
		HMI.setBackgroundColor(colors.red)
		HMI.write("NON")
	end
	HMI.setBackgroundColor(colors.black)
	
	--Affichage de l'état de remplissage des coffres
	HMI.setCursorPos(1,9)
	if WoodChestFillingLevel > 50 and WoodChestFillingLevel < 85 then HMI.setBackgroundColor(colors.yellow)
	elseif WoodChestFillingLevel >= 85 then HMI.setBackgroundColor(colors.red)
	elseif WoodChestFillingLevel <=50 then HMI.setBackgroundColor(colors.green)
	end
	HMI.write("Coffre buches = "..WoodChestFillingLevel.."%")
	HMI.setBackgroundColor(colors.black)
	
	HMI.setCursorPos(1,10)
	if FuelChestFillingLevel >= 10 and FuelChestFillingLevel < 45 then HMI.setBackgroundColor(colors.yellow)		
	elseif FuelChestFillingLevel < 10 then HMI.setBackgroundColor(colors.red)		
	elseif FuelChestFillingLevel >= 45 then HMI.setBackgroundColor(colors.green)		
	end
	HMI.write("Coffre carburant = "..FuelChestFillingLevel.."%")	
	HMI.setBackgroundColor(colors.black)
	
end 
