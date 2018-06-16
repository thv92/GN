require 'nokogiri'
require 'open-uri'
require 'json'
require './hero_scraper'
require './constants/image_fields'
require './constants/common_fields'



def getMaxPageNum(url)
    doc = Nokogiri::HTML(open(url))
    doc.xpath("//div[@class='pagenation']/ul/li[last() - 1]").text.strip.to_i
end

url = 'http://portal.grimmsnotes.jp/tag/hero-%E3%82%B0%E3%83%AA%E3%83%A0%E3%83%8E%E3%83%BC%E3%83%84'
maxPageNum = getMaxPageNum(url)
heroes = []
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
        heroes.push(rawData)
    end
end

File.open('./rawDataFinal.json', 'w') { |file|
    file.write(JSON.pretty_generate heroes)
}
