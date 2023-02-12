module GameData
    class Ability
        SUN_ABILITIES = %i[DROUGHT INNERLIGHT CHLOROPHYLL SOLARPOWER LEAFGUARD FLOWERGIFT MIDNIGHTSUN
                        HARVEST SUNCHASER HEATSAVOR BLINDINGLIGHT SOLARCELL SUSTAINABLE FINESUGAR REFRESHMENTS
                        HEATVEIL OXYGENATION
        ]

        RAIN_ABILITIES = %i[DRIZZLE STORMBRINGER SWIFTSWIM RAINDISH HYDRATION TIDALFORCE STORMFRONT
                          DREARYCLOUDS DRYSKIN RAINPRISM STRIKETWICE AQUAPROPULSION OVERWHELM ARCCONDUCTOR
        ]

        SAND_ABILITIES = %i[SANDSTREAM SANDBURST SANDRUSH SANDSHROUD DESERTSPIRIT SANDDRILLING SANDDEMON
                          IRONSTORM SANDSTRENGTH SANDPOWER CRAGTERROR DESERTSCAVENGER
        ]

        HAIL_ABILITIES = %i[SNOWWARNING FROSTSCATTER ICEBODY SNOWSHROUD BLIZZBOXER SLUSHRUSH ICEFACE
                          BITTERCOLD ECTOPARTICLES ICEQUEEN ETERNALWINTER TAIGATRECKER ICEMIRROR WINTERINSULATION
                          POLARHUNTER WINTERWISDOM
        ]

        ECLIPSE_ABILITIES = %i[HARBINGER SUNEATER APPREHENSIVE TOTALGRASP EXTREMOPHILE WORLDQUAKE RESONANCE
                            DISTRESSING SHAKYCODE MYTHICSCALES SHATTERING STARSALIGN WARPINGEFFECT TOLLDANGER
                            DRAMATICLIGHTING CALAMITY ANARCHIC MENDINGTONES PEARLSEEKER
        ]

        MOONGLOW_ABILITIES = %i[MOONGAZE LUNARLOYALTY LUNATIC MYSTICTAP ASTRALBODY NIGHTLIGHT NIGHTLIFE
                              MALICIOUSGLOW MOONMIRROR NIGHTVISION MOONLIGHTER LUNARCLEANSING NIGHTSTALKER WEREWOLF
                              FULLMOONBLADE MOONBUBBLE MIDNIGHTTOIL MOONBASKING NIGHTOWL
        ]

        attr_reader :signature_of

        # The highest evolution of a line
        def signature_of=(val)
          @signature_of = val
        end

        def is_signature?()
          return !@signature_of.nil?
        end

        def is_primeval?
          return @id.to_s[/PRIMEVAL/]
        end
    end
  end