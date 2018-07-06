require '../constants/common_fields'
module PassiveSkillScraper
    def self.scrape
        Scraper.new.scrapePassives
    end

    class Scraper
        def initialize
            @passiveSkillsFile = File.join('..', 'rawData', 'm_skill.bin')
            raise 'Could not find m_skill.bin' unless File.exist?(@passiveSkillsFile)
        end

        def scrapePassives
            index = 0
            File.open(@passiveSkillsFile) do |f|
                #Replace any invalid characters that could not be represented in UTF-8
                data = f.read.encode('UTF-8', invalid: :replace, undef: :replace, replace: '' )
                #Random characters after name with lowercase ending
                #Extra characters after ')' and upwards arrow
                #Extra character after specific names
                #Extra letter after roman numeral
                #Extra Character after Guard Regen Skills
                #Extra character after lv00
                #Extra Letter after +
                #Extra Number after Name
                #Capital Letter after Name
                data = data.gsub(/[\x01-\x1F\"]/, ' ')
                        .gsub(/(?<=[a-z\)])[\.\?\-\,\(\{\|\\\!\*\#\$\%\&0-9](?=\x00{2,})/, '')
                        .gsub(/(?<=[\)\u2191])[\]\x5e\)\+\@\\\_\`\[A-Za-z](?=\x00{2,})/, '')
                        .gsub(/(Thunder|Light|Darkness|Ice|Fire|Infight|Guard|Hellfire|Defense|Immunity|Freeze|Recovery|Poison|Paralysis|Stun|Burn|Effect|Skin|Sway|Attack|HP)([\<\~\/A-Za-z\}\_\@\=\>]\x00{3,})/, '\1')
                        .gsub(/([\u2160-\u2167])([A-Z]\0{3,})|/, '\1')
                        .gsub(/((?:Guard|Regeneration)\u00b7)(10|25|50|100|150)([a-z1-9\;\:](?=\x00{3,}))/, '\1\2')
                        .gsub(/(lv00)([a-zA-z\-\+\%\&,:;?#*\(\)0-9](?=\x00{3}))/, '\1')
                        .gsub(/(\+)([A-Za-z](?=\x00{3}))/, '\1')
                        .gsub(/(\d{1,3}%)([a-zA-Z](?=\x00{3}))/, '\1')
                        .gsub(/([a-z])([A-Z])(?=\x00{3})/, '\1')
                        .gsub(/\+(?=\x00)/, '')

                # puts data
                passives = []
                data.split(/(?<=\.\s)\x00{6,};|(?<=[\d\)]\s)\x00{4,}|\x00{3}\s\x00{3};(?!\x00{3}[A-Z])/).each do |splitLine|
                    splitLine = splitLine.sub(/\n/, ' ')#.sub(/^\W+\\W+(?=[A-Z])/, '')
                    skillName = nil
                    index = 1

                    # puts "SplitLine #{splitLine}"
                    splitLine.scan(/(?>\x00{3,})(?:(?:[A-Z](?=\s*[\_A-Za-z]\s*)|\d{2,})|\!{3}|\?{3}|\d\u2606)/) do |scan|
                        matchIndexBegin = Regexp.last_match.begin(0)
                        while (splitLine[matchIndexBegin].match(/\x00/) != nil)
                            matchIndexBegin += 1
                        end

                        matchIndexEnd = matchIndexBegin
                        while (matchIndexEnd < splitLine.length && splitLine[matchIndexEnd].match(/\x00/) == nil )
                            matchIndexEnd += 1
                        end

                        matchedLine = splitLine[matchIndexBegin..(matchIndexEnd-1)].strip
                        if (index % 2 == 0)
                            if (block_given?)
                                yield skillName, matchedLine
                            else
                                passives.push({CommonFields::FULLNAME => skillName, CommonFields::DESC => matchedLine})
                            end
                        else
                            skillName = matchedLine
                            if (skillName.match(/Combo Tactics/))
                                skillName = 'Combo Tactics'
                            elsif (skillName.match(/(?<!\s)(\([\u2160-\u2167]\))/))
                                idxForSkillName = Regexp.last_match.begin(0)
                                skillName = "#{skillName[0..(idxForSkillName-1)]} #{skillName[idxForSkillName..-1]}"
                            end
                            skillName = skillName.gsub(/\x7f/, '')
                        end
                        index += 1
                    end #End splitLine.scan
                end #End data.split
                passives unless block_given?
            end #End File.open
        end
    end #End Class
end #End Module