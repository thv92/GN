require 'json'
require './extractor'
require '../constants/common_fields'
require '../constants/common_fields_jp'
require '../constants/image_fields'
require '../constants/materials'
require '../constants/materials_jp'
require '../constants/stat_fields'
require '../constants/stat_fields_jp'

module Transformer
    def self.transformHeroes



    end

    class HeroTransformer
        def initialize
            @cf = CommonFields
            @cfp = CommonFieldsJP
            @imgf = ImageFields
            @mat = Materials
            @matjp = MaterialsJP
            @sf = StatFields
            @sfjp = StatFieldsJP
            @rawData = File.open(File.join('..', 'rawData', 'rawDataHeroes.json')
            createDir
        end

        def initialize(rawData)
            initialize()
            @rawData = rawData
        end


        def transform



        end

        def translatePartOne
            translationQueue = []
            totalCount = 0
            translationFilePage = 1
            toTranslateFileName = "toTranslate_#{translationFilePage}.json"
            @rawData.each do |heroData|
                toAddToCount = 14 + (@cf::MATS).length + (@cf::PASSIVES).length + (@cf::ULT).length
                #Setup block to translate
                toTranslate = {}
                toTranslate[@cf::MATS] = {}
                toTranslate[@cf::PASSIVES] = []
                toTranslate[@cf::ULT] = {}

                transPt1MD(heroData, toTranslate)
                transPt1Images(heroData, toTranslate)
                toAddToCount += transPt1Name(heroData, toTranslate)
                             + transPtEvoMats(heroData, toTranslate)
                             + transPt1Passives(heroData, toTranslate)
                             + transPt1Ult(heroData, toTranslate)
                toTranslate[@cf::HERO_ID] = heroData[@cf::HERO_ID]
                toAddToCount += (@cf::HERO_ID).length + heroData[@cf::HERO_ID].length + 4

                #Write to File
                if ((totalCount + toAddToCount) <= 4800)
                    File.open(File.join('..', 'toTranslateData', toTranslateFileName), "w") do |f|
                        f.write(JSON.generate(toTranslate))
                    end
                    totalCount = toAddToCount
                    translationFilePage += 1
                    toTranslateFileName = "toTranslate_#{translationFilePage}.json"
                    translationQueue = [toTranslate]
                else
                    totalCount += toAddToCount
                    translationQueue.push(toTranslate)
                end
            end
        end

        def translatePartTwo
            answer = false
            while(!answer)
                print 'Done with manual translation? (Y/N): '
                answer = gets.chomp.strip.upcase == 'Y'
            end
            puts 'Proceeding with Translation Part Two'

            # if(Dir.exists? '../translatedData')
            #     raise "TranslationPartTwo Error: Could not find dir translatedData"
            # end

            # translatedData = []
            # dirName = "../translationData"
            # Dir.entries(dirName).each do |fileName|
            #     if(fileName == '..' or fileName == '.')
            #         next
            #     end
            #     translatedData.push JSON.parse File.read("#{dirName}/#{fileName}")
            # end

            0.upto(translatedData.length-1) do |index|
                if (index > translatedData.length or index > @rawData.length)
                    break
                end

                #Need hero name
                #Open only files we need to save memory

                rawHero = @rawData[index]
                translatedHero = translatedData[index]

                rawHero[@cf::ULT][@cf::NAME] = translatedHero[@cf::ULT][@cf::NAME]
                rawHero[@cf::ULT][@cf::DESC] = translatedHero[@cf::ULT][@cf::DESC]

                0.upto(rawHero[@cf::PASSIVES].length-1) do |i|
                    rPassive = rawHero[@cf::PASSIVES][i]
                    tPassive = translatedHero[@cf::PASSIVES][i]

                    #If FULLNAME
                    if (tPassive[@cf::FULLNAME])


                    else


                    end

                end


            end

        end

        #------------TranslatePartTwo--------------


        #------------TranslatePartOne--------------

        #Add hero name to translation queue
        def transPt1Name(heroData, toTranslate)
            toTranslate[@cf::NAME] = heroData[@cf::NAME]
            heroData[@cf::NAME_JP] = heroData[@cf::NAME]
            return 4 + heroData[@cf::NAME].length + (@cf::NAME).length
        end

        #Translate Metadata
        def transPt1MD(heroData, toTranslate)
            heroData[@cf::MD] = {
                @cf::ROLE => translateRole(heroData[@cf::MD][@cf::ROLE]),
                @cf::WT => translateWeaponType(heroData[@cf::MD][@cf::WT]),
                @cf::SERIES => translateSeries(heroData[@cf::MD][@cf::SERIES])
            }
        end

        #Translate Evo Mats
        def transPt1EvoMats(heroData, toTranslate)
            toAddToCount = 0
            heroData[@cf::EVO].each do |evo|
                evo[@cf::MATS].each do |mat|
                    translatedOrb = translateEvoOrb(mat[@cf::NAME])
                    if (translatedOrb)
                        mat[@cf::FULLNAME_JP] = "#{mat[@cf::NAME]} (#{mat[@cf::SIZE]})"
                        mat[@cf::NAME] = translateEvoOrb(mat[@cf::NAME])
                        mat[@cf::SIZE] = translateMatSize(mat[@cf::SIZE])
                        mat[@cf::FULLNAME] = "#{mat[@cf::NAME]} (#{mat[@cf::SIZE]})"
                    elsif (toTranslate[@cf::MATS][@cf::MAT_ID] == nil)
                        toTranslate[@cf::MATS][@cf::MAT_ID] = mat[@cf::NAME]
                        if (mat[@cf::SIZE])
                            mat[@cf::SIZE] = translateMatSize(mat[@cf::SIZE])
                        end
                        toAddToCount += mat[@cf::MAT_ID].length + mat[@cf::NAME].length + 4
                    end
                end
            end
            toAddToCount
        end

        #Translate Images
        def transPt1Images(heroData, toTranslate)
            #images (Should still be evo mats)
            heroData[@cf::IMGS].each do |img|
                if (img[@cf::MAT_ID] && toTranslate[@cf::MATS][img[@cf::MAT_ID]] == nil)
                    if (img[@cf::NAME].include? "(")
                        matchMatData = img[@cf::NAME].match(/(.+)\((.)\)/)
                        img[@cf::NAME] = "#{translateEvoOrb(matchMatData[1])} (#{translateMatSize(matchMatData[2])})"
                    else
                        img[@cf::NAME] = translateEvoOrb(img[@cf::NAME])
                    end
                end
            end #End images
        end

        #Translate Passives
        def transPt1Passives(heroData, toTranslate)
            toAddToCount = 0
            #Add Passives to Translation Queue
            heroData[@cf::PASSIVES].each do |passive|
                if (passive[@cf::NAME])
                    toTranslate[@cf::PASSIVES].push({
                        @cf::NAME => passive[@cf::NAME],
                        @cf::DESC => passive[@cf::DESC]
                    })
                    toAddToCount += (@cf::NAME).length + (@cf::DESC).length + 
                                    passive[@cf::NAME].length + passive[@cf::DESC].length + 8 + 10

                    passive[@cf::FULLNAME_JP] = passive[@cf::FULLNAME]
                    passive[@cf::FULLNAME] = nil
                    
                    if (passive[@cf::TIER])
                        passive[@cf::TIER] = translateSkillTier(passive[@cf::TIER])
                    end
                else #Only fullname is available
                    toTranslate[@cf::PASSIVES].push({
                        @cf::FULLNAME => passive[@cf::FULLNAME],
                        @cf::DESC => passive[@cf::DESC]
                    })
                    toAddToCount += 8 + (@cf::FULLNAME).length + (@cf::DESC).length + passive[@cf::FULLNAME].length
                                  + passive[@cf::DESC].length + 10
                    passive[@cf::FULLNAME_JP] = passive[@cf::FULLNAME] 
                end
            end
            toAddToCount
        end

        #Add Ultimate to Translation Queue
        def transPt1Ult(heroData, toTranslate)
            toTranslate[@cf::ULT] = {
                @cf::NAME => heroData[@cf::ULT][@cf::NAME],
                @cf::DESC => heroData[@cf::ULT][@cf::DESC]
            }
            return (@cf::NAME).length + (@cf::DESC).length + heroData[@cf::ULT][@cf::NAME].length 
                + heroData[@cf::ULT][@cf::DESC].lenght + 8 + 10
        end

        #------------Skills--------------
        def translateSkillTier(t)
            case t
            when @sfjp::T_I
                @sf::T_I
            when @sfjp::T_II
                @sf::T_II
            when @sfjp::T_III
                @sf::T_III
            when @sfjp::T_IV
                @sf::T_IV
            when @sfjp::T_V
                @sf::T_V
            else
                raise 'HeroTransformerError: Could not find Skill Tier'
            end
        end

        #------------Evo Mats------------
        def translateMatSize(size)
            case size
            when @matjp::XS
                @mat::XS
            when @matjp::S
                @mat::S
            when @matjp::M
                @mat::M
            when @matjp::L
                @mat::L
            when @mat::XL
                @mat::XL
            else
                raise 'HeroTransformerError: Could not find MatSize'
            end
        end
    
        def translateEvoOrb(orb)
            case size
            when @matjp::ORB_PATIENCE
                @mat::ORB_PATIENCE
            when @matjp::ORB_JUSTICE
                @mat::ORB_JUSTICE
            when @matjp::ORB_PRUDENCE
                @mat::ORB_PRUDENCE
            when @matjp::ORB_HOPE
                @mat::ORB_HOPE
            when @matjp::ORB_LOVE
                @mat::ORB_LOVE
            when @matjp::ORB_TEMPERANCE
                @mat::ORB_TEMPERANCE
            when @matjp::ORB_SINCERITY
                @mat::ORB_SINCERITY
            when @matjp::ORB_POEM
                @mat::ORB_POEM
            when @matjp::FLAME_OF_EVOLUTION
                @mat::FLAME_OF_EVOLUTION
            when @matjp::SEED_OF_EVOLUTION
                @mat::SEED_OF_EVOLUTION
            else
                puts "HeroTransformerError: Could not find correct Evo Orb #{orb}"
                nil
            end

        end

        #------------Metadata------------
        def translateRole(role)
            case role
            when @cfp::R_ATTACKER
                'Attacker'
            when @cfp::R_HEALER
                'Healer'
            when @cfp::R_DEFENDER
                'Defender'
            when @cfp::R_SHOOTER
                'Shooter'
            else
                raise 'HeroTransformerError: Could not find correct role'
            end
        end

        def translateWeaponType(wt)
            case wt
            when @cfp::WT_1_HAND_SWORD
                '1 Hand Sword'
            when @cfp::WT_HAMMER
                'Hammer'
            when @cfp::WT_1_HAND_STAFF
                '1 Hand Staff'
            when @cfp::WT_2_HAND_STAFF
                '2 Hand Staff'
            when @cfp::WT_GREAT_SWORD
                'Great Sword'
            when @cfp::WT_SPEAR
                'Spear'
            when @cfp::WT_GRIMOIRE
                'Grimoire'
            when @cfp::WT_BOW
                'Bow'
            when @cfp::WT_KNUCKLE
                'Knuckle'
            when @cfp::WT_CANNON
                'Cannon'
            else
                raise 'HeroTransformerError: Could not find correct Weapon Type'
            end
        end

        def translateSeries(s)
            case s
            when @cfp::S_REPAGE
                'Re-Page'
            when @cfp::S_GN
                'Grimm Notes'
            else
                raise 'HeroTransformerError: Could not find correct Series'
            end
        end

        #---------Utility--------
        def createDir
            if (!Dir.exists?(File.join('..', 'toTranslateData')))
                Dir.mkdir(File.join('..', 'toTranslateData'))
            end

            if(!Dir.exists?(File.join('..', 'translatedData')))
                Dir.mkdir(File.join('..', 'translatedData'))
            end

            if(!Dir.exists?(File.join('..', 'finalizedData')))
                Dir.mkdir(File.join('..', 'finalizedData'))
            end
        end
    end #End class
end #End module