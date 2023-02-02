BattleHandlers::CriticalCalcUserAbility.add(:SUPERLUCK,
  proc { |_ability, _user, _target, _move, c|
      next c + 2
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:STAMPEDE,
  proc { |_ability, user, _target, _move, c|
      next c + user.stages[:SPEED]
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:RAZORSEDGE,
  proc { |_ability, _user, _target, move, c|
      next c + 1 if move.slashMove?
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:NIGHTVISION,
  proc { |_ability, user, _target, _move, c|
      next c + 1 if user.battle.pbWeather == :Moonglow
  }
)

BattleHandlers::CriticalCalcUserAbility.add(:SANDDRILLING,
  proc { |_ability, user, _target, _move, c|
      next c + 1 if user.battle.pbWeather == :Sandstorm
  }
)