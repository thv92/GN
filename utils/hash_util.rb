module HashUtil
    def self.convertArrayToDictWithKeys(keyName, arrayOfDicts, rejectKey = false)
        dict = {}
        # puts "KEYNAME #{keyName}"
        arrayOfDicts.each do |data|
            # puts "DATA: #{data}"
            if (dict.include?(data[keyName]))
                puts "Duplicate keys exist for: #{data[keyName]}"
            end
            dict[data[keyName]] = data unless rejectKey
            dict[data[keyName]] = data.reject{|k| k == keyName} unless !rejectKey
        end
        dict
    end

    def self.convertKeyDictToDiffKey(curKeyName, newKeyName, dictOfDicts, rejectNewKeyName = false)
        result = {}
        dictOfDicts.each do |key, dict|
            dict[curKeyName] = key
            if(result.include?(dict[newKeyName]))
                puts "Key: #{key}"
                puts "Duplicate keys exist for: #{dict.inspect}"
            end
            result[dict[newKeyName]] = dict unless rejectNewKeyName
            result[dict[newKeyName]] = dict.reject{|k| k == newKeyName} unless !rejectNewKeyName
        end
        result
    end


end