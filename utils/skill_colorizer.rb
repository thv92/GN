require '../constants/common_fields'


module SkillColorizer
    def self.categorizeSkillDesc(skillDesc)
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
        damagePattern_3 = /(?:(?:A|a)ttack) power .+ increases by/
        defensePattern_1 = /(?:(?:(?:D|d)ef)|DEF)(?:(\sagainst.+(?:(?:are|is)\sincrease))|(?:\s(?:is|are) increase))|(?:D|d)amage received.+(?:is decreased)|(?:(?:D|d)efense effect is applied)/
        defensePattern_2 = /HP is increased by/
        defensePattern_3 = /DEF against/
        guardPattern = /frontal attack|damage reduction from Guard is increased/
        supportPattern = /HP is recovered|HP is restored|(?:R|r)egeneration effect.+(applied)|(?:R|r)ecovery effect.+is increase|(?:(?:R|r)ecovery) from (?:(?:R|r)egeneration).+is increase|Damage received from .+ is recovered|recovers? from status effect/
        utilityPattern = /duration is extended|reduction rate|Switch Reload|distance being thrown|Gold|Movement Speed|Combo duration|immune|Swap Skill|Sway|Ultimate Skill|hit that reduces HP to zero|drop rate|EXP|stagger|inherited|stealth|(?:S|s)tep invincible duration|(?:R|r)esists .+ effect|(?:R|r)egeneration range is expanded|charge Mana|Regeneration does not heal but deals/
        #Attributes
        attributePattern = /(Ice|Thunder|Light|Darkness|Fire).+(element)?/
        fireAttributePattern = /Fire/
        iceAttributePattern = /Ice/
        thunderAttributePattern = /Thunder/
        lightAttributePattern = /Light/
        darkAttributePattern = /Darkness/
        #Statuses
        poisonStatusPattern = /Poison(?:ed)?/
        freezeStatusPattern = /Freeze|Frozen/
        burnStatusPattern = /Burn(?:ed|t|ing)?/
        paraStatusPattern = /Paraly(?:ze|zed|sis)/
        stunStatusPattern = /Stun(?:ned)?/
        curseStatusPattern = /Curse(?:d)?/
        statusPattern = /#{poisonStatusPattern.source}|#{freezeStatusPattern.source}|#{burnStatusPattern.source}|#{paraStatusPattern.source}|#{stunStatusPattern.source}|#{curseStatusPattern.source}/
        debuffPattern = /(?:is|are) decreased/
        attackDebuffPattern = /(?:ATK|(?:(?:A|a)ttack)) #{debuffPattern.source}/
        defenseDebuffPattern = /DEF #{debuffPattern.source}|HP #{debuffPattern.source}|DEF against .+ #{debuffPattern.source}/
        arenaPattern = /Arena/
    
        attributes = nil
        statustypes = nil
        skillDesc.split(splitPattern).each do |splitted|
            resistBlock = false
            guardBlock = false
            #Arena block
            if (arenaPattern.match(splitted))
                isArena = true
            end
            #Attribute block
            if (attributePattern.match(splitted))
                isAttribute = true
                attributes = []
                if (fireAttributePattern.match(splitted))
                    attributes.push('fire')
                end
                if (iceAttributePattern.match(splitted))
                    attributes.push('ice')
                end
                if (thunderAttributePattern.match(splitted))
                    attributes.push('thunder')
                end
                if (lightAttributePattern.match(splitted))
                    attributes.push('light')
                end
                if (darkAttributePattern.match(splitted))
                    attributes.push('darkness')
                end
            end
            #Status block
            if (statusPattern.match(splitted))
                isStatus = true
                statustypes = []
                if (poisonStatusPattern.match(splitted))
                    statustypes.push('poison')
                end
                if (freezeStatusPattern.match(splitted))
                    statustypes.push('freeze')
                end
                if (burnStatusPattern.match(splitted))
                    statustypes.push('burn')
                end
                if (paraStatusPattern.match(splitted))
                    statustypes.push('paralysis')
                end
                if (stunStatusPattern.match(splitted))
                    statustypes.push('stun')
                end
                if (curseStatusPattern.match(splitted))
                    statustypes.push('curse')
                end
                if (/Resists (?:#{statusPattern.source})/.match(splitted))
                    isUtility = true
                end
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
                isUtility = true
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
            if (!guardBlock && !resistBlock && (damagePattern_1.match(splitted) || damagePattern_2.match(splitted) || damagePattern_3.match(splitted)))
                isDamage = true
            end
            #Supoprt block
            if (supportPattern.match(splitted))
                isSupport = true
            end
            #Debuff DEF block
            if (defenseDebuffPattern.match(splitted))
                isDebuff = true
                isDefense = true
            end
            #Debuff ATK block
            if (!resistBlock && !guardBlock && !isDefense && attackDebuffPattern.match(splitted))
                isDamage = true
                isDebuff = true
            end
        end
    
        # if (!isDamage && !isDefense && !isSupport && !isUtility && !isAttribute && !isStatus && !isArena && !isDebuff)
        #     puts "Non Classified Skills"
        #     puts "SkillName: #{skillName}"
        #     puts "SkillDesc: #{skillDesc}"
        # end
        {
            CommonFields::IS_DAMAGE => isDamage,
            CommonFields::IS_DEFENSE => isDefense,
            CommonFields::IS_SUPPORT => isSupport,
            CommonFields::IS_UTILITY => isUtility,
            CommonFields::IS_ARENA => isArena,
            CommonFields::IS_DEBUFF => isDebuff,
            CommonFields::IS_ATTRIBUTE => isAttribute,
            CommonFields::ATTRIBUTES => attributes,
            CommonFields::IS_STATUS => isStatus,
            CommonFields::STATUSTYPES => statustypes
        }
    end
end
