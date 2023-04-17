class PokeBattle_AI
    #=============================================================================
    #
    #=============================================================================
    def pbTargetsMultiple?(move, user)
        target_data = move.pbTarget(user)
        return false if target_data.num_targets <= 1
        num_targets = 0
        case target_data.id
        when :UserAndAllies
            @battle.eachSameSideBattler(user) { |_b| num_targets += 1 }
        when :AllNearFoes
            @battle.eachOtherSideBattler(user) { |b| num_targets += 1 if b.near?(user) }
        when :AllFoes
            @battle.eachOtherSideBattler(user) { |_b| num_targets += 1 }
        when :AllNearOthers
            @battle.eachBattler { |b| num_targets += 1 if b.near?(user) }
        when :AllBattlers
            @battle.eachBattler { |_b| num_targets += 1 }
        end
        return num_targets > 1
    end

    def pbCalcTypeModAI(moveType, user, target, move)
        return Effectiveness::NORMAL_EFFECTIVE unless moveType
        return Effectiveness::NORMAL_EFFECTIVE if moveType == :GROUND &&
                                                  target.pbHasTypeAI?(:FLYING) && target.hasActiveItem?(:IRONBALL)
        # Determine types
        tTypes = target.pbTypesAI(true)
        # Get effectivenesses
        typeMods = [Effectiveness::NORMAL_EFFECTIVE_ONE] * 3 # 3 types max
        tTypes.each_with_index do |defType, i|
            typeMods[i] = move.pbCalcTypeModSingle(moveType, defType, user, target)
        end
        # Multiply all effectivenesses together
        ret = 1
        typeMods.each { |m| ret *= m }
        # Modify effectiveness for bosses
        ret = Effectiveness.modify_boss_effectiveness(ret, user, target)
        return ret
    end

    def moveFailureAlert(move, user, target, failureMessage)
        echoln("#{user.pbThis(true)} thinks that move #{move.id} against target #{target.pbThis(true)} will fail due to #{failureMessage}")
    end

    #=============================================================================
    # Get a move's base damage value
    #=============================================================================
    def pbMoveBaseDamageAI(move, user, target)
        baseDmg = move.baseDamage
        baseDmg = move.pbBaseDamageAI(baseDmg, user, target)
        return baseDmg
    end

    #=============================================================================
    # Damage calculation
    #=============================================================================
    def pbTotalDamageAI(move, user, target, numTargets = 1)
        # Get the move's type
        type = pbRoughType(move, user)

        baseDmg = pbMoveBaseDamageAI(move, user, target)

        # Calculate the damage for one hit
        damage = move.calculateDamageForHit(user, target, type, baseDmg, numTargets, true)

        # Estimate how many hits the move will do
        numHits = move.numberOfHits(user, [target], true)

        # Calculate the total estimated damage of all hits
        totalDamage = damage * numHits

        return totalDamage.floor
    end

    #===========================================================================
    # Accuracy calculation
    #===========================================================================
    def pbRoughAccuracy(move, user, target)
        return 100 if target.effectActive?(:Telekinesis)
        baseAcc = move.accuracy
        return 100 if baseAcc == 0
        baseAcc = move.pbBaseAccuracy(user, target)
        return 100 if baseAcc == 0
        # Get the move's type
        type = pbRoughType(move, user)
        # Calculate all modifier effects
        modifiers = {}
        modifiers[:base_accuracy]  = baseAcc
        modifiers[:accuracy_stage] = user.stages[:ACCURACY]
        modifiers[:evasion_stage]  = target.stages[:EVASION]
        modifiers[:accuracy_multiplier] = 1.0
        modifiers[:evasion_multiplier]  = 1.0
        pbCalcAccuracyModifiers(user, target, modifiers, move, type)
        # Calculation
        statBoundary = PokeBattle_Battler::STAT_STAGE_BOUND
        accStage = modifiers[:accuracy_stage].clamp(-statBoundary, statBoundary)
        evaStage = modifiers[:evasion_stage].clamp(-statBoundary, statBoundary)
        accuracy = 100.0 * user.statMultiplierAtStage(accStage)
        evasion  = 100.0 * user.statMultiplierAtStage(evaStage)
        accuracy = (accuracy * modifiers[:accuracy_multiplier]).round
        evasion  = (evasion  * modifiers[:evasion_multiplier]).round
        evasion = 1 if evasion < 1
        # Value always hit moves if otherwise would be hard to hit here
        if modifiers[:base_accuracy] == 0
            return (accuracy / evasion < 1) ? 125 : 100
        end
        return modifiers[:base_accuracy] * accuracy / evasion
    end

    def pbCalcAccuracyModifiers(user, target, modifiers, move, type)
        moldBreaker = false
        moldBreaker = true if target.hasMoldBreaker?
        # User's abilities
        user.eachActiveAbility do |ability|
            BattleHandlers.triggerAccuracyCalcUserAbility(ability,
            modifiers, user, target, move, type)
        end
        # User's ally's abilities
        user.eachAlly do |ally|
            ally.eachActiveAbility do |ability|
                BattleHandlers.triggerAccuracyCalcUserAllyAbility(ability,
                    modifiers, user, target, move, type)
            end
        end
        # Target's abilities
        unless moldBreaker
            target.eachActiveAbility do |ability|
                BattleHandlers.triggerAccuracyCalcTargetAbility(ability,
                    modifiers, user, target, move, type)
            end
        end
        # Item effects that alter accuracy calculation
        user.eachActiveItem do |item|
            BattleHandlers.triggerAccuracyCalcUserItem(item, modifiers, user, target, move, type)
        end
        target.eachActiveItem do |item|
            BattleHandlers.triggerAccuracyCalcTargetItem(item, modifiers, user, target, move, type)
        end
        # Other effects, inc. ones that set accuracy_multiplier or evasion_stage to specific values
        modifiers[:accuracy_multiplier] *= 2.0 if @battle.field.effectActive?(:Gravity)
        modifiers[:accuracy_multiplier] *= 1.2 if user.effectActive?(:MicleBerry)
        modifiers[:evasion_stage] = 0 if target.effectActive?(:MiracleEye) && modifiers[:evasion_stage] > 0
        modifiers[:evasion_stage] = 0 if target.effectActive?(:Foresight) && modifiers[:evasion_stage] > 0
        # "AI-specific calculations below"
        modifiers[:evasion_stage] = 0 if move.function == "0A9" # Chip Away
        modifiers[:base_accuracy] = 0 if ["0A5", "139", "13A", "13B", "13C",   # "Always hit"
                                          "147",].include?(move.function)
        modifiers[:base_accuracy] = 0 if user.effectActive?(:LockOn) && user.pointsAt?(:LockOnPos, target)
    end
end
