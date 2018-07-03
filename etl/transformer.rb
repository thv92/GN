require 'json'
require 'fileutils'
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
        HeroTransformer.new.transform
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
            restructureData
            translatePartOne
            translatePartTWo
            # mergePassives
        end

        def restructureData
            heroes = {}
            mats = {}
            imgs = {}
            passives = {}
            passivesIDAsKey = {}
            imgs[@cf::HEROES] = {}
            imgs[@cf::MATS] = {}

            passiveIndex = 1
            @rawData.each do |heroData|
                heroID = heroData[@cf::HERO_ID]
                #PASSIVES section
                passiveRefs = []
                heroData[@cf::PASSIVES].each do |passive|
                    fullName = passive[@cf::FULLNAME]
                    if (!passives.include?(fullName))
                        passive[@cf::HERO_REFS] = [heroID]
                        passives[fullName] = passive
                        #Add in indexing as temp ID
                        passives[@cf::PASSIVE_ID] = "SK%05d" % passiveIndex
                        passivesIDAsKey[passives[@cf::PASSIVE_ID]] = passive.reject{|k| k == cf::PASSIVE_ID}
                        passiveIndex += 1
                    else
                        # This should push it to the other map's array too since reference is same
                        passives[fullName][@cf::HERO_REFS].push(heroID)
                        # passiveID = passives[fullName][@cf::PASSIVE_ID]
                        # passivesIDAsKey[passiveID][@cf:HERO_REFS].push(heroID)
                    end
                    #Push temp indexed ID as reference to passive instead of fullName
                    passiveRefs.push(passives[fullName][@cf::PASSIVE_ID])
                end
                heroData[@cf::PASSIVES] = passiveRefs

                #ULTS section to get MATS
                heroData[@cf::ULTS].each do |ult|
                    matRefs = []
                    ult[@cf::MATS].each do |mat|
                        matID = mat[@cf::MAT_ID]
                        matRefs.push({@cf::MAT_ID => matID, @cf::AMT => mat[@cf::AMT]})
                        if (!mats.include?(matID))
                            mats[matID] = mat.reject{|k| k == @cf::AMT || k== @cf::MAT_ID}
                        end
                    end
                    ult[@cf::MATS] = matRefs
                end
                
                #IMAGES section
                imgHeroes = imgs[@cf::HEROES]
                imgMats = imgs[@cf::MATS]
                heroData[@cf::IMGS].each do |image|
                    if (image.include?(@cf::HERO_ID))
                        if (!imgHeroes.include?(heroID))
                            imgsHeroes[heroID] = []
                        end
                        imgsHeroes[heroID].push(image.reject{|k| k == @cf::HERO_ID || k == @imgf::CAT})
                    else
                        matID = image[@cf::MAT_ID]
                        if (!imgMats.include?(matID))
                            imgMats[matID] = []
                        end
                        found = false
                        #If image same?
                        imgMats[matID].map {|item| found = true if item[url] == image[url]}
                        imgMats[matID].push(image.reject{|k| k == @cf::MAT_ID || k == @imgf::CAT || k == @imgf::NAME}) unless found
                    end
                end
                heroData.delete(@cf::IMGS)
                heroes[heroID] = heroData
            end
            @rawData = {@cf::HEROES => heroes, @cf::PASSIVES => passivesIDAsKey, @cf::MATS => mats, @cf::IMGS => imgs}
        end


        #------------TranslatePartOne--------------
        def translatePartOne
            #Translate Hero
            #Translate MD
            heroesQ = transPt1Heroes(@rawData[@cf::HEROES])
            #Translate Passives
            passivesQ = transPt1Passives(@rawData[@cf::PASSIVES])
            #Translate Mats
            matsQ = transPt1Mats(@rawData[@cf::MATS])

            #WriteToFile
            writeToFilePartitioned(heroesQ, 'ToTranslate_Heroes')
            writeToFilePartitioned(passivesQ, 'ToTranslate_Passives')
            writeToFilePartitioned(matsQ, 'ToTranslate_Mats')

        end

        #Add Heroes' ULT and NAME to translation queue | translate heroMD
        #Heroes: { HERO_ID => "", NAME => "", ULT => { NAME =>  "", DESC => "" } }
        def transPt1Heroes(heroes)
            heroesQ = []
            heroes.each do |heroID, heroData|
                #Add ULT, NAME to translation Queue
                heroesQ.push({
                    @cf::HERO_ID => heroID,
                    @cf::NAME => heroData[@cf::NAME]
                    @cf::ULT => {@cf::NAME => heroData[@cf::ULT][@cf::NAME], @cf::DESC => heroData[@cf::ULT][@cf::DESC]}
                })
                #Translate metadata
                heroData[@cf::MD] = {
                    @cf::ROLE => translateRole(heroData[@cf::MD][@cf::ROLE]),
                    @cf::WT => translateWeaponType(heroData[@cf::MD][@cf::WT]),
                    @cf::SERIES => translateSeries(heroData[@cf::MD][@cf::SERIES])
                }
            end
            heroesQ
        end

        #Passive Skills
        #Passives: {PASSIVE_ID => "", FULLNAME => "", DESC => ""}
        def transPt1Passives(passives)
            passivesQ = []
            passives.each do |passiveID, passive|
                passivesQ.push({
                    @cf::PASSIVE_ID => passiveID
                    @cf::FULLNAME => passive[@cf::FULLNAME],
                    @cf::DESC => passive[@cf::DESC]
                })
            end
            passivesQ
        end
        

        #Evo Orbs
        #Mats: {MAT_ID => "", FULLNAME => ""}
        def transPt1Mats(mats)
            matQ = []
            mats.each do |matID, mat|
                mat[@cf::FULLNAME_JP] = mat[@cf::SIZE] == nil ? mat[@cf::NAME] : "#{mat[@cf::NAME]} (#{mat[@cf::SIZE]})"
                transName = translateEvoOrb(mat[@cf::NAME])
                transSize = translateMatSize(mat[@cf::SIZE])
                if (transName)
                    if (transSize)
                        mat[@cf::FULLNAME] = "#{transName} (#{transSize})"
                        mat[@cf::SIZE] = transSize
                    else
                        mat[@cf::FULLNAME] = transName
                    end
                    mat[@cf::NAME_JP] = mat[@cf::NAME]
                    mat[@cf::NAME] = transName
                else  #Cannot translate, must put into translation Queue
                    matQ.push({
                        @cf::MAT_ID => matID,
                        @cf::FULLNAME => mat[@cf::FULLNAME_JP]
                    })
                end
            end
            matQ
        end
        
        #Write to files with goal of keeping character count under 5000
        #Requires data to be partitioned
        def writeToFilePartitioned(dataToWrite, fileNamePrefix)
            pageNum = 1
            charCount = 0
            #Array of hero dicts
            writeQueue = []
            dataToWrite.each do |data|
                charCountTemp = 0
                data.map do |k, v|
                    charCountTemp += k.length + 2 + v.length + 3
                    #For Ult
                    if (v.is_a?(Hash))
                        v.map do |k2, v2|
                            charCountTemp += k2.length + 2 + v2.length + 3
                        end
                    end
                end
                
                if ((charCount + charCountTemp) <= 4600)
                    writeQueue.push(data)
                    charCount += charCountTemp
                else
                    File.open(File.join('..', 'toTranslateData', fileNamePrefix + "_#{pageNum}.json"), 'w') { |f| f.write(JSON.generate(writeQueue))}
                    charCount = charCountTemp
                    writeQueue = [data]
                    pageNum += 1
                end
            end
        end
        
        
        #------------TranslatePartTwo--------------
        def translatePartTwo
            waitOnManualTranslation
            transPt2Heroes
            transPt2Mats
            transPt2Passives
        end

        def waitOnManualTranslation
            answer = false
            while(!answer)
                print 'Done with manual translation? (Y/N): '
                answer = gets.chomp.strip.upcase == 'Y'
            end
            puts 'Proceeding with Translation Part Two'
        end
        
        #Translate Hero Ults and Name
        def transPt2Heroes
            pageNum = 1
            translatedFile = File.join('..', 'translatedData', "Translated_Heroes_#{pageNum}.json")
            heroes = @rawData[@cf::HEROES]
            while (File.exist?(translatedFile))
                dataFromFile = JSON.parse(File.read(translatedFile))
                dataFromFile.each do |heroTranslation|
                    hero = heroes[heroTranslation[@cf::HERO_ID]]
                    hero[@cf::NAME_JP] = hero[@cf::NAME]
                    hero[@cf::NAME] = heroTranslation[@cf::NAME]
                    
                    heroUlt = hero[@cf::ULT]
                    translatedUlt = heroTranslation[@cf::ULT]
                    heroUlt[@cf::NAME_JP] = heroUlt[@cf::NAME]
                    heroUlt[@cf::NAME] = translatedUlt[@cf::NAME]
                    heroUlt[@cf::DESC] = translatedUlt[@cf::DESC]
                end
                pageNum += 1
                translatedFile = File.join('..', 'translatedData', "Translated_Heroes_#{pageNum}.json")
            end
        end

        #Translate Evo Mats
        def transPt2EvoMats
            pageNum = 1
            translatedFile = File.join('..', 'translatedData', "Translated_Mats_#{pageNum}.json")
            mats = @rawData[@cf::MATS]
            while (File.exist?(translatedFile))
                dataFromFile = JSON.parse(File.read(translatedFile))
                dataFromFile.each do |matTranslation|
                    mat = mats[matTranslation[@cf::MAT_ID]]
                    if (mat[@cf::SIZE])
                        matchData = matTranslation[@cf::FULLNAME].match(/(.+)\((.)\)/)
                        translatedSize = translateMatSize(mat[@cf::SIZE])
                        mat[@cf::FULLNAME] = "#{matchData[1].strip} (#{translatedSize})"
                        mat[@cf::SIZE] = translatedSize
                        mat[@cf::NAME_JP] = mat[@cf::NAME]
                        mat[@cf::NAME] = matchData[1]
                    else
                        mat[@cf::FULLNAME] = matTranslation[@cf::FULLNAME]
                        mat[@cf::NAME_JP] = mat[@cf::NAME]
                        mat[@cf::NAME] = matTranslation[@cf::FULLNAME]
                    end
                end
                pageNum += 1
                translatedFile = File.join('..', 'translatedData', "Translated_Mats_#{pageNum}.json")
            end
        end

        #Translate Passives
        def transPt2Passives
            pageNum = 1
            translatedFile = File.join('..', 'translatedData', "Translated_Passives_#{pageNum}.json")
            passives = @rawData[@cf::PASSIVES]
            while (File.exist?(translatedFile))
                dataFromFile = JSON.parse(File.read(translatedFile))
                dataFromFile.each do |passiveTranslation|
                    passive = passives[passiveTranslation[@cf::PASSIVE_ID]]
                    if (passive[@cf::TIER])
                        matchData = passiveTranslation[@cf::FULLNAME].match(/(.{2,})(#{@cf::BUFF_SYMBOL}|#{@cf::DOT_SYMBOL})(.)/)
                        translatedTier = translateSkillTier(passive[@cf::TIER])
                        translatedName = matchData[1].strip
                        symbol = passive[@cf::SYMBOL] == @cf::DOT_SYMBOL ? ' ' : @cf::BUFF_SYMBOL + ' '
                        
                        passive[@cf::FULLNAME_JP] = passive[@cf::FULLNAME]
                        passive[@cf::FULLNAME] = "#{translatedName}#{symbol}(#{translatedTier})"
                        passive[@cf::NAME_JP] = passive[@cf::NAME]
                        passive[@cf::NAME] = transName 
                        passive[@cf::DESC] = passiveTranslation[@cf::DESC]
                    else
                        passive[@cf::FULLNAME_JP] = passive[@cf::FULLNAME]
                        passive[@cf::FULLNAME] = passiveTranslation[@cf::FULLNAME]
                        passive[@cf::NAME_JP] = passiveTranslation[@cf::FULLNAME]
                        passive[@cf::NAME] = passiveTranslation[@cf::FULLNAME]
                        passive[@cf::DESC] = passiveTranslation[@cf::DESC]
                    end
                end
                pageNum += 1
                translatedFile = File.join('..', 'translatedData', "Translated_Passives_#{pageNum}.json")
            end
        end

        #------------Translation Methods--------------
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
                puts "HeroTransformerError: Could not find Skill Tier #{t}"
                nil
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
                puts "HeroTransformerError: Could not find MatSize #{size}"
                nil
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
                raise "HeroTransformerError: Could not find correct role: #{role}"
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
                raise "HeroTransformerError: Could not find correct Weapon Type #{wt}"
            end
        end

        def translateSeries(s)
            case s
            when @cfp::S_REPAGE
                'Re-Page'
            when @cfp::S_GN
                'Grimm Notes'
            else
                raise "HeroTransformerError: Could not find correct Series #{s}"
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