require 'json'
require './extractor'

# jsonFile = File.open('./rawDataFinal.json')
# rawData = JSON.parse(jsonFile.read)


# puts JSON.pretty_generate rawData[0]


# jsonFile.close
Extractor.extractHeroes do |rawHeroData|
    puts JSON.pretty_generate rawHeroData


end