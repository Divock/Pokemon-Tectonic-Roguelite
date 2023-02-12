#=============================================================================
# Queries about what the battler has
#=============================================================================
class PokeBattle_Battler
    def isSpecies?(species)
        return @pokemon&.isSpecies?(species)
    end

    # Returns the active types of this Pokémon. The array should not include the
    # same type more than once, and should not include any invalid type numbers
    # (e.g. -1).
    def pbTypes(withType3 = false, allowIllusions = false)
        # If the pokemon is disguised as another pokemon, fake its type bars
        if allowIllusions && illusion?
            ret = disguisedAs.types
        else
            ret = [@type1]
            ret.push(@type2) if @type2 != @type1
        end
        # Burn Up erases the Fire-type.
        ret.delete(:FIRE) if effectActive?(:BurnUp)
        # Cold Conversion erases the Ice-type.
        ret.delete(:ICE) if effectActive?(:ColdConversion)
        # Dry Heat erases the Water-type.
        ret.delete(:WATER) if effectActive?(:DryHeat)
        # Roost erases the Flying-type. If there are no types left, adds the Normal-
        # type.
        if effectActive?(:Roost)
            ret.delete(:FLYING)
            ret.push(:NORMAL) if ret.length.zero?
        end
        # Add the third type specially.
        ret.push(@effects[:Type3]) if withType3 && effectActive?(:Type3) && !ret.include?(@effects[:Type3])
        return ret
    end

    def pbHasType?(type)
        return false unless type
        activeTypes = pbTypes(true)
        return activeTypes.include?(GameData::Type.get(type).id)
    end
    alias hasType? pbHasType?

    def pbHasOtherType?(type)
        return false unless type
        activeTypes = pbTypes(true)
        activeTypes.delete(GameData::Type.get(type).id)
        return activeTypes.length.positive?
    end

    # NOTE: Do not create any held item which affects whether a Pokémon's ability
    #       is active. The ability Klutz affects whether a Pokémon's item is
    #       active, and the code for the two combined would cause an infinite loop
    #       (regardless of whether any Pokémon actualy has either the ability or
    #       the item - the code existing is enough to cause the loop).
    def abilityActive?(ignore_fainted = false, ignore_gas = false)
        return false if fainted? && !ignore_fainted
        return false if !ignore_gas && @battle.field.effectActive?(:NeutralizingGas)
        return false if effectActive?(:GastroAcid)
        return false if dizzy? && !%i[MARVELSCALE MARVELSKIN].include?(@ability_id)
        return true
    end

    def hasActiveAbility?(check_ability, ignore_fainted = false, checkingForAI = false)
        return hasActiveAbilityAI?(check_ability, ignore_fainted) if checkingForAI
        return false unless abilityActive?(ignore_fainted)
        return check_ability.include?(@ability_id) if check_ability.is_a?(Array)
        return false if ability.nil?
        return check_ability == ability.id
    end
    alias hasWorkingAbility hasActiveAbility?

    def hasActiveNeutralizingGas?(ignore_fainted = false)
        return @ability_id == :NEUTRALIZINGGAS && abilityActive?(ignore_fainted, true)
    end

    alias hasType? pbHasType?

    # Applies to both losing self's ability (i.e. being replaced by another) and
    # having self's ability be negated.
    def unstoppableAbility?(abil = nil)
        abil ||= @ability_id
        abil = GameData::Ability.try_get(abil)
        return false unless abil
        ability_blacklist = [
            # Form-changing abilities
            :BATTLEBOND,
            :DISGUISE,
            :MULTITYPE,
            :POWERCONSTRUCT,
            :SCHOOLING,
            :SHIELDSDOWN,
            :STANCECHANGE,
            :ZENMODE,
            :ICEFACE,
            # Abilities intended to be inherent properties of a certain species
            :COMATOSE,
            :RKSSYSTEM,
            :GULPMISSILE,
            :ASONEICE,
            :ASONEGHOST,
            # Abilities with undefined behaviour if they were replaced or moved around
            :STYLISH,
            :FRIENDTOALL,
        ]
        return ability_blacklist.include?(abil.id)
    end

    # Applies to gaining the ability.
    def ungainableAbility?(abil = nil)
        abil ||= @ability_id
        abil = GameData::Ability.try_get(abil)
        return false unless abil
        ability_blacklist = [
            # Form-changing abilities
            :BATTLEBOND,
            :DISGUISE,
            :FLOWERGIFT,
            :FORECAST,
            :MULTITYPE,
            :POWERCONSTRUCT,
            :SCHOOLING,
            :SHIELDSDOWN,
            :STANCECHANGE,
            :ZENMODE,
            :SEALORD,
            :DUNEPREDATOR,
            :GROWUP,
            # Appearance-changing abilities
            :ILLUSION,
            :IMPOSTER,
            # Abilities intended to be inherent properties of a certain species
            :COMATOSE,
            :RKSSYSTEM,
            :NEUTRALIZINGGAS,
            :HUNGERSWITCH,
            # Abilities with undefined behaviour if they were replaced or moved around
            :STYLISH,
        ]
        return ability_blacklist.include?(abil.id)
    end

    def itemActive?(ignoreFainted = false)
        return false if fainted? && !ignoreFainted
        return false if effectActive?(:Embargo)
        return false if pbOwnSide.effectActive?(:EmpoweredEmbargo)
        return false if hasActiveAbility?(:KLUTZ, ignoreFainted)
        return true
    end

    def hasActiveItem?(check_item, ignore_fainted = false)
        return false unless itemActive?(ignore_fainted)
        return check_item.include?(@item_id) if check_item.is_a?(Array)
        return check_item == @item_id
    end
    alias hasWorkingItem hasActiveItem?

    # Returns whether the specified item will be unlosable for this Pokémon.
    def unlosableItem?(check_item, showMessages = false)
        return false unless check_item
        return true if GameData::Item.get(check_item).is_mail?
        return false if effectActive?(:Transform)
        # Items that change a Pokémon's form
        if mega? # Check if item was needed for this Mega Evolution
            return true if @pokemon.species_data.mega_stone == check_item
        else # Check if item could cause a Mega Evolution
            GameData::Species.each do |data|
                next if data.species != @species || data.unmega_form != @form
                return true if data.mega_stone == check_item
            end
        end
        if check_item == :LUNCHBOX
            @battle.pbDisplay(_INTL("But #{pbThis(false)} hold's tightly onto its Lunch Box!")) if showMessages
            return true
        end
        # Other unlosable items
        return GameData::Item.get(check_item).unlosable?(@species, ability)
    end

    def eachMove(&block)
        @moves.each(&block)
    end

    def eachMoveWithIndex(&block)
        @moves.each_with_index(&block)
    end

    def pbHasMove?(move_id)
        return false unless move_id
        eachMove { |m| return true if m.id == move_id }
        return false
    end

    def pbHasMoveType?(check_type)
        return false unless check_type
        check_type = GameData::Type.get(check_type).id
        eachMove { |m| return true if m.type == check_type }
        return false
    end

    def pbHasMoveFunction?(*arg)
        return false unless arg
        eachMove do |m|
            arg.each { |code| return true if m.function == code }
        end
        return false
    end

    def hasMoldBreaker?
        return hasActiveAbility?(%i[MOLDBREAKER TERAVOLT TURBOBLAZE CLEAVING])
    end

    def canChangeType?
        return !%i[MULTITYPE RKSSYSTEM].include?(@ability_id)
    end

    def airborne?(checkingForAI = false)
        return false if hasActiveItem?(:IRONBALL)
        return false if effectActive?(:Ingrain)
        return false if effectActive?(:SmackDown)
        return false if @battle.field.effectActive?(:Gravity)
        return true if shouldTypeApply?(:FLYING, checkingForAI)
        return true if hasLevitate?(checkingForAI) && !@battle.moldBreaker
        return true if hasActiveItem?(LEVITATION_ITEMS)
        return true if effectActive?(:MagnetRise)
        return true if effectActive?(:Telekinesis)
        return false
    end

    def hasLevitate?(checkingForAI = false)
        return shouldAbilityApply?(%i[LEVITATE DESERTSPIRIT], checkingForAI)
    end

    def takesIndirectDamage?(showMsg = false)
        return false if fainted?
        if hasActiveAbility?(:MAGICGUARD)
            if showMsg
                @battle.pbShowAbilitySplash(self)
                @battle.pbDisplay(_INTL("{1} is unaffected!", pbThis))
                @battle.pbHideAbilitySplash(self)
            end
            return false
        end
        return true
    end

    def affectedByPowder?(showMsg = false)
        return false if fainted?
        if pbHasType?(:GRASS) && Settings::MORE_TYPE_EFFECTS
            @battle.pbDisplay(_INTL("{1} is unaffected!", pbThis)) if showMsg
            return false
        end
        if hasActiveAbility?(:OVERCOAT) && !@battle.moldBreaker
            if showMsg
                @battle.pbShowAbilitySplash(self)
                @battle.pbDisplay(_INTL("{1} is unaffected!", pbThis))
                @battle.pbHideAbilitySplash(self)
            end
            return false
        end
        if hasActiveItem?(:SAFETYGOGGLES)
            @battle.pbDisplay(_INTL("{1} is unaffected because of its {2}!", pbThis, itemName)) if showMsg
            return false
        end
        return true
    end

    def canHeal?
        return false if fainted? || @hp >= @totalhp
        return false if effectActive?(:HealBlock)
        return false if hasActiveAbility?(:ONEDGE) && @battle.pbWeather == :Moonglow
        return true
    end

    def movedThisRound?
        return @lastRoundMoved && @lastRoundMoved == @battle.turnCount
    end

    def usingMultiTurnAttack?
        @effects.each do |effect, value|
            effectData = GameData::BattleEffect.get(effect)
            next unless effectData.multi_turn_tracker?
            return true if effectData.active_value?(value)
        end
        return false
    end

    def inTwoTurnAttack?(*arg)
        return false unless effectActive?(:TwoTurnAttack)
        ttaFunction = GameData::Move.get(@effects[:TwoTurnAttack]).function_code
        arg.each { |a| return true if a == ttaFunction }
        return false
    end

    def semiInvulnerable?
        return inTwoTurnAttack?("0C9", "0CA", "0CB", "0CC", "0CD", "0CE", "14D")
    end

    def pbEncoredMoveIndex
        return -1 unless effectActive?(:Encore)
        ret = -1
        eachMoveWithIndex do |m, i|
            next if m.id != @effects[:EncoreMove]
            ret = i
            break
        end
        return ret
    end

    def initialItem
        return @battle.initialItems[@index & 1][@pokemonIndex]
    end

    def setInitialItem(newItem)
        @battle.initialItems[@index & 1][@pokemonIndex] = newItem
    end

    def recycleItem
        return @battle.recycleItems[@index & 1][@pokemonIndex]
    end

    def setRecycleItem(newItem)
        @battle.recycleItems[@index & 1][@pokemonIndex] = newItem
    end

    def belched?
        return @battle.belch[@index & 1][@pokemonIndex]
    end

    def setBelched
        @battle.belch[@index & 1][@pokemonIndex] = true
    end

    def empowered?
        return @avatarPhase > 1
    end

    def resetExtraMovesPerTurn
        @pokemon.extraMovesPerTurn = GameData::Avatar.get(@species).num_turns - 1
    end

    def evenTurn?
        return @battle.turnCount.even?
    end

    def oddTurn?
        return @battle.turnCount.odd?
    end

    def lastTurnThisRound?
        return @battle.commandPhasesThisRound == extraMovesPerTurn
    end

    def firstTurnThisRound?
        return @battle.firstTurnThisRound?
    end

    # Turn check starts at 1
    def nthTurnThisRound?(turnCheck)
        raise _INTL("nthTurnThisRound checks for turns 1 or above!") if turnCheck <= 0
        return @battle.commandPhasesThisRound == (turnCheck - 1)
    end

    def immuneToHazards?
        return true if hasActiveItem?(:HEAVYDUTYBOOTS)
        return false
    end

    def hasHonorAura?
        return hasActiveAbility?([:HONORAURA])
    end

    def isLastAlive?
        return false if @battle.wildBattle? && opposes?
        return false if fainted?
        return @battle.pbGetOwnerFromBattlerIndex(@index).able_pokemon_count == 1
    end

    def protectedAgainst?(user, move)
        holdersToCheck = [self, pbOwnSide]
        holdersToCheck.each do |effectHolder|
            effectHolder.eachEffect(true) do |_effect, _value, data|
                next unless data.is_protection?
                if data.protection_info&.has_key?(:does_negate_proc)
                    return data.protection_info[:does_negate_proc].call(user, self, move, @battle)
                else
                    return true
                end
            end
        end
        return false
    end

    def canGulpMissile?
        return @species == :CRAMORANT && hasActiveAbility?(:GULPMISSILE) && @form.zero?
    end

    def bunkeringDown?(checkingForAI = false)
        return shouldAbilityApply?(:BUNKERDOWN, checkingForAI) && @hp == @totalhp
    end

    def getRoomDuration
        if hasActiveItem?(:REINFORCINGROD)
            return 8
        else
            return 5
        end
    end

    def getScreenDuration
        ret = 5
        ret += 3 if hasActiveItem?(:LIGHTCLAY)
        ret += 6 if hasActiveItem?(:BRIGHTCLAY)
        ret *= 2 if hasActiveAbility?(:RESONANCE) && @battle.pbWeather == :Eclipse
        return ret
    end

    def firstTurn?
        return @turnCount <= 1
    end

    def substituted?
        return effectActive?(:Substitute)
    end

    # Only to be called during hit or post-most-use triggers
    def knockedBelowHalf?
        return @damageState.initialHP >= @totalhp / 2 && @hp < @totalhp / 2
    end

    def canActThisTurn?
        return false if effectActive?(:HyperBeam)
        return false if effectActive?(:Truant)
        return true
    end

    #=============================================================================
    # Methods relating to this battler's position on the battlefield
    #=============================================================================
    # Returns whether the given position belongs to the opposing Pokémon's side.
    def opposes?(i = 0)
        i = i.index if i.respond_to?("index")
        return (@index & 1) != (i & 1)
    end

    # Returns whether the given position/battler is near to self.
    def near?(i)
        i = i.index if i.respond_to?("index")
        return @battle.nearBattlers?(@index, i)
    end

    # Returns whether self is owned by the player.
    def pbOwnedByPlayer?
        return @battle.pbOwnedByPlayer?(@index)
    end

    # Returns 0 if self is on the player's side, or 1 if self is on the opposing
    # side.
    def idxOwnSide
        return @index & 1
    end

    # Returns 1 if self is on the player's side, or 0 if self is on the opposing
    # side.
    def idxOpposingSide
        return (@index & 1) ^ 1
    end

    # Returns the data structure for this battler's side.
    def pbOwnSide
        return @battle.sides[idxOwnSide]
    end

    # Returns the data structure for the opposing Pokémon's side.
    def pbOpposingSide
        return @battle.sides[idxOpposingSide]
    end

    def position
        return @battle.positions[@index]
    end

    # Yields each unfainted ally Pokémon.
    def eachAlly(nearOnly = false)
        eachOther(nearOnly) do |b|
            next if b.opposes?(@index)
            yield b
        end
    end

    # Yields each unfainted opposing Pokémon.
    def eachOpposing(nearOnly = false)
        eachOther(nearOnly) do |b|
            next unless b.opposes?(@index)
            yield b
        end
    end

    # Yields each other unfainted battler
    def eachOther(nearOnly = false)
        @battle.battlers.each do |b|
            next if b.nil?
            next if b.index == @index # Ignore the self
            next if nearOnly && !near?(b)
            next if b.fainted?
            yield b
        end
    end

    # Returns the battler that is most directly opposite to self. unfaintedOnly is
    # whether it should prefer to return a non-fainted battler.
    def pbDirectOpposing(unfaintedOnly = false)
        @battle.pbGetOpposingIndicesInOrder(@index).each do |i|
            next unless @battle.battlers[i]
            break if unfaintedOnly && @battle.battlers[i].fainted?
            return @battle.battlers[i]
        end
        # Wanted an unfainted battler but couldn't find one; make do with a fainted
        # battler
        @battle.pbGetOpposingIndicesInOrder(@index).each do |i|
            return @battle.battlers[i] if @battle.battlers[i]
        end
        return @battle.battlers[(@index ^ 1)]
    end

    def ownerParty
        return @battle.pbParty(@index)
    end

    def partyIndex
        return @index % 2
    end

    def typeMod(type, target, move, aiCheck = false)
        if aiCheck
            return @battle.battleAI.pbCalcTypeModAI(type, self, target, move)
        else
            return @damageState.typeMod
        end
    end

    def aboveHalfHealth?
        return @hp > @totalhp / 2
    end

    def belowHalfHealth?
        return @hp <= @totalhp / 2
    end

    def getWeatherSettingDuration(weatherType, baseDuration = 4, ignoreFainted = false)
        duration = baseDuration
        if duration > 0 && itemActive?(ignoreFainted)
            duration = BattleHandlers.triggerWeatherExtenderItem(item, weatherType, duration, self, @battle)
        end
        return duration
    end

    def ignoreScreens?(checkingForAI)
        return true if shouldAbilityApply?(:INFILTRATOR,checkingForAI)
        return true if shouldAbilityApply?(:CLEAVING,checkingForAI)
        return false
    end

    def canBeDisabled?(show_messages = false, move = nil)
        return false if move&.pbMoveFailedAromaVeil?(nil, self, show_messages)
        return false if fainted?
        return false if effectActive?(:Disable)
        regularMove = nil
        eachMove do |m|
            next if m.id != @lastRegularMoveUsed
            regularMove = m
            break
        end
        return false unless regularMove && (regularMove.pp == 0 && regularMove.total_pp > 0)
        return true
    end
end
