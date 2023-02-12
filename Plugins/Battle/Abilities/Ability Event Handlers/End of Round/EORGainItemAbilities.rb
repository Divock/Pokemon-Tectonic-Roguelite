BattleHandlers::EORGainItemAbility.add(:HARVEST,
    proc { |_ability, battler, battle|
        next if battler.item
        next if !battler.recycleItem || !GameData::Item.get(battler.recycleItem).is_berry?
        next if !battle.sunny? && !(battle.pbRandom(100) < 50)
        battle.pbShowAbilitySplash(battler)
        battler.item = battler.recycleItem
        battler.setRecycleItem(nil)
        battler.setInitialItem(battler.item) unless battler.initialItem
        battle.pbDisplay(_INTL("{1} harvested one {2}!", battler.pbThis, battler.itemName))
        battle.pbHideAbilitySplash(battler)
        battler.pbHeldItemTriggerCheck
    }
)

BattleHandlers::EORGainItemAbility.add(:LARDER,
    proc { |_ability, battler, battle|
        next if battler.item
        next if !battler.recycleItem || !GameData::Item.get(battler.recycleItem).is_berry?
        battle.pbShowAbilitySplash(battler)
        battler.item = battler.recycleItem
        battler.setRecycleItem(nil)
        battler.setInitialItem(battler.item) unless battler.initialItem
        battle.pbDisplay(_INTL("{1} withdrew one {2}!", battler.pbThis, battler.itemName))
        battle.pbHideAbilitySplash(battler)
        battler.pbHeldItemTriggerCheck
    }
)

BattleHandlers::EORGainItemAbility.add(:PICKUP,
  proc { |_ability, battler, battle|
      next if battler.item
      foundItem = nil
      fromBattler = nil
      use = 0
      battle.eachBattler do |b|
          next if b.index == battler.index
          next if b.effects[:PickupUse] <= use
          foundItem   = b.effects[:PickupItem]
          fromBattler = b
          use         = b.effects[:PickupUse]
      end
      next unless foundItem
      battle.pbShowAbilitySplash(battler)
      battler.item = foundItem
      fromBattler.disableEffect(:PickupItem)
      fromBattler.setRecycleItem(nil) if fromBattler.recycleItem == foundItem
      if battle.wildBattle? && !battler.initialItem && fromBattler.initialItem == foundItem
          battler.setInitialItem(foundItem)
          fromBattler.setInitialItem(nil)
      end
      battle.pbDisplay(_INTL("{1} found one {2}!", battler.pbThis, battler.itemName))
      battle.pbHideAbilitySplash(battler)
      battler.pbHeldItemTriggerCheck
  }
)

BattleHandlers::EORGainItemAbility.add(:GOURMAND,
    proc { |_ability, battler, battle|
        next if battler.item
        battle.pbShowAbilitySplash(battler)
        battler.item =
            %i[
                ORANBERRY GANLONBERRY LANSATBERRY APICOTBERRY LIECHIBERRY
                PETAYABERRY SALACBERRY STARFBERRY MICLEBERRY SITREONBERRY
            ].sample
        battle.pbDisplay(_INTL("{1} was delivered one {2}!", battler.pbThis, battler.itemName))
        battle.pbHideAbilitySplash(battler)
        battler.pbHeldItemTriggerCheck
    }
)