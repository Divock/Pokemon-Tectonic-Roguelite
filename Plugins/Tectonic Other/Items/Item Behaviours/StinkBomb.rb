ItemHandlers::UseFromBag.add(:STINKBOMB,proc { |item|
    if getStinkBombables.empty?
        pbMessage(_INTL("There's no trainers nearby to use the Stink Bomb on."))
        next 0
    end
    next 4
})

def getStinkBombables
    stinkBombables = []
    for event in $game_map.events.values
		next unless event.name.downcase.include?("stinkable")
		xDif = (event.x - $game_player.x).abs
		yDif = (event.y - $game_player.y).abs
		next unless xDif <= 3 && yDif <= 3 # Must be nearby
		stinkBombables.push(event)
    end
    return stinkBombables
end

ItemHandlers::UseInField.add(:STINKBOMB,proc { |item|
    eventsToRemove = getStinkBombables
    next 0 if eventsToRemove.empty?
    pbUseItemMessage(:STINKBOMB)
    if eventsToRemove.count > 1
        pbMessage(_INTL("#{eventsToRemove.count} trainers fled from the stench!"))
    else
        pbMessage(_INTL("A nearby trainer fled from the stench!"))
    end
    condensedLightCount = 0
    blackFadeOutIn {
        eventsToRemove.each do |eventToRemove|
            echoln("Causing event #{eventToRemove.name} (#{eventToRemove.event.id}) to flee")
            pbSetSelfSwitch(eventToRemove.id,'D',true,$game_map.map_id)
            setFollowerGone(eventToRemove.id)
            condensedLightCount += 1 if eventToRemove.name.downcase.include?("condensedlight")
        end
    }
    if condensedLightCount > 0
        if condensedLightCount == 1
            pbMessage(_INTL("Oh, a strange item was left behind!"))
        else
            pbMessage(_INTL("Oh, some strange items were left behind!"))
        end
        pbReceiveItem(:CONDENSEDLIGHT,condensedLightCount)
    end
    next 3
})