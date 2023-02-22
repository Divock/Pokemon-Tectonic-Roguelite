##########################################
# Team combo effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :EchoedVoiceCounter,
    :real_name => "Echoed Voice Counter",
    :type => :Integer,
    :maximum => 5,
    :court_changed => false,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :EchoedVoiceUsed,
    :real_name => "Echoed Voice Used",
    :resets_eor => true,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Round,
    :real_name => "Round Singers",
    :resets_eor => true,
})

##########################################
# Screens
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Reflect,
    :real_name => "Reflect",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1}'s Defense is raised! This will last for #{value - 1} more turns!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Reflect was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Reflect wore off.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :LightScreen,
    :real_name => "Light Screen",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1}'s Sp. Def is raised! This will last for #{value - 1} more turns!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Light Screen was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Light Screen wore off.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :AuroraVeil,
    :real_name => "Aurora Veil",
    :type => :Integer,
    :ticks_down => true,
    :is_screen => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1}'s Defense and Sp. Def are raised! This will last for #{value - 1} more turns!",
teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Aurora Veil was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Aurora Veil wore off!", teamName))
    end,
})

##########################################
# Misc. immunity effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :LuckyChant,
    :real_name => "Lucky Chant",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} is now blessed!", teamName))
        battle.pbDisplay(_INTL("They'll be protected from critical hits for #{value - 1} more turns!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Lucky Chant was broken!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer protected by Lucky Chant.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Mist,
    :real_name => "Mist",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} is shrouded in mist!", teamName))
        battle.pbDisplay(_INTL("Their stats can't be lowered for #{value - 1} more turns!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Mist was swept away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer protected by Mist.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Safeguard,
    :real_name => "Safeguard",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("{1} became cloaked in a mystical veil!", teamName))
        battle.pbDisplay(_INTL("They'll be protected from status ailments for #{value - 1} more turns!", value))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Safeguard was removed!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1} is no longer protected by Safeguard.", teamName))
    end,
})

##########################################
# Temporary full side protecion effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :CraftyShield,
    :real_name => "Crafty Shield",
    :resets_eor => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("Crafty Shield protected {1}!", teamName))
    end,
    :protection_info => {
        :does_negate_proc => proc do |user, _target, move, _battle|
            move.statusMove? && !move.pbTarget(user).targets_all
        end,
    },
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :MatBlock,
    :real_name => "Mat Block",
    :resets_eor => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("The kicked up mat will block attacks against #{teamName} this turn!"))
    end,
    :protection_info => {
        :does_negate_proc => proc do |_user, _target, move, _battle|
            move.damagingMove?
        end,
    },
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :QuickGuard,
    :real_name => "Quick Guard",
    :resets_eor => true,
    :protection_info => {
        :does_negate_proc => proc do |user, _target, _move, battle|
            # Checking the move priority saved from pbCalculatePriority
            battle.choices[user.index][4] > 0
        end,
    },
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :WideGuard,
    :real_name => "Wide Guard",
    :resets_eor => true,
    :protection_info => {
        :does_negate_proc => proc do |user, _target, move, _battle|
            move.pbTarget(user).num_targets > 1
        end,
    },
})

##########################################
# Pledge combo effects
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Rainbow,
    :real_name => "Rainbow Turns",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A rainbow appeared in the sky above {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Rainbow on {1}'s side was sent away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Rainbow on {1}'s side dissapeared.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :SeaOfFire,
    :real_name => "Sea of Fire Turns",
    :type => :Integer,
    :ticks_down => true,
    :remain_proc => proc do |battle, side, _teamName|
        battle.pbCommonAnimation("SeaOfFire") if side.index == 0
        battle.pbCommonAnimation("SeaOfFireOpp") if side.index == 1
        battle.eachBattler.each do |b|
            next if b.opposes?(side.index)
            next if !b.takesIndirectDamage? || b.pbHasType?(:FIRE)
            battle.pbDisplay(_INTL("{1} is hurt by the sea of fire!", b.pbThis))
            b.applyFractionalDamage(1.0 / 8.0)
        end
    end,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A sea of fire enveloped {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Sea of Fire on {1}'s side was sent away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Sea of Fire on {1}'s side dissapeared.", teamName))
    end,
})
GameData::BattleEffect.register_effect(:Side, {
    :id => :Swamp,
    :real_name => "Swamp Turns",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A swamp enveloped {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Swamp on {1}'s side was sent away!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Swamp on {1}'s side dissapeared.", teamName))
    end,
})

##########################################
# Hazards
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Spikes,
    :real_name => "Spikes Count",
    :type => :Integer,
    :maximum => 2,
    :is_hazard => true,
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of Spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Spikes around {1}'s feet were swept aside!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :PoisonSpikes,
    :real_name => "Poison Spikes",
    :type => :Integer,
    :maximum => 2,
    :type_applying_hazard => {
        :status => :POISON,
        :absorb_proc => proc do |pokemonOrBattler|
            pokemonOrBattler.hasType?(:POISON)
        end,
    },
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Poison Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of Poison Spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Poison Spikes around {1}'s feet were swept aside!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :FlameSpikes,
    :real_name => "Flame Spikes",
    :type => :Integer,
    :maximum => 2,
    :type_applying_hazard => {
        :status => :BURN,
        :absorb_proc => proc do |pokemonOrBattler|
            pokemonOrBattler.hasType?(:FIRE)
        end,
    },
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Flame Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of Flame Spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Flame Spikes around {1}'s feet were swept aside!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :FrostSpikes,
    :real_name => "Frost Spikes",
    :type => :Integer,
    :maximum => 2,
    :is_hazard => true,
    :type_applying_hazard => {
        :status => :FROSTBITE,
        :absorb_proc => proc do |pokemonOrBattler|
            pokemonOrBattler.hasType?(:ICE)
        end,
    },
    :increment_proc => proc do |battle, _side, teamName, _value, increment|
        if increment == 1
            battle.pbDisplay(_INTL("Frost Spikes were scattered all around {1}'s feet!", teamName))
        else
            battle.pbDisplay(_INTL("{1} layers of Frost Spikes were scattered all around {2}'s feet!", increment,
teamName))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The Frost Spikes around {1}'s feet were swept aside!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :StealthRock,
    :real_name => "Stealth Rock",
    :is_hazard => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The pointed stones around {1} were removed!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :FeatherWard,
    :real_name => "Feather Ward",
    :is_hazard => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("Sharp feathers float in the air around {1}!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The sharp feathers around {1} were removed!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :StickyWeb,
    :real_name => "Sticky Web",
    :is_hazard => true,
    :apply_proc => proc do |battle, _side, teamName, _value|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("A sticky web has been laid out beneath {1}'s feet!", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        teamName[0] = teamName[0].downcase
        battle.pbDisplay(_INTL("The sticky web beneath {1}'s feet was removed!", teamName))
    end,
})

##########################################
# Internal Tracking
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :LastRoundFainted,
    :real_name => "Last Round Fainted",
    :type => :Integer,
    :default => -1,
    :info_displayed => false,
    :court_changed => false,
})

##########################################
# Other
##########################################
GameData::BattleEffect.register_effect(:Side, {
    :id => :Tailwind,
    :real_name => "Tailwind Turns",
    :type => :Integer,
    :ticks_down => true,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("A Tailwind blew from behind {1}!", teamName))
        if value > 99
            battle.pbDisplay(_INTL("It will last forever!"))
        else
            battle.pbDisplay(_INTL("It will last for #{value - 1} more turns!"))
        end
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Tailwind was stopped!", teamName))
    end,
    :expire_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("{1}'s Tailwind petered out.", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :EmpoweredEmbargo,
    :real_name => "Items Supressed",
    :apply_proc => proc do |battle, _side, teamName, _value|
        battle.pbDisplay(_INTL("{1} can no longer use items!", teamName))
    end,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :Bulwark,
    :real_name => "Bulwark",
    :resets_eor => true,
})

GameData::BattleEffect.register_effect(:Side, {
    :id => :ErodedRock,
    :real_name => "Eroded Rocks",
    :type => :Integer,
    :maximum => 4,
    :apply_proc => proc do |battle, _side, teamName, value|
        battle.pbDisplay(_INTL("A rock lands on the ground around {1}.", teamName))
    end,
    :disable_proc => proc do |battle, _side, teamName|
        battle.pbDisplay(_INTL("Each rock on the ground around {1} was absorbed!", teamName))
    end,
})