module HashUtil
    def self.convertArrayToDictWithKeys(keyName, dataSet)
        dict = {}
        dataSet.each do |data|
            if (dict.include?(data[keyName]))
                puts 'Duplicate keys exist for: #{data[keyName]}'
            end
            dict[data[keyName]] = data
        end
        dict
    end


end