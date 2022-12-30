BattleHandlers::AttackCalcUserItem.add(:MUSCLEBAND,
    proc { |_item, _user, _battle, attackMult|
        attackMult *= 1.1
        next attackMult
    }
)

BattleHandlers::AttackCalcUserItem.add(:CHOICEBAND,
  proc { |_item, _user, _battle, attackMult|
      attackMult *= 1.33
      next attackMult
  }
)

BattleHandlers::AttackCalcUserItem.add(:THICKCLUB,
  proc { |_item, user, _battle, attackMult|
      attackMult *= 1.5 if user.isSpecies?(:CUBONE) || user.isSpecies?(:MAROWAK)
      next attackMult
  }
)
