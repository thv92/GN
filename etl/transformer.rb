require 'json'
require './extractor'
require '../constants/common_fields'
require '../constants/common_fields_jp'
require '../constants/image_fields'
require '../constants/materials'
require '../constants/materials_jp'

# jsonFile.close
# file = File.open('test.json', 'a+')
# file.write("[\n")


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
        end


        def translate
            Extractor.extractHeroes do |heroData, index|
                #Metadata
                    heroData[@cf::MD] = {
                        @cf::ROLE => translateRole(heroData[@cf::MD][@cf::ROLE]),
                        @cf::WT => translateWeaponType(heroData[@cf::MD][@cf::WT]),
                        @cf::SERIES => translateSeries(heroData[@cf::MD][@cf::SERIES])
                    }
                #evoMats
                    heroData[@cf::EVO].each do |evo|
                        evo[@cf::MATS].each do |mat|
                            mat[@cf::NAME_JP] = mat[@cf::NAME]
                            mat[@cf::NAME] = translateEvoOrb(mat[@cf::NAME_JP])
                            mat[@cf::SIZE] = translateMatSize(mat[@cf::SIZE])
                        end
                    end
                #images
                    heroData[@cf::IMGS].each do |img|
                        

                    end


                puts JSON.pretty_generate heroData
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
            else
                raise 'HeroTransformerError: Could not find correct Evo Orb'
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
    end #End class
end #End module