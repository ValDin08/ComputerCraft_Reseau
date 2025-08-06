-- Structure des "payload" à utiliser avec PixelLink

-- Message type "status"
  -- Turtles
    payload = {
      turtleType  = *Fonction de la turtle*,
      pos         = *Position GPS de la turtle*,
      orientation = *Orientation GPS de la turtle*,          
      fuel        = *Quantité de carburant dans la turtle, avec ou sans la reserve dans l'inventaire*,               
      running     = *Etat de la turtle, en cycle ou en attente*,          
      cycles      = *Nombre de cycles de récolte effectués*,               
      inventory   = {
        rawMaterial   		= *Matière première (par exemple, graines ou pousses d'arbres)*,            
        harvestedMaterial = *Matière récoltée*,               
        misc    			    = *Autre matière possible contenue dans la turtle*                  
        },
      errors  = {*Code(s) d'erreur emis par la turtle*},                    
      extra   = {*Autres variables*}
  
      }

    -- Relais
    payload = {
      relayType  = *Fonction du relais*,
      chestInventory = *Quantité de matériel contenue dans le coffre 1 (pourcentage de remplissage)*,
    }


  -- Message type "auth"
    -- Turtles
    payload = {
      turtleType          = *Fonction de la turtle*,
      pos                 = *Position GPS de la turtle*,
      orientation         = *Orientation GPS de la turtle*,   
      serverAuthorization = *Autorisation actuelle turtle*
    }

  -- Message type "connect"
    --Le payload doit toujours rester vide : 
    payload = { }
      
