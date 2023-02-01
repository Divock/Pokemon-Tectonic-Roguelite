BattleHandlers::AccuracyCalcUserAbility.add(:COMPOUNDEYES,
    proc { |_ability, mults, _user, _target, _move, _type|
        mults[:accuracy_multiplier] *= 1.3
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:HUSTLE,
  proc { |_ability, mults, _user, _target, move, _type|
      mults[:accuracy_multiplier] *= 0.8 if move.physicalMove?
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:KEENEYE,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:evasion_stage] = 0 if mults[:evasion_stage] > 0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:NOGUARD,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:base_accuracy] = 0
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:UNAWARE,
  proc { |_ability, mults, _user, _target, move, _type|
      mults[:evasion_stage] = 0 if move.damagingMove?
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:VICTORYSTAR,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 1.1
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:OCULAR,
  proc { |_ability, mults, _user, _target, _move, _type|
      mults[:accuracy_multiplier] *= 1.5
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:SANDSNIPER,
    proc { |_ability, mults, user, _target, _move, _type|
        mults[:base_accuracy] = 0 if user.battle.pbWeather == :Sandstorm
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:NIGHTOWL,
  proc { |_ability, mults, user, _target, _move, _type|
      mults[:base_accuracy] = 0 if user.battle.pbWeather == :Moonglow
  }
)

BattleHandlers::AccuracyCalcUserAbility.add(:AQUASNEAK,
    proc { |_ability, mults, user, _target, _move, _type|
        mults[:base_accuracy] = 0 if user.turnCount <= 1
    }
)

BattleHandlers::AccuracyCalcUserAbility.add(:STARSALIGN,
  proc { |_ability, mults, user, _target, _move, _type|
      mults[:base_accuracy] = 0 if user.battle.pbWeather == :Eclipse
  }
)
