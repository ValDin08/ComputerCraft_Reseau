local PixelLink = {}
local serverRef = nil

local lastMessageID = 0

-- FONCTIONS
    -- Traçabilité messages
    local function nextMessageID()
        lastMessageID = lastMessageID + 1
        return lastMessageID
    end
	
	-- Mise en fonction PixelLink pour serveur
		function PixelLink.setServeur(ref)
			serverRef = ref
		end

    -- Fonctions d'envoi de message
        -- Envoi simple (fire and forget)
            function PixelLink.send(msgType, srcType, dstID, payload, replyTo)
				print("Envoi simple en cours...")
                local message = {
                    msgID = nextMessageID(),
                    msgType = msgType,
                    srcType = srcType,
                    srcID   = os.getComputerID(),
                    dstID   = dstID,
                    ts      = os.epoch("utc"),
                    payload = payload,
                    replyTo = replyTo -- msgID du message auquel on répond, le cas échéant
                }
                    if dstID then
                        rednet.send(dstID, message) -- Envoi en Simplecast

                    else
                        rednet.broadcast(message) -- Envoi en Broadcast
                    end

            end

        -- Envoi avec attente de réponse
            function PixelLink.request(msgType, srcType, dstID, payload, timeout)
				print("Envoi d'une requête en cours...")
                local message = {
                    msgID = nextMessageID(),
                    msgType = msgType,
                    srcType = srcType,
                    srcID   = os.getComputerID(),
                    dstID   = dstID,
                    ts      = os.epoch("utc"),
                    payload = payload
                }
                -- Envoie la requête
                rednet.send(dstID, message)

                -- Attend une réponse pendant un temps (par défaut 5 secondes), en ignorant tout message
                -- qui ne correspond pas à CETTE requête (autre expéditeur ou réponse à une autre requête),
                -- sans pour autant relâcher le délai d'attente avant son terme
                local t = timeout or 5
                local deadline = os.clock() + t

                while os.clock() < deadline do
                    local id, receivedMessage = rednet.receive(deadline - os.clock())

                    if id == nil then
                        break -- Délai écoulé, aucune réponse valide reçue
                    end

                    -- Vérifie que la réponse vient bien de la bonne source et répond bien à cette requête
                    if id == dstID and type(receivedMessage) == "table" and receivedMessage.replyTo == message.msgID then
                        -- Selon le type de la réponse
                        if receivedMessage.msgType == "auth" then -- Demande d'autorisation
                            return true, receivedMessage.payload

                        elseif receivedMessage.msgType == "command" then -- Demande de commande
                            return true, receivedMessage.payload

                        elseif receivedMessage.msgType == "connect" then -- Demande de connexion
                            return true

                        else -- Type inconnu
                            return false, receivedMessage

                        end
                    end
                    -- Sinon : message sans rapport avec cette requête, on continue d'attendre le temps restant
                end

                -- Pas de réponse valide reçue avant expiration du délai
                return false, nil

            end


    -- Fonctions de réception des messages
        function PixelLink.receive(srcType, timeout)
            -- Attend une réponse pendant un temps (par défaut 30 secondes)
			print("Attente message...")
            local t = timeout or 30
            local id, receivedMessage = rednet.receive(t) -- Attend un message
            if type(receivedMessage) == "table" then -- Vérification si le message reçu est bien sous la forme d'une table
                if receivedMessage.msgType == "connect" then -- Demande de connexion
                    serverRef.updateHMI(receivedMessage) -- Mise à jour de l'IHM et des données serveur
                    local payload = {}
                    PixelLink.send("connect", srcType, id, payload, receivedMessage.msgID) -- Envoi de la réponse de connexion
                    return true, receivedMessage

                elseif receivedMessage.msgType == "auth" then -- Demande d'autorisation de travail
                    local authorization = serverRef.authorization()
                    -- La commande en attente (bouton tactile) voyage ici : c'est le seul canal par
                    -- lequel le serveur peut atteindre la turtle, qui interroge en boucle.
                    local payload = {authorization = authorization, command = serverRef.PendingCommand}
                    PixelLink.send("auth", srcType, id, payload, receivedMessage.msgID) -- Envoi de la réponse d'autorisation de travail
                    return true, receivedMessage

                elseif receivedMessage.msgType == "status" then -- Reception de statut
                    serverRef.updateHMI(receivedMessage) -- Mise à jour de l'IHM et des données serveur
                    return true, receivedMessage

                else
                    return false

                end

            end

        end

return PixelLink
