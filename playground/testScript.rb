require '../constants/common_fields'

    #Replace asterisk with GN's asterisk and remove space
    #Capitalize every attribute and status
    def fixSkillDescription(desc)
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
        attributesPattern = /light|darkness|dark|ice|fire/
        statusesPattern = /paraly(?:zed|sis|ze)|poison(?:ed)?|freeze|frozen|burn(?:ed|t|ing)?|stun(?:ned)?|curse(?:d)?/
        desc.scan(/#{attributesPattern.source}|#{statusesPattern.source}/) do |m|
            desc = desc.gsub(m, m.capitalize)
        end



        desc.gsub(/\r|\R|\n/, '').strip
    end

        #Sub Up Arrow to have no space
        #Capitalize every word inside parenthesis
        #Remove Effect
        #Fix Lightning to be Thunder
        def fixSkillName(name)
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
            desc = desc.gsub( /(?:L|l)ightning/, 'Thunder')
            desc = desc.gsub(/(?:E|e)xplosion/, 'Blast')

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

# puts fixSkillName('GN lightning effect         ↑')
# puts fixSkillDescription("The attack power of the lightning attribute of all parties increases by 20%. * Only one GN skill will be activated during the battle Lightning. (paralysis, lightning, darkness)\n")
puts fixSkillDescription("Rock uplift attack on the same line and ambient attack (lightning, stun, explosion).")