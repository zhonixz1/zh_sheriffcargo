Config = {}

Config.DefaultRoute = "valentine"
Config.OpenCommand = "setup_cargo"
Config.RouteRecordCommandName = "record_route"

Config.RouteRecorder = {
    interval = 500,
    minDistance = 8.0,
    defaultSpeed = 4.5,
    defaultArrivalDistance = 1.4
}

-- "manual": /setup_cargo opens the setup menu.
-- "automatic": cargo starts at the configured server times.
Config.SpawnMode = "manual"

Config.Automatic = {
    -- Uses the server machine's local clock (24-hour format).
    times = {
        {hour = 12, minute = 0},
        {hour = 18, minute = 0}
    },
    route = "valentine",
    -- These rewards are sanitized against Config.MarketItems.
    items = {
        {item = "consumable_coffee", amount = 1},
        {item = "consumable_medicine", amount = 1}
    },
    checkInterval = 15000
}

Config.Permissions = {
    enabled = true,
    jobs = {
        sheriff = true,
        police = true,
        marshal = true
    },
    minimumJobGrade = 0,
    denyMessage = "Only authorized sheriff staff can use this command."
}

Config.UI = {
    title = "Cargo Setup",
    subtitle = "Choose a route and load the cargo chest",
    maxTotalItems = 30,
    maxPerItem = 10,
    emptySelectionText = "The chest is empty",
    startButton = "Start Cargo",
    cancelButton = "Close"
}

Config.MarketItems = {
    {item = "consumable_coffee", label = "Coffee", image = "item/consumable_coffee.png", defaultAmount = 1, maxAmount = 5},
    {item = "consumable_peach", label = "Peach", image = "item/consumable_peach.png", defaultAmount = 1, maxAmount = 5},
    {item = "consumable_medicine", label = "Medicine", image = "item/consumable_medicine.png", defaultAmount = 1, maxAmount = 3},
    {item = "ammorevolvernormal", label = "Revolver Ammo", image = false, defaultAmount = 1, maxAmount = 10}
}

Config.Notifications = {
    enabled = true,
    duration = 6000,
    manualStarted = "The cargo wagon has started its route.",
    automaticStarted = "A scheduled cargo wagon has started its route.",
    alreadyActive = "A cargo wagon is already active.",
    opened = "The cargo chest has been opened.",
    noInventorySpace = "You do not have enough space or you reached the item limit."
}

Config.Blip = {
    enabled = true,
    name = "cargo",
    style = 1664425300,
    sprite = "blip_ambient_coach",
    scale = 0.2
}

Config.Models = {
    vehicle = "coach4",
    driver = "s_m_m_coachtaxidriver_01",
    crate = "p_crate01x"
}

Config.Controls = {
    interact = 0xCEFD9220, -- E
    disableWhileCarrying = true,
    disabledWhileCarrying = {
        0x07CE1E61,
        0xF84FA74F,
        0xB2F377E8,
        0xC1989F95,
        0xD8F73058 
    }
}

Config.Timing = {
    modelLoadTimeout = 5000,
    requestControlTimeout = 3000,
    deleteControlTimeout = 1000,
    routeCheckInterval = 500,
    routeTaskRefreshInterval = 5000,
    spawnRegisterTimeout = 15000,
    idleInteractionInterval = 500,
    holdToOpen = 1200,
    cleanupAfterRoute = 5000,
    driverSeatCheckDelay = 250
}

Config.Driving = {
    speed = 8.0,
    drivingStyle = 262144,
    stoppingRange = 2.0,
    straightLineDistance = -1.0,
    arrivalDistance = 5.0,
    startPointIndex = 2
}

Config.Crate = {
    interactionDistance = 2.0,
    spawnZOffset = 1.0,
    attachToWagon = {
        bone = 0,
        offset = vector3(0.0, -1.50, 0.35),
        rotation = vector3(0.0, 0.0, 90.0)
    },
    attachToPlayer = {
        boneName = "SKEL_Spine2",
        fallbackBone = 0,
        offset = vector3(0.0, -0.32, 0.22),
        rotation = vector3(90.0, 85.0, 0.0)
    }
}

Config.Network = {
    canMigrate = true,
    alwaysExistsForPlayers = true,
    cullingRadius = 3000.0
}

Config.routePoints = {
    ["valentine"] = {
        label = "Valentine Route",
        locations = {
            {coords = vector3(-216.0961, 625.4980, 116.2943)},
            {coords = vector3(-129.6071, 568.3389, 113.5835)},
            {coords = vector3(-61.3760, 368.7657, 113.8761)},
            {coords = vector3(-94.9770, 252.7098, 103.0539)},
            {coords = vector3(-170.4528, 219.6492, 84.3196)},
            {coords = vector3(-164.4931, 197.7179, 90.0639)}
        }
    },
    ["heartland"] = {
        label = "Heartland Route",
        driving = {
            speed = 7.0,
            stoppingRange = 0.5,
            straightLineDistance = -1.0,
            arrivalDistance = 1.4,
            routeCheckInterval = 150,
            startPointIndex = 2
        },
        locations = {
            {coords = vector3(-184.9689, 611.1081, 113.3610)},
            {coords = vector3(-150.4631, 582.0602, 112.8104)},
            {coords = vector3(-85.7593, 575.3840, 116.6646)},
            {coords = vector3(41.5733, 575.0474, 132.6751)},
            {coords = vector3(144.6789, 570.2433, 125.5757)},
            {coords = vector3(303.8988, 736.6031, 148.5595)},
            {coords = vector3(346.9674, 874.5909, 158.5806)},
            {coords = vector3(470.9425, 957.8622, 161.9688)},
            {coords = vector3(490.7878, 946.8092, 157.4790)},
            {coords = vector3(514.9238, 897.7377, 144.0178)},
            {coords = vector3(550.1050, 892.8484, 146.3713)},
            {coords = vector3(648.0540, 881.0336, 144.2011)},
            {coords = vector3(768.9002, 829.9281, 119.5888)},
            {coords = vector3(789.6569, 850.7990, 118.4469)},
            {coords = vector3(776.5261, 871.8481, 120.9027)}
        }
    },
    ["yenirota"] = {
    label = "New Route",
    driving = {
        speed = 8.0,
        stoppingRange = 0.5,
        straightLineDistance = -1.0,
        arrivalDistance = 4.0,
        routeCheckInterval = 150,
        startPointIndex = 2
    },
    locations = {
        {coords = vector3(-169.8155, 575.8483, 112.2890)},
        {coords = vector3(-161.5804, 578.5157, 112.4481)},
        {coords = vector3(-148.9261, 580.5520, 112.8480)},
        {coords = vector3(-137.5416, 580.7397, 112.9938)},
        {coords = vector3(-124.5420, 580.8749, 113.1472)},
        {coords = vector3(-111.0029, 579.6483, 113.5524)},
        {coords = vector3(-96.6702, 576.5765, 114.7001)},
        {coords = vector3(-83.7677, 573.9917, 117.0070)},
        {coords = vector3(-71.9131, 574.2631, 119.3757)},
        {coords = vector3(-61.2028, 578.1122, 122.3964)},
        {coords = vector3(-50.9041, 580.5884, 125.2630)},
        {coords = vector3(-40.7569, 583.7306, 126.9019)},
        {coords = vector3(-29.3134, 586.3486, 127.2718)},
        {coords = vector3(-16.8963, 587.7335, 127.1930)},
        {coords = vector3(-4.7868, 587.1404, 127.5774)},
        {coords = vector3(7.0985, 584.9830, 128.5193)},
        {coords = vector3(18.7788, 581.3894, 129.2686)},
        {coords = vector3(30.0763, 577.7195, 130.5830)},
        {coords = vector3(41.3474, 573.3714, 132.6619)},
        {coords = vector3(51.7790, 568.6321, 135.2500)},
        {coords = vector3(61.3963, 564.6892, 137.9785)},
        {coords = vector3(71.3673, 560.7092, 139.7677)},
        {coords = vector3(81.7752, 556.9995, 141.2484)},
        {coords = vector3(93.5863, 554.2079, 141.9063)},
        {coords = vector3(105.7911, 551.7680, 141.6850)},
        {coords = vector3(117.4927, 548.5195, 141.1467)},
        {coords = vector3(128.5511, 543.3854, 140.2194)},
        {coords = vector3(139.0378, 537.4572, 139.3527)},
        {coords = vector3(149.1898, 530.4136, 138.2768)},
        {coords = vector3(158.4152, 522.3820, 137.0104)},
        {coords = vector3(167.3092, 514.1142, 134.5878)},
        {coords = vector3(176.0289, 505.9467, 132.0291)},
        {coords = vector3(184.9186, 497.6103, 129.1146)},
        {coords = vector3(193.8161, 489.3544, 125.8896)},
        {coords = vector3(202.6151, 481.6196, 122.5360)},
        {coords = vector3(212.9256, 475.4044, 120.6899)},
        {coords = vector3(224.3338, 472.8203, 119.4507)},
        {coords = vector3(236.6079, 472.9091, 119.0062)},
        {coords = vector3(248.9227, 473.2831, 119.6248)},
        {coords = vector3(260.6508, 470.5746, 120.1656)},
        {coords = vector3(272.0119, 466.9557, 119.9311)},
        {coords = vector3(283.6576, 463.2035, 119.3457)},
        {coords = vector3(295.1718, 459.4237, 117.9098)},
        {coords = vector3(306.9683, 455.6475, 116.0337)},
        {coords = vector3(318.8124, 452.6023, 114.4217)},
        {coords = vector3(330.7355, 452.1041, 113.5362)},
        {coords = vector3(342.6152, 449.2892, 112.6179)},
        {coords = vector3(353.6550, 444.0504, 111.5573)},
        {coords = vector3(364.5958, 438.5317, 110.4218)},
        {coords = vector3(376.2623, 434.3037, 109.5739)},
        {coords = vector3(387.7013, 432.5703, 109.2633)},
        {coords = vector3(396.3510, 430.1444, 109.0692)},
        {coords = vector3(404.6163, 424.3967, 108.6686)},
        {coords = vector3(414.2508, 419.1345, 108.4260)},
        {coords = vector3(424.7479, 413.6346, 108.1981)},
        {coords = vector3(435.5495, 408.0023, 107.9632)},
        {coords = vector3(446.2313, 402.4285, 107.7587)},
        {coords = vector3(457.1926, 396.6242, 107.8523)},
        {coords = vector3(467.4207, 389.7605, 107.9380)},
        {coords = vector3(477.7322, 383.2318, 108.1554)},
        {coords = vector3(488.4613, 377.0130, 108.4351)},
        {coords = vector3(499.3040, 370.9783, 108.0951)},
        {coords = vector3(508.3617, 367.1994, 107.5174)},
        {coords = vector3(519.1523, 364.5495, 107.1726)},
        {coords = vector3(528.0272, 364.7010, 106.8797)},
        {coords = vector3(538.5645, 364.8194, 106.8003)},
        {coords = vector3(550.0007, 364.2563, 106.8862)},
        {coords = vector3(561.9369, 363.2921, 106.7308)},
        {coords = vector3(573.7817, 362.8186, 106.6716)},
        {coords = vector3(586.0752, 364.0946, 106.6538)},
        {coords = vector3(597.6569, 367.8347, 106.2980)},
        {coords = vector3(608.7930, 373.1741, 105.8788)},
        {coords = vector3(619.2232, 380.0717, 105.6671)},
        {coords = vector3(629.7736, 386.5597, 106.0843)},
        {coords = vector3(640.8607, 391.4849, 106.1649)},
        {coords = vector3(652.3131, 395.9198, 106.8618)},
        {coords = vector3(663.8289, 400.2136, 107.6941)},
        {coords = vector3(675.3898, 404.6996, 107.9212)},
        {coords = vector3(686.4731, 409.3283, 107.4436)},
        {coords = vector3(698.3085, 412.9969, 107.5337)},
        {coords = vector3(710.3662, 414.4805, 107.8711)},
        {coords = vector3(721.8758, 411.7322, 108.0249)},
        {coords = vector3(732.1198, 405.8414, 108.2900)},
        {coords = vector3(741.5760, 398.1527, 108.5107)},
        {coords = vector3(750.8503, 390.1805, 108.9812)},
        {coords = vector3(761.1920, 383.8948, 109.8713)},
        {coords = vector3(772.6949, 381.0058, 111.4459)},
        {coords = vector3(784.4471, 379.7616, 113.1052)},
        {coords = vector3(796.6175, 378.4231, 114.3541)},
        {coords = vector3(808.1065, 377.4625, 115.7503)},
        {coords = vector3(818.7329, 378.9495, 117.6208)},
        {coords = vector3(829.2396, 382.6413, 118.6348)},
        {coords = vector3(840.6716, 386.3850, 118.6391)},
        {coords = vector3(852.6226, 388.1296, 118.1513)},
        {coords = vector3(864.4341, 388.9656, 117.7435)},
        {coords = vector3(873.2886, 389.0989, 117.3971)},
        {coords = vector3(882.6003, 389.1028, 117.4539)},
        {coords = vector3(891.1044, 389.1976, 117.1648)},
        {coords = vector3(899.4611, 382.7109, 116.8067)},
        {coords = vector3(904.2574, 375.2407, 115.7546)},
        {coords = vector3(906.7853, 365.2650, 115.4270)},
        {coords = vector3(908.1381, 355.6033, 115.3115)},
        {coords = vector3(909.0622, 344.7804, 114.6441)},
        {coords = vector3(908.9122, 334.5115, 114.5810)},
        {coords = vector3(905.5823, 323.3113, 115.8617)},
        {coords = vector3(899.7190, 317.7753, 116.4989)},
        {coords = vector3(896.6538, 308.3437, 116.1698)},
        {coords = vector3(896.5838, 299.5891, 115.6688)},
        {coords = vector3(896.3484, 295.0647, 115.7024)}
    }
}
}
