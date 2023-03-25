class PokeBattle_Battler
    #=============================================================================
    # Called when a Pokémon (self) is sent into battle or its ability changes.
    #=============================================================================
    def pbEffectsOnSwitchIn(switchIn = false)
        # Healing Wish/Lunar Dance/entry hazards
        @battle.pbOnActiveOne(self) if switchIn
        # Primal Revert upon entering battle
        @battle.pbPrimalReversion(@index) unless fainted?
        # Ending primordial weather, checking Trace
        pbContinualAbilityChecks(true)
        # Abilities that trigger upon switching in
        if (!fainted? && unstoppableAbility?) || abilityActive?
            eachAbility do |ability|
                BattleHandlers.triggerAbilityOnSwitchIn(ability, self, @battle)
            end
        end
        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather
        # Items that trigger upon switching in (Air Balloon message)
        if switchIn
            eachActiveItem do |item|
                BattleHandlers.triggerItemOnSwitchIn(item, self, @battle)
            end
        end
        # Berry check, status-curing ability check
        pbHeldItemTriggerCheck if switchIn
        pbAbilityStatusCureCheck
    end

    #=============================================================================
    # Ability effects
    #=============================================================================
    def pbAbilitiesOnSwitchOut
        eachActiveAbility do |ability|
            BattleHandlers.triggerAbilityOnSwitchOut(ability, self, false)
        end
        # Caretaker bonus
        pbRecoverHP(@totalhp / 16.0, false, false, false) if hasTribeBonus?(:CARETAKER)
        # Reset form
        @battle.peer.pbOnLeavingBattle(@battle, @pokemon, @battle.usedInBattle[idxOwnSide][@index / 2])
        # Treat self as fainted
        @hp = 0
        @fainted = true
        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather
    end

    def pbAbilitiesOnFainting
        # Self fainted; check all other battlers to see if their abilities trigger
        @battle.pbPriority(true).each do |b|
            next unless b
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerAbilityChangeOnBattlerFainting(ability, b, self, @battle)
            end
        end
        @battle.pbPriority(true).each do |b|
            next unless b
            b.eachActiveAbility do |ability|
                BattleHandlers.triggerAbilityOnBattlerFainting(ability, b, self, @battle)
            end
        end
        @battle.pbPriority(true).each do |b|
            next unless b
            next unless b.hasTribeBonus?(:SCOURGE)
            scoureHealingMsg = _INTL("#{b.pbThis} takes joy in #{pbThis(true)}'s pain!")
            pbShowTribeSplash(b.pbOwnSide,:SCOURGE)
            b.applyFractionalHealing(1/8.0, customMessage: scoureHealingMsg)
            pbHideTribeSplash(b.pbOwnSide)
        end
    end

    # Used for Emergency Exit/Wimp Out.
    def pbAbilitiesOnDamageTaken(oldHP, newHP = -1)
        newHP = @hp if newHP < 0
        return false if oldHP < @totalhp / 2 || newHP >= @totalhp / 2 # Didn't drop below half
        ret = false
        eachActiveAbility(true) do |ability|
            ret = true if BattleHandlers.triggerAbilityOnHPDroppedBelowHalf(ability, self, @battle)
        end
        return ret # Whether self has switched out
    end

    # Called when a Pokémon (self) enters battle, at the end of each move used,
    # and at the end of each round.
    def pbContinualAbilityChecks(onSwitchIn = false)
        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather
        # Trace
        if hasActiveAbility?(:TRACE)
            # NOTE: In Gen 5 only, Trace only triggers upon the Trace bearer switching
            #       in and not at any later times, even if a traceable ability turns
            #       up later. Essentials ignores this, and allows Trace to trigger
            #       whenever it can even in the old battle mechanics.
            choices = []
            @battle.eachOtherSideBattler(@index) do |b|
                next if b.ungainableAbility? ||
                        %i[POWEROFALCHEMY RECEIVER TRACE].include?(b.ability_id)
                choices.push(b)
            end
            if choices.length > 0
                choice = choices[@battle.pbRandom(choices.length)]
                @battle.pbShowAbilitySplash(self, :TRACE)
                stolenAbility = choice.ability
                self.ability = stolenAbility
                @battle.pbDisplay(_INTL("{1} traced {2}'s {3}!", pbThis, choice.pbThis(true), getAbilityName(stolenAbility)))
                @battle.pbHideAbilitySplash(self)
                if !onSwitchIn && (unstoppableAbility? || abilityActive?)
                    eachAbility do |ability|
                        BattleHandlers.triggerAbilityOnSwitchIn(ability, self, @battle)
                    end
                end
            end
        end
    end

    #=============================================================================
    # Ability curing
    #=============================================================================
    # Cures status conditions, confusion and infatuation.
    #=============================================================================
    def pbAbilityStatusCureCheck
        eachActiveAbility do |ability|
            BattleHandlers.triggerStatusCureAbility(ability, self)
        end

        if hasAnyStatusNoTrigger? && hasTribeBonus?(:TYRANICAL) && !pbOwnSide.effectActive?(:TyranicalImmunity)
            @battle.pbShowTribeSplash(self,:TYRANICAL)
            @battle.pbDisplay(_INTL("{1} refuses to be statused!", pbThis))
            pbCureStatus(true)
            @battle.pbHideTribeSplash(self)
            pbOwnSide.applyEffect(:TyranicalImmunity)
        end
    end

    #=============================================================================
    # Ability change
    #=============================================================================
    def pbOnAbilityChanged(oldAbil)
        if illusion? && oldAbil == :ILLUSION
            disableEffect(:Illusion)
            unless effectActive?(:Transform)
                @battle.scene.pbChangePokemon(self, @pokemon)
                @battle.pbDisplay(_INTL("{1}'s {2} wore off!", pbThis, GameData::Ability.get(oldAbil).name))
                @battle.pbSetSeen(self)
            end
        end
        disableEffect(:GastroAcid) if unstoppableAbility?
        disableEffect(:SlowStart) unless hasAbility?(:SLOWSTART)
        # Revert form if Flower Gift/Forecast was lost
        pbCheckFormOnWeatherChange
        # Check for end of primordial weather
        @battle.pbEndPrimordialWeather
    end

    #=============================================================================
    # Held item consuming/removing
    #=============================================================================
    def canConsumeBerry?
        return false if @battle.pbCheckOpposingAbility(%i[UNNERVE ASONEICE ASONEGHOST STRESSFUL], @index)
        return true
    end

    def canLeftovers?
        return false if @battle.pbCheckOpposingAbility(%i[UNNERVE ASONEICE ASONEGHOST], @index)
        return true
    end

    def canConsumeGem?
        return false if @battle.pbCheckOpposingAbility(%i[STRESSFUL], @index)
        return true
    end

    def canConsumePinchBerry?(check_gluttony = true)
        return false unless canConsumeBerry?
        return true if @hp <= @totalhp / 4
        return true if @hp <= @totalhp / 2 && (!check_gluttony || hasActiveAbility?(:GLUTTONY))
        return false
    end

    # permanent is whether the item is lost even after battle. Is false for Knock
    # Off.
    def pbRemoveItem(permanent = true)
        permanent = false # Items respawn after battle always!!
        disableEffect(:ChoiceBand)
        applyEffect(:ItemLost) if baseItem
        setInitialItem(nil) if permanent && baseItem == initialItem
        self.item = nil
    end

    #=========================================
    # Also handles SCAVENGE
    #=========================================
    def pbConsumeItem(item, recoverable = true, symbiosis = true, belch = true, scavenge = true)
        if item.nil?
            PBDebug.log("[Item not consumed] #{pbThis} could not consume a #{item} because it was already missing")
            return
        end
        itemData = GameData::Item.get(item)
        itemName = itemData.name
        PBDebug.log("[Item consumed] #{pbThis} consumed its held #{itemName}")
        @battle.triggerBattlerConsumedItemDialogue(self, item)
        if recoverable
            setRecycleItem(item)
            applyEffect(:PickupItem, item)
            applyEffect(:PickupUse, @battle.nextPickupUse)
        end
        setBelched if belch && itemData.is_berry?
        pbRemoveItem
        pbSymbiosis(item) if symbiosis
    end

    def pbSymbiosis(item)
        return if fainted?
        @battle.pbPriority(true).each do |b|
            next if b.opposes?
            next unless b.hasActiveAbility?(:SYMBIOSIS)
            next if !b.baseItem || b.unlosableItem?(b.baseItem)
            next if unlosableItem?(b.baseItem)
            @battle.pbShowAbilitySplash(b, :SYMBIOSIS)
            @battle.pbDisplay(_INTL("{1} copies its {2} to {3}!", b.pbThis, getItemName(baseItem), pbThis(true)))
            self.item = b.baseItem
            @battle.pbHideAbilitySplash(b)
            pbHeldItemTriggerCheck
            break
        end
    end

    # item_to_use is an item ID or GameData::Item object. ownitem is whether the
    # item is held by self. fling is for Fling only.
    def pbHeldItemTriggered(item_to_use, ownitem = true, fling = false)
        # Cheek Pouch and similar abilities
        if GameData::Item.get(item_to_use).is_berry?
            eachActiveAbility do |ability|
                BattleHandlers.triggerOnBerryConsumedAbility(ability, self, item_to_use, ownitem, @battle)
            end
        end
        pbConsumeItem(item_to_use) if ownitem
        pbSymbiosis(item_to_use) if !ownitem && !fling # Bug Bite/Pluck users trigger Symbiosis
    end

    #=============================================================================
    # Held item trigger checks
    #=============================================================================
    # NOTE: A Pokémon using Bug Bite/Pluck, and a Pokémon having an item thrown at
    #       it via Fling, will gain the effect of the item even if the Pokémon is
    #       affected by item-negating effects.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbHeldItemTriggerCheck(item_to_use = nil, fling = false)
        return if fainted?
        pbItemHPHealCheck(item_to_use, fling)
        pbItemStatusCureCheck(item_to_use, fling)
        pbItemEndOfMoveCheck(item_to_use, fling)
        # For Enigma Berry, Kee Berry and Maranga Berry, which have their effects
        # when forcibly consumed by Pluck/Fling.
        if item_to_use
            if BattleHandlers.triggerTargetItemOnHitPositiveBerry(item_to_use, self, @battle, true)
                pbHeldItemTriggered(item_to_use, false, fling)
            end
        end
    end

    def pbItemHPHealCheck(item_to_use = nil, fling = false)
        # Check for berry filching
        unless item_to_use
            eachActiveItem do |item|
                next unless GameData::Item.get(item).is_berry?
                filcher = nil

                @battle.eachBattler { |b|
                    next if b.index == @index
                    next unless b.hasActiveAbility?(:GREEDYGUTS)
                    filcher = b
                    break
                }
    
                # If the berry is being filched
                if filcher && BattleHandlers.triggerHPHealItem(item, filcher, @battle, false, self)
                    filcher.pbHeldItemTriggered(item, false)
                    pbConsumeItem(item)
                end
            end
        end

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems
        itemsToCheck.each do |item|
            # Check for user
            if BattleHandlers.triggerHPHealItem(item, self, @battle, forced, nil)
                pbHeldItemTriggered(item, !forced, fling)
                break
            elsif !forced
                pbItemTerrainStatBoostCheck
                pbItemFieldEffectCheck
            end
        end
    end

    # Cures status conditions, confusion, infatuation and the other effects cured
    # by Mental Herb.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbItemStatusCureCheck(item_to_use = nil, fling = false)
        return if fainted?

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems
        itemsToCheck.each do |item|
            if BattleHandlers.triggerStatusCureItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
                break
            end
        end
    end

    # Called at the end of using a move.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbItemEndOfMoveCheck(item_to_use = nil, fling = false)
        return if fainted?

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems
        itemsToCheck.each do |item|
            if BattleHandlers.triggerEndOfMoveItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
                break
            elsif BattleHandlers.triggerEndOfMoveStatRestoreItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
                break
            end
        end
    end

    # Used for White Herb (restore lowered stats). Only called by Moody and Sticky
    # Web, as all other stat reduction happens because of/during move usage and
    # this handler is also called at the end of each move's usage.
    # item_to_use is an item ID for Bug Bite/Pluck and Fling, and nil otherwise.
    # fling is for Fling only.
    def pbItemStatRestoreCheck(item_to_use = nil, fling = false)
        return if fainted?

        forced = !item_to_use.nil?

        itemsToCheck = forced ? [item_to_use] : activeItems

        itemsToCheck.each do |item|
            if BattleHandlers.triggerEndOfMoveStatRestoreItem(item, self, @battle, forced)
                pbHeldItemTriggered(item, !forced, fling)
                break
            end
        end
    end

    # Called when the battle terrain changes and when a Pokémon loses HP.
    def pbItemTerrainStatBoostCheck
        eachActiveItem do |item|
            pbHeldItemTriggered(item) if BattleHandlers.triggerTerrainStatBoostItem(item, self, @battle)
        end
    end

    def pbItemFieldEffectCheck
        eachActiveItem do |item|
            pbHeldItemTriggered(item) if BattleHandlers.triggerFieldEffectItem(item, self, @battle)
        end
    end

    # Used for Adrenaline Orb. Called when Intimidate is triggered (even if
    # Intimidate has no effect on the Pokémon).
    def pbItemOnIntimidatedCheck
        eachActiveItem do |item|
            pbHeldItemTriggered(item) if BattleHandlers.triggerItemOnIntimidated(item, self, @battle)
        end
    end
end
