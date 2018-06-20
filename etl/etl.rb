require './extractor'
require './transformer'


module ETL
    def self.etlHeroes
        Extractor.extractHeroes
        Transformer.transformHeroes
    end
end


ETL::etlHeroes
