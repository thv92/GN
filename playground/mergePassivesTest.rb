require 'json'
require '../constants/common_fields'
require '../utils/hash_util'
require 'logger'

def mergePassives(rawPassives, localizedPassives)
    if (rawPassives == nil || localizedPassives == nil)
        raise 'Parameters are nil. Cannot merge'
    end
    matchedLogger = Logger.new('./mergeMatchedLog.log', File::WRONLY | File::CREAT)
    matchedLogger.datetime_format = '%d-%m-%Y %H:%M:%S'
    matchedLogger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}, #{datetime}| #{progname}: #{msg}\n"
    end
    matchedLogger.level = Logger::DEBUG
    
    unmatchedLogger = Logger.new('./mergeUnmatchedLog.log', File::WRONLY | File::CREAT)
    unmatchedLogger.datetime_format = '%d-%m-%Y %H:%M:%S'
    unmatchedLogger.formatter = proc do |severity, datetime, progname, msg|
        "#{severity}, #{datetime}| #{progname}: #{msg}\n"
    end
    unmatchedLogger.level = Logger::DEBUG

    result = {}

    rawPassives.each do |fullName, passive|
        if (fullName == nil)
            puts "Found Nil: #{passive.inspect}"

        end

        if (fullName != nil && fullName.include?('Tolerance'))
            fullName = fullName.gsub('Tolerance', 'Resistance')
        end

        if (localizedPassives.include?(fullName))
            matchedLogger.debug("Matched: #{fullName}")
        else
            unmatchedLogger.debug("Unmatched: #{fullName}")
        end


    end
end
localizedPassives = HashUtil::convertArrayToDictWithKeys(CommonFields::FULLNAME, JSON::parse(File.read('./catPassives.json')), true)
rawPassives = HashUtil::convertKeyDictToDiffKey(CommonFields::PASSIVE_ID, CommonFields::FULLNAME, JSON::parse(File.read('../finalizedData/finalizedHeroes.json'))[CommonFields::PASSIVES], true)

File.open('./localizedPassives.json', 'w') do |f|
    f.write JSON.pretty_generate(localizedPassives)
end

File.open('./rawPassives.json', 'w') do |f|
    f.write(JSON.pretty_generate(rawPassives))

end







mergePassives(rawPassives, localizedPassives)