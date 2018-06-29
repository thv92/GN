require '../constants/stat_fields'
require '../constants/common_fields'
require 'json'

def categorizeSkill(skillName, skillDesc)
    #Check skillName for + and split on .
    #Passive Skill Fields
    isDamage = false
    isDefense = false
    isSupport = false
    isUtility = false
    isAttribute = false
    isStatus = false
    isArena = false
    isDebuff = false

    #Patterns
    splitPattern = /(?<=[A-Za-z0-9])\.(?=\s)/
    damagePattern_1 = /(?:(?:I|i)ncrease(?:s|d))\s(?:D|d)amage dealt|((?:(?:D|d)amage)\sdealt|(?:ATK|(?:A|a)ttack(?=\s))(?:\s(?:effect|damage))?)(?:.*\s(?:is|are)\s(?:increase|applied))/
    damagePattern_2 = /intended damage/
    defensePattern_1 = /(?:(?:(?:D|d)ef)|DEF)(?:(\sagainst.+(?:are|is\sincrease))|(?:\sis increase))|(?:D|d)amage received.+(?:is decreased)|(?:(?:D|d)efense effect is applied)/
    defensePattern_2 = /HP is increased by/
    defensePattern_3 = /DEF against/
    guardPattern = /frontal attack/
    supportPattern = /HP is recovered|HP is restored|Regeneration effect.+(applied)|recovery effect.+is increase|(?:(?:R|r)ecovery) from (?:(?:R|r)egeneration).+is increase/
    utilityPattern = /Movement Speed|Combo Duration|immune|Swap Skill|Sways|Ultimate Skill|hit that reduces HP to zero|drop rate|EXP|stagger|inherited|stealth/
    attributePattern = /(Ice|Thunder|Light|Darkness|Fire).+(element)?/
    statusPattern = /Poison(:?ed)?|Freeze|Frozen|Burn(?:ed|t|ing)|Paraly(?:ze|zed|sis)|Stun(?:ned)?|Curse(?:d)?/
    debuffPattern = /(?:is|are) decreased/
    attackDebuffPattern = /ATK|(?:(?:A|a)ttack) #{debuffPattern}/
    arenaPattern = /Arena/
    resistBlock = false
    guardBlock = false

    skillDesc.split(splitPattern).each do |splitted|
        #Arena block
        if (arenaPattern.match(splitted))
            isArena = true
        end
        #Attribute block
        if (attributePattern.match(splitted))
            isAttribute = true
        end
        #Status block
        if (statusPattern.match(splitted))
            isStatus = true
        end
        #Utility block
        if (utilityPattern.match(splitted))
            isUtility = true
            if(debuffPattern.match(splitted))
                isDebuff = true
            end
        end
        #Guard block
        if (guardPattern.match(splitted))
            isDefense = true
            guardBlock = true
        end
        #Resist block
        if (defensePattern_3.match(splitted))
            resistBlock = true
            isDefense = true
        end
        #Defense block
        if (!resistBlock && (defensePattern_1.match(splitted) || defensePattern_2.match(splitted)))
            isDefense = true
        end
        #Damage block
        if (!guardBlock && !resistBlock && (damagePattern_1.match(splitted) || damagePattern_2.match(splitted)))
            isDamage = true
        end
        #Supoprt block
        if (supportPattern.match(splitted))
            isSupport = true
        end
        #Debuff DEF block
        if (/DEF #{debuffPattern}/.match(splitted))
            isDebuff = true
            isDefense = true
        end
        #Debuff ATK block
        if (!resistBlock && !guardBlock && !isDefense && attackDebuffPattern.match(splitted))
            isDamage = true
            isDebuff = true
        end
    end
    {
        CommonFields::FULLNAME => skillName,
        CommonFields::DESC => skillDesc,
        CommonFields::IS_DAMAGE => isDamage,
        CommonFields::IS_DEFENSE => isDefense,
        CommonFields::IS_SUPPORT => isSupport,
        CommonFields::IS_UTILITY => isUtility,
        CommonFields::IS_ATTRIBUTE => isAttribute,
        CommonFields::IS_STATUS => isStatus,
        CommonFields::IS_ARENA => isArena,
        CommonFields::IS_DEBUFF => isDebuff
    }
end



index = 0
File.open('./m_skill.bin') do |f|

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


    # puts data

    passives = []
    data.split(/(?<=\.\s)\x00{6,};|(?<=[\d\)]\s)\x00{4,}|\x00{3}\s\x00{3};(?!\x00{3}[A-Z])/).each do |splitLine|
        splitLine = splitLine.sub(/\n/, ' ')#.sub(/^\W+\\W+(?=[A-Z])/, '')
        skillName = nil
        index = 1

        # puts "SplitLine #{splitLine}"
        scanned = splitLine.scan(/(?>\x00{3,})(?:(?:[A-Z](?=\s*[\_A-Za-z]\s*)|\d{2,})|\!{3}|\?{3}|\d\u2606)/) do |scan|
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
                puts "SkillDesc: #{matchedLine}"
                passives.push categorizeSkill(skillName, matchedLine)
            else
                puts "SkillName: #{matchedLine}"
                skillName = matchedLine
            end
            index += 1
        end
    end
    File.open('./catPassives.json', 'w') do |f|
        f.write(JSON.pretty_generate(passives))
    end
end