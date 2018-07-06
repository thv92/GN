require '../constants/common_fields'
require 'json'

@cf = CommonFields
    
    def getCorrectKeyName(key)
        case key.upcase
        when (@cf::NAME).upcase
            @cf::NAME
        when (@cf::ULT).upcase
            @cf::ULT
        when (@cf::DESC).upcase
            @cf::DESC
        when (@cf::PASSIVE_ID).upcase
            @cf::PASSIVE_ID
        when (@cf::MAT_ID).upcase
            @cf::MAT_ID
        when (@cf::HERO_ID).upcase
            @cf::HERO_ID
        when (@cf::FULLNAME).upcase
            @cf::FULLNAME
        else
            raise "Could not find correct key for #{key}"
        end
    end


     #Replace asterisk with GN's asterisk and remove space
        #Capitalize every attribute and status
        def localizeSkillDescription(desc)
            #Replace asterisk
            starPattern = /(\s\*)/
            if (starPattern.match(desc))
                matchData = Regexp.last_match
                desc = "#{desc[0..(matchData.begin(1)-1)]} \u203b#{desc[(matchData.end(1)+1)..-1]}"
            end

            #Replacement for localization (lightning, blast)
            desc = desc.gsub( /(?:L|l)ightning/, 'Thunder')
            desc = desc.gsub(/(?:E|e)xplosion/, 'Blast')

            #Capitalize every attribute and status
            attributesPattern = /light|darkness|dark|ice|fire|thunder/
            statusesPattern = /paraly(?:zed|sis|ze)|poison(?:ed)?|freez(?:e|ing)|frozen|burn(?:ed|t|ing)?|stun(?:ned)?|curse(?:d)?/
            desc.scan(/#{attributesPattern.source}|#{statusesPattern.source}/) do |m|
                desc = desc.gsub(m, m.capitalize)
            end

            desc.gsub(/\r|\R|\n/, '').strip
        end

        #Sub Up Arrow to have no space
        #Capitalize every word inside parenthesis
        #Remove Effect
        #Fix Lightning to be Thunder
        def localizeSkillName(name)
            #Remove 'effect' from translated
            effectPattern = /(?<=\s)((?:E|e)ffect)/
            if (effectPattern.match(name))
                lastMatch = Regexp.last_match
                idxB = lastMatch.begin(0)
                idxE = lastMatch.end(0)
                name = "#{name[0..(idxB-1)].strip} #{name[(idxE+1)..-1].strip}"
            end

            #Remove space between arrow symbol
            arrowPattern = /(\s+)(#{CommonFields::BUFF_SYMBOL})/
            if (arrowPattern.match(name))
                lastMatch = Regexp.last_match
                spaceIdxB = lastMatch.begin(1)
                spaceIdxE = lastMatch.end(1)
                name = "#{name[0..(spaceIdxB-1)]}#{name[lastMatch.begin(2)]}"
            end

            #Replacement for localization (lightning, blast)
            name = name.gsub( /(?:L|l)ightning/, 'Thunder')
            name = name.gsub(/(?:E|e)xplosion/, 'Blast')

            #Capitalize every word inside parenthesis
            nameArray = name.split(/\s+/)
            (nameArray.map do |v| 
                if v.length > 2 
                    v.capitalize
                else
                    v 
                end
            end).join(' ').gsub(/\r|\R|\n/, '').strip
        end


        #Read nontranslated/translated partitions
        def readPartitionedFile(readData)
            result = []
            keyValuePattern = /(?:(?:\[(.+)\]\s*\[(.+)\]\s*(.+))|(?:\[(.+)\]\s*(.+)))/
            readData.split(/(?:\-\-\-)|(?:\-\s\-)/).each do |block|
                puts "Block: \n#{block}"
                blockData = {}
                block.split(/\n/).each do |line|
                    puts "Line: #{line}"
                    matchData = keyValuePattern.match(line)
                    
                    if (matchData)
                        #Matches key - value
                        if (matchData[4] && matchData[5]) 
                            key_1 = matchData[4].strip
                            value = matchData[5].strip
                            
                            if (key_1 == @cf::NAME)
                                value = localizeSkillName(value)
                            elsif (key_1 == @cf::DESC)
                                value = localizeSkillDescription(value.capitalize)
                            end
                            
                            blockData[key_1] = value
                        elsif (matchData[1] && matchData[2] && matchData[3]) #Matches key - key - value
                            key_1 = matchData[1].strip
                            key_2 = matchData[2].strip
                            value = matchData[3].strip
                            if (!blockData[key_1])
                                blockData[key_1] = {}
                            end

                            if (key_2 == @cf::NAME)
                                value = localizeSkillName(value)
                            elsif (key_2 == @cf::DESC)
                                value = localizeSkillDescription(value.capitalize)
                            end
                            blockData[key_1][key_2] = value
                        end
                    end #if matchData
                end #end split \n
                result.push(blockData) unless blockData.size == 0
            end #end split ---
            puts JSON.pretty_generate(result)
            result
        end




        readPartitionedFile(File.read('../translatedData/ToTranslate_Heroes_1.txt'))