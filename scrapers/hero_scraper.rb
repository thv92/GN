require 'nokogiri'
require 'open-uri'
require 'json'
require '../constants/common_fields'
require '../constants/image_fields'
require '../constants/attributes'
require '../constants/stat_fields'
require '../constants/common_fields_jp'

module HeroScraper
    def self.scrape(linkToHero = nil, pathToFile = nil)
        Scraper.new(linkToHero, pathToFile).scrapeHero
    end

    class Scraper
        def initialize(linkToHero = nil, pathToFile = nil)
            @cf = CommonFields
            @cfp = CommonFieldsJP
            @imgf = ImageFields
            @att = Attributes
            @sf = StatFields

            if (pathToFile)
                @file = File.open(pathToFile)
                @doc = Nokogiri::HTML(@file)
            elsif (linkToHero)
                @doc = Nokogiri::HTML(open(linkToHero))
            else
                raise 'Invalid Params. Both are null'
            end
        end

        #Main method to scrape
        def scrapeHero
            rawData = {}
            images = []
            @heroID = @doc.xpath("//div[@class='hero-bnr']/img/@src").text.strip.match(/[A-Z]+\d{5,}/)[0]

            evoData = scrapeEvo
            rawData[@cf::NAME] = @doc.xpath("//div[@class=\'page-title\']").text.strip
            rawData[@cf::HERO_ID] = @heroID
            rawData[@cf::MD] = scrapeMetadata
            rawData[@cf::STATS] = scrapeStats
            rawData[@cf::ULT] = scrapeUltimate
            rawData[@cf::ATTR] = scrapeAttributes
            rawData[@cf::PASSIVES] = scrapePassives
            rawData[@cf::EVOS] = evoData[0]
            rawData[@cf::IMGS] = [scrapeBannerImageURL, *evoData[1]]
            
            if(@file)
                @file.close
            end
            rawData
        end
        
        private
        #Scrape banner image URL
        def scrapeBannerImageURL
            #Banner Image URL
            {
                @imgf::HERO_ID => @heroID,
                @imgf::TYPE => "banner",
                @imgf::NAME => "banner",
                @imgf::URL => @doc.xpath("//div[@class='hero-bnr']/img/@src").text.strip
            }
        end

        #Metadata Table
        def scrapeMetadata
            metadataDict = {}
            metadataTable = @doc.xpath("//table[@class='flex']")
            metadataTable.xpath('./tbody/tr').each do |tr| 
                header =  tr.xpath('./th').text.strip
                data = tr.xpath('./td').text.strip
                if(header === @cfp::ROLE)
                    metadataDict[@cf::ROLE] = data
                elsif (header === @cfp::WT)
                    metadataDict[@cf::WT] = data
                elsif (header === @cfp::SERIES)
                    metadataDict[@cf::SERIES] = data
                end
            end
            metadataDict
        end

        # Stats Table
        def scrapeStats
            statsDict = {}
            statTable = @doc.xpath("//div[@class='tab-group'][1]")
            #Prepare Evo Nums
            index = 1
            maxStatSection = 1;
            maxEvoStage = 1;
            @doc.xpath("//div[@class='tab-group'][1]/ul[@class='tabs']//a").each do |a|
                evoStageNum = a.text.match(/\d+/)[0].to_i
                stat = statTable.xpath("./div/div[contains(@class, 'tabpanel')][#{index}]")
                
                # puts evoStageNum
                trIndex = 2
                statTR = stat.xpath('./table/tbody/tr')

                #level hp attack def
                stats = []
                1.upto(statTR.length - 1) do |i|
                    tr = statTR[i]
                    level = tr.xpath('./td[1]').text.strip
                    hp = tr.xpath('./td[2]').text.strip
                    atk = tr.xpath('./td[3]').text.strip
                    defense = tr.xpath('./td[4]').text.strip
                    isTrans = level.include?(@cfp::TRANS_SYMBOL)
                    #Removed TRANS_SYMBOL
                    level = level.match(/\d+/)[0]
                    # puts "Level: #{level} HP: #{hp} Attack: #{atk} Defense: #{defense} isTranscendance: #{isTrans}"
                    stats.push({
                        @sf::LEVEL => level.to_i,
                        @sf::HP => hp.to_i,
                        @sf::ATK => atk.to_i,
                        @sf::DEF => defense.to_i,
                        @sf::IS_TRANS => isTrans
                    })
                end
                #add into statsDict
                statsDict[evoStageNum] = stats
                maxEvoStage = evoStageNum
                maxStatSection = statTR.length-1
                index+=1
            end
            {
                @cf::SUMMARY => statsDict,
                @cf::MAX => statsDict[maxEvoStage][maxStatSection-1]
            }
        end

        # Ultimate Table
        def scrapeUltimate
            ultDict = {}
            @doc.xpath("//h2[contains(text(), '#{@cfp::ULT}')]/following-sibling::table[1]/tbody/tr"). each do |row|
                header = row.xpath('./th').text.strip.gsub(/\n/, "")
                data = row.xpath('./td').text.strip.gsub(/\n/, "")
                if (header === @cfp::ULT_NAME)
                    ultDict[@cf::NAME] = data
                elsif (header === @cfp::ULT_COST)
                    ultDict[@cf::COST] = data.to_i
                elsif (header === @cfp::ULT_DESC)
                    ultDict[@cf::DESC] = data.match(/\[#{@cfp::ULT_DESC}\]/).post_match
                end
            end
            ultDict
        end

        # Attribute Table
        def scrapeAttributes
            attributeDict = {}
            attributeDict[@cf::DMG] = {}
            attributeDict[@cf::RESIST] = {}
            index = 1
            @doc.xpath("//h2[contains(text(), '#{@cfp::ULT}')]/following-sibling::table[2]/tbody/tr[position() > 1]").each do |row|
                damageValue = row.xpath('./td[2]').text.strip.to_i
                resistValue = row.xpath('./td[3]').text.strip.to_i

                if (index == 1) #fire
                    attributeDict[@cf::DMG][@att::FIRE] = damageValue
                    attributeDict[@cf::RESIST][@att::FIRE] = resistValue
                elsif (index == 2) #ice
                    attributeDict[@cf::DMG][@att::ICE] = damageValue
                    attributeDict[@cf::RESIST][@att::ICE] = resistValue
                elsif (index == 3) #thunder
                    attributeDict[@cf::DMG][@att::THR] = damageValue
                    attributeDict[@cf::RESIST][@att::THR] = resistValue    
                elsif (index == 4) #light
                    attributeDict[@cf::DMG][@att::LIGHT] = damageValue
                    attributeDict[@cf::RESIST][@att::LIGHT] = resistValue
                elsif (index == 5) #dark
                    attributeDict[@cf::DMG][@att::DARK] = damageValue
                    attributeDict[@cf::RESIST][@att::DARK] = resistValue
                end
                index += 1
            end
            attributeDict
        end

        # Passives Table
        def scrapePassives
            passives = []
            @doc.xpath("//div[@class='auto-width']/table").each do |table|
                level = table.xpath('./caption').text.strip.match(/\d+/)[0].to_i
                passiveFullName = table.xpath('./tbody/tr/th').text.strip.gsub(/\n/, "")
                passiveDesc = table.xpath('./tbody/tr/td').text.strip.gsub(/\n/, "")
                matchData = passiveFullName.match(/(.{2,})(#{@cf::BUFF_SYMBOL}|#{@cf::DOT_SYMBOL})(?:(.)(?!.))/)
                symbol = nil
                tier = nil
                if (matchData != nil)
                    passiveName = matchData[1].strip
                    symbol = matchData[2].strip
                    tier = matchData[3].strip
                end
                # puts "Caption: #{caption} Passive Name: #{passiveName} Passive Desc: #{passiveDesc}"
                passives.push({
                    @cf::FULLNAME => passiveFullName,
                    @cf::NAME => passiveName,
                    @sf::LEVEL => level,
                    @cf::DESC => passiveDesc,
                    @cf::TIER => tier,
                    @cf::SYMBOL => symbol
                })
            end
            # puts passives
            passives
        end

        # Evo Table
        def scrapeEvo
            evolutions = []
            images = []
            index = 1
            evoSection = @doc.xpath("//div[@class='tab-group'][2]")
            evoSection.xpath("./ul/li").each do |li|
                evoDict = {}
                evoMats = []
                matchData =  li.text.strip.match(/.(\d)..(\d)/)
                base = matchData[1].to_i
                to = matchData[2].to_i
                
                evoDict[@cf::BASE] = base
                evoDict[@cf::TO] = to
                
                #process sprite images
                tabPanel = evoSection.xpath("./div[@class='tab-content']/div[contains(@class, 'tabpanel')][#{index}]")
                tabPanelCharaImageBase = tabPanel.xpath("./div[@class='panel-inner'][1]/ul[@class='evol']/li[1]/img/@src").text
                tabPanelCharaImageTo   = tabPanel.xpath("./div[@class='panel-inner'][1]/ul[@class='evol']/li[3]/img/@src").text
                
                images.push({
                    @imgf::HERO_ID => @heroID,
                    @imgf::CAT => "hero",
                    @imgf::TYPE => "sprite",
                    @cf::NAME => base.to_s,
                    @imgf::URL => tabPanelCharaImageBase
                }) unless index == 2  #ignore repeat on second evo

                images.push({
                    @imgf::HERO_ID => @heroID,
                    @imgf::CAT => "hero",
                    @imgf::TYPE => "sprite",
                    @cf::NAME => to.to_s,
                    @imgf::URL => tabPanelCharaImageTo
                })

                #process evo mats
                tabPanelInner = tabPanel.xpath("./div[@class='panel-inner'][2]/ul[@class='line-list']")
                tabPanelInner.xpath("./li").each do |evoMatItem|
                    #Mat Image Processing
                    evoMatImageURL = evoMatItem.xpath("./img/@src").text.strip
                    #Mat Data Processing
                    evoMatText = evoMatItem.xpath("./p").text.gsub(/\n|\s/, "")
                    if(evoMatText.include? "(")
                        evoMatMatchData = evoMatText.match(/(.+)\((.)\)?.(\d+)/)
                        evoMatName = evoMatMatchData[1]
                        evoMatSize = evoMatMatchData[2]
                        evoMatAmt = evoMatMatchData[3].to_i
                    else
                        evoMatMatchData = evoMatText.match(/(.+).(\d+)/)
                        evoMatName = evoMatMatchData[1]
                        evoMatSize = nil
                        evoMatAmt = evoMatMatchData[2].to_i
                    end

                    evoMatID = evoMatImageURL.match(/[A-Z]+\d{5,}/)[0]
                    images.push({
                        @imgf::MAT_ID => evoMatID,
                        @imgf::NAME => evoMatSize == nil ? evoMatName : "#{evoMatName} (#{evoMatSize})",
                        @imgf::CAT => "material",
                        @imgf::TYPE => "evolution",
                        @imgf::DESC => "no background",
                        @imgf::URL => evoMatImageURL,
                        @imgf::SIZE => "medium"
                    }) unless images.any? { |image| image[@imgf::MAT_ID] === evoMatID}
                    evoMats.push({
                        @cf::MAT_ID => evoMatID,
                        @cf::NAME => evoMatName,
                        @cf::SIZE => evoMatSize,
                        @cf::AMT => evoMatAmt
                    })
                    # puts "evoMatMatchData: #{evoMatName} | #{evoMatSize} | #{evoMatAmt}"
                end
                evoDict[@cf::MATS] = evoMats
                evolutions.push(evoDict)
                index += 1
            end
            [evolutions, images]
        end
    end
end