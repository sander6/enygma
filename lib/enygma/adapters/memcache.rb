require 'memcache'

module Enygma
  module Adapters
    
    class MemcacheAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(datastore)
        @datastore = case datastore
        when MemCache
          datastore
        else
          Memcache.new(datastore)
        end
      end
      
      def query(args = {})
        connect!(args[:datastore])
        @datastore.get_multi(*args[:ids]).values
      end
      
    end

  end
end