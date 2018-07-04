require './extractor'
require './transformer'


module ETL
    def self.etlHeroes
        Extractor.extractHeroes
        # Transformer.transformHeroes(Extractor.extractPassives)
        Transformer.transformHeroes
    end
end


ETL::etlHeroes
