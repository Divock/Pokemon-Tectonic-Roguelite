VALID_FORMS = [
    [:DARMANITAN,1],
    [:GDARMANITAN,1],
    [:LYCANROC,2],
    [:ROTOM,1],
    [:ROTOM,2],
    [:ROTOM,3],
    [:ROTOM,4],
    [:ROTOM,5],
    [:SAWSBUCK,1],
    [:SAWSBUCK,2],
    [:SAWSBUCK,3],
]

STARTING_BLOCK_MAP_IDS = [
    21,
    28,
]

CONTENT_BLOCK_MAP_IDS = [
    27,
    30,
]

EXIT_BLOCK_MAP_IDS = [
    24,
    29,
]

STARTING_TRAINER_HEALTH = 20

##############################################################
# Game mode class
##############################################################
class TectonicRogueGameMode
    attr_reader :speciesForms
    attr_reader :floorNumber

    ##############################################################
    # Initialization
    ##############################################################

    def initialize
        @active = false
        @currentFloorTrainers = []
        @currentFloorMaps = []
        @floorNumber = 0
        @trainerHealth = STARTING_TRAINER_HEALTH
    end
    
    def loadValidSpecies
        @speciesForms = []
        GameData::Species.each do |speciesData|
            next if speciesData.form != 0 && !VALID_FORMS.include?([speciesData.id,speciesData.form])
            next unless speciesData.get_evolutions(true).empty?
            next if speciesData.isLegendary?
            @speciesForms.push([speciesData.id,speciesData.form])
        end
    end

    def beginRun
        @active = true
        loadValidSpecies

        setGlobals

        $TectonicRogue.moveToNextFloor

        unless debugControl
            chooseStartingPokemon
            giveStartingItems
        end
    end

    def giveStartingItems
        # Nothing yet
        pbReceiveItem(:SITRUSBERRY)
        pbReceiveItem(:STRENGTHHERB)
        pbReceiveItem(:INTELLECTHERB)
    end

    def setGlobals
        $Trainer.has_running_shoes = true
        setLevelCap(70,false)
        setGlobalSwitch(33) # No money lost in battles
    end

    def active?
        return @active
    end

    ##############################################################
    # Health and losing
    ##############################################################
    def removeTrainerHealth(amount = 1)
        @trainerHealth -= amount
        if amount == 1
            pbMessage(_INTL("You lost a health point!"))
        else
            pbMessage(_INTL("You lost #{amount} health points!"))
        end
        if @trainerHealth <= 0
            loseRun
        else
            pbMessage(_INTL("You have #{@trainerHealth} remaining."))
        end
    end

    def loseRun
        pbMessage(_INTL("You've lost this run."))
        PokemonPartyShowcase_Scene.new($Trainer.party,true) # Take party snapshot

        # Delete the current save
        SaveData.delete_file($storenamefilesave)

        pbCallTitle # Reset the game
    end

    ##############################################################
    # Pokemon selection
    ##############################################################

    def chooseStartingPokemon
        pbMessage(_INTL("Choose your first Pokemon."))
        chooseGiftPokemon(2)
        pbMessage(_INTL("Choose your second Pokemon."))
        chooseGiftPokemon(3)
        pbMessage(_INTL("Choose your third Pokemon."))
        chooseGiftPokemon(4)
    end

    def chooseGiftPokemon(numberOfChoices = 3)
        speciesFormChoices = getSpeciesFormChoices(numberOfChoices)
        displayChoices = []
        speciesFormChoices.each do |speciesFormArray|
            speciesID = speciesFormArray[0]
            formNumber = speciesFormArray[1]

            speciesFormData = GameData::Species.get_species_form(speciesID,formNumber)
            speciesFormName = speciesFormData.name
            speciesFormName = _INTL("#{speciesFormName} (#{speciesFormData.form_name})") if formNumber != 0
            displayChoices.push(speciesFormName)
        end

        while true
            result = pbShowCommands(nil,displayChoices)
    
            chosenDisplayName = displayChoices[result]
            speciesFormChosen = speciesFormChoices[result]

            pkmn = Pokemon.new(speciesFormChosen[0], getLevelCap)
            pkmn.form = speciesFormChosen[1]
            pkmn.reset_moves(50,true)

            choicesArray = [_INTL("View MasterDex"), _INTL("Take Pokemon"), _INTL("Cancel")]
            secondResult = pbShowCommands(nil,choicesArray,3)
            case secondResult
            when 1
                pbAddPokemon(pkmn)
                break
            when 0
                openSingleDexScreen(pkmn)
            end
            next
        end
    end

    # TODO: Extend with the ability to pass in restrictions
    def getSpeciesFormChoices(numberOfChoices = 3)
        speciesFormChoices = []
        numberOfChoices.times do
            speciesFormChoices.push(getRandomSpeciesForm(speciesFormChoices))
        end
        return speciesFormChoices
    end

    ##############################################################
    # Pokemon generation
    ##############################################################
    def getRandomSpeciesForm(existingChoices = [])
        newChoice = nil
        while newChoice.nil? || existingChoices.include?(newChoice)
            newChoice = @speciesForms.sample
        end
        return newChoice
    end

    ##############################################################
    # Trainer generation
    ##############################################################
    def resetFloorTrainers
        @currentFloorTrainers.clear
    end
    
    def initializeNextTrainer
        partySize = getRandomTrainerPartySize
        randomTrainer = getRandomTrainer(partySize)
        @currentFloorTrainers.push(randomTrainer)
        return randomTrainer,@currentFloorTrainers.length-1
    end

    def trainersAssigned?
        return !@currentFloorTrainers.empty?
    end

    def getTrainerByLevelID(idNumber)
        return @currentFloorTrainers[idNumber]
    end

    def getRandomTrainer(partySize = 3)
        trainerData = GameData::Trainer.randomMonumentTrainer
        actualTrainer = trainerData.to_trainer

        # Select only some of the party members of the given trainer
        newParty = []
        newParty.push(actualTrainer.party[0])
        until newParty.length == partySize
            newPartyMember = actualTrainer.party.sample
            newParty.push(newPartyMember) unless newParty.include?(newPartyMember)
        end

        # Remove all items
        newParty.each do |partyMember|
            partyMember.removeItems
        end
        
        actualTrainer.party = newParty
        return actualTrainer
    end

    def startTrainerBattle(idNumber)
        trainer = getTrainerByLevelID(idNumber)
        
        setBattleRule("canLose")
        setBattleRule("double")
        setBattleRule("lanetargeting")
        setBattleRule("doubleshift")
        pbTrainerBattleCore(trainer)
    end

    def floorDifficulty
        return 1 + (@floorNumber / 3)
    end

    def getRandomTrainerPartySize
        partySize = 2
        partySize += floorDifficulty / 2
        partySize += 1 if rand(3) == 0 # A third of the time
        partySize = 6 if partySize > 6
        return partySize
    end

    ##############################################################
    # Floor selection and movement
    ##############################################################
    def moveToNextFloor
        resetFloorTrainers
        resetMapState

        @floorNumber += 1
        $rogue_floor_displayed = false

        pbSEPlay("Battle flee")
        pbCaveEntrance
        
        nextFloorMapID = generateNewFloor
        transferPlayerToSpawn(nextFloorMapID)
    end

    def transferPlayerToSpawn(mapID)
        mapData = Compiler::MapData.new
		map = mapData.getMap(mapID)
        spawningEvent = nil
        for event in map.events.values
            next unless event.name.include?("spawnpoint")
            spawningEvent = event
            break
        end
        raise _INTL("Could not find valid spawn point for map {1}!",mapID) unless spawningEvent
        transferPlayerToEvent(spawningEvent.id,Up,mapID)
    end

    def chooseNextFloor
        newFloor = nil
        while newFloor.nil? || newFloor == @currentFloorMapID
            newFloor = getRandomStartingBlockMapID
        end
        return newFloor
    end

    def getRandomStartingBlockMapID
        blockID = nil
        while blockID.nil? || @currentFloorMaps.include?(blockID)
            blockID = STARTING_BLOCK_MAP_IDS.sample
        end
        return blockID
    end

    def getRandomContentBlockMapID
        blockID = nil
        while blockID.nil? || @currentFloorMaps.include?(blockID)
            blockID = CONTENT_BLOCK_MAP_IDS.sample
        end
        return blockID
    end

    def getRandomExitBlockMapID
        blockID = nil
        while blockID.nil? || @currentFloorMaps.include?(blockID)
            blockID = EXIT_BLOCK_MAP_IDS.sample
        end
        return blockID
    end

    def resetMapState
        mapData = Compiler::MapData.new

        eachMapIDOnFloor do |mapID|
            map = mapData.getMap(mapID)
            for key in map.events.keys
                echoln(_INTL("Resetting the state of event {1} on map {2}",key,mapID))
                ['A','B','C','D'].each do |switch|
                    $game_self_switches[[mapID, key, switch]] = false
                end
            end
        end
    end

    ##############################################################
    # Floor generation
    ##############################################################
    def floorGenerated?
        return @currentFloorMaps && !@currentFloorMaps.empty?
    end

    def floorLoaded?
        return MapFactoryHelper.connectionsLoaded?
    end

    def generateNewFloor
        @currentFloorMaps = []

        startingBlockID = getRandomStartingBlockMapID
        contentBlockID = getRandomContentBlockMapID
        exitBlockID = getRandomExitBlockMapID
        @currentFloorMaps.push(startingBlockID)
        @currentFloorMaps.push(contentBlockID)
        @currentFloorMaps.push(exitBlockID)

        loadCurrentFloor

        return startingBlockID
    end

    def loadCurrentFloor
        MapFactoryHelper.clearConnections
        for index in 0...@currentFloorMaps.length-1
            mapID_A = @currentFloorMaps[index]
            mapID_B = @currentFloorMaps[index + 1]
            MapFactoryHelper.addMapConnection(mapID_A,mapID_B,"E")
        end
    end

    def eachMapIDOnFloor
        @currentFloorMaps.each do |mapID|
            yield mapID
        end
    end

    ##############################################################
    # Miscellaneous
    ##############################################################
    def dungeonName
        return _INTL("Prototype Dungeon")
    end
end

module MapFactoryHelper
    def self.clearConnections
        @@MapConnections = []
    end

    def self.connectionsLoaded?
        return @@MapConnections && !@@MapConnections.empty?
    end

    def self.addMapConnection(mapID_A,mapID_B,directionA)
        directionB = nil
        case directionA
        when "N"
            directionB = "S"
        when "S"
            directionB = "N"
        when "E"
            directionB = "W"
        when "W"
            directionB = "E"
        end

        connectionInfo = [mapID_A,directionA,1,mapID_B,directionB,1]

        # Convert first map's edge and coordinate to pair of coordinates
        edge = getMapEdge(connectionInfo[0], connectionInfo[1])
        case connectionInfo[1]
            when "N", "S"
                connectionInfo[1] = connectionInfo[2]
                connectionInfo[2] = edge
            when "E", "W"
                connectionInfo[1] = edge
        end
        # Convert second map's edge and coordinate to pair of coordinates
        edge = getMapEdge(connectionInfo[3], connectionInfo[4])
        case connectionInfo[4]
            when "N", "S"
                connectionInfo[4] = connectionInfo[5]
                connectionInfo[5] = edge
            when "E", "W"
                connectionInfo[4] = edge
        end

        # Add connection to arrays for both maps
        @@MapConnections[mapID_A] = [] unless @@MapConnections[mapID_A]
        @@MapConnections[mapID_A].push(connectionInfo)
        @@MapConnections[mapID_B] = [] unless @@MapConnections[mapID_B]
        @@MapConnections[mapID_B].push(connectionInfo)
    end
end

# Reload the map connections if loading in from a save file
Events.onMapChange += proc { |_sender,_e|
    next if $TectonicRogue.floorLoaded?
    next unless $TectonicRogue.floorGenerated?
    $TectonicRogue.loadCurrentFloor
}

##############################################################
# Event generation
##############################################################
Events.onMapSceneChange += proc { |_sender,_e|
    next unless rogueModeActive?
    next if $TectonicRogue.trainersAssigned?
    mapID = $game_map.map_id
    for event in $game_map.events.values
		match = event.name.match(/roguetrainer/)
        next unless match
        # Reset the trainer's flag
        pbSetSelfSwitch(event.id,"A",false)

        trainer,trainerID = $TectonicRogue.initializeNextTrainer

        # Construct the first page, in which the battle takes place
        firstPage = RPG::Event::Page.new
		firstPage.graphic.character_name = "Trainers/" + trainer.trainer_type.to_s
        firstPage.graphic.direction = event.event.pages[0].graphic.direction
		firstPage.trigger = 2 # event touch
		firstPage.list = []
        push_script(firstPage.list,sprintf("noticePlayer"))
		push_script(firstPage.list,sprintf("$TectonicRogue.startTrainerBattle(#{trainerID})"))
        push_script(firstPage.list,sprintf("defeatRogueTrainer"))
        push_script(firstPage.list,sprintf("$Trainer.heal_party"))
		firstPage.list.push(RPG::EventCommand.new(0,0,[]))
		
        # Construct the second page (trainer gone)
        secondPage = RPG::Event::Page.new
        secondPage.condition.self_switch_valid = true
        secondPage.condition.self_switch_ch = "A"

        # Set the pages
		event.event.pages[0] = firstPage
        event.event.pages[1] = secondPage
		event.refresh

        # Modify the follower pokemon
        followers = getFollowerPokemon(event.id)
        followers.each do |followerEvent|
            firstFollowerPage = createPokemonInteractionEventPage(trainer.party[0],followerEvent.event.pages[0])
            secondFollowerPage = RPG::Event::Page.new
            secondFollowerPage.condition.self_switch_valid = true
            secondFollowerPage.condition.self_switch_ch = "D"

            followerEvent.event.pages[0] = firstFollowerPage
            followerEvent.event.pages[1] = secondFollowerPage

            # Reset the follower's flag
            pbSetSelfSwitch(followerEvent.id,"D",false)

            followerEvent.refresh
        end
    end
}

##############################################################
# Show dungeon info
##############################################################
$rogue_floor_displayed = false

Events.onMapSceneChange += proc { |_sender, e|
	scene      = e[0]
	mapChanged = e[1]
	next if !scene || !scene.spriteset
	next unless rogueModeActive?
    next if $rogue_floor_displayed
	$PokEstate.load_estate_box
	boxName = $PokemonStorage[$PokEstate.estate_box].name
	label = _INTL("{1}, Floor {2}",$TectonicRogue.dungeonName,$TectonicRogue.floorNumber)
	scene.spriteset.addUserSprite(LocationWindow.new(label))
    $rogue_floor_displayed = true
}

##############################################################
# Helper methods
##############################################################
def enterRogueMode
    # Setup various data
    setLevelCap(70,false)
    $Trainer.party.clear
    $PokemonBag.clear
    $game_switches[ESTATE_DISABLED_SWITCH] = true

    # Create the roguelike run
    $TectonicRogue = TectonicRogueGameMode.new
    $TectonicRogue.beginRun
end

def ladderInteraction
    promptMoveToNextFloor
end

def promptMoveToNextFloor
    if pbConfirmMessage(_INTL("Drop down to the next floor?"))
        $TectonicRogue.moveToNextFloor
    else
        forcePlayerBackwards
    end
end

def reloadValidSpecies
    $TectonicRogue.loadValidSpecies
end

def chooseGiftPokemon(numberOfChoices = 3)
    $TectonicRogue.chooseGiftPokemon(numberOfChoices)
end

def rogueModeActive?
    return $TectonicRogue.active? || false
end

##############################################################
# Save registration
##############################################################
SaveData.register(:tectonic_rogue_mode) do
	ensure_class :TectonicRogueGameMode
	save_value { $TectonicRogue }
	load_value { |value| $TectonicRogue = value }
	new_game_value { TectonicRogueGameMode.new }
end