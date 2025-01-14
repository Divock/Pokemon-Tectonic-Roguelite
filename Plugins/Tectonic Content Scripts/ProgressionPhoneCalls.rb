Events.onBadgeEarned += proc { |_sender,_e|
    totalBadges = _e[1]
	if totalBadges == 2
		$PokemonGlobal.shouldProc2BadgesZainCall = true
	elsif totalBadges == 3
		$PokemonGlobal.shouldProc3BadgesZainCall = true
	elsif totalBadges == 4
        $PokemonGlobal.shouldProcGrouzAvatarCall = true
    elsif totalBadges == 6
        $PokemonGlobal.shouldProcCatacombsCall = true
	elsif totalBadges == 8
        $PokemonGlobal.shouldProcWhitebloomCall = true
    end
}

def gameWon?
	return $game_switches[68]
end

Events.onMapChange += proc { |_sender, _e|
	if playerIsOutdoors?()
		if $PokemonGlobal.shouldProcGrouzAvatarCall
			$game_switches[GROUZ_AVATAR_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProcGrouzAvatarCall = false
		elsif $PokemonGlobal.shouldProcCatacombsCall
			$game_switches[CATACOMBS_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProcCatacombsCall = false
		elsif $PokemonGlobal.shouldProcWhitebloomCall
			$game_switches[WHITEBLOOM_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProcWhitebloomCall = false
		elsif $PokemonGlobal.shouldProc2BadgesZainCall
			$game_switches[ZAIN_2_BADGES_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProc2BadgesZainCall = false
		elsif $PokemonGlobal.shouldProc3BadgesZainCall
			$game_switches[ZAIN_3_BADGES_PHONECALL_GLOBAL] = true
			$PokemonGlobal.shouldProc3BadgesZainCall = false
		end
	else
		if gameWon? && !$game_switches[99] # Battle monument unlocked
			$game_switches[153] = true # Trigger the phonecall from Vanya
		end
	end
}

class PokemonGlobalMetadata
	attr_accessor :shouldProc2BadgesZainCall
	attr_accessor :shouldProc3BadgesZainCall
	attr_accessor :shouldProcGrouzAvatarCall
	attr_accessor :shouldProcCatacombsCall
	attr_accessor :shouldProcWhitebloomCall
end