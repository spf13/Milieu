module MongoModule

    attr_accessor :collection, :updated_at

    def initialize(hash = nil)
      self.init_collection

      unless hash == nil
          hash.each do |k,v|
              self.instance_variable_set("@#{k}", v)
              self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})
              self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})
          end
      end
    end

    def save()
        col = DB[self.collection]
        @updated_at = Time.now
        col.save(self.to_hash)
    end

    def to_hash
        h = {}
        instance_variables.each {|var| h[var.to_s.delete("@")] = instance_variable_get(var) }
        h.delete("collection")
        h
    end

end
