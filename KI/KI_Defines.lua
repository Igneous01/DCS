if not KI then
  KI = {}
end

KI.Defines = {}

KI.Defines.Event = {}
KI.Defines.Event.KI_EVENT_CARGO_PACKED = "KI_EVENT_CARGO_PACKED"
KI.Defines.Event.KI_EVENT_CARGO_UNPACKED = "KI_EVENT_CARGO_UNPACKED"
KI.Defines.Event.KI_EVENT_SLING_HOOK = "KI_EVENT_SLING_HOOK"
KI.Defines.Event.KI_EVENT_SLING_UNHOOK = "KI_EVENT_SLING_UNHOOK"
KI.Defines.Event.KI_EVENT_TRANSPORT_MOUNT = "KI_EVENT_TRANSPORT_MOUNT"
KI.Defines.Event.KI_EVENT_TRANSPORT_DISMOUNT = "KI_EVENT_TRANSPORT_DISMOUNT"
KI.Defines.Event.KI_EVENT_DEPOT_RESUPPLY = "KI_EVENT_DEPOT_RESUPPLY"
KI.Defines.Event.KI_EVENT_SIDEMISSION_COMPLETE = "KI_EVENT_SIDEMISSION_COMPLETE"
KI.Defines.Event.KI_EVENT_ZONE_CHANGED = "KI_EVENT_ZONE_CHANGED"

KI.Defines.EventNames = 
{
  [world.event.S_EVENT_SHOT] = "SHOT",
  [world.event.S_EVENT_SHOOTING_START] = "SHOOTING_START",
  [world.event.S_EVENT_SHOOTING_END] = "SHOOTING_END",
  [world.event.S_EVENT_HIT] = "HIT",
  [world.event.S_EVENT_TAKEOFF] = "TAKEOFF",
  [world.event.S_EVENT_LAND] = "LAND",
  [world.event.S_EVENT_CRASH] = "CRASH",
  [world.event.S_EVENT_DEAD] = "DEAD",
  [world.event.S_EVENT_EJECTION] = "EJECTION",
  [world.event.S_EVENT_PILOT_DEAD] = "PILOT_DEAD",
  [world.event.S_EVENT_PLAYER_LEAVE_UNIT] = "PLAYER_LEAVE_UNIT",
  [world.event.S_EVENT_REFUELING] = "REFUELING",
  [world.event.S_EVENT_REFUELING_STOP] = "REFUELING_STOP",
  
  -- KI Custom Events
  [KI.Defines.Event.KI_EVENT_CARGO_PACKED] = "CARGO_PACKED",
  [KI.Defines.Event.KI_EVENT_CARGO_UNPACKED] = "CARGO_UNPACKED",
  [KI.Defines.Event.KI_EVENT_SLING_HOOK] = "SLING_HOOK",
  [KI.Defines.Event.KI_EVENT_SLING_UNHOOK] = "SLING_UNHOOK",
  [KI.Defines.Event.KI_EVENT_TRANSPORT_MOUNT] = "TRANSPORT_MOUNT",
  [KI.Defines.Event.KI_EVENT_TRANSPORT_DISMOUNT] = "TRANSPORT_DISMOUNT",
  [KI.Defines.Event.KI_EVENT_DEPOT_RESUPPLY] = "DEPOT_RESUPPLY",
  [KI.Defines.Event.KI_EVENT_SIDEMISSION_COMPLETE] = "SIDEMISSION_COMPLETE",
  [KI.Defines.Event.KI_EVENT_ZONE_CHANGED] = "ZONE_CHANGED"
}

KI.Defines.WeaponCategories =
{
  [Weapon.Category.SHELL] = "SHELL",
  [Weapon.Category.MISSILE] = "MISSILE",
  [Weapon.Category.ROCKET] = "ROCKET",
  [Weapon.Category.BOMB] = "BOMB"
}

KI.Defines.UnitCategories =
{
  [Unit.Category.AIRPLANE] = "AIR",
  [Unit.Category.HELICOPTER] = "HELICOPTER",
  [Unit.Category.GROUND_UNIT] = "GROUND",
  [Unit.Category.SHIP] = "SHIP",
  [Unit.Category.STRUCTURE] = "STRUCTURE"
}

KI.Defines.UnitTypes = 
{
	["2B11 mortar"] = "ARTILLERY",
	["SAU Gvozdika"] = "ARTILLERY",
	["SAU Msta"] = "ARTILLERY",
	["SAU Akatsia"] = "ARTILLERY",
	["SAU 2-C9"] = "ARTILLERY",
	["M-109"] = "ARTILLERY",
	["SpGH_Dana"] = "ARTILLERY",
	
	["Bunker"] = "FORTIFICATION",
	["Sandbox"] = "FORTIFICATION",
	["house1arm"] = "FORTIFICATION",
	["house2arm"] = "FORTIFICATION",
	["outpost_road"] = "FORTIFICATION",
	["outpost"] = "FORTIFICATION",
	["houseA_arm"] = "FORTIFICATION",
	
	["AAV7"] = "APC",
	["BMD-1"] = "APC",
	["BMP-1"] = "APC",
	["BMP-2"] = "APC",
	["BMP-3"] = "APC",
	["M1128 Stryker MGS"] = "APC",
	["Boman"] = "APC",
	["BRDM-2"] = "APC",
	["BTR-80"] = "APC",
	["BTR_D"] = "APC",
	["Cobra"] = "APC",
	["LAV-25"] = "APC",
	["M1043 HMMWV Armament"] = "APC",
	["M1045 HMMWV TOW"] = "APC",
	["M1126 Stryker ICV"] = "APC",
	["M-113"] = "APC",
	["M1134 Stryker ATGM"] = "APC",
	["M-2 Bradley"] = "APC",
	["Marder"] = "APC",
	["MCV-80"] = "APC",
	["MTLB"] = "APC",
	["TPZ"] = "APC",
	["Tigr_233036"] = "APC",
	
	["Paratrooper RPG-16"] = "INFANTRY",
	["Paratrooper AKS-74"] = "INFANTRY",
	["Soldier AK"] = "INFANTRY",
	["Infantry AK Ins"] = "INFANTRY",
	["Infantry AK"] = "INFANTRY",
	["Soldier M249"] = "INFANTRY",
	["Soldier M4"] = "INFANTRY",
	["Soldier M4 GRG"] = "INFANTRY",
	["Soldier RPG"] = "INFANTRY",
	
	["Grad-URAL"] = "MLRS",
	["Uragan_BM-27"] = "MLRS",
	["Smerch"] = "MLRS",
	["MLRS"] = "MLRS",
	
	["2S6 Tunguska"] = "SAM",
	["Kub 2P25 ln"] = "SAM",
	["5p73 s-125 ln"] = "SAM",
	["S-300PS 5P85C ln"] = "SAM",
	["S-300PS 5P85D ln"] = "SAM",
	["SA-11 Buk LN 9A310M1"] = "SAM",
	["Osa 9A33 ln"] = "SAM",
	["Tor 9A331"] = "SAM",
	["Strela-10M3"] = "SAM",
	["Strela-1 9P31"] = "SAM",
	["Hawk ln"] = "SAM",
	["M48 Chaparral"] = "SAM",
	["M6 Linebacker"] = "SAM",
	["Patriot ln"] = "SAM",
	["M1097 Avenger"] = "SAM",
	["Roland ADS"] = "SAM",
	
	["S-300PS 54K6 cp"] = "SAM_CC",
	["SA-11 Buk CC 9S470M1"] = "SAM_CC",
	["Hawk pcp"] = "SAM_CC",
	
	["SA-18 Igla manpad"] = "MANPADS",
	["SA-18 Igla comm"] = "MANPADS",
	["Igla manpad INS"] = "MANPADS",
	["SA-18 Igla-S manpad"] = "MANPADS",
	["SA-18 Igla-S comm"] = "MANPADS",
	["Stinger comm dsr"] = "MANPADS",
	["Stinger comm"] = "MANPADS",
	["Soldier stinger"] = "MANPADS",
	
	["Vulcan"] = "AAA",
	["Gepard"] = "AAA",
	["ZSU-23-4 Shilka"] = "AAA",
	["ZU-23 Emplacement Closed"] = "AAA",
	["ZU-23 Emplacement"] = "AAA",
	["ZU-23 Closed Insurgent"] = "AAA",
	["Ural-375 ZU-23 Insurgent"] = "AAA",
	["ZU-23 Insurgent"] = "AAA",
	["Ural-375 ZU-23"] = "AAA",
	
	["1L13 EWR"] = "EWR",
	["55G6 EWR"] = "EWR",
	
	["S-300PS 64H6E sr"] = "SAM_RADAR",
	["SA-11 Buk SR 9S18M1"] = "SAM_RADAR",
	["Dog Ear radar"] = "SAM_RADAR",
	["Hawk tr"] = "SAM_RADAR",
	["Hawk sr"] = "SAM_RADAR",
	["Patriot str"] = "SAM_RADAR",
	["Hawk cwar"] = "SAM_RADAR",
	["p-19 s-125 sr"] = "SAM_RADAR",
	["Roland Radar"] = "SAM SR",
	["snr s-125 tr"] = "SAM_RADAR",
	["Kub 1S91 str"] = "SAM_RADAR",
	["S-300PS 40B6M tr"] = "SAM_RADAR",
	["S-300PS 40B6MD sr"] = "SAM_RADAR",
	
	["Challenger2"] = "TANK",
	["Leclerc"] = "TANK",
	["Leopard1A3"] = "TANK",
	["Leopard-2"] = "TANK",
	["M-60"] = "TANK",	
	["M-1 Abrams"] = "TANK",
	["Merkava_Mk4"] = "TANK",
	["T-55"] = "TANK",
	["T-72B"] = "TANK",
	["T-80UD"] = "TANK",
	["T-90"] = "TANK",
	["TrainTest"] = "TANK",

	["Patriot EPP"] = "TRUCK",
	["Patriot cp"] = "TRUCK",	
	["SA-8 Osa LD 9T217"] = "TRUCK",
	["Patriot AMG"] = "TRUCK",
	["Patriot ECS"] = "TRUCK",
	
	["Ural-4320 APA-5D"] = "TRUCK",
	["ATMZ-5"] = "TRUCK",
	["ATZ-10"] = "TRUCK",
	["GAZ-3307"] = "TRUCK",
	["GAZ-3308"] = "TRUCK",
	["GAZ-66"] = "TRUCK",
	["M978 HEMTT Tanker"] = "TRUCK",
	["HEMTT TFFT"] = "TRUCK",
	["IKARUS Bus"] = "TRUCK",
	["KAMAZ Truck"] = "TRUCK",
	["KrAZ6322"] = "TRUCK",
	["LAZ Bus"] = "TRUCK",
	["Hummer"] = "APC",
	["M 818"] = "TRUCK",
	["MAZ-6303"] = "TRUCK",
	["Predator GCS"] = "TRUCK",
	["Predator TrojanSpirit"] = "TRUCK",
	["Ural ATsP-6"] = "TRUCK",
	["Ural-375 PBU"] = "TRUCK",
	["Ural-375"] = "TRUCK",
	["Ural-4320-31"] = "TRUCK",
	["Ural-4320T"] = "TRUCK",
	["ZiL-131 APA-80"] = "TRUCK",
	["SKP-11"] = "TRUCK",
	["ZIL-131 KUNG"] = "TRUCK",
	["ZIL-4331"] = "TRUCK",
	["Trolley bus"] = "TRUCK",
	
	["Suidae"] = "CAR",
	["UAZ-469"] = "CAR",
	["VAZ Car"] = "CAR",
	
	["A-10A"] = "STRIKER",
	["A-10C"] = "STRIKER",
	["A-50"] = "AWACS",
	["An-26B"] = "TRANSPORT",
	["An-30M"] = "TRANSPORT",
	["B-1B"] = "BOMBER",
	["B-52H"] = "BOMBER",
	["BAE Harrier"] = "BOMBER",
	["C-130"] = "TRANSPORT",
	["C-17A"] = "TRANSPORT",
	["E-2C"] = "AWACS",
	["E-3A"] = "AWACS",
	["F-111F"] = "BOMBER",
	["F-117A"] = "BOMBER",
	["F-14A"] = "FIGHTER",
	["F-15C"] = "FIGHTER",
	["F-15E"] = "FIGHTER",
	["F-16A MLU"] = "MULTIROLE",
	["F-16A"] = "MULTIROLE",
	["F-16C bl.52d"] = "MULTIROLE",
	["F-16C bl.50"] = "MULTIROLE",
	["F-4E"] = "MULTIROLE",
	["F/A-18A"] = "MULTIROLE",
	["F/A-18C"] = "MULTIROLE",
	["IL-76MD"] = "TRANSPORT",
	["IL-78M"] = "TANKER",
	["KC-10A"] = "TANKER",
	["KC-135"] = "TANKER",
	["MiG-23MLD"] = "FIGHTER",
	["MiG-25PD"] = "FIGHTER",
	["MiG-25RBT"] = "FIGHTER",
	["MiG-27K"] = "BOMBER",
	["MiG-29A"] = "FIGHTER",
	["MiG-29G"] = "FIGHTER",
	["MiG-29K"] = "MULTIROLE",
	["MiG-29S"] = "FIGHTER",
	["MiG-31"] = "FIGHTER",
	["Mirage 2000-5"] = "MULTIROLE",
	["P-51B"] = "STRIKER",
	["P-51D"] = "STRIKER",
	["RQ-1A Predator"] = "UAV",
	["S-3B Tanker"] = "TANKER",
	["S-3B"] = "TRANSPORT",
	["Su-17M4"] = "BOMBER",
	["Su-24M"] = "BOMBER",
	["Su-24MR"] = "BOMBER",
	["Su-25"] = "STRIKER",
	["Su-25T"] = "STRIKER",
	["Su-25TM"] = "STRIKER",
	["Su-27"] = "FIGHTER",
	["Su-30"] = "MULTIROLE",
	["Su-33"] = "FIGHTER",
	["Su-34"] = "BOMBER",
	["Tornado GR4"] = "BOMBER",
	["Tornado IDS"] = "BOMBER",
	["Tu-142"] = "BOMBER",
	["Tu-160"] = "BOMBER",
	["Tu-22M3"] = "BOMBER",
	["Tu-95MS"] = "BOMBER",
	["Yak-40"] = "TRANSPORT",
	
	["UH-1H"] = "TRANSPORT_HELO",
	["AH-1W"] = "ATTACK_HELO",
	["AH-64A"] = "ATTACK_HELO",
	["AH-64D"] = "ATTACK_HELO",
	["CH-47D"] = "TRANSPORT_HELO",
	["CH-53E"] = "TRANSPORT_HELO",
	["Ka-27"] = "TRANSPORT_HELO",
	["Ka-50"] = "ATTACK_HELO",
	["Ka-52"] = "ATTACK_HELO",
	["Mi-24V"] = "ATTACK_HELO",
	["Mi-26"] = "TRANSPORT_HELO",
	["Mi-28N"] = "ATTACK_HELO",
	["Mi-8MT"] = "TRANSPORT_HELO",
	["OH-58D"] = "ATTACK_HELO",
	["SH-3W"] = "TRANSPORT_HELO",
	["SH-60B"] = "ATTACK_HELO",
	["UH-60A"] = "TRANSPORT_HELO",
}












