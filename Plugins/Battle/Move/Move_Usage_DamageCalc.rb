DAMAGE_CALC_DEBUG = false

class PokeBattle_Move
    #=============================================================================
    # Final damage calculation
    #=============================================================================
    def pbCalcDamage(user,target,numTargets=1)
        return if statusMove?

        if target.damageState.disguise
            target.damageState.calcDamage = 1
            return
        end

        # Get the move's type
        type = @calcType # nil is treated as physical
        
        # Calcuate base power of move
        baseDmg = pbBaseDamage(@baseDamage,user,target)

        # Calculate whether this hit deals critical damage
        target.damageState.critical,target.damageState.forced_critical = pbIsCritical?(user,target)
        
        # Calculate the actual damage dealt, and assign it to the damage state for tracking
        target.damageState.calcDamage = calculateDamageForHit(user,target,type,baseDmg,numTargets)
    end

    def calculateDamageForHit(user,target,type,baseDmg,numTargets,aiChecking=false)
        echoln("[DAMAGE CALC] Calcing damage based on given base power #{baseDmg} and type #{type}") if DAMAGE_CALC_DEBUG
        
        # Get the relevant attacking and defending stat values (after stages)
        attack, defense = damageCalcStats(user,target,aiChecking)

        # Calculate all multiplier effects
        multipliers = initializeMultipliers
        pbCalcDamageMultipliers(user,target,numTargets,type,baseDmg,multipliers,aiChecking)

        # Main damage calculation
        finalCalculatedDamage = calcDamageWithMultipliers(baseDmg,attack,defense,user.level,multipliers)

        return finalCalculatedDamage
    end

    def initializeMultipliers
        return {
            :base_damage_multiplier  => 1.0,
            :attack_multiplier       => 1.0,
            :defense_multiplier      => 1.0,
            :final_damage_multiplier => 1.0
        }
    end

    def calcDamageWithMultipliers(baseDmg,attack,defense,userLevel,multipliers)
        baseDmg = [(baseDmg * multipliers[:base_damage_multiplier]).round, 1].max
        attack  = [(attack  * multipliers[:attack_multiplier]).round, 1].max
        defense = [(defense * multipliers[:defense_multiplier]).round, 1].max
        damage  = calcBasicDamage(baseDmg,userLevel,attack,defense)
        damage  = [(damage  * multipliers[:final_damage_multiplier]).round, 1].max
        return damage
    end

    def printMultipliers(multipliers)
        echoln("The calculated base damage multiplier: #{multipliers[:base_damage_multiplier]}")
        echoln("The calculated attack and defense multipliers: #{multipliers[:attack_multiplier]},#{multipliers[:defense_multiplier]}")
        echoln("The calculated final damage multiplier: #{multipliers[:final_damage_multiplier]}")
    end

    def calcBasicDamage(base_damage,attacker_level,user_attacking_stat,target_defending_stat)
        pseudoLevel = 15.0 + (attacker_level.to_f / 2.0)
        levelMultiplier = 2.0 + (0.4 * pseudoLevel)
        damage  = 2.0 + ((levelMultiplier * base_damage.to_f * user_attacking_stat.to_f / target_defending_stat.to_f) / 50.0).floor
        return damage
    end

    def damageCalcStats(user,target,aiChecking=false)
        # Calculate user's attack stat
        attacking_stat_holder, attacking_stat = pbAttackingStat(user,target)
        attack_stage = attacking_stat_holder.stages[attacking_stat]
        critical = target.damageState.critical
        critical = false if aiChecking
        attack_stage = 0 if critical && attack_stage < 0
        attack_stage = 0 if target.hasActiveAbility?(:UNAWARE) && !@battle.moldBreaker
        attack = attacking_stat_holder.getFinalStat(attacking_stat, aiChecking, attack_stage)
        # Calculate target's defense stat
        defending_stat_holder, defending_stat = pbDefendingStat(user,target)
        defense_stage = defending_stat_holder.stages[defending_stat]
        if defense_stage > 0 &&
                (ignoresDefensiveStageBoosts?(user,target) || user.hasActiveAbility?(:INFILTRATOR) || critical)
            defense_stage = 0
        end
        defense_stage = 0 if user.hasActiveAbility?(:UNAWARE)
        defense = defending_stat_holder.getFinalStat(defending_stat, aiChecking, defense_stage)
        echoln("[DAMAGE CALC] Calcing damage based on #{attacking_stat_holder.pbThis(true)}'s final #{attacking_stat} of #{attack} and #{defending_stat_holder.pbThis(true)}'s final #{defending_stat} of #{defense}") if DAMAGE_CALC_DEBUG
        return attack, defense
    end
    
    def pbCalcAbilityDamageMultipliers(user,target,type,baseDmg,multipliers,aiChecking=false)
        # Global abilities
        if (@battle.pbCheckGlobalAbility(:DARKAURA) && type == :DARK) ||
            (@battle.pbCheckGlobalAbility(:FAIRYAURA) && type == :FAIRY)
            if @battle.pbCheckGlobalAbility(:AURABREAK)
                multipliers[:base_damage_multiplier] *= 2 / 3.0
            else
                multipliers[:base_damage_multiplier] *= 4 / 3.0
            end
        end
        if @battle.pbCheckGlobalAbility(:RUINOUS)
            multipliers[:base_damage_multiplier] *= 1.2
        end
        # Ability effects that alter damage
        if user.abilityActive?
            BattleHandlers.triggerDamageCalcUserAbility(user.ability,user,target,self,multipliers,baseDmg,type,aiChecking)
        end
        if !@battle.moldBreaker
            # NOTE: It's odd that the user's Mold Breaker prevents its partner's
            #       beneficial abilities (e.g. Power Spot), but that's how it works.
            user.eachAlly do |b|
                next if !b.abilityActive?
                BattleHandlers.triggerDamageCalcUserAllyAbility(b.ability,user,target,self,multipliers,baseDmg,type,aiChecking)
            end
            # TODO: AI-Check discrepency for targets abilities
            if target.abilityActive?
                BattleHandlers.triggerDamageCalcTargetAbility(target.ability,user,target,self,multipliers,baseDmg,type) if !@battle.moldBreaker
                BattleHandlers.triggerDamageCalcTargetAbilityNonIgnorable(target.ability,user,target,self,multipliers,baseDmg,type)
            end
            target.eachAlly do |b|
                next if !b.abilityActive?
                BattleHandlers.triggerDamageCalcTargetAllyAbility(b.ability,user,target,self,multipliers,baseDmg,type)
            end
        end
    end

    def pbCalcTerrainDamageMultipliers(user,target,type,multipliers,checkingForAI=false)
        # Terrain moves
        case @battle.field.terrain
        when :Electric
            multipliers[:base_damage_multiplier] *= 1.3 if type == :ELECTRIC && user.affectedByTerrain?
        when :Grassy
            multipliers[:base_damage_multiplier] *= 1.3 if type == :GRASS && user.affectedByTerrain?
        when :Psychic
            multipliers[:base_damage_multiplier] *= 1.3 if type == :PSYCHIC && user.affectedByTerrain?
        when :Fairy
            multipliers[:base_damage_multiplier] *= 1.3 if type == :FAIRY && target.affectedByTerrain?
        end
    end

    def pbCalcWeatherDamageMultipliers(user,target,type,multipliers,checkingForAI=false)
        case @battle.pbWeather
        when :Sun, :HarshSun
            if type == :FIRE
                multipliers[:final_damage_multiplier] *= @battle.pbWeather == :HarshSun ? 1.5 : 1.3
            elsif applySunDebuff?(user,type,checkingForAI)
                if @battle.pbCheckGlobalAbility(:BLINDINGLIGHT)
                    multipliers[:final_damage_multiplier] *= 0.7
                else
                    multipliers[:final_damage_multiplier] *= 0.85
                end
            end
        when :Rain, :HeavyRain
            if type == :WATER
                multipliers[:final_damage_multiplier] *= @battle.pbWeather == :HeavyRain ? 1.5 : 1.3
            elsif applyRainDebuff?(user,type,checkingForAI)
                if @battle.pbCheckGlobalAbility(:DREARYCLOUDS)
                    multipliers[:final_damage_multiplier] *= 0.7
                else
                    multipliers[:final_damage_multiplier] *= 0.85
                end
            end
        when :Swarm
            if type == :DRAGON || type == :BUG
                multipliers[:final_damage_multiplier] *= 1.3
            end
        when :Sandstorm
            if target.shouldTypeApply?(:ROCK,checkingForAI) && specialMove? && @function != "122"   # Psyshock/Psystrike
                if @battle.pbCheckGlobalAbility(:SHRAPNELSTORM)
                    multipliers[:defense_multiplier] *= 2.0
                else
                    multipliers[:defense_multiplier] *= 1.5
                end
            end
        when :Hail
            if target.shouldTypeApply?(:ICE,checkingForAI) && physicalMove? && @function != "506"   # Soul Claw/Rip
                if @battle.pbCheckGlobalAbility(:BITTERCOLD)
                    multipliers[:defense_multiplier] *= 2.0
                else
                    multipliers[:defense_multiplier] *= 1.5
                end
            end
        end
    end

    def pbCalcStatusesDamageMultipliers(user,target,multipliers,checkingForAI=false)
        # Burn
        if user.burned? && physicalMove? && damageReducedByBurn? && !user.shouldAbilityApply?(:GUTS,checkingForAI) && !user.shouldAbilityApply?(:BURNHEAL,checkingForAI)
            damageReduction = user.boss? ? (1.0/5.0) : (1.0/3.0)
            damageReduction *= 2 if user.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            multipliers[:final_damage_multiplier] *= (1.0 - damageReduction)
        end
        # Frostbite
        if user.frostbitten? && specialMove? && damageReducedByBurn? && !user.shouldAbilityApply?(:AUDACITY,checkingForAI) && !user.shouldAbilityApply?(:FROSTHEAL,checkingForAI)
            damageReduction = user.boss? ? (1.0/5.0) : (1.0/3.0)
            damageReduction *= 2 if user.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            multipliers[:final_damage_multiplier] *= (1.0 - damageReduction)
        end
        # Numb
        if user.numbed?
            damageReduction = user.boss? ? (3.0/20.0) : (1.0/4.0)
            damageReduction *= 2 if user.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            multipliers[:final_damage_multiplier] *= (1.0 - damageReduction)
        end
        # Dizzy
        if target.dizzy? && !target.shouldAbilityApply?([:MARVELSKIN,:MARVELSCALE],checkingForAI)
            damageIncrease = target.boss? ? (3.0/20.0) : (1.0/4.0)
            damageIncrease *= 2 if target.pbOwnedByPlayer? && @battle.curseActive?(:CURSE_STATUS_DOUBLED)
            multipliers[:final_damage_multiplier] *= (1.0 + damageIncrease)
        end
    end

    def pbCalcProtectionsDamageMultipliers(user,target,multipliers,checkingForAI=false)
        # Aurora Veil, Reflect, Light Screen
        if !ignoresReflect? && !target.damageState.critical && !user.shouldAbilityApply?(:INFILTRATOR,checkingForAI)
            if target.pbOwnSide.effectActive?(:AuroraVeil)
                if @battle.pbSideBattlerCount(target)>1
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                else
                    multipliers[:final_damage_multiplier] *= 0.5
                end
            elsif target.pbOwnSide.effectActive?(:Reflect) && physicalMove?
                if @battle.pbSideBattlerCount(target)>1
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                else
                    multipliers[:final_damage_multiplier] *= 0.5
                end
            elsif target.pbOwnSide.effectActive?(:LightScreen) && specialMove?
                if @battle.pbSideBattlerCount(target) > 1
                    multipliers[:final_damage_multiplier] *= 2 / 3.0
                else
                    multipliers[:final_damage_multiplier] *= 0.5
                end
            end
        end
        # Partial protection moves
        if target.effectActive?(:StunningCurl) || target.effectActive?(:RootShelter)
            multipliers[:final_damage_multiplier] *= 0.5
        end
        if target.effectActive?(:EmpoweredDetect)
            multipliers[:final_damage_multiplier] *= 0.5
        end
        if target.pbOwnSide.effectActive?(:Bulwark)
            multipliers[:final_damage_multiplier] *= 0.5
        end
        # For when bosses are partway piercing protection
        if target.damageState.partiallyProtected
            multipliers[:final_damage_multiplier] *= 0.5
        end
    end

    def pbCalcTypeBasedDamageMultipliers(user,target,type,multipliers,checkingForAI=false)
        # STAB
        if !user.pbOwnedByPlayer? || !@battle.curses.include?(:DULLED)
            if type && user.pbHasType?(type)
                stab = 1.5
                if user.shouldAbilityApply?(:ADAPTED,checkingForAI)
                    stab *= 4.0/3.0
                elsif user.shouldAbilityApply?(:ULTRAADAPTED,checkingForAI)
                    stab *= 3.0/2.0
                end
                multipliers[:final_damage_multiplier] *= stab
            end
        end

        # Type effectiveness
        typeMod = target.typeMod(type,target,self,checkingForAI)
        effectiveness = typeMod / Effectiveness::NORMAL_EFFECTIVE.to_f
        multipliers[:final_damage_multiplier] *= effectiveness

        echoln("[DAMAGE CALC] Calcing damage based on expected type effectiveness mult of #{effectiveness}") if DAMAGE_CALC_DEBUG

        # Charge
        if user.effectActive?(:Charge) && type == :ELECTRIC
            multipliers[:base_damage_multiplier] *= 2
        end
        
        # Mud Sport
        if type == :ELECTRIC
            @battle.eachBattler do |b|
                next if !b.effectActive?(:MudSport)
                multipliers[:base_damage_multiplier] /= 3.0
                break
            end
            if @battle.field.effectActive?(:MudSportField)
                multipliers[:base_damage_multiplier] /= 3.0
            end
        end
        
		# Volatile Toxin
		if target.effectActive?(:VolatileToxin) && (type == :GROUND)
			multipliers[:base_damage_multiplier] *= 2
		end

        # Water Sport
        if type == :FIRE
            @battle.eachBattler do |b|
                next if !b.effectActive?(:WaterSport)
                multipliers[:base_damage_multiplier] /= 3.0
                break
            end
            if @battle.field.effectActive?(:WaterSportField)
                multipliers[:base_damage_multiplier] /= 3.0
            end
        end
    end
      
    def pbCalcDamageMultipliers(user,target,numTargets,type,baseDmg,multipliers,aiChecking=false)
        pbCalcAbilityDamageMultipliers(user,target,type,baseDmg,multipliers,aiChecking)
        pbCalcTerrainDamageMultipliers(user,target,type,multipliers,aiChecking)
        pbCalcWeatherDamageMultipliers(user,target,type,multipliers,aiChecking)
        pbCalcStatusesDamageMultipliers(user,target,multipliers,aiChecking)
        pbCalcProtectionsDamageMultipliers(user,target,multipliers,aiChecking)
        pbCalcTypeBasedDamageMultipliers(user,target,type,multipliers,aiChecking)

        # Item effects that alter damage
        if user.itemActive?
            BattleHandlers.triggerDamageCalcUserItem(user.item,
                user,target,self,multipliers,baseDmg,type,aiChecking)
        end
        if target.itemActive?
            BattleHandlers.triggerDamageCalcTargetItem(target.item,
                user,target,self,multipliers,baseDmg,type)
        end
        
        if aiChecking
            # Parental Bond
            if user.hasActiveAbility?(:PARENTALBOND)
                multipliers[:base_damage_multiplier] *= 1.25
            end
        else
            # Parental Bond's second attack
            if user.effects[:ParentalBond] == 1
                multipliers[:base_damage_multiplier] *= 0.25
            end
            # Me First
            if user.effectActive?(:MeFirst)
                multipliers[:base_damage_multiplier] *= 1.5
            end
            # Helping Hand
            if user.effectActive?(:HelpingHand) && !self.is_a?(PokeBattle_Confusion)
                multipliers[:base_damage_multiplier] *= 1.5
            end
            # Shimmering Heat
            if target.effectActive?(:ShimmeringHeat)
                multipliers[:final_damage_multiplier] *= 0.67
            end
            # Echo
            if user.effectActive?(:Echo)
                multipliers[:final_damage_multiplier] *= 0.75
            end
        end

        # Multi-targeting attacks
        if numTargets > 1
            multipliers[:final_damage_multiplier] *= 0.75
        end

        # Battler properites
        multipliers[:base_damage_multiplier] *= user.dmgMult
        multipliers[:base_damage_multiplier] *= [0,(1.0 - target.dmgResist.to_f)].max

        # Critical hits
        if aiChecking
            rate = pbIsCritical?(user,target,true)

            if rate >= 0
                rate = 5 if rate > 5
                multipliers[:final_damage_multiplier] *= 1.0 + (0.1 * rate)
            end
        else
            if target.damageState.critical
                multipliers[:final_damage_multiplier] *= 1.5
            end
        end

        # Random variance (What used to be for that)
        if !self.is_a?(PokeBattle_Confusion) && !self.is_a?(PokeBattle_Charm)
            multipliers[:final_damage_multiplier] *= 0.9
        end

        # Move-specific final damage modifiers
        multipliers[:final_damage_multiplier] = pbModifyDamage(multipliers[:final_damage_multiplier], user, target)
    end
end