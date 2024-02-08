module MoveInfoDisplay
    # Text colours of PP of selected move
    PP_COLORS = [
       Color.new(248,72,72),Color.new(136,48,48),    # Red, zero PP
       Color.new(248,136,32),Color.new(144,72,24),   # Orange, 1/4 of total PP or less
       Color.new(248,192,0),Color.new(144,104,0),    # Yellow, 1/2 of total PP or less
       Color.new(80, 80, 88),Color.new(160, 160, 168)       # Black, more than 1/2 of total PP
    ]

    def writeMoveInfoToInfoOverlay3x3(overlay,move)
        moveData = GameData::Move.get(move.id)

        base = Color.new(64, 64, 64)
        shadow = Color.new(176, 176, 176)

        overlay.clear
              
        # Write power and accuracy values for selected move
        # Write various bits of text
        moveInfoColumn1LabelX = 8
        moveInfoColumn2LabelX = moveInfoColumn1LabelX + 184
        moveInfoColumn3LabelX = moveInfoColumn2LabelX + 184 - 40
      
        textpos = []
      
        # Column 1
        textpos.concat(
          [
            [_INTL("TYPE"),moveInfoColumn1LabelX,0,0,base,shadow],
            [_INTL("CATEGORY"),moveInfoColumn1LabelX,32,0,base,shadow],
            [_INTL("POWER"),moveInfoColumn1LabelX,64,0,base,shadow],
          ]
        )
      
        # Column 2
        textpos.concat(
          [
            [_INTL("ACC"),moveInfoColumn2LabelX,0,0,base,shadow],
            [_INTL("PP"),moveInfoColumn2LabelX,32,0,base,shadow],
            [_INTL("TAG"),moveInfoColumn2LabelX,64,0,base,shadow],
          ]
        )
      
        # Column 1
        textpos.concat(
          [
            [_INTL("PRIORITY"),moveInfoColumn3LabelX,0,0,base,shadow],
            [_INTL("TARGET"),moveInfoColumn3LabelX,32,0,base,shadow],
          ]
        )
        
        base = Color.new(64,64,64)
        faded_base = Color.new(110,110,110)
        shadow = Color.new(176,176,176)
        moveInfoColumn1ValueX = moveInfoColumn1LabelX + 134
        moveInfoColumn2ValueX = moveInfoColumn2LabelX + 134 - 40
        moveInfoColumn3ValueX = moveInfoColumn3LabelX + 134
      
        # Column 1
        # Draw selected move's damage category icon and type icon
        imagepos = [
          ["Graphics/Pictures/types", moveInfoColumn1ValueX - 28, 8, 0, GameData::Type.get(moveData.type).id_number * 28, 64, 28],
          ["Graphics/Pictures/category", moveInfoColumn1ValueX - 28, 32 + 8, 0, moveData.category * 28, 64, 28],
        ]
        pbDrawImagePositions(overlay, imagepos)
        # Base damage
        case moveData.base_damage
        when 0 then textpos.push(["---", moveInfoColumn1ValueX, 64, 2, faded_base, shadow])   # Status move
        when 1 then textpos.push(["???", moveInfoColumn1ValueX, 64, 2, base, shadow])   # Variable power move
        else        textpos.push([moveData.base_damage.to_s, moveInfoColumn1ValueX, 64, 2, base, shadow])
        end
      
        # Column 2
        # Accuracy
        if moveData.accuracy == 0
          textpos.push(["---", moveInfoColumn2ValueX, 0, 2, faded_base, shadow])
        else
          textpos.push(["#{moveData.accuracy}%", moveInfoColumn2ValueX, 0, 2, base, shadow])
        end
        # PP
        if moveData.total_pp > 0
          ppFraction = [(4.0*move.pp/move.total_pp).ceil,3].min
          textpos.push([_INTL("{1}/{2}",move.pp,move.total_pp),moveInfoColumn2ValueX, 32, 2, PP_COLORS[ppFraction*2], PP_COLORS[ppFraction*2+1]])
        else
          textpos.push(["---", moveInfoColumn2ValueX, 32, 2, faded_base, shadow])
        end
        # Tag
        moveCategoryLabel = moveData.tagLabel || "---"
        textpos.push([moveCategoryLabel, moveInfoColumn2ValueX, 64, 2, moveData.tagLabel ? base : faded_base, shadow])
      
        # Column 3
        # Priority
        textpos.push([moveData.priorityLabel,moveInfoColumn3ValueX + 6, 0, 2, move.priority != 0 ? base : faded_base, shadow])
        # Targeting
        targetingData = GameData::Target.get(moveData.target)
        textpos.push([targetingData.get_targeting_label,moveInfoColumn3LabelX + 4, 64, 0, base, shadow])
      
        # Targeting graphic
        targetingGraphicTextPos = []
        targetingGraphicColumn1X = moveInfoColumn3LabelX + 84
        targetingGraphicColumn2X = targetingGraphicColumn1X + 46
        targetingGraphicRow1Y = 38
        targetingGraphicRow2Y = targetingGraphicRow1Y + 26
      
        targetableColor = Color.new(120,5,5)
        untargetableColor = faded_base
      
        # Foes
        foeColor = targetingData.show_foe_targeting? ? targetableColor : untargetableColor
        targetingGraphicTextPos.push(["Foe",targetingGraphicColumn1X, targetingGraphicRow1Y, 0, foeColor, shadow])
        targetingGraphicTextPos.push(["Foe",targetingGraphicColumn2X, targetingGraphicRow1Y, 0, foeColor, shadow])
      
        # User
        userColor = targetingData.show_user_targeting? ? targetableColor : untargetableColor
        targetingGraphicTextPos.push(["User",targetingGraphicColumn1X, targetingGraphicRow2Y, 0, userColor, shadow])
        
        # Ally
        allyColor = targetingData.show_ally_targeting? ? targetableColor : untargetableColor
        targetingGraphicTextPos.push(["Ally",targetingGraphicColumn2X, targetingGraphicRow2Y, 0, allyColor, shadow])
        
        # Draw the targeting graphic text
        pbSetNarrowFont(overlay)
        overlay.font.size = 20
        pbDrawTextPositions(overlay, targetingGraphicTextPos)
        pbSetSystemFont(overlay)
      
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
      
        # Draw selected move's description
        drawTextEx(overlay,8,96 + 12,500,4,moveData.description,base,shadow)
      end
end