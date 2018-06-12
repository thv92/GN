require 'nokogiri'
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
# puts doc.xpath("//div[@class='tab-group'][1]")

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
        stat = {}
        tr = statTR[i]
        level = tr.xpath('./td[1]').text.strip
        hp = tr.xpath('./td[2]').text.strip
        atk = tr.xpath('./td[3]').text.strip
        defense = tr.xpath('./td[4]').text.strip
        isTrans = level.include?(gfp::TRANS_SYMBOL)
        #Remove TRANS_SYMBOL
        level = level.match(/\d+/)[0]

        stat[sf::LEVEL] = level.to_i
        stat[sf::HP] = hp.to_i
        stat[sf::ATK] = atk.to_i
        stat[sf::DEF] = defense.to_i
        stat[sf::IS_TRANS] = isTrans
        # puts "Level: #{level} HP: #{hp} Attack: #{atk} Defense: #{defense} isTranscendance: #{isTrans}"
        stats.push(stat)
    end
    #add into statsDict
    statsDict[evoStageNum] = stats 
    index+=1
end
rawData[gf::STATS] = statsDict

# Ultimate Table
ultDict = {}
doc.xpath("//h2[contains(text(), '#{gfp::ULT}')]/following-sibling::table[1]/tbody/tr"). each do |row|
    # puts row
    header = row.xpath('./th').text.strip
    data = row.xpath('./td').text.strip
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
    damageValue = row.xpath('./td[2]').text.to_i
    resistValue = row.xpath('./td[3]').text.to_i

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
    passiveSkill = {}
    level = table.xpath('./caption').text.strip.match(/\d+/)[0].to_i
    passiveName = table.xpath('./tbody/tr/th').text.strip
    passiveDesc = table.xpath('./tbody/tr/td').text.strip
    # puts "Caption: #{caption} Passive Name: #{passiveName} Passive Desc: #{passiveDesc}"
    passiveSkill[sf::LEVEL] = level
    passiveSkill[gf::NAME] = passiveName
    passiveSkill[gf::DESC] = passiveDesc
    passives.push(passiveSkill)
end
rawData[gf::PASSIVES] = passives


# Evo Table
puts doc.xpath("//div[@class='tab-group'][2]")

# rawData[gf::IMGS] = images
# puts rawData.inspect
# Close file
file.close()