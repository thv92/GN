module LogUtil
    def self.printMethodStatus(header, complete)
        "----------#{header} Started----------" unless complete
        "----------#{header} Finished----------" unless !complete
    end
end