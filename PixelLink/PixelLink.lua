local PixelLink = {}
local serveur_ref = nil

local lastMessageID = 0

-- FONCTIONS
    -- Traçabilité messages
    local function nextMessageID()
        lastMessageID = lastMessageID + 1
        return lastMessageID
    end
	
	-- Mise en fonction PixelLink pour serveur
		function PixelLink.setServeur(ref)
			serveur_ref = ref
		end

    -- Fonctions d'envoi de message
        -- Envoi simple (fire and forget)
            function PixelLink.send(msgType, srcType, dstID, payload)
				print("Envoi simple en cours...")
                local message = {
                    msgID = nextMessageID(),
                    msgType = msgType,
                    srcType = srcType,
                    srcID   = os.getComputerID(),
                    dstID   = dstID,
                    ts      = os.epoch("utc"),
                    payload = payload
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

                -- Attend une réponse pendant un temps (par défaut 5 secondes)
                local t = timeout or 5
                local id, receivedMessage = rednet.receive(t)

                -- Vérifie qu'une réponse a bien été reçue, et de la bonne source
                if id == dstID and type(receivedMessage) == "table" then -- Vérification si le message reçu est bien sous la forme d'une table
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

                else
                    -- Pas de réponse ou pas du bon ID
                    return false, nil

                end

            end


    -- Fonctions de réception des messages
        function PixelLink.receive(srcType, timeout)
            -- Attend une réponse pendant un temps (par défaut 30 secondes)
			print("Attente message...")
            local t = timeout or 30
            local id, receivedMessage = rednet.receive(t) -- Attend un message
            if type(receivedMessage) == "table" then -- Vérification si le message reçu est bien sous la forme d'une table
                if receivedMessage.msgType == "connect" then -- Demande de connexion
                    serveur_ref.updateHMI(receivedMessage) -- Mise à jour de l'IHM et des données serveur
                    payload = {}
                    PixelLink.send("connect", srcType, id, payload) -- Envoi de la réponse de connexion
                    return true, receivedMessage

                elseif receivedMessage.msgType == "auth" then -- Demande d'autorisation de travail
                    local authorization = serveur_ref.authorization()
                    payload = {authorization = authorization}
                    PixelLink.send("auth", srcType, id, payload) -- Envoi de la réponse d'autorisation de travail
                    return true, receivedMessage

                elseif receivedMessage.msgType == "status" then -- Reception de statut
                    serveur_ref.updateHMI(receivedMessage) -- Mise à jour de l'IHM et des données serveur
                    return true, receivedMessage

                else
                    return false

                end

            end

        end

return PixelLink
