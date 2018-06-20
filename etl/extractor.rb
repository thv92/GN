require 'nokogiri'
require 'open-uri'
require 'json'
require '../scrapers/hero_scraper'
require '../constants/image_fields'
require '../constants/common_fields'

module Extractor
    def self.extractHeroes(&block)
        HeroesExtractor.new.extractHeroes &block
    end

    class HeroesExtractor
        def extractHeroes
            url = 'http://portal.grimmsnotes.jp/category/hero/'
            maxPageNum = getMaxPageNum(url)
            cf = CommonFields
            imgf = ImageFields
            heroes = []

            1.upto(maxPageNum) do |i|
                pageURL = "#{url}/page/#{i}"
                heroListPage = Nokogiri::HTML(open(pageURL))
                heroListPage.xpath("//div[@class='hero-list']/div[contains(@class, 'hero-list__item')]").each do |heroDiv|
                    thumbnailURL = heroDiv.xpath("./article/figure/img/@src").text.strip
                    heroID = thumbnailURL.match(/[A-Z]\d{5,}/)[0]
                    isOrigin = heroDiv.xpath('@class').text.strip.include? "origin"
                    thumbnail = {
                        imgf::HERO_ID => heroID,
                        imgf::NAME => 'thumbnail',
                        imgf::CAT => 'hero',
                        imgf::TYPE => 'thumbnail',
                        imgf::URL => thumbnailURL,
                        imgf::SIZE => 'small'
                    }
                    heroURL = heroDiv.xpath("./article/a/@href").text.strip
                    puts heroURL
                    rawData = HeroScraper.scrape(heroURL)
                    rawData[cf::IS_ORIGIN] = isOrigin
                    rawData[cf::IMGS].push(thumbnail)
                    
                    if(block_given?)
                        yield rawData, i
                    else
                        heroes.push(rawData)
                    end
                    break
                end
                break
            end
            if(!block_given?)
                createRawDataDir
                File.open(File.join('..', 'rawData', 'rawDataHeroes.json') do |f|
                    f.write JSON.generate heroes
                end
                heroes
            end
        end

        def getMaxPageNum(url)
            doc = Nokogiri::HTML(open(url))
            doc.xpath("//div[@class='pagenation']/ul/li[last() - 1]").text.strip.to_i
        end

        def createRawDataDir
            dirPath = File.join('~', '..', 'rawData')
            if(!Dir.exist?(dirPath))
                Dir.mkdir(dirPath)
            end
        end
    end
end
