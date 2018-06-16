require 'nokogiri'
require 'open-uri'
require 'json'
require './hero_scraper'
require './constants/image_fields'
require './constants/common_fields'


module Extractor
    def self.extractHeroes



    end


    class HeroesExtractor
        def extractHeroes
            url = 'http://portal.grimmsnotes.jp/category/hero/'
            maxPageNum = getMaxPageNum(url)
            gf = CommonFields
            imgf = ImageFields

            1.upto(maxPageNum) do |i|
                pageURL = "#{url}/page/#{i}"
                heroListPage = Nokogiri::HTML(open(pageURL))
                heroListPage.xpath("//div[@class='hero-list']/div[contains(@class, 'hero-list__item')]").each do |heroDiv|
                    thumbnailURL = heroDiv.xpath("./article/figure/img/@src").text.strip
                    heroID = thumbnailURL.match(/[A-Z]\d{5,}/)[0]
                    isOrigin = heroDiv.xpath('@class').text.strip.include? "origin"
                    thumbnail = {
                        imgf::HEROID => heroID,
                        imgf::NAME => 'thumbnail',
                        imgf::CAT => 'hero',
                        imgf::TYPE => 'thumbnail',
                        imgf::URL => thumbnailURL,
                        imgf::SIZE => 'small'
                    }
                    heroURL = heroDiv.xpath("./article/a/@href").text.strip
                    puts heroURL
                    rawData = HeroScraper.scrape(heroURL)
                    rawData[gf::IS_ORIGIN] = isOrigin
                    rawData[gf::IMGS].push(thumbnail)
                    # heroes.push(rawData)
                    yield rawData
                end
            end
            def getMaxPageNum(url)
                doc = Nokogiri::HTML(open(url))
                doc.xpath("//div[@class='pagenation']/ul/li[last() - 1]").text.strip.to_i
            end
        end
    end
end
