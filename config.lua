Config = {}

-- ============================================
-- CONFIGURATION GÉNÉRALE
-- ============================================

Config.ESXMode = 'new' -- 'old' ou 'new' (compatibilité ESX)
Config.lfPersistence = false -- Activer l'intégration avec lfPersistence

-- ============================================
-- PNJ ET COORDONNÉES
-- ============================================

-- PNJ de location
Config.RentalPed = {
    coords = vector4(-631.61, 6972.39, 24.52, 273.73),
    model = 'a_m_m_farmer_01',
    blip = {
        sprite = 225,
        display = 4,
        scale = 0.6,
        colour = 25,
        name = "Location de Véhicules"
    }
}

-- PNJ de suppression (point 1)
Config.DeletePed = {
    coords = vector4(-3293.96, 6195.72, 13.78, 100.96),
    model = 's_m_m_dockwork_01'
}

-- PNJ de retour (point 2)
Config.ReturnPed2 = {
    coords = vector4(34.92, 6451.09, 31.43, 227.33),
    model = 's_m_m_dockwork_01'
}

-- ============================================
-- POINTS DE RETOUR
-- ============================================

Config.ReturnPoints = {
    {
        coords = vector3(-3300.05, 6199.22, 13.65),
        blip = {
            sprite = 225,
            display = 4,
            scale = 0.6,
            colour = 1,
            name = "Location - Retour Véhicule"
        }
    },
    {
        coords = vector3(32.68, 6446.33, 31.43),
        blip = {
            sprite = 225,
            display = 4,
            scale = 0.6,
            colour = 1,
            name = "Location - Retour Véhicule"
        }
    }
}

-- ============================================
-- VÉHICULES DISPONIBLES
-- ============================================

Config.Vehicles = {
    {
        model = 'faggio',
        label = 'Faggio',
        price = 300,
        image = 'faggio.webp'
    },
    {
        model = 'kalahari',
        label = 'Kalahari',
        price = 500,
        image = 'kalahari.webp'
    }
}

-- ============================================
-- PRIX ET ÉCONOMIE
-- ============================================

Config.DeletePrice = 100 -- Prix pour supprimer un véhicule loué
Config.GovernmentAccount = 'society_gouv' -- Nom du compte gouvernement pour recevoir l'argent de suppression

-- ============================================
-- SPAWN DES VÉHICULES
-- ============================================

Config.SpawnLocations = {
    { x = -639.03, y = 6990.40, z = 24.32, h = 181.04 },
    { x = -634.98, y = 6990.60, z = 24.32, h = 180.26 },
    { x = -630.16, y = 6990.60, z = 24.32, h = 177.90 },
    { x = -621.43, y = 6991.51, z = 24.32, h = 175.81 },
    { x = -625.68, y = 6991.90, z = 24.32, h = 173.37 },
    { x = -627.57, y = 6977.78, z = 24.32, h = 267.34 },
    { x = -628.46, y = 6969.02, z = 24.32, h = 267.34 },
    { x = -639.27, y = 6987.02, z = 24.32, h = 257.32 },
}

Config.SpawnRadius = 5.0 -- Rayon de vérification pour les emplacements de spawn

-- ============================================
-- PLAQUES
-- ============================================

Config.PlatePrefix = "LOC" -- Préfixe des plaques (ex: LOC1234)
Config.PlateMin = 1000 -- Numéro minimum de la plaque
Config.PlateMax = 9999 -- Numéro maximum de la plaque

-- ============================================
-- WEBHOOKS DISCORD
-- ============================================

Config.DiscordWebhook = {
    enabled = false, -- Activer/désactiver les webhooks
    url = '',
    colors = {
        rented = 3066993,    -- Vert pour nouvelle location
        returned = 15105570,  -- Orange pour retour
        deleted = 15158332   -- Rouge pour suppression
    },
    footer = "lfRental"
}

-- ============================================
-- DISTANCES D'INTERACTION
-- ============================================

Config.InteractionDistance = 3.0 -- Distance pour interagir avec les PNJ
Config.DrawDistance = 20.0 -- Distance pour afficher les marqueurs et vérifier la proximité

-- ============================================
-- MARQUEURS
-- ============================================

Config.Markers = {
    enabled = true, -- Activer/désactiver les marqueurs
    type = 1, -- Type de marqueur (1 = cylindre)
    size = { x = 3.0, y = 3.0, z = 1.0 }, -- Taille du marqueur
    color = { r = 255, g = 0, b = 0, a = 100 }, -- Couleur RGBA
    bobUpAndDown = false, -- Le marqueur bouge de haut en bas
    faceCamera = false, -- Le marqueur fait face à la caméra
    rotate = false -- Le marqueur tourne
}

-- ============================================
-- NOTIFICATIONS
-- ============================================

Config.Notifications = {
    alreadyRented = "Vous avez déjà un véhicule loué. Vous pouvez le supprimer au point indiqué sur votre GPS.",
    notEnoughMoney = "Vous n'avez pas assez d'argent.",
    noVehicleToDelete = "Vous n'avez pas de véhicule à supprimer.",
    vehicleRented = "Vous avez loué un %s pour $%s.",
    vehicleReady = "Votre %s est prêt. Plaque: %s",
    vehicleReturned = "Vous avez rendu le véhicule.",
    vehicleDeleted = "Vous avez payé %s$ pour supprimer le véhicule.",
    refundReceived = "Vous avez été remboursé de $%s",
    notRentedVehicle = "Ce n'est pas le véhicule loué.",
    noVehicleToReturn = "Vous n'avez pas de véhicule loué à rendre.",
    vehicleRecovered = "Votre véhicule de location a été récupéré.",
    noSpawnAvailable = "Aucun emplacement de spawn disponible."
}

-- ============================================
-- HELP NOTIFICATIONS
-- ============================================

Config.HelpNotifications = {
    openRental = "Appuyez sur ~INPUT_CONTEXT~ pour voir les locations",
    deleteVehicle = "Appuyez sur ~INPUT_CONTEXT~ pour supprimer le véhicule pour %s$",
    returnVehicle = "Appuyez sur ~INPUT_CONTEXT~ pour rendre le véhicule"
}
