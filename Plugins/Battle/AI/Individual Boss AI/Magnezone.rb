# Lock On
PokeBattle_AI::BossSpeciesUseMoveCodeIfAndOnlyIf.add([:MAGNEZONE,"0A6"],
  proc { |speciesAndMove,user,target|
	next user.battle.commandPhasesThisRound == battler.battle.numBossOnlyTurns
  }
)

# Zap Cannon
PokeBattle_AI::BossSpeciesUseMoveIDIfAndOnlyIf.add([:MAGNEZONE,:ZAPCANNON],
	 proc { |speciesAndMove,user,target|
	next user.battle.commandPhasesThisRound == 0 && user.effects[PBEffects::LockOnPos] == target.index
  }
)