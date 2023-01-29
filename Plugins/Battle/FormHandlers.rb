MultipleForms.register(:AMPHAROS, {
    "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
        next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
    },
})

MultipleForms.register(:GARCHOMP, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:GYARADOS, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:LYCANROC, {
  "getFormOnLeavingBattle" => proc { |pkmn, _battle, _usedInBattle, endBattle|
      next 0 if pkmn.form == 1 && (pkmn.fainted? || endBattle)
  },
})

MultipleForms.register(:ZAMAZENTA,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.item == :RUSTEDSHIELD
    next 0
  }
})

MultipleForms.register(:ZACIAN,{
  "getForm" => proc { |pkmn|
    next 1 if pkmn.item == :RUSTEDSWORD
    next 0
  }
})
