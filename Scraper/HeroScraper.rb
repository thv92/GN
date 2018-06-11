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
rawData[gf::NAME] = doc.xpath("//div[@class=\'page-title\']").text

#Banner Image URL
bannerImageDict = {}
bannerImageDict[imgf::CAT] = "Banner"
bannerImageDict[gf::NAME] = "Banner"
bannerImageDict[imgf::URL] = doc.xpath("//div[@class='hero-bnr']/img/@src").text
images.push(bannerImageDict)

#Metadata Table
metadataDict = {}
metadataTable = doc.xpath("//table[@class='flex']")
metadataTable.xpath('./tbody/tr').each do |tr| 
    header =  tr.xpath('./th').text
    data = tr.xpath('./td').text
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
    
    puts evoStageNum
    trIndex = 2
    statTR = stat.xpath('./table/tbody/tr')

    #level hp attack def
    stats = []
    1.upto(statTR.length - 1) do |i|
        stat = {}
        tr = statTR[i]
        level = tr.xpath('./td[1]').text
        hp = tr.xpath('./td[2]').text
        atk = tr.xpath('./td[3]').text
        defense = tr.xpath('./td[4]').text
        isTrans = level.include?(gfp::TRANS_SYMBOL)
        #Remove TRANS_SYMBOL
        level = level.match(/\d+/)[0]

        stat[sf::LEVEL] = level
        stat[sf::HP] = hp
        stat[sf::ATK] = atk
        stat[sf::DEF] = defense
        stat[sf::IS_TRANS] = isTrans
        puts "Level: #{level} HP: #{hp} Attack: #{atk} Defense: #{defense} isTranscendance: #{isTrans}"
        stats.push(stat)
    end
    #add into statsDict
    statsDict[evoStageNum] = stats 
    index+=1
end


# Ultimate Table
ultDict = {}
ultTable = doc.xpath("//h2[contains(text(), '#{gfp::ULT}')]/following-sibling::table[1]/tbody/tr")
ultTable.each do |row| 
    puts row
    header = row.xpath('./th').text
    data = row.xpath('./td').text
    puts "#{header} | #{data}"
    if (header === gfp::ULT_NAME)
        ultDict[gf::NAME] = data
    elsif (header === gfp::ULT_COST)
        ultDict[gf::COST] = data
    elsif (header === gfp::ULT_DESC)
        ultDict[gf::DESC] = data.match(/\[#{gfp::ULT_DESC}\]/).post_match
    end
end

# Attribute Table
# puts doc.xpath("//h2[contains(text(), '#{gfp::ULT}')]/following-sibling::table[2]")

# Passives Table
# puts doc.xpath("//div[@class='auto-width']")

# Evo Table
# puts doc.xpath("//div[@class='tab-group'][2]")

# rawData[gf::IMGS] = images
# puts rawData.inspect
# Close file
file.close()