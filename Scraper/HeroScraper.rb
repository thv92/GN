require 'nokogiri'
require 'json'
require './Constants/GeneralFields'
require './Constants/ImageFields'
require './Constants/Attributes'
require './Constants/StatFields'
require './Constants/GeneralFieldsJP'


gf = GeneralFields
gfp = GeneralFieldsJP
imgf = ImageFields
att = Attributes
sf = StatFields

rawData = {}
images = []
file = File.open('./test.html')
doc = Nokogiri::HTML(file)

#Character Name
rawData[gf::NAME] = doc.xpath("//div[@class=\'page-title\']").text.strip

#Banner Image URL
bannerImageDict = {}
bannerImageDict[imgf::CAT] = "Banner"
bannerImageDict[gf::NAME] = "Banner"
bannerImageDict[imgf::URL] = doc.xpath("//div[@class='hero-bnr']/img/@src").text.strip
rawData[gf::HEROID] = bannerImageDict[imgf::URL].match(/[A-Z]\d{5,}/)[0]
images.push(bannerImageDict)

#Metadata Table
metadataDict = {}
metadataTable = doc.xpath("//table[@class='flex']")
metadataTable.xpath('./tbody/tr').each do |tr| 
    header =  tr.xpath('./th').text.strip
    data = tr.xpath('./td').text.strip
    if(header === gfp::ROLE)
        metadataDict[gf::ROLE] = data
    elsif (header === gfp::WT)
        metadataDict[gf::WT] = data
    elsif (header === gfp::SERIES)
        metadataDict[gf::SERIES] = data
    end
end
rawData[gf::MD] = metadataDict

# Stats Table
#TODO: Put max stats?
statsDict = {}
statTable = doc.xpath("//div[@class='tab-group'][1]")
#Prepare Evo Nums
index = 1
doc.xpath("//div[@class='tab-group'][1]/ul[@class='tabs']//a").each do |a|
    evoStageNum = a.text.match(/\d+/)[0]
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
        isTrans = level.include?(gfp::TRANS_SYMBOL)
        #Removed TRANS_SYMBOL
        level = level.match(/\d+/)[0]
        # puts "Level: #{level} HP: #{hp} Attack: #{atk} Defense: #{defense} isTranscendance: #{isTrans}"
        stats.push({
            sf::LEVEL => level.to_i,
            sf::HP => hp.to_i,
            sf::ATK => atk.to_i,
            sf::DEF => defense.to_i,
            sf::IS_TRANS => isTrans
        })
    end
    #add into statsDict
    statsDict[evoStageNum] = stats 
    index+=1
end

puts statsDict[index.to_s]

rawData[gf::STATS] = statsDict

# Ultimate Table
ultDict = {}
doc.xpath("//h2[contains(text(), '#{gfp::ULT}')]/following-sibling::table[1]/tbody/tr"). each do |row|
    # puts row
    header = row.xpath('./th').text.strip.gsub(/\n/, "")
    data = row.xpath('./td').text.strip.gsub(/\n/, "")
    if (header === gfp::ULT_NAME)
        ultDict[gf::NAME] = data
    elsif (header === gfp::ULT_COST)
        ultDict[gf::COST] = data.to_i
    elsif (header === gfp::ULT_DESC)
        ultDict[gf::DESC] = data.match(/\[#{gfp::ULT_DESC}\]/).post_match
    end
end
rawData[gf::ULT] = ultDict


# Attribute Table
attributeDict = {}
attributeDict[gf::DMG] = {}
attributeDict[gf::RESIST] = {}
index = 1
doc.xpath("//h2[contains(text(), '#{gfp::ULT}')]/following-sibling::table[2]/tbody/tr[position() > 1]").each do |row|
    damageValue = row.xpath('./td[2]').text.strip.to_i
    resistValue = row.xpath('./td[3]').text.strip.to_i

    if (index == 1) #fire
        attributeDict[gf::DMG][att::FIRE] = damageValue
        attributeDict[gf::RESIST][att::FIRE] = resistValue
    elsif (index == 2) #ice
        attributeDict[gf::DMG][att::ICE] = damageValue
        attributeDict[gf::RESIST][att::ICE] = resistValue
    elsif (index == 3) #thunder
        attributeDict[gf::DMG][att::THR] = damageValue
        attributeDict[gf::RESIST][att::THR] = resistValue    
    elsif (index == 4) #light
        attributeDict[gf::DMG][att::LIGHT] = damageValue
        attributeDict[gf::RESIST][att::LIGHT] = resistValue
    elsif (index == 5) #dark
        attributeDict[gf::DMG][att::DARK] = damageValue
        attributeDict[gf::RESIST][att::DARK] = resistValue
    end
    index += 1
end
rawData[gf::ATTR] = attributeDict

# Passives Table
passives = []
doc.xpath("//div[@class='auto-width']/table").each do |table|
    level = table.xpath('./caption').text.strip.match(/\d+/)[0].to_i
    passiveName = table.xpath('./tbody/tr/th').text.strip.gsub(/\n/, "")
    passiveDesc = table.xpath('./tbody/tr/td').text.strip.gsub(/\n/, "")
    matchData = passiveName.match(/(.{2,})(.)(.)/)
    symbol = nil
    tier = nil
    if (matchData != nil)
        passiveName = matchData[1]
        symbol = matchData[2]
        tier = matchData[3]
    end
    # puts "Caption: #{caption} Passive Name: #{passiveName} Passive Desc: #{passiveDesc}"
    passives.push({
        sf::LEVEL => level,
        gf::NAME => passiveName,
        gf::DESC => passiveDesc,
        gf::TIER => tier,
        gf::SYMBOL => symbol
    })
end
rawData[gf::PASSIVES] = passives


# Evo Table
# puts doc.xpath("//div[@class='tab-group'][2]")
evolutions = []
index = 1
evoSection = doc.xpath("//div[@class='tab-group'][2]")
evoSection.xpath("./ul/li").each do |li| 
    evoDict = {}
    evoMats = []
    matchData =  li.text.strip.match(/.(\d)..(\d)/)
    base = matchData[1].to_i
    to = matchData[2].to_i
    
    evoDict[gf::BASE] = base
    evoDict[gf::TO] = to
    
    #process sprite images
    tabPanel = evoSection.xpath("./div[@class='tab-content']/div[contains(@class, 'tabpanel')][#{index}]")
    tabPanelCharaImageBase = tabPanel.xpath("./div[@class='panel-inner'][1]/ul[@class='evol']/li[1]/img/@src").text
    tabPanelCharaImageTo   = tabPanel.xpath("./div[@class='panel-inner'][1]/ul[@class='evol']/li[3]/img/@src").text
    
    images.push({
        imgf::CAT => "hero",
        imgf::TYPE => "sprite",
        gf::NAME => base.to_s,
        imgf::URL => tabPanelCharaImageBase
    }) unless index == 2  #ignore repeat on second evo

    images.push({
        imgf::CAT => "hero",
        imgf::TYPE => "sprite",
        gf::NAME => to.to_s,
        imgf::URL => tabPanelCharaImageTo
    })

    #process evo mats
    tabPanelInner = tabPanel.xpath("./div[@class='panel-inner'][2]/ul[@class='line-list']")
    tabPanelInner.xpath("./li").each do |evoMatItem|
        #Mat Image Processing
        evoMatImageURL = evoMatItem.xpath("./img/@src").text.strip
        #Mat Data Processing
        evoMatMatchData = evoMatItem.xpath("./p").text.gsub!(/\n|\s/, "").match(/(.+)\((.)\).(\d*)/)
        evoMatName = evoMatMatchData[1]
        evoMatSize = evoMatMatchData[2]
        evoMatAmt = evoMatMatchData[3].to_i
        evoMatID = evoMatImageURL.match(/[A-Z]\d{5,}/)[0]


        images.push({
            imgf::NAME => "#{evoMatName} (#{evoMatSize})",
            imgf::MATID => evoMatID,
            imgf::CAT => "material",
            imgf::TYPE => "evolution",
            imgf::DESC => "no background",
            imgf::URL => evoMatImageURL,
            imgf::SIZE => "medium"
        }) unless images.any? { |image| image[imgf::MATID] === evoMatID}
        evoMats.push({
            gf::NAME => evoMatName,
            gf::MATID => evoMatID,
            gf::SIZE => evoMatSize,
            gf::AMT => evoMatAmt
        })

        # puts "evoMatMatchData: #{evoMatName} | #{evoMatSize} | #{evoMatAmt}"
    end
    evoDict[gf::MATS] = evoMats
    evolutions.push(evoDict)
    index += 1
end
rawData[gf::EVO] = evolutions
rawData[gf::IMGS] = images


# puts images.inspect
# puts rawData.inspect
# puts JSON.pretty_generate(rawData)
# Close file
file.close()