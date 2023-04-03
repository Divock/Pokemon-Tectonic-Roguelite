class Pokemon
    attr_reader   :items
    attr_accessor :hpMult
    attr_accessor :dmgMult
    attr_accessor :dmgResist
    attr_accessor :battlingStreak
    attr_accessor :extraMovesPerTurn
    attr_accessor :bossType
    attr_accessor :itemTypeChosen

    # Creates a new Pokémon object.
    # @param species [Symbol, String, Integer] Pokémon species
    # @param level [Integer] Pokémon level
    # @param owner [Owner, Player, NPCTrainer] Pokémon owner (the player by default)
    # @param withMoves [TrueClass, FalseClass] whether the Pokémon should have moves
    # @param rechech_form [TrueClass, FalseClass] whether to auto-check the form
    def initialize(species, level, owner = $Trainer, withMoves = true, recheck_form = true)
        species_data = GameData::Species.get(species)
        @species          = species_data.species
        @form             = species_data.form
        @forced_form      = nil
        @time_form_set    = nil
        self.level        = level
        @steps_to_hatch   = 0
        heal_status
        @gender           = nil
        @shiny            = nil
        @ability_index    = nil
        @ability          = nil
        @extraAbilities   = []
        @nature           = nil
        @nature_for_stats = nil
        @items            = []
        @mail             = nil
        @moves            = []
        reset_moves if withMoves
        @first_moves      = []
        @ribbons          = []
        @cool             = 0
        @beauty           = 0
        @cute             = 0
        @smart            = 0
        @tough            = 0
        @sheen            = 0
        @pokerus          = 0
        @name             = nil
        @happiness        = species_data.happiness
        @poke_ball        = :POKEBALL
        @markings         = 0
        @iv               = {}
        @ivMaxed          = {}
        @ev               = {}
        GameData::Stat.each_main do |s|
            @iv[s.id] = 0
            @ev[s.id] = DEFAULT_STYLE_VALUE
        end
        if owner.is_a?(Owner)
            @owner = owner
        elsif owner.is_a?(Player) || owner.is_a?(NPCTrainer)
            @owner = Owner.new_from_trainer(owner)
        else
            @owner = Owner.new(0, "", 2, 2)
        end
        @obtain_method    = 0 # Met
        @obtain_method    = 4 if $game_switches && $game_switches[Settings::FATEFUL_ENCOUNTER_SWITCH]
        @obtain_map       = $game_map ? $game_map.map_id : 0
        @obtain_text      = nil
        @obtain_level     = level
        @hatched_map      = 0
        @timeReceived     = Time.now.to_i
        @timeEggHatched   = nil
        @fused            = nil
        @personalID       = rand(2**16) | rand(2**16) << 16
        @hp               = 1
        @totalhp          = 1
        @hpMult = 1
        @dmgMult = 1
        @dmgResist = 0
        @extraMovesPerTurn = 0
        @battlingStreak = 0
        @bossType = nil
        calc_stats
        if @form == 0 && recheck_form
            f = MultipleForms.call("getFormOnCreation", self)
            if f
                self.form = f
                reset_moves if withMoves
            end
        end
    end

    def onHotStreak?
        return @battlingStreak >= 2
    end

    def nature
        @nature = GameData::Nature.get(0).id # ALWAYS RETURN NEUTRAL
        return GameData::Nature.try_get(@nature)
    end

    def itemTypeChosen
        @itemTypeChosen = :NORMAL if @itemTypeChosen.nil?
        return @itemTypeChosen
    end

    def canSetItemType?
        return true if hasItem?(:MEMORYSET)
        return true if hasItem?(:PRISMATICPLATE)
        return false
    end

    # Recalculates this Pokémon's stats.
    def calc_stats
        base_stats = baseStats
        this_level = level
        this_IV    = calcIV
        # Calculate stats
        stats = {}
        stylish = ability_id == :STYLISH
        GameData::Stat.each_main do |s|
            if s.id == :HP
                stats[s.id] = calcHPGlobal(base_stats[s.id], this_level, @ev[s.id], stylish)
                stats[s.id] *= hpMult
            elsif (s.id == :ATTACK) || (s.id == :SPECIAL_ATTACK)
                stats[s.id] = calcStatGlobal(base_stats[s.id], this_level, @ev[s.id], stylish)
            else
                stats[s.id] = calcStatGlobal(base_stats[s.id], this_level, @ev[s.id], stylish)
            end
        end
        hpDiff = @totalhp - @hp
        @totalhp = stats[:HP]
        @hp      = (fainted? ? 0 : (@totalhp - hpDiff))
        @attack  = stats[:ATTACK]
        @defense = stats[:DEFENSE]
        @spatk   = stats[:SPECIAL_ATTACK]
        @spdef   = stats[:SPECIAL_DEFENSE]
        @speed   = stats[:SPEED]
    end

    # The core method that performs evolution checks. Needs a block given to it,
    # which will provide either a GameData::Species ID (the species to evolve
    # into) or nil (keep checking).
    # @return [Symbol, nil] the ID of the species to evolve into
    def check_evolution_internal
        return nil if egg? || shadowPokemon?
        return nil if hasItem?(:EVERSTONE)
        return nil if hasItem?(:EVIOLITE)
        return nil if hasAbility?(:BATTLEBOND)
        species_data.get_evolutions(true).each do |evo| # [new_species, method, parameter, boolean]
            next if evo[3] # Prevolution
            ret = yield self, evo[0], evo[1], evo[2] # pkmn, new_species, method, parameter
            return ret if ret
        end
        return nil
    end

    # Silently learns the given move. Will erase the first known move if it has to.
    # @param move_id [Symbol, String, Integer] ID of the move to learn
    def learn_move(move_id, ignoreMax = false)
        move_data = GameData::Move.try_get(move_id)
        return unless move_data
        # Check if self already knows the move; if so, move it to the end of the array
        @moves.each_with_index do |m, i|
            next if m.id != move_data.id
            @moves.push(m)
            @moves.delete_at(i)
            return
        end
        # Move is not already known; learn it
        @moves.push(Pokemon::Move.new(move_data.id))
        # Delete the first known move if self now knows more moves than it should
        @moves.shift if numMoves > MAX_MOVES && !ignoreMax
    end

    # Heals this Pokemon's HP by an amount
    def healBy(amount)
        return if egg?
        @hp += amount
        @hp = @totalhp if @hp > @totalhp
    end

    # Heals this Pokemon's HP by an amount
    def healByFraction(fraction)
        healBy((@totalhp * fraction).ceil)
    end

    def addExtraAbility(ability)
        @extraAbilities.push(ability) unless @extraAbilities.include?(ability)
    end

    def extraAbilities
        @extraAbilities = [] if @extraAbilities.nil?
        return @extraAbilities
    end

    def canHaveExtraItem?(itemCheck = nil, showMessages = false)
        return true if @item.nil?
        return true if itemCheck.nil?
        theoreticalItems = items.clone.push(itemCheck)
        return legalItems?(theoreticalItems, showMessages)
    end

    def legalItems?(itemSet, showMessages = false)
        return true if itemSet.length <= 1

        # Jeweler
        if @ability == :JEWELER
            allGems = true
            itemSet.each do |item|
                next if GameData::Item.get(@item).is_gem?
                allGems = false
                break
            end
            if allGems
                pbMessage(_INTL("For #{name} to have two items, both must be Gems!")) if showMessages
                return false
            else
            return true
        end

        # Berry Bunch
        if @ability == :BERRYBUNCH
            allBerries = true
            itemSet.each do |item|
                next if GameData::Item.get(@item).is_berry?
                allBerries = false
                break
            end
            if allBerries
                pbMessage(_INTL("For #{name} to have two items, both must be Berries!")) if showMessages
                return false
            else
            return true
        end

		# Fashionable
        if @ability == :FASHIONABLE
            clothingCount = 0
            itemSet.each do |item|
                next unless CLOTHING_ITEMS.include?(item)
                clothingCount += 1
            end
            if clothingCount == 0
                pbMessage(_INTL("For #{name} to have two items, at least one must be Clothing!")) if showMessages
                return false
            else
            if clothingCount > 1
                pbMessage(_INTL("For #{name} to have two items, only one can be Clothing!")) if showMessages
                return false
            else
            return true
        end

        return false
    end

    def removeInvalidItems
        return unless legalItems?(items)
        pbTakeItemsFromPokemon(self)
    end

    def hasMultipleItems?
        return items.length > 1
    end
end

class Pokemon
    class Owner
        # Returns a new Owner object populated with values taken from +trainer+.
        # @param trainer [Player, NPCTrainer] trainer object to read data from
        # @return [Owner] new Owner object
        def self.new_from_trainer(trainer)
            validate trainer => [Player, NPCTrainer]
            return new(trainer.id, trainer.nameForHashing || trainer.name, trainer.gender, trainer.language)
        end
    end
end
