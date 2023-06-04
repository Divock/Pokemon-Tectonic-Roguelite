VOLUME_FAKERY_MULT = 2.0

class PokemonSystem
    attr_accessor :textspeed
    attr_accessor :battlescene
    attr_accessor :battlestyle
    attr_accessor :frame
    attr_accessor :textskin
    attr_accessor :screensize
    attr_accessor :language
    attr_accessor :runstyle
    attr_accessor :bgmvolume
    attr_accessor :sevolume
    attr_accessor :textinput
    attr_accessor :followers
    attr_accessor :autosave
    attr_accessor :particle_effects
    attr_writer   :overworld_weather
    attr_accessor :screenshake
    attr_accessor :skip_fades
    attr_accessor :gendered_look
    attr_accessor :damage_numbers
    attr_accessor :show_item_descriptions
    attr_accessor :show_trait_unlocks
    attr_accessor :effectiveness_messages
    attr_accessor :weather_messages
    attr_accessor :status_effect_messages
    attr_accessor :move_clarifying_messages
    attr_accessor :nicknaming_prompt
    attr_accessor :color_shifts
    attr_accessor :party_snapshots
    attr_accessor :bag_sorting
    attr_accessor :battle_transitions

    def bgmvolume
        return @bgmvolume / VOLUME_FAKERY_MULT
    end

    attr_writer :bgmvolume

    def sevolume
        return @sevolume / VOLUME_FAKERY_MULT
    end

    attr_writer :sevolume

    def overworld_weather
        @overworld_weather ||= 0
        return @overworld_weather
    end

    def initialize
        @textspeed = $DEBUG ? 4 : 2 # Text speed (0=slow, 1=normal, 2=fast, 3=rapid, 4=instant)
        @battlescene = 1 # Battle effects (animations) (0=on, 1=fast, 2=off)
        @battle_transitions = $DEBUG ? 1 : 0 # (0=standard, 1=fast)
        @battlestyle = 1 # Battle style (0=switch, 1=set)
        @frame = 0 # Default window frame (see also Settings::MENU_WINDOWSKINS)
        @textskin    		          = 0 # Speech frame
        @font        		          = 0 # Font (see also Settings::FONT_OPTIONS)
        @screensize  		          = (Settings::SCREEN_SCALE * 2).floor - 1 # 0=half size, 1=full size, 2=full-and-a-half size, 3=double size
        @language    		          = 0 # Language (see also Settings::LANGUAGES in script PokemonSystem)
        @runstyle    		          = 0 # Default movement speed (0=walk, 1=run)
        @bgmvolume = 50 # Volume of background music and ME
        @sevolume    		          = 50 # Volume of sound effects
        @textinput   		          = System.platform.downcase[/android/] ? 0 : 1 # Text input mode (0=cursor, 1=keyboard)
        @followers   		          = 0	# Follower Pokemon enabled (0=true, 1=false)
        @autosave	 		            = 0	# Autosave enabled (0=true, 1=false)
        @color_shifts = 0 # (0=true, 1=false)
        @particle_effects = 0 # (0=true, 1=false)
        @overworld_weather        = 0 # (0=true, 1=false)
        @screenshake              = 0 # (0=true, 1=false)
        @skip_fades = 1 # (0=true, 1=false)
        @gendered_look 		        = 0 # (0 = Masc, 1 = Fem, 2 = Andro)
        @damage_numbers 	        = 0 # (0=true, 1=false)
        @show_item_descriptions   = $DEBUG ? 1 : 0 # (0=true, 1=false)
        @effectiveness_messages   = 0 # (0=true, 1=false)
        @weather_messages         = 0 # (0=true, 1=false)
        @status_effect_messages   = 0 # (0=true, 1=false)
        @move_clarifying_messages = 0 # (0=true, 1=false)
        @nicknaming_prompt        = 0 # (0=true, 1=false)
        @show_trait_unlocks       = $DEBUG ? 1 : 0 # (0=true, 1=false)
        @party_snapshots          = $DEBUG ? 1 : 0 # (0=true, 1=false)
        @bag_sorting              = 0 # (0=none,1=alphabetical,2=ID)
    end
end

#===============================================================================
#
#===============================================================================
module PropertyMixin
    def get
        @getProc ? @getProc.call : nil
    end

    def set(value)
        @setProc.call(value) if @setProc
    end
end

#===============================================================================
#
#===============================================================================
class EnumOption
    include PropertyMixin
    attr_reader :values
    attr_reader :name

    def initialize(name, options, getProc, setProc)
        @name    = name
        @values  = options
        @getProc = getProc
        @setProc = setProc
    end

    def next(current)
        index = current + 1
        index = @values.length - 1 if index > @values.length - 1
        return index
    end

    def prev(current)
        index = current - 1
        index = 0 if index < 0
        return index
    end
end

#===============================================================================
#
#===============================================================================
class EnumOption2
    include PropertyMixin
    attr_reader :values
    attr_reader :name

    def initialize(name, options, getProc, setProc)
        @name    = name
        @values  = options
        @getProc = getProc
        @setProc = setProc
    end

    def next(current)
        index = current + 1
        index = @values.length - 1 if index > @values.length - 1
        return index
    end

    def prev(current)
        index = current - 1
        index = 0 if index < 0
        return index
    end
end

#===============================================================================
#
#===============================================================================
class NumberOption
    include PropertyMixin
    attr_reader :name
    attr_reader :optstart
    attr_reader :optend

    def initialize(name, optstart, optend, getProc, setProc)
        @name     = name
        @optstart = optstart
        @optend   = optend
        @getProc  = getProc
        @setProc  = setProc
    end

    def next(current)
        index = current + @optstart
        index += 1
        index = @optstart if index > @optend
        return index - @optstart
    end

    def prev(current)
        index = current + @optstart
        index -= 1
        index = @optend if index < @optstart
        return index - @optstart
    end
end

#===============================================================================
#
#===============================================================================
class SliderOption
    include PropertyMixin
    attr_reader :name
    attr_reader :optstart
    attr_reader :optend

    def initialize(name, optstart, optend, optinterval, getProc, setProc)
        @name        = name
        @optstart    = optstart
        @optend      = optend
        @optinterval = optinterval
        @getProc     = getProc
        @setProc     = setProc
    end

    def next(current)
        index = current + @optstart
        index += @optinterval
        index = @optend if index > @optend
        return index - @optstart
    end

    def prev(current)
        index = current + @optstart
        index -= @optinterval
        index = @optstart if index < @optstart
        return index - @optstart
    end
end

#===============================================================================
# Main options list
#===============================================================================
class Window_PokemonOption < Window_DrawableCommand
    attr_reader :mustUpdateOptions

    def initialize(options, x, y, width, height)
        @options = options
        @nameBaseColor   = Color.new(24 * 8, 15 * 8, 0)
        @nameShadowColor = Color.new(31 * 8, 22 * 8, 10 * 8)
        @selBaseColor    = Color.new(31 * 8, 6 * 8, 3 * 8)
        @selShadowColor  = Color.new(31 * 8, 17 * 8, 16 * 8)
        @optvalues = []
        @mustUpdateOptions = false
        for i in 0...@options.length
            @optvalues[i] = 0
        end
        super(x, y, width, height)
    end

    def [](i)
        return @optvalues[i]
    end

    def []=(i, value)
        @optvalues[i] = value
        refresh
    end

    def setValueNoRefresh(i, value)
        @optvalues[i] = value
    end

    def itemCount
        return @options.length + 1
    end

    def drawItem(index, _count, rect)
        rect = drawCursor(index, rect)
        optionname = (index == @options.length) ? _INTL("Exit") : @options[index].name
        optionwidth = rect.width * 9 / 20
        pbDrawShadowText(contents, rect.x, rect.y, optionwidth, rect.height, optionname,
           @nameBaseColor, @nameShadowColor)
        return if index == @options.length
        if @options[index].is_a?(EnumOption)
            if @options[index].values.length > 1
                totalwidth = 0
                for value in @options[index].values
                    totalwidth += contents.text_size(value).width
                end
                spacing = (optionwidth - totalwidth) / (@options[index].values.length - 1)
                spacing = 0 if spacing < 0
                xpos = optionwidth + rect.x
                ivalue = 0
                for value in @options[index].values
                    pbDrawShadowText(contents, xpos, rect.y, optionwidth, rect.height, value,
                       (ivalue == self[index]) ? @selBaseColor : baseColor,
                       (ivalue == self[index]) ? @selShadowColor : shadowColor
                    )
                    xpos += contents.text_size(value).width
                    xpos += spacing
                    ivalue += 1
                end
            else
                pbDrawShadowText(contents, rect.x + optionwidth, rect.y, optionwidth, rect.height,
                   optionname, baseColor, shadowColor)
            end
        elsif @options[index].is_a?(NumberOption)
            value = _INTL("Type {1}/{2}", @options[index].optstart + self[index],
               @options[index].optend - @options[index].optstart + 1)
            xpos = optionwidth + rect.x
            pbDrawShadowText(contents, xpos, rect.y, optionwidth, rect.height, value,
               @selBaseColor, @selShadowColor)
        elsif @options[index].is_a?(SliderOption)
            value = format(" %d", @options[index].optend)
            sliderlength = optionwidth - contents.text_size(value).width
            xpos = optionwidth + rect.x
            contents.fill_rect(xpos, rect.y - 2 + rect.height / 2,
               optionwidth - contents.text_size(value).width, 4, baseColor)
            contents.fill_rect(
                xpos + (sliderlength - 8) * (@options[index].optstart + self[index]) / @options[index].optend,
               rect.y - 8 + rect.height / 2,
               8, 16, @selBaseColor)
            value = format("%d", @options[index].optstart + self[index])
            xpos += optionwidth - contents.text_size(value).width
            pbDrawShadowText(contents, xpos, rect.y, optionwidth, rect.height, value,
               @selBaseColor, @selShadowColor)
        else
            value = @options[index].values[self[index]]
            xpos = optionwidth + rect.x
            pbDrawShadowText(contents, xpos, rect.y, optionwidth, rect.height, value,
               @selBaseColor, @selShadowColor)
        end
    end

    def update
        oldindex = index
        @mustUpdateOptions = false
        super
        dorefresh = (index != oldindex)
        if active && index < @options.length
            if Input.repeat?(Input::LEFT)
                self[index] = @options[index].prev(self[index])
                dorefresh = true
                @mustUpdateOptions = true
            elsif Input.repeat?(Input::RIGHT)
                self[index] = @options[index].next(self[index])
                dorefresh = true
                @mustUpdateOptions = true
            end
        end
        refresh if dorefresh
    end
end

#===============================================================================
#
#===============================================================================
class PokemonOption_Scene_Base
    def pbUpdate
        pbUpdateSpriteHash(@sprites)
    end

    def optionsName
        return _INTL("Options")
    end

    def pbStartScene(_inloadscreen = false)
        @sprites = {}
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99_999
        @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
            optionsName, 0, 0, Graphics.width, 64, @viewport)
        @sprites["textbox"] = pbCreateMessageWindow
        @sprites["textbox"].text           = _INTL("Speech frame {1}.", 1 + $PokemonSystem.textskin)
        @sprites["textbox"].letterbyletter = false
        pbSetSystemFont(@sprites["textbox"].contents)
        # These are the different options in the game. To add an option, define a
        # setter and a getter for that option. To delete an option, comment it out
        # or delete it. The game's options may be placed in any order.
        @PokemonOptions = []
        @PokemonOptions = pbAddOnOptions(@PokemonOptions)
        @sprites["option"] = Window_PokemonOption.new(@PokemonOptions, 0,
           @sprites["title"].height, Graphics.width,
           Graphics.height - @sprites["title"].height - @sprites["textbox"].height)
        @sprites["option"].viewport = @viewport
        @sprites["option"].visible  = true
        # Get the values of each option
        for i in 0...@PokemonOptions.length
            @sprites["option"].setValueNoRefresh(i, (@PokemonOptions[i].get || 0))
        end
        @sprites["option"].refresh
        pbDeactivateWindows(@sprites)
        pbFadeInAndShow(@sprites) { pbUpdate }
    end

    def pbAddOnOptions(options)
        return options
    end

    def pbOptions
        oldSystemSkin = $PokemonSystem.frame # Menu
        oldTextSkin = $PokemonSystem.textskin # Speech
        pbActivateWindow(@sprites, "option") do
            loop do
                Graphics.update
                Input.update
                pbUpdate
                if @sprites["option"].mustUpdateOptions
                    # Set the values of each option
                    for i in 0...@PokemonOptions.length
                        @PokemonOptions[i].set(@sprites["option"][i])
                    end
                    if $PokemonSystem.textskin != oldTextSkin
                        @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame)
                        @sprites["textbox"].text = _INTL("Speech frame {1}.", 1 + $PokemonSystem.textskin)
                        oldTextSkin = $PokemonSystem.textskin
                    end
                    if $PokemonSystem.frame != oldSystemSkin
                        @sprites["title"].setSkin(MessageConfig.pbGetSystemFrame)
                        @sprites["option"].setSkin(MessageConfig.pbGetSystemFrame)
                        oldSystemSkin = $PokemonSystem.frame
                    end
                end
                if Input.trigger?(Input::BACK)
                    break
                elsif Input.trigger?(Input::USE)
                    break if @sprites["option"].index == @PokemonOptions.length
                end
            end
        end
    end

    def pbEndScene
        pbPlayCloseMenuSE
        pbFadeOutAndHide(@sprites) { pbUpdate }
        # Set the values of each option
        for i in 0...@PokemonOptions.length
            @PokemonOptions[i].set(@sprites["option"][i])
        end
        pbDisposeMessageWindow(@sprites["textbox"])
        pbDisposeSpriteHash(@sprites)
        pbRefreshSceneMap
        @viewport.dispose
    end
end

#===============================================================================
#
#===============================================================================
class PokemonOptionScreen
    def initialize(scene)
        @scene = scene
    end

    def pbStartScreen(inloadscreen = false)
        @scene.pbStartScene(inloadscreen)
        @scene.pbOptions
        @scene.pbEndScene
    end
end

#===============================================================================
#
#===============================================================================
module MessageConfig
    def self.pbSettingToTextSpeed(speed, slowed = false)
        modifiedSpeed = speed
        modifiedSpeed -= 1 if speed && slowed
        case modifiedSpeed
        when -1 then return 3
        when 0 then return 2
        when 1 then return 1
        when 2 then return -2
        when 3 then return -5
        when 4 then return -20
        end
        return TEXT_SPEED || -20
    end
end

SaveData.register(:pokemon_system) do
    ensure_class :PokemonSystem
    save_value { $PokemonSystem }
    load_value { |value| $PokemonSystem = value }
    new_game_value { PokemonSystem.new }
    from_old_format { |old_format| old_format[3] }
end

#===============================================================================
# Audio options scene
#===============================================================================
class PokemonOption_Scene_Audio < PokemonOption_Scene_Base
    def optionsName
        return _INTL("Audio Options")
    end

	def pbAddOnOptions(options)
		options.concat([
			SliderOption.new(_INTL("Music Volume"), 0, 100, 5,
				proc { $PokemonSystem.bgmvolume * VOLUME_FAKERY_MULT },
				proc { |value|
					if $PokemonSystem.bgmvolume * VOLUME_FAKERY_MULT != value
						$PokemonSystem.bgmvolume = value
						if !$game_system.playing_bgm.nil? && !inloadscreen
							playingBGM = $game_system.getPlayingBGM
							$game_system.bgm_pause
							$game_system.bgm_resume(playingBGM)
						end
					end
				}
			),
			SliderOption.new(_INTL("SE Volume"), 0, 100, 5,
				proc { $PokemonSystem.sevolume * VOLUME_FAKERY_MULT },
				proc { |value|
					if $PokemonSystem.sevolume * VOLUME_FAKERY_MULT != value
						$PokemonSystem.sevolume = value
						unless $game_system.playing_bgs.nil?
							$game_system.playing_bgs.volume = $PokemonSystem.sevolume
							playingBGS = $game_system.getPlayingBGS
							$game_system.bgs_pause
							$game_system.bgs_resume(playingBGS)
						end
						pbPlayCursorSE
					end
				}
			),
		])
	end
end

#===============================================================================
# User Interface options scene
#===============================================================================
class PokemonOption_Scene_UserInterface < PokemonOption_Scene_Base
    def optionsName
        return _INTL("User Interface Options")
    end

	def pbAddOnOptions(options)
		options.concat([
			EnumOption.new(_INTL("Text Speed"), [_INTL("1"), _INTL("2"), _INTL("3"), _INTL("4"), _INTL("5")],
				proc { $PokemonSystem.textspeed },
				proc { |value|
					$PokemonSystem.textspeed = value
					MessageConfig.pbSetTextSpeed(MessageConfig.pbSettingToTextSpeed(value))
				}
			),
			NumberOption.new(_INTL("Speech Frame"), 1, Settings::SPEECH_WINDOWSKINS.length,
				proc { $PokemonSystem.textskin },
				proc { |value|
					$PokemonSystem.textskin = value
					MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/" + Settings::SPEECH_WINDOWSKINS[value])
				}
			),
			NumberOption.new(_INTL("Menu Frame"), 1, Settings::MENU_WINDOWSKINS.length,
				proc { $PokemonSystem.frame },
				proc { |value|
					$PokemonSystem.frame = value
					MessageConfig.pbSetSystemFrame("Graphics/Windowskins/" + Settings::MENU_WINDOWSKINS[value])
				}
			),
			EnumOption.new(_INTL("Text Entry"), [_INTL("Cursor"), _INTL("Keyboard")],
				proc { $PokemonSystem.textinput },
				proc { |value| $PokemonSystem.textinput = value }
			),
			EnumOption.new(_INTL("Bag Sorting"), [_INTL("Off"), _INTL("Name"), _INTL("Amount")],
				proc { $PokemonSystem.bag_sorting },
				proc { |value|
					$PokemonSystem.bag_sorting = value
					$PokemonBag.sortItems
				}
			),
			EnumOption.new(_INTL("Nicknaming Prompt"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.nicknaming_prompt },
				proc { |value|
					$PokemonSystem.nicknaming_prompt = value
				}
			),
			EnumOption.new(_INTL("Item Desc Popups"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.show_item_descriptions },
				proc { |value|
					$PokemonSystem.show_item_descriptions = value
				}
			),
			EnumOption.new(_INTL("Trait Unlock Popups"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.show_trait_unlocks },
				proc { |value|
					$PokemonSystem.show_trait_unlocks = value
				}
			),
			EnumOption.new(_INTL("Team Snapshots"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.party_snapshots },
				proc { |value|
					$PokemonSystem.party_snapshots = value
				}
			),
		])
	end
end

#===============================================================================
# Battle options scene
#===============================================================================
class PokemonOption_Scene_Battle < PokemonOption_Scene_Base
    def optionsName
        return _INTL("Battle Options")
    end

	def pbAddOnOptions(options)
		options.concat([
			EnumOption.new(_INTL("Battle Effects"), [_INTL("Standard"), _INTL("Fast"), _INTL("Off")],
				proc { $PokemonSystem.battlescene },
				proc { |value| $PokemonSystem.battlescene = value }
			),
			EnumOption.new(_INTL("Battle Transitions"), [_INTL("Standard"), _INTL("Fast")],
				proc { $PokemonSystem.battlescene },
				proc { |value| $PokemonSystem.battle_transitions = value }
			),
			EnumOption.new(_INTL("Damage Numbers"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.damage_numbers },
				proc { |value|
					$PokemonSystem.damage_numbers = value
				}
			),
			EnumOption.new(_INTL("Effectiveness Msgs"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.effectiveness_messages },
				proc { |value|
					$PokemonSystem.effectiveness_messages = value
				}
			),
			EnumOption.new(_INTL("Weather Msgs"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.weather_messages },
				proc { |value|
					$PokemonSystem.weather_messages = value
				}
			),
			EnumOption.new(_INTL("Status Condition Msgs"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.status_effect_messages },
				proc { |value|
					$PokemonSystem.status_effect_messages = value
				}
			),
			EnumOption.new(_INTL("Move Clarifying Msgs"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.move_clarifying_messages },
				proc { |value|
					$PokemonSystem.move_clarifying_messages = value
				}
			),
		])
	end
end

#===============================================================================
# Overworld options scene
#===============================================================================
class PokemonOption_Scene_Overworld < PokemonOption_Scene_Base
    def optionsName
        return _INTL("Overworld Options")
    end

	def pbAddOnOptions(options)
		options.concat([
			EnumOption.new(_INTL("Default Movement"), [_INTL("Walking"), _INTL("Running")],
				proc { $PokemonSystem.runstyle },
				proc { |value| $PokemonSystem.runstyle = value }
			),
			EnumOption.new(_INTL("Autosave"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.autosave },
				proc { |value|
					$PokemonSystem.autosave = value
				}
			),
			EnumOption.new(_INTL("Look"), [_INTL("M"), _INTL("F"), _INTL("A")],
				proc { $PokemonSystem.gendered_look },
				proc { |value|
					pbChangePlayer(value)
				}
			),
			EnumOption.new(_INTL("Pokemon Follow"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.followers },
				proc { |value|
					$PokemonSystem.followers = value
					pbToggleFollowingPokemon($PokemonSystem.followers == 0 ? "on" : "off", false)
				}
			),
		])
	end
end

#===============================================================================
# Advanced Graphics options scene
#===============================================================================
class PokemonOption_Scene_AdvancedGraphics < PokemonOption_Scene_Base
    def optionsName
        return _INTL("Advanced Graphics Options")
    end

	def pbAddOnOptions(options)
		options.concat([
			EnumOption.new(_INTL("Color Shifts"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.color_shifts },
				proc { |value|
					$PokemonSystem.color_shifts = value
				}
			),
			EnumOption.new(_INTL("Particles"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.particle_effects },
				proc { |value|
					$PokemonSystem.particle_effects = value
				}
			),
			EnumOption.new(_INTL("Screenshake"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.screenshake },
				proc { |value|
					$PokemonSystem.screenshake = value
				}
			),
			EnumOption.new(_INTL("World Weather"), [_INTL("On"), _INTL("Off")],
				proc { $PokemonSystem.overworld_weather },
				proc { |value|
					$PokemonSystem.overworld_weather = value
					if value == 0
						applyOutdoorEffects
					else
						$game_screen.resetWeather
					end
				}
			),
		])
	end
end

class PokemonOption_Scene
	def pbStartScene
		@viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
		@viewport.z = 99999
		@sprites = {}
		@sprites["cmdwindow"] = Window_CommandPokemon.new([])
		@sprites["cmdwindow"].visible = false
		@sprites["cmdwindow"].viewport = @viewport
		pbSEPlay("GUI menu open")
	end
	
	def pbShowCommands(commands)
		ret = -1
		cmdwindow = @sprites["cmdwindow"]
		cmdwindow.commands = commands
		cmdwindow.index    = $PokemonTemp.menuLastChoice
		cmdwindow.resizeToFit(commands)
		cmdwindow.x        = Graphics.width-cmdwindow.width
		cmdwindow.y        = 0
		cmdwindow.visible  = true
		loop do
		  cmdwindow.update
		  Graphics.update
		  Input.update
		  pbUpdateSceneMap
		  if Input.trigger?(Input::BACK)
			ret = -1
			break
		  elsif Input.trigger?(Input::USE)
			ret = cmdwindow.index
            $PokemonTemp.menuLastChoice = ret
			break
		  end
		end
		return ret
	end
	
	def pbEndScene
		pbDisposeSpriteHash(@sprites)
		@viewport.dispose
	end

	def pbRefresh; end
end

class PokemonOptionMenu < PokemonPauseMenu
	def pbStartPokemonMenu
		if !$Trainer
			if $DEBUG
			  pbMessage(_INTL("The player trainer was not defined, so the pause menu can't be displayed."))
			  pbMessage(_INTL("Please see the documentation to learn how to set up the trainer player."))
			end
			return
		end
		@scene.pbStartScene
		endscene = true
		cmdAudioOptions  = -1
		cmdUIOoptions = -1
        cmdBattleOptions = -1
        cmdOverworldOptions = -1
        cmdAdvancedGraphicsOptions = -1
        cmdCancel    = -1
		optionsCommands = []
		optionsCommands[cmdAudioOptions = optionsCommands.length] = _INTL("Audio Options")
		optionsCommands[cmdUIOoptions = optionsCommands.length] = _INTL("UI Options")
		optionsCommands[cmdBattleOptions = optionsCommands.length] = _INTL("Battle Options")
		optionsCommands[cmdOverworldOptions = optionsCommands.length] = _INTL("Overworld Options")
        optionsCommands[cmdAdvancedGraphicsOptions = optionsCommands.length] = _INTL("Adv. Graphics Options")
        optionsCommands[cmdCancel = optionsCommands.length] = _INTL("Cancel")
		loop do
			infoCommand = @scene.pbShowCommands(optionsCommands)
            break if infoCommand < 0 || infoCommand == cmdCancel
            optionsScene = [
                PokemonOption_Scene_Audio,
                PokemonOption_Scene_UserInterface,
                PokemonOption_Scene_Battle,
                PokemonOption_Scene_Overworld,
                PokemonOption_Scene_AdvancedGraphics,
            ][infoCommand]
            pbPlayDecisionSE
            pbFadeOutIn {
                scene = optionsScene.new
                screen = PokemonOptionScreen.new(scene)
                screen.pbStartScreen
                @scene.pbRefresh
            }
		end
		@scene.pbEndScene if endscene
	end
end