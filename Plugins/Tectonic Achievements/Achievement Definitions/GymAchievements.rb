GYM_LEVEL_CAPS = [
    15,
    20,
    25,
    30,
    40,
    45,
    55,
    60,
]

def checkCursedGymPerfectAchievement(gymNumber)
    return unless battlePerfected?
    return unless tarotAmuletActive?
    return unless getLevelCap <= GYM_LEVEL_CAPS[gymNumber-1]
    achievementID = ("PERFECT_CURSED_GYM_" + gymNumber).to_sym
    unlockAchievement(achievementID)
end