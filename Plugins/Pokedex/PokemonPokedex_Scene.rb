SEARCHES_STACK = true

class PokemonPokedex_Scene
  def pbStartScene
    @sliderbitmap       = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_slider")
    @typebitmap         = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_types"))
    @shapebitmap        = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_shapes")
    @hwbitmap           = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_hw")
    @selbitmap          = AnimatedBitmap.new("Graphics/Pictures/Pokedex/icon_searchsel")
    @searchsliderbitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/icon_searchslider"))
	@search2Cursorbitmap 		= AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/Rework/cursor_search"))
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    addBackgroundPlane(@sprites,"background","Pokedex/bg_list",@viewport)
    addBackgroundPlane(@sprites,"searchbg","Pokedex/Rework/bg_search",@viewport)
	addBackgroundPlane(@sprites,"searchbg2","Pokedex/Rework/bg_search_2",@viewport)
    @sprites["searchbg"].visible = false
	@sprites["searchbg2"].visible = false
    @sprites["pokedex"] = Window_Pokedex.new(206,30,276,364,@viewport)
    @sprites["icon"] = PokemonSprite.new(@viewport)
    @sprites["icon"].setOffset(PictureOrigin::Center)
    @sprites["icon"].x = 112
    @sprites["icon"].y = 196
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    #@sprites["searchcursor"] = PokedexSearchSelectionSprite.new(@viewport)
    #@sprites["searchcursor"].visible = false
	@sprites["search2cursor"] = SpriteWrapper.new(@viewport)
	@sprites["search2cursor"].bitmap = @search2Cursorbitmap.bitmap
    @sprites["search2cursor"].visible = false
	@searchPopupbitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Pokedex/z_header_filled"))
	@sprites["z_header"] = SpriteWrapper.new(@viewport)

	@sprites["z_header"].bitmap = @searchPopupbitmap.bitmap
	@sprites["z_header"].x = Graphics.width - @searchPopupbitmap.width
	@sprites["z_header"].visible = false
    @searchResults = false
    @searchParams  = [$PokemonGlobal.pokedexMode,-1,-1,-1,-1,-1,-1,-1,-1,-1]
    pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites)
  end
  
  def pbEndScene
    pbFadeOutAndHide(@sprites)
    pbDisposeSpriteHash(@sprites)
    @sliderbitmap.dispose
    @typebitmap.dispose
    @shapebitmap.dispose
    @hwbitmap.dispose
    @selbitmap.dispose
    @searchsliderbitmap.dispose
    @viewport.dispose
	@search2Cursorbitmap.dispose
  end


	def pbGetDexList
		region = pbGetPokedexRegion
		regionalSpecies = pbAllRegionalSpecies(region)
		if !regionalSpecies || regionalSpecies.length == 0
		  # If no Regional Dex defined for the given region, use the National Pokédex
		  regionalSpecies = []
		  GameData::Species.each { |s| regionalSpecies.push(s.id) if s.form == 0 }
		end
		shift = Settings::DEXES_WITH_OFFSETS.include?(region)
		ret = []
		regionalSpecies.each_with_index do |species, i|
		  next if !species
		  species_data = GameData::Species.get(species)
		  color  = species_data.color
		  type1  = species_data.type1
		  type2  = species_data.type2 || type1
		  shape  = species_data.shape
		  height = species_data.height
		  weight = species_data.weight
		  
		  abilities = species_data.abilities
          lvlmoves = species_data.moves
		  tutormoves = species_data.tutor_moves
		  
		  firstSpecies = GameData::Species.get(species)
		  while GameData::Species.get(firstSpecies.get_previous_species()) != firstSpecies do
			firstSpecies = GameData::Species.get(firstSpecies.get_previous_species())
		  end
		
		  eggmoves = firstSpecies.egg_moves
		  
		  evos = species_data.get_evolutions
		  prevos = species_data.get_prevolutions
		  
		  ret.push([species, species_data.name, height, weight, i + 1, shift, type1, type2, color, shape, abilities, lvlmoves, tutormoves, eggmoves, evos, prevos])
		end
		return ret
	end
	
	def pbRefreshDexList(index=0)
		dexlist = pbGetDexList
		# Sort species in ascending order by Regional Dex number
		dexlist.sort! { |a,b| a[4]<=>b[4] }
		@dexlist = dexlist
		@sprites["pokedex"].commands = @dexlist
		@sprites["pokedex"].index    = index
		@sprites["pokedex"].refresh
		if @searchResults
		  @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_listsearch")
		else
		  @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_list")
		end
		pbRefresh
	end
	
	def pbRefresh
		overlay = @sprites["overlay"].bitmap
		overlay.clear
		base   = Color.new(88,88,80)
		shadow = Color.new(168,184,184)
		zBase = Color.new(248,248,248)
		zShadow = Color.new(0,0,0)
		iconspecies = @sprites["pokedex"].species
		iconspecies = nil if isLegendary(iconspecies) && !$Trainer.seen?(iconspecies)
		# Write various bits of text

		#@sprites["cursor_list"].setBitmap("Graphics/Pictures/Pokedex/cursor_list")
		#zOverlay = @sprites["z_header"].bitmap
		#zTextpos = [[_INTL("Z/SHIFT to search."),20,2,0,zBase,shadow]]
		#pbDrawTextPositions(zOverlay,zTextpos)
		dexname = _INTL("Pokédex")
		if $Trainer.pokedex.dexes_count > 1
		  thisdex = Settings.pokedex_names[pbGetSavePositionIndex]
		  if thisdex!=nil
			dexname = (thisdex.is_a?(Array)) ? thisdex[0] : thisdex
		  end
		end
		textpos = [
		   [dexname,Graphics.width/10,-2,2,Color.new(248,248,248),Color.new(0,0,0)]
		]
		textpos.push([GameData::Species.get(iconspecies).name,112,46,2,base,shadow]) if iconspecies
		
		if @searchResults
		  textpos.push([_INTL("Search results"),112,302,2,base,shadow])
		  textpos.push([@dexlist.length.to_s,112,334,2,base,shadow])
		  textpos.push([_INTL("ACTION/Z to search further."),Graphics.width-5,-2,1,zBase,zShadow])
		else
		  textpos.push([_INTL("ACTION/Z to search."),Graphics.width-5,-2,1,zBase,zShadow])
		  textpos.push([_INTL("Seen:"),42,302,0,base,shadow])
		  textpos.push([$Trainer.pokedex.seen_count(pbGetPokedexRegion).to_s,182,302,1,base,shadow])
		  textpos.push([_INTL("Owned:"),42,334,0,base,shadow])
		  textpos.push([$Trainer.pokedex.owned_count(pbGetPokedexRegion).to_s,182,334,1,base,shadow])
		end
		# Draw all text
		pbDrawTextPositions(overlay,textpos)
		# Set Pokémon sprite
		setIconBitmap(iconspecies)
		# Draw slider arrows
		itemlist = @sprites["pokedex"]
		showslider = false
		if itemlist.top_row>0
		  overlay.blt(468,48,@sliderbitmap.bitmap,Rect.new(0,0,40,30))
		  showslider = true
		end
		if itemlist.top_item+itemlist.page_item_max<itemlist.itemCount
		  overlay.blt(468,346,@sliderbitmap.bitmap,Rect.new(0,30,40,30))
		  showslider = true
		end
		# Draw slider box
		if showslider
		  sliderheight = 268
		  boxheight = (sliderheight*itemlist.page_row_max/itemlist.row_max).floor
		  boxheight += [(sliderheight-boxheight)/2,sliderheight/6].min
		  boxheight = [boxheight.floor,40].max
		  y = 78
		  y += ((sliderheight-boxheight)*itemlist.top_row/(itemlist.row_max-itemlist.page_row_max)).floor
		  overlay.blt(468,y,@sliderbitmap.bitmap,Rect.new(40,0,40,8))
		  i = 0
		  while i*16<boxheight-8-16
			height = [boxheight-8-16-i*16,16].min
			overlay.blt(468,y+8+i*16,@sliderbitmap.bitmap,Rect.new(40,8,40,height))
			i += 1
		  end
		  overlay.blt(468,y+boxheight-16,@sliderbitmap.bitmap,Rect.new(40,24,40,16))
		end
	end
	  
	def pbDexEntry(index)
		oldsprites = pbFadeOutAndHide(@sprites)
		region = -1
		if !Settings::USE_CURRENT_REGION_DEX
		  dexnames = Settings.pokedex_names
		  if dexnames[pbGetSavePositionIndex].is_a?(Array)
			region = dexnames[pbGetSavePositionIndex][1]
		  end
		end
		
		while true
			scene = PokemonPokedexInfo_Scene.new
			screen = PokemonPokedexInfoScreen.new(scene)
			ret = screen.pbStartScreen(@dexlist,index,region,true)
			
			# If given a species symbol, we move directly to that species
			if ret.is_a?(Symbol)
				# Find the species slot on the existing dexlist, if there
				currentListIndex = -1
				@dexlist.each_with_index do |dexListEntry,index|
					next if dexListEntry[0] != ret
					currentListIndex = index
					break
				end
			
				if @searchResults && currentListIndex < 0
					# Species isn't in the current search, so scrap that search and go to it through its index on a reset dexlist
					@dexlist = pbGetDexList()
					@searchResults = false
					@sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_list")
					@sprites["pokedex"].commands = @dexlist
					
					@dexlist.each_with_index do |dexListEntry,index|
						next if dexListEntry[0] != ret
						currentListIndex = index
						break
					end
					
					ret = currentListIndex
				end
				
				index = currentListIndex
				@sprites["pokedex"].index = index
				next
			# Otherwise, we were given the last looked index of the current dexlist
			# Go back to the main pokedex menu, at that index
			else
				@sprites["pokedex"].index = ret
				break
			end
		end
		
		@sprites["pokedex"].refresh
		pbRefresh
		pbFadeInAndShow(@sprites,oldsprites)
	end

	def pbPokedex
	  pbActivateWindow(@sprites,"pokedex") {
      loop do
        Graphics.update
        Input.update
        oldindex = @sprites["pokedex"].index
        pbUpdate
		#zOverlay = @sprites["overlay"].bitmap
		#zTextpos = [[_INTL("Press Z or SHIFT to search.") ,Graphics.width/4*3,Graphics.height,0,Color.new(104,104,104),Color.new(248,248,248)]]
		#pbDrawTextPositions(zOverlay,zTextpos)
        if oldindex!=@sprites["pokedex"].index
          $PokemonGlobal.pokedexIndex[pbGetSavePositionIndex] = @sprites["pokedex"].index if !@searchResults
          pbRefresh
        end
        if Input.trigger?(Input::ACTION)
          pbPlayDecisionSE
          @sprites["pokedex"].active = false
          pbDexSearch
          @sprites["pokedex"].active = true
        elsif Input.trigger?(Input::BACK)
          if @searchResults
            pbPlayCancelSE
            pbCloseSearch
          else
            pbPlayCloseMenuSE
            break
          end
        elsif Input.trigger?(Input::USE)
          if $Trainer.pokedex.seen?(@sprites["pokedex"].species) || !isLegendary(@sprites["pokedex"].species) || (Input.trigger?(Input::CTRL) && $DEBUG)
            pbPlayDecisionSE
            pbDexEntry(@sprites["pokedex"].index)
          end
		elsif Input.pressex?(:NUMBER_1)
		  acceptSearchResults {
			searchBySpeciesName()
		  }
		elsif Input.pressex?(:NUMBER_2)
		  acceptSearchResults {
			searchByType()
		  }
		elsif Input.pressex?(:NUMBER_3)
		  acceptSearchResults {
			searchByAbility()
		  }
		elsif Input.pressex?(:NUMBER_4)
		  acceptSearchResults {
			searchByMoveLearned()
		  }
		elsif Input.pressex?(:NUMBER_5)
		  acceptSearchResults {
			searchByEvolutionMethod()
		  }
		elsif Input.pressex?(:NUMBER_6)
		  acceptSearchResults {
			searchByAvailableLevel()
		  }
		elsif Input.pressex?(0x52) # R, for Random
		  @sprites["pokedex"].index = rand(@dexlist.length)
		  @sprites["pokedex"].refresh
		  pbRefresh
		elsif Input.pressex?(0x47) && $DEBUG # G, for Get
		  pbAddPokemon(@sprites["pokedex"].species,$game_variables[26])
		elsif Input.pressex?(0x42) && $DEBUG # B, for Battle
		  pbWildBattle(@sprites["pokedex"].species, $game_variables[26])
		elsif Input.pressex?(0x49) && $DEBUG # I, for Investigation
		  # Find information about the currently displayed list
		  typesCount = {}
		  GameData::Type.each do |typesData|
			next if typesData.id == :QMARKS
			typesCount[typesData.id] = 0
		  end
		  total = 0
		  @dexlist.each do |dexEntry|
			next if isLegendary(dexEntry[0]) || isQuarantined(dexEntry[0])
			speciesData = GameData::Species.get(dexEntry[0])
			disqualify = false
			speciesData.get_evolutions().each do |evolutionEntry|
				evoSpecies = evolutionEntry[0]
				@dexlist.each do |searchDexEntry|
					if searchDexEntry[0] == evoSpecies
						disqualify = true
					end
					break if disqualify
				end
				break if disqualify
			end
			next if disqualify
			typesCount[speciesData.type1] += 1
			typesCount[speciesData.type2] += 1 if speciesData.type2 != speciesData.type1
			total += 1
		  end
		  
		  typesCount = typesCount.sort_by{|type,count| -count}
		  
		  # Find information about the whole game list
		  
		  wholeGameTypesCount = {}
		  GameData::Type.each do |typesData|
			next if typesData.id == :QMARKS
			wholeGameTypesCount[typesData.id] = 0
		  end
		  pbGetDexList.each do |dexEntry|
			next if isLegendary(dexEntry[0]) || isQuarantined(dexEntry[0])
			speciesData = GameData::Species.get(dexEntry[0])
			next if speciesData.get_evolutions().length > 0
			wholeGameTypesCount[speciesData.type1] += 1
			wholeGameTypesCount[speciesData.type2] += 1 if speciesData.type2 != speciesData.type1
		  end
		  
		  # Display investigation
		  
		  echoln("Investigation of the currently displayed dexlist:")
		  typesCount.each do |type,count|
			percentOfThisList = ((count.to_f/total.to_f) * 10000).floor / 100.0
			percentOfTypeIsInThisMap = ((count.to_f/wholeGameTypesCount[type].to_f) * 10000).floor / 100.0
			echoln("#{type}-types")
			echoln("Total: #{count},Percent of list: #{percentOfThisList}, Percent of all: #{percentOfTypeIsInThisMap}")
		  end
		end
      end
    }
  end
  
  def updateSearch2Cursor(index)
	if index >= 6
		index -= 6
		shiftRightABit = true
	end
	@sprites["search2cursor"].x = index % 2 == 0 ? 72 : 296
	@sprites["search2cursor"].x += 4 if shiftRightABit
	@sprites["search2cursor"].y = 62 + index / 2 * 96
  end
  
  def pbDexSearch
    # Prepare to start the search screen
	oldsprites = pbFadeOutAndHide(@sprites)
	@sprites["searchbg"].visible     = true
    @sprites["overlay"].visible      = true
    @sprites["search2cursor"].visible = true
	overlay = @sprites["overlay"].bitmap
	overlay.clear
    index = 0
	updateSearch2Cursor(index)
    oldindex = index
	
	# Write the button names onto the overlay
	base   = Color.new(104,104,104)
    shadow = Color.new(248,248,248)
	xLeft = 92
	xLeft2 = 316
	page1textpos = [
	   [_INTL("Choose a Search"),Graphics.width/2,-2,2,shadow,base],
       [_INTL("Name"),xLeft,68,0,base,shadow],
       [_INTL("Types"),xLeft2,68,0,base,shadow],
       [_INTL("Abilities"),xLeft,164,0,base,shadow],
       [_INTL("Moves"),xLeft2,164,0,base,shadow],
	   [_INTL("Evolution"),xLeft,260,0,base,shadow],
	   [_INTL("Available"),xLeft2,260,0,base,shadow]
    ]
	xLeft += 4
	xLeft2 += 4
	page2textpos = [
	   [_INTL("Choose a Search"),Graphics.width/2,-2,2,shadow,base],
       [_INTL("Owned"),xLeft,68,0,base,shadow],
       [_INTL("Stats"),xLeft2,68,0,base,shadow],
       [_INTL("Matchups"),xLeft,164,0,base,shadow],
       [_INTL("Misc."),xLeft2,164,0,base,shadow],
	   [_INTL("Stat Sort"),xLeft,260,0,base,shadow],
	   [_INTL("Other Sort"),xLeft2,260,0,base,shadow]
    ]
	pbDrawTextPositions(overlay,page1textpos)
	
	# Begin the search screen
	pbFadeInAndShow(@sprites)
	oldIndex = 0
	loop do
      if index!=oldIndex
		pbPlayCursorSE
		
		if oldIndex < 6 && index >=6
			pbFadeOutAndHide(@sprites)
			overlay.clear
			pbDrawTextPositions(overlay,page2textpos)
			@sprites["searchbg2"].visible     = true
			@sprites["overlay"].visible      = true
			@sprites["search2cursor"].visible = true
		elsif oldIndex >= 6 && index < 6
			pbFadeOutAndHide(@sprites)
			overlay.clear
			pbDrawTextPositions(overlay,page1textpos)
			@sprites["searchbg"].visible     = true
			@sprites["overlay"].visible      = true
			@sprites["search2cursor"].visible = true
		end
		
        updateSearch2Cursor(index)
        oldIndex = index
      end
	  
	  Graphics.update
      Input.update
      pbUpdate
	  
      if Input.trigger?(Input::UP)
        index -= 2 if ![0,1,6,7].include?(index)
      elsif Input.trigger?(Input::DOWN)
        index += 2 if ![4,5,10,11].include?(index)
      elsif Input.trigger?(Input::LEFT)
		if index % 2 == 1
			index -= 1
		elsif [6,8,10].include?(index)
			index -= 5
		end
      elsif Input.trigger?(Input::RIGHT)
        if index % 2 == 0
			index += 1
		elsif [1,3,5].include?(index)
			index += 5
		end
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
		case index 
		when 0
		  searchChanged = acceptSearchResults2 {
			searchBySpeciesName()
		  }
		when 1
		  searchChanged = acceptSearchResults2 {
			searchByType()
		  }
		when 2
		  searchChanged = acceptSearchResults2 {
			searchByAbility()
		  }
		when 3
		  searchChanged = acceptSearchResults2 {
			searchByMoveLearned()
		  }
		when 4
		  searchChanged = acceptSearchResults2 {
			searchByEvolutionMethod()
		  }
		when 5
		  searchChanged = acceptSearchResults2 {
			searchByAvailableLevel()
		  }
		when 6
		  searchChanged = acceptSearchResults2 {
			searchByOwned()
		  }
		when 7
		  searchChanged = acceptSearchResults2 {
			searchByStatComparison()
		  }
		when 8
		  searchChanged = acceptSearchResults2 {
			searchByTypeMatchup()
		  }
		when 9
		  searchChanged = acceptSearchResults2 {
			searchByZooSection()
		  }
		when 10
		  searchChanged = acceptSearchResults2 {
			sortByStat()
		  }
		when 11
		  searchChanged = acceptSearchResults2 {
			sortByOther()
		  }
		end
		if searchChanged
			break
		else
			pbPlayCloseMenuSE
		end
	  end
	end
	pbFadeOutAndHide(@sprites)
	if @searchResults
      @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_listsearch")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_list")
    end
	pbRefresh
    pbFadeInAndShow(@sprites,oldsprites)
	Input.update
  end
  
  def acceptSearchResults2(&searchingBlock)
	  pbPlayDecisionSE
	  dexlist = searchingBlock.call
	  if !dexlist
		# Do nothing
	  elsif dexlist.length==0
		pbMessage(_INTL("No matching Pokémon were found."))
	  else
		@dexlist = dexlist
		@sprites["pokedex"].commands = @dexlist
		@sprites["pokedex"].index    = 0
		@sprites["pokedex"].refresh
		@searchResults = true
		return true
	  end
	  return false
  end
  
  def acceptSearchResults(&searchingBlock)
	  pbPlayDecisionSE
	  @sprites["pokedex"].active = false
	  dexlist = searchingBlock.call
	  if !dexlist
		# Do nothing
	  elsif dexlist.length==0
		pbMessage(_INTL("No matching Pokémon were found."))
	  else
		@dexlist = dexlist
		@sprites["pokedex"].commands = @dexlist
		@sprites["pokedex"].index    = 0
		@sprites["pokedex"].refresh
		@searchResults = true
		@sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_listsearch")
	  end
	  @sprites["pokedex"].active = true
	  pbRefresh
  end
  
  def searchBySpeciesName()
	  nameInput = pbEnterText("Search species...", 0, 12)
	  if nameInput && nameInput!=""
		  reversed = nameInput[0] == '-'
		  nameInput = nameInput[1..-1] if reversed
		  dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
		  dexlist = dexlist.find_all { |item|
			next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
			searchPokeName = item[1]
			value = searchPokeName.downcase.include?(nameInput.downcase) ^ reversed # Boolean XOR
			next value
		  }
		  return dexlist
	  end
	  return nil
  end
  
  def searchByAbility()
	  abilitySearchTypeSelection = pbMessage("Which search?",[_INTL("Name"),_INTL("Description"),_INTL("Cancel")],3)
	  return if abilitySearchTypeSelection == 2
	  
	  if abilitySearchTypeSelection == 0
		  while true
			  abilityNameInput = pbEnterText("Search abilities...", 0, 20)
			  if abilityNameInput && abilityNameInput!=""
				reversed = abilityNameInput[0] == '-'
				abilityNameInput = abilityNameInput[1..-1] if reversed

				actualAbility = nil
				GameData::Ability.each do |abilityData|
					if abilityData.real_name.downcase == abilityNameInput.downcase
						actualAbility = abilityData.id
						break
					end
				end
				if actualAbility.nil?
					pbMessage(_INTL("Invalid input: {1}", abilityNameInput))
					next
				end

				dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
				dexlist = dexlist.find_all { |item|
					next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
					searchPokeAbilities = item[10]
					value = false
					value = true if searchPokeAbilities.include?(actualAbility)
					value = value ^ reversed # Boolean XOR
					next value
				}
				return dexlist
			  end
		  end
	  elsif abilitySearchTypeSelection == 1
		  abilityDescriptionInput = pbEnterText("Search ability desc...", 0, 20)
		  if abilityDescriptionInput && abilityDescriptionInput!=""
			reversed = abilityDescriptionInput[0] == '-'
			abilityDescriptionInput = abilityDescriptionInput[1..-1] if reversed

			dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
			dexlist = dexlist.find_all { |item|
				next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
				searchPokeAbilities = item[10]
				value = false
				value = true if searchPokeAbilities[0] && GameData::Ability.get(searchPokeAbilities[0]).description.downcase.include?(abilityDescriptionInput)
				value = true if searchPokeAbilities[1] && GameData::Ability.get(searchPokeAbilities[1]).description.downcase.include?(abilityDescriptionInput)
				value = value ^ reversed # Boolean XOR
				next value
			}
			return dexlist
		  end
	  end
	  return nil
  end
  
  def searchByMoveLearned()
	  learningMethodSelection = pbMessage("Which method?",[_INTL("Any"),_INTL("Level Up"),_INTL("By Specific Level"),_INTL("Tutor"),_INTL("Cancel")],5)
	  return if learningMethodSelection == 4
	  
	  if learningMethodSelection == 2
		while true
			levelTextInput = pbEnterText(_INTL("Enter level..."), 0, 3)
			return nil if levelTextInput.blank?
			reversed = levelTextInput[0] == '-'
			levelTextInput = levelTextInput[1..-1] if reversed

			levelIntAttempt = levelTextInput.to_i
			if levelIntAttempt == 0
				pbMessage(_INTL("Invalid level input."))
				next
			end
			break
		end
	  end
      
	  while true
		  moveNameInput = pbEnterText("Move name...", 0, 16)
		  if moveNameInput && moveNameInput!=""
				reversed = moveNameInput[0] == '-'
				moveNameInput = moveNameInput[1..-1] if reversed
				
				actualMove = nil
			    GameData::Move.each do |moveData|
					if moveData.real_name.downcase == moveNameInput.downcase
						actualMove = moveData.id
						break
					end
			    end
				if actualMove.nil?
					pbMessage(_INTL("Invalid input: {1}", moveNameInput))
					next
				end
				
				dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
				dexlist = dexlist.find_all { |item|
					next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
					contains = false
					
					if learningMethodSelection == 0 || learningMethodSelection == 1
						lvlmoves = item[11]
						lvlmoves.each do |learnset_entry|
						  if learnset_entry[1] == actualMove
							contains = true
							break
						  end
						end
					end
					
					if learningMethodSelection == 2
						lvlmoves = item[11]
						lvlmoves.each do |learnset_entry|
							break if learnset_entry[0] > levelIntAttempt
							if learnset_entry[1] == actualMove
								contains = true
								break
							end
						end
					end
					
					if learningMethodSelection == 0 || learningMethodSelection == 3
						eggmoves = item[13]
						eggmoves.each do |move|
						  if move == actualMove
							contains = true
							break
						  end
						end
						
						tutormoves = item[12]
						tutormoves.each do |move|
						  if move == actualMove
							contains = true
							break
						  end
						end
					end

					next contains ^ reversed # Boolean XOR
				}
			  return dexlist
		  end
		  break
	  end
	  return nil
  end
  
  def searchByType()
	  while true
		  typesInput = pbEnterText("Search types...", 0, 100)
		  typesInput.downcase!
		  if typesInput && typesInput!=""
			  typesInputArray = typesInput.split(" ")
			  
			  # Don't do the search if one of the input type names isn't an actual type
			  invalid = false
			  typesSearchInfo = {}
			  typesInputArray.each do |type_input_entry|
				reversed = type_input_entry[0] == '-'
			    type_input_entry = type_input_entry[1..-1] if reversed
				typeIsReal = false
				GameData::Type.each do |type_data|
					typeIsReal = true if type_data.real_name.downcase == type_input_entry
					break if typeIsReal
				end
				if !typeIsReal
					pbMessage(_INTL("Invalid input: {1}", type_input_entry))
					invalid = true
					break
				end
				typesSearchInfo[type_input_entry] = reversed
			  end
			  next if invalid
			  
			  dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
			  dexlist = dexlist.find_all { |item|
				next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
				searchPokeType1 = item[6]
				searchPokeType1Name = GameData::Type.get(searchPokeType1).real_name.downcase if searchPokeType1
				searchPokeType2 = item[7]
				searchPokeType2Name = GameData::Type.get(searchPokeType2).real_name.downcase if searchPokeType2
				
				pokeTypeNames = [searchPokeType1Name,searchPokeType2Name]
				
				survivesSearch = true
				typesSearchInfo.each do |type,reversed|
					if !reversed
						survivesSearch = false if !pokeTypeNames.include?(type)
					else
						survivesSearch = false if pokeTypeNames.include?(type)
					end
				end
				next survivesSearch
			  }
			  return dexlist
		  end
		  return nil
	  end
  end
  
  def searchByEvolutionMethod()
	  evoMethodTextInput = pbEnterText("Search method...", 0, 12)
	  if evoMethodTextInput && evoMethodTextInput!=""
		  reversed = evoMethodTextInput[0] == '-'
		  evoMethodTextInput = evoMethodTextInput[1..-1] if reversed
		  dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
		  dexlist = dexlist.find_all { |item|
			next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
			anyContain = false
			# Evolutions
			item[14].each do |evomethod|
				strippedActualDescription = describeEvolutionMethod(evomethod[1],evomethod[2]).downcase.delete(' ')
				strippedInputString = evoMethodTextInput.downcase.delete(' ')
				anyContain = true if strippedActualDescription.include?(strippedInputString)
			end
			value = anyContain ^ reversed # Boolean XOR
			next value
		  }
		  return dexlist
	  end
	  return nil
  end
  

  def searchByAvailableLevel()
	  levelTextInput = pbEnterText("Search available by level...", 0, 3)
	  if levelTextInput && levelTextInput!=""
		  reversed = levelTextInput[0] == '-'
		  levelTextInput = levelTextInput[1..-1] if reversed
	  
		  levelIntAttempt = levelTextInput.to_i
		  return nil if levelIntAttempt == 0
		  
		  maps_available_by_cap = {
			15 => [33,34,29,30,38,26, # Casaba Villa, Scenic Path, Mine Path, Small Mine, Beach Route, Seaside Grotto
					35,27		# Impromptu Lab, Casaba Mart
			], 
			30 => [60,56,51,66,123, 	 # Forested Road, Suburb, Starters Store, Nemeth Attic, Nemeth Academy
					3,25,55,6,81,	 # Savannah Route, Mining Camp, Flower Fields, LuxTech Campus, Cave Path
					54,37,7,8,53, # Crossroads, Ice Rink, Swamp Route, Jungle Route
					117,36,10,12, # Ice Cave, Abandoned Mine, Jungle Temple, Gigalith's Guts
					13,11,122,120,121,		# Cave Path, River Route, Sewer, Deep Layer, Mountain Climb
					
					4,20,86,       # Scientist's House, Lengthy Glade, Zigzagoon Nest
					78,87,103,92,    # LuxTech Main, LuxTech Apartments, Ghost Town Mart, Ice Rink Lodge
					32,71,74		# Nemeth Apartments, Nemeth Apartments Room 103, Nemeth Apartments Room 203
					]
		  }
		  
		  items_available_by_cap = {
			15 => [],
			20 => [],
			25 => [],
			30 => [],
			35 => [:FIRESTONE,:WATERSTONE,:LEAFSTONE,:THUNDERSTONE,:DAWNSTONE,
					:DUSKSTONE,:SUNSTONE,:SHINYSTONE,:ICESTONE,:KINGSROCK,:MOONSTONE]
		  }
		  
		  surfingAvailable = levelIntAttempt >= 35
		  
		  dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
		  dexlist = dexlist.find_all { |item|
			next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
			
			speciesToCheckLocationsFor = [item[0]]
			# Note each pre-evolution which could be the path to aquiring this pokemon by the given level
			currentPrevo = item[15].length > 0 ? item[15][0] : nil
			while currentPrevo != nil
				evoMethod = currentPrevo[1]
				case evoMethod
				# All method based on leveling up to a certain level
				when :Level,:LevelDay,:LevelNight,:LevelMale,:LevelFemale,:LevelRain,
					:AttackGreater,:AtkDefEqual,:DefenseGreater,:LevelDarkInParty,
					:Silcoon,:Cascoon,:Ninjask,:Shedinja
					
					levelThreshold = currentPrevo[2]
					if levelThreshold <= levelIntAttempt
						#echoln("Adding #{currentPrevo[0]} to the checks for #{item[0]} based on level evo.")
						speciesToCheckLocationsFor.push(currentPrevo[0])
					else
						break
					end
				# All methods based on holding a certain item or using a certain item on the pokemon
				when :HoldItem,:HoldItemMale,:HoldItemFemale,:DayHoldItem,:NightHoldItem,
					:Item,:ItemMale,:ItemFemale,:ItemDay,:ItemNight,:ItemHappiness
					
					# Push this prevo if the evolution from it is gated by an item which is available by this point
					itemNeeded = currentPrevo[2]
					itemAvailable = false
					items_available_by_cap.each do |key, value|
						itemAvailable = true if value.include?(itemNeeded)
						break if key >= levelIntAttempt
					end
					if itemAvailable
						speciesToCheckLocationsFor.push(currentPrevo[0])
						#echoln("Adding #{currentPrevo[0]} to the checks for #{item[0]} based on item evo.") if itemAvailable
					else
						break
					end
				end
				
				# Find the prevo of the prevo
				prevosfSpecies = GameData::Species.get_species_form(currentPrevo[0],0)
				prevolutions = prevosfSpecies.get_prevolutions
				currentPrevo = prevolutions.length > 0 ? prevolutions[0] : nil
			end
			
			# Find all the maps which are available by the given level
			mapsToCheck = []
			levelCapBracket = 0
			maps_available_by_cap.each do |key, value|
				mapsToCheck.concat(value)
				levelCapBracket = key
				break if levelCapBracket >= levelIntAttempt
			end
			
			# For each possible species which could lead to this species, check to see if its available in any of the maps 
			# which are available by the level cap which would apply at the given level
			available = false
			# For each encounters data listing
			GameData::Encounter.each_of_version($PokemonGlobal.encounter_version) do |enc_data|
				next unless mapsToCheck.include?(enc_data.map)
				# For each species we need to check for
				speciesToCheckLocationsFor.each do |species|
					encounterInfoForSpecies = nil
					# For each slot in that encounters data listing
					enc_data.types.each do |key,slots|
					    next if !slots
						next if key == :ActiveWater && !surfingAvailable
					    slots.each { |slot|
							species_data = GameData::Species.get(slot[1])
							if species_data.species == species
								# Mark down this slot if no such slot is marked, or if this is a lower level encounter
								if encounterInfoForSpecies == nil || slot[3] < encounterInfoForSpecies[3]
									encounterInfoForSpecies = slot
								end
							end
					    }
					end
					# Continue onto the next species if no slots on the map being currently looked at have an entry for this species
					next if !encounterInfoForSpecies

					# Assume that encounters which distribute a pokemon beyond the level cap bracket
					# are not actually available during that level cap
					# But through returning to a secret part of that map later, or something
					available = true if encounterInfoForSpecies[3] <= levelCapBracket
				end
				break if available
			end
			value = available ^ reversed # Boolean XOR
			next value
		  }
		  return dexlist
	  end
	  return nil
  end


	def searchByOwned()
		selection = pbMessage("Which search?",[_INTL("Owned"),_INTL("Not Owned"),_INTL("Cancel")],3)
	    if selection != 2 
			dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
			
			dexlist = dexlist.find_all { |item|
				next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
				
				if selection == 1
					next !$Trainer.owned?(item[0])
				else
					next $Trainer.owned?(item[0])
				end
			}
			
			return dexlist
		end
		return nil
	end
	
	def searchByStatComparison()
		statSelection = pbMessage("Which stat?",[_INTL("HP"),_INTL("Attack"),_INTL("Defense"),
			_INTL("Sp. Atk"),_INTL("Sp. Def"),_INTL("Speed"),_INTL("Total"),_INTL("Cancel")],8)
	    return if statSelection == 7 
		comparisonSelection = pbMessage("Which comparison?",[_INTL("Equal to"),
			_INTL("Greater than"),_INTL("Less than"),_INTL("Cancel")],4)
		return if comparisonSelection == 3 
		dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
		statTextInput = pbEnterText("Input value...", 0, 3)
		if statTextInput && statTextInput!=""
			reversed = statTextInput[0] == '-'
			statTextInput = statTextInput[1..-1] if reversed
		  
			statIntAttempt = statTextInput.to_i
			
			return nil if statIntAttempt == 0
			
			dexlist = dexlist.find_all { |item|
				next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
				
				species_data = GameData::Species.get(item[0])
				
				statToCompare = 0
				case statSelection
				when 0
					statToCompare = species_data.base_stats[:HP]
				when 1
					statToCompare = species_data.base_stats[:ATTACK]
				when 2
					statToCompare = species_data.base_stats[:DEFENSE]
				when 3
					statToCompare = species_data.base_stats[:SPECIAL_ATTACK]
				when 4
					statToCompare = species_data.base_stats[:SPECIAL_DEFENSE]
				when 5
					statToCompare = species_data.base_stats[:SPEED]
				when 6
					species_data.base_stats.each do |s|
						statToCompare += s[1]
					end
				end
					
				case comparisonSelection
				when 0
					next statToCompare == statIntAttempt
				when 1
					next statToCompare > statIntAttempt
				when 2
					next statToCompare < statIntAttempt
				end
				next false
			}
			
			return dexlist
		end
		return nil
	end
	
	def searchByZooSection()
		sectionSelection = pbMessage("Which section?",[_INTL("Zoo"),_INTL("Cancel")],2)
	    return if sectionSelection == 1 
		dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
		mapIDs = [31]
		
		# Get all the names of the species given events on that map
		mapID = mapIDs[sectionSelection]
		map = $MapFactory.getMapNoAdd(mapID)
		speciesPresent = []
		map.events.each_value { |event|
			speciesPresent.push(event.name.downcase)
		}
		
		dexlist = dexlist.find_all { |item|
				next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
				
				next speciesPresent.include?(item[0].name.downcase)
		}
		return dexlist
	end
	
	def searchByTypeMatchup()
		sectionSelection = pbMessage("Which interaction?",[_INTL("Weak To"),_INTL("Resists"),
			_INTL("Immune To"),_INTL("Cancel")],4)
	    return if sectionSelection == 3 
		
		while true
		  typesInput = pbEnterText("Which type(s)?", 0, 100)
		  typesInput.downcase!
		  if typesInput && typesInput!=""
			  typesInputArray = typesInput.split(" ")
			  
			  # Don't do the search if one of the input type names isn't an actual type
			  invalid = false
			  typesSearchInfo = {}
			  typesInputArray.each do |type_input_entry|
				reversed = type_input_entry[0] == '-'
			    type_input_entry = type_input_entry[1..-1] if reversed
				typeIsReal = false
				type_symbol = nil
				GameData::Type.each do |type_data|
					if type_data.real_name.downcase == type_input_entry
						typeIsReal = true
						type_symbol = type_data.id
						break
					end
				end
				if !typeIsReal
					pbMessage(_INTL("Invalid input: {1}", type_input_entry))
					invalid = true
					break
				end
				typesSearchInfo[type_symbol] = reversed
			  end
			  next if invalid
			  
			  dexlist = SEARCHES_STACK ? @dexlist : pbGetDexList
			  dexlist = dexlist.find_all { |item|
				next false if isLegendary(item[0]) && !$Trainer.seen?(item[0]) && !$DEBUG
				
				result = true
				
				survivesSearch = true
				typesSearchInfo.each do |type,reversed|
					effect = Effectiveness.calculate(type,item[6],item[7])
							
					case sectionSelection
					when 0
						survivesSearch = false if !Effectiveness.super_effective?(effect) ^ reversed
					when 1
						survivesSearch = false if !Effectiveness.not_very_effective?(effect) ^ reversed
					when 2
						survivesSearch = false if !Effectiveness.ineffective?(effect) ^ reversed
					end
				end
				next survivesSearch
			  }
			  return dexlist
		  end
		  return nil
	  end
	end
	
	def sortByStat()
		statSelection = pbMessage("Which stat?",[_INTL("HP"),_INTL("Attack"),_INTL("Defense"),
			_INTL("Sp. Atk"),_INTL("Sp. Def"),_INTL("Speed"),_INTL("Total"),_INTL("Cancel")],8)
	    return if statSelection == 7
		sortDirection = pbMessage("Which direction?",[_INTL("Descending"),_INTL("Ascending"),_INTL("Cancel")],3)
		return if sortDirection == 2
		dexlist = @dexlist
		dexlist.sort_by! { |entry|
			speciesData = GameData::Species.get(entry[0])
			value = 0
			case statSelection
			when 0
				value = speciesData.base_stats[:HP]
			when 1
				value = speciesData.base_stats[:ATTACK]
			when 2
				value = speciesData.base_stats[:DEFENSE]
			when 3
				value = speciesData.base_stats[:SPECIAL_ATTACK]
			when 4
				value = speciesData.base_stats[:SPECIAL_DEFENSE]
			when 5
				value = speciesData.base_stats[:SPEED]
			when 6
				speciesData.base_stats.each do |s|
					value += s[1]
				end
			end
			
			value *= -1 if sortDirection == 0
			next value
		}
		
		return dexlist
	end
	
	def sortByOther()
		statSelection = pbMessage("Which stat?",[_INTL("Type"),_INTL("Cancel")],2)
	    return if statSelection == 1 
		dexlist = @dexlist
		dexlist.sort_by! { |entry|
			speciesData = GameData::Species.get(entry[0])
			
			types = [speciesData.type1,speciesData.type2]
			types.sort_by!{ |type|
				GameData::Type.get(type).id_number
			}
			value = 0
			types.each_with_index do |type,index|
				value += GameData::Type.get(type).id_number * (18 ** index)
			end
			
			next value
		}
		return dexlist
	end
end