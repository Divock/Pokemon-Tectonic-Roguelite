#########################################
# Terrain Abilities
#########################################

BattleHandlers::TargetAbilityOnHit.add(:SEEDSCATTER,
    proc { |_ability, _target, battler, _move, battle|
        terrainSetAbility(:Grassy, battler, battle)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:MISTCRAFT,
    proc { |_ability, _target, battler, _move, battle|
        terrainSetAbility(:Fairy, battler, battle)
    }
)

#########################################
# Weather Abilities
#########################################

BattleHandlers::TargetAbilityOnHit.add(:SANDBURST,
    proc { |_ability, _target, battler, _move, battle|
        pbBattleWeatherAbility(:Sandstorm, battler, battle, false, true)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:INNERLIGHT,
    proc { |_ability, _target, battler, _move, battle|
        pbBattleWeatherAbility(:Sun, battler, battle, false, true)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:STORMBRINGER,
    proc { |_ability, _target, battler, _move, battle|
        pbBattleWeatherAbility(:Rain, battler, battle, false, true)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:FROSTSCATTER,
    proc { |_ability, _target, battler, _move, battle|
        pbBattleWeatherAbility(:Hail, battler, battle, false, true)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:SUNEATER,
    proc { |_ability, _target, battler, _move, battle|
        pbBattleWeatherAbility(:Eclipse, battler, battle, false, true)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:LUNARLOYALTY,
    proc { |_ability, _target, battler, _move, battle|
        pbBattleWeatherAbility(:Moonglow, battler, battle, false, true)
    }
)

#########################################
# Other
#########################################

BattleHandlers::TargetAbilityOnHit.add(:THUNDERSTRUCK,
    proc { |_ability, _target, battler, _move, battle|
        battler.applyEffect(:Charge,2)
    }
)

BattleHandlers::TargetAbilityOnHit.add(:ANGERPOINT,
  proc { |_ability, _user, target, _move, battle|
      next unless target.damageState.critical
      next unless target.pbCanRaiseStatStage?(:ATTACK, target)
      battle.pbShowAbilitySplash(target)
      target.pbMaximizeStatStage(:ATTACK, target)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:GOOEY,
  proc { |_ability, user, target, move, _battle|
      next unless move.physicalMove?
      user.tryLowerStat(:SPEED, target, showAbilitySplash: true)
  }
)

BattleHandlers::TargetAbilityOnHit.copy(:GOOEY, :TANGLINGHAIR)

BattleHandlers::TargetAbilityOnHit.add(:ILLUSION,
  proc { |_ability, _user, target, _move, battle|
      # NOTE: This intentionally doesn't show the ability splash.
      next unless target.illusion?
      target.disableEffect(:Illusion)
      battle.scene.pbChangePokemon(target, target.pokemon)
      battle.pbSetSeen(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:RATTLED,
  proc { |_ability, _user, target, move, _battle|
      next unless %i[BUG DARK GHOST].include?(move.calcType)
      target.tryRaiseStat(:SPEED, target, showAbilitySplash: true)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:STAMINA,
  proc { |_ability, _user, target, _move, _battle|
      target.tryRaiseStat(:DEFENSE, target, showAbilitySplash: true)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:WATERCOMPACTION,
  proc { |_ability, _user, target, move, _battle|
      next if move.calcType != :WATER
      target.tryRaiseStat(:DEFENSE, target, increment: 2, showAbilitySplash: true)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:WEAKARMOR,
  proc { |_ability, _user, target, move, battle|
      next unless move.physicalMove?
      next unless target.pbCanLowerAnyOfStats?(%i[DEFENSE SPEED], target)
      battle.pbShowAbilitySplash(target)
      target.tryLowerStat(:DEFENSE, target)
      target.tryRaiseStat(:SPEED, target, increment: 2)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:WEAKSPIRIT,
    proc { |_ability, _user, target, move, battle|
        next unless move.specialMove?
        next unless target.pbCanLowerAnyOfStats?(%i[SPECIAL_DEFENSE SPEED], target)
        battle.pbShowAbilitySplash(target)
        target.tryLowerStat(:SPECIAL_DEFENSE, target)
        target.tryRaiseStat(:SPEED, target, increment: 2)
        battle.pbHideAbilitySplash(target)
    }
  )

BattleHandlers::TargetAbilityOnHit.add(:AFTERMATH,
  proc { |_ability, user, target, move, battle|
      next unless target.fainted?
      next unless move.physicalMove?
      battle.pbShowAbilitySplash(target)
      unless battle.moldBreaker
          dampBattler = battle.pbCheckGlobalAbility(:DAMP)
          if dampBattler
              battle.pbShowAbilitySplash(dampBattler)
              battle.pbDisplay(_INTL("{1} cannot use {2}!", target.pbThis, target.abilityName))
              battle.pbHideAbilitySplash(dampBattler)
              battle.pbHideAbilitySplash(target)
              next
          end
      end
      if user.takesIndirectDamage?(true)
          battle.pbDisplay(_INTL("{1} was caught in the aftermath!", user.pbThis))
          user.applyFractionalDamage(1.0 / 4.0)
      end
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:INNARDSOUT,
  proc { |_ability, user, target, _move, battle|
      next unless target.fainted? || user.dummy
      battle.pbShowAbilitySplash(target)
      if user.takesIndirectDamage?(true)
          battle.pbDisplay(_INTL("{1} is hurt!", user.pbThis))
          oldHP = user.hp
          damageTaken = target.damageState.hpLost
          damageTaken /= 4 if target.boss?
          user.damageState.displayedDamage = damageTaken
          battle.scene.pbDamageAnimation(user)
          user.pbReduceHP(damageTaken, false)
          user.pbHealthLossChecks(oldHP)
      end
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:STATIC,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.numbed? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyNumb(target) if user.canNumb?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:LIVEWIRE,
  proc { |_ability, user, target, move, battle|
      next unless move.specialMove?
      next if user.numbed? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyNumb(target) if user.canNumb?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:CURSEDBODY,
  proc { |_ability, user, target, move, battle|
      next if user.fainted? || user.effectActive?(:Disable) 
      battle.pbShowAbilitySplash(target)
      user.applyEffect(:Disable, 3) if user.canBeDisabled?
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:MUMMY,
  proc { |ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.fainted?
      next if user.unstoppableAbility? || user.ability == ability
      oldAbil = nil
      battle.pbShowAbilitySplash(target) if user.opposes?(target)
      oldAbil = user.ability
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      user.ability = ability
      battle.pbReplaceAbilitySplash(user) if user.opposes?(target)
      battle.pbDisplay(_INTL("{1}'s Ability became {2}!", user.pbThis, user.abilityName))
      battle.pbHideAbilitySplash(user) if user.opposes?(target)
      battle.pbHideAbilitySplash(target) if user.opposes?(target)
      user.pbOnAbilityChanged(oldAbil) unless oldAbil.nil?
  }
)

BattleHandlers::TargetAbilityOnHit.add(:IRONBARBS,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      battle.pbShowAbilitySplash(target)
      if user.takesIndirectDamage?(true)
          battle.pbDisplay(_INTL("{1} is hurt!", user.pbThis))
          user.applyFractionalDamage(1.0 / 8.0)
      end
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.copy(:IRONBARBS, :ROUGHSKIN)

BattleHandlers::TargetAbilityOnHit.add(:FLAMEBODY,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.burned? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyBurn(target) if user.canBurn?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:FIERYSPIRIT,
  proc { |_ability, user, target, move, battle|
      next unless move.specialMove?
      next if user.burned? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyBurn(target) if user.canBurn?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)


BattleHandlers::TargetAbilityOnHit.add(:EFFECTSPORE,
  proc { |_ability, user, target, move, battle|
      # NOTE: This ability has a 30% chance of triggering, not a 30% chance of
      #       inflicting a status condition. It can try (and fail) to inflict a
      #       status condition that the user is immune to.
      next unless move.physicalMove?
      next if battle.pbRandom(100) >= 30
      r = battle.pbRandom(3)
      next if r == 0 && user.asleep?
      next if r == 1 && user.poisoned?
      next if r == 2 && user.numbed?
      battle.pbShowAbilitySplash(target)
      if user.affectedByPowder?(true)
          case r
          when 0
              user.applySleep if user.canSleep?(target, true)
          when 1
              user.applyPoison(target) if user.canPoison?(target, true)
          when 2
              user.applyNumb(target) if user.canNumb?(target, true)
          end
      end
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:POISONPOINT,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.poisoned? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyPoison(target) if user.canPoison?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:STEAMENGINE,
  proc { |_ability, _user, target, move, _battle|
      next if move.calcType != :FIRE && move.calcType != :WATER
      target.tryRaiseStat(:SPEED, target, increment: 6, showAbilitySplash: true)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:PERISHBODY,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.effectActive?(:PerishSong)
      battle.pbShowAbilitySplash(target)
      battle.pbDisplay(_INTL("Both Pokémon will faint in three turns!"))
      user.applyEffect(:PerishSong, 3)
      target.applyEffect(:PerishSong, 3) unless target.effectActive?(:PerishSong)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:COTTONDOWN,
  proc { |_ability, _user, target, _move, battle|
      battle.pbShowAbilitySplash(target)
      target.eachOpposing do |b|
          b.tryLowerStat(:SPEED, target)
      end
      target.eachAlly do |b|
          b.tryLowerStat(:SPEED, target)
      end
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:GULPMISSILE,
  proc { |_ability, user, target, _move, battle|
      next if target.form == 0
      if target.species == :CRAMORANT
          battle.pbShowAbilitySplash(target)
          gulpform = target.form
          target.form = 0
          battle.scene.pbChangePokemon(target, target.pokemon)
          battle.scene.pbDamageAnimation(user)
          user.applyFractionalDamage(1.0 / 4.0) if user.takesIndirectDamage?(true)
          if gulpform == 1
              user.tryLowerStat(:DEFENSE, target, showAbilitySplash: true)
          elsif gulpform == 2
              msg = nil
              user.applyNumb(target, msg)
          end
          battle.pbHideAbilitySplash(target)
      end
  }
)

BattleHandlers::TargetAbilityOnHit.add(:WANDERINGSPIRIT,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.fainted?
      abilityBlacklist = [
          :DISGUISE,
          :FLOWERGIFT,
          :GULPMISSILE,
          :ICEFACE,
          :IMPOSTER,
          :RECEIVER,
          :RKSSYSTEM,
          :SCHOOLING,
          :STANCECHANGE,
          :WONDERGUARD,
          :ZENMODE,
          # Abilities that are plain old blocked.
          :NEUTRALIZINGGAS,
      ]
      failed = false
      abilityBlacklist.each do |abil|
          next if user.ability != abil
          failed = true
          break
      end
      next if failed
      oldAbil = -1
      battle.pbShowAbilitySplash(target) if user.opposes?(target)
      oldAbil = user.ability
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      user.ability = :WANDERINGSPIRIT
      target.ability = oldAbil
      if user.opposes?(target)
          battle.pbReplaceAbilitySplash(user)
          battle.pbReplaceAbilitySplash(target)
      end
      battle.pbDisplay(_INTL("{1}'s Ability became {2}!", user.pbThis, user.abilityName))
      battle.pbHideAbilitySplash(user)
      battle.pbHideAbilitySplash(target) if user.opposes?(target)
      if oldAbil
          user.pbOnAbilityChanged(oldAbil)
          target.pbOnAbilityChanged(:WANDERINGSPIRIT)
      end
  }
)

BattleHandlers::TargetAbilityOnHit.add(:FEEDBACK,
  proc { |_ability, user, target, move, battle|
      next unless move.specialMove?(user)
      battle.pbShowAbilitySplash(target)
      if user.takesIndirectDamage?(true)
          battle.pbDisplay(_INTL("{1} is hurt!", user.pbThis))
          user.applyFractionalDamage(1.0 / 8.0)
      end
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:POISONPUNISH,
  proc { |_ability, user, target, move, battle|
      next unless move.specialMove?
      next if battle.pbRandom(100) >= 30
      next if user.poisoned?
      battle.pbShowAbilitySplash(target)
      user.applyPoison(target) if user.canPoison?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:SUDDENCHILL,
  proc { |_ability, user, target, move, battle|
      next unless move.specialMove?
      next if battle.pbRandom(100) >= 30
      next if user.frostbitten?
      battle.pbShowAbilitySplash(target)
      user.applyFrostbite(target) if user.canFrostbite?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:CHILLEDBODY,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if battle.pbRandom(100) >= 30
      next if user.frostbitten?
      battle.pbShowAbilitySplash(target)
      user.applyFrostbite(target) if user.canFrostbite?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:CURSEDTAIL,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.effectActive?(:Curse) || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyEffect(:Curse)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:BEGUILING,
  proc { |_ability, user, target, move, battle|
      next if target.fainted?
      next if move.physicalMove?
      next if battle.pbRandom(100) >= 30
      next if user.dizzy?
      battle.pbShowAbilitySplash(target)
      user.applyDizzy(target) if user.canDizzy?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:DISORIENT,
  proc { |_ability, user, target, move, battle|
      next if target.fainted?
      next unless move.physicalMove?
      next if battle.pbRandom(100) >= 30
      next if user.dizzy?
      battle.pbShowAbilitySplash(target)
      user.applyDizzy(target) if user.canDizzy?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:GRIT,
  proc { |_ability, _user, target, _move, _battle|
      target.tryRaiseStat(:SPECIAL_DEFENSE, target, showAbilitySplash: true)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:ADAPTIVESKIN,
  proc { |_ability, _user, target, move, _battle|
      if move.physicalMove?
          target.tryRaiseStat(:DEFENSE, target, showAbilitySplash: true)
      else
          target.tryRaiseStat(:SPECIAL_DEFENSE, target, showAbilitySplash: true)
      end
  }
)

BattleHandlers::TargetAbilityOnHit.add(:QUILLERINSTINCT,
  proc { |_ability, _user, target, _move, battle|
      next if target.pbOpposingSide.effectAtMax?(:Spikes)
      battle.pbShowAbilitySplash(target)
      target.pbOpposingSide.incrementEffect(:Spikes)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:ARCCONDUCTOR,
  proc { |_ability, user, target, _move, battle|
      next unless battle.rainy?
      battle.pbShowAbilitySplash(target)
      if user.takesIndirectDamage?(true)
          battle.pbDisplay(_INTL("{1} is hurt!", user.pbThis))
          user.applyFractionalDamage(1.0 / 6.0)
      end
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:PETRIFYING,
  proc { |_ability, user, target, _move, battle|
      next if user.numbed? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyNumb(target) if user.canNumb?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:FORCEREVERSAL,
  proc { |_ability, _user, target, _move, _battle|
      next unless Effectiveness.resistant?(target.damageState.typeMod)
      target.pbRaiseMultipleStatStages([:ATTACK, 1, :SPECIAL_ATTACK, 1], target, showAbilitySplash: true)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:RELUCTANTBLADE,
  proc { |_ability, user, target, move, battle|
      battle.forceUseMove(target, :LEAFAGE, user.index, true, nil, nil, true) if move.physicalMove? && !target.fainted?
  }
)

BattleHandlers::TargetAbilityOnHit.add(:WIBBLEWOBBLE,
  proc { |_ability, user, target, _move, battle|
      next if target.fainted?
      battle.forceUseMove(target, :POWERSPLIT, user.index, true, nil, nil, true)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:CONSTRICTOR,
  proc { |_ability, user, target, move, battle|
      battle.forceUseMove(target, :BIND, user.index, true, nil, nil, true) if move.physicalMove? && !target.fainted?
  }
)

BattleHandlers::TargetAbilityOnHit.add(:KELPLINK,
  proc { |_ability, user, target, move, battle|
      next unless move.physicalMove?
      next if user.leeched? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyLeeched(target) if user.canLeech?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:PLAYVICTIM,
  proc { |_ability, user, target, move, battle|
      next unless move.specialMove?
      next if user.leeched? || battle.pbRandom(100) >= 30
      battle.pbShowAbilitySplash(target)
      user.applyLeeched(target) if user.canLeech?(target, true)
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:SPINTENSITY,
  proc { |_ability, user, target, _move, battle|
      next unless target.stages[:SPEED] > 0
      battle.pbShowAbilitySplash(target)
      battle.pbDisplay(_INTL("#{user.pbThis} catches the full force of #{target.pbThis(true)}'s Speed!"))
      oldStage = target.stages[:SPEED]
      user.applyFractionalDamage(oldStage / 6.0)
      battle.pbCommonAnimation("StatDown", target)
      target.stages[:SPEED] = 0
      battle.pbHideAbilitySplash(target)
  }
)

BattleHandlers::TargetAbilityOnHit.add(:TOTALMIRROR,
    proc { |_ability, user, target, move, battle|
        battle.forceUseMove(target, move.id, user.index, true, nil, nil, true) if move.specialMove? && !target.fainted?
    }
)

BattleHandlers::TargetAbilityOnHit.add(:ROCKCYCLE,
    proc { |_ability, target, battler, _move, battle|
        target.pbOwnSide.applyEffect(:ErodedRock) if move.physicalMove?
    }
)