require 'memcache'

module Enygma
  module Adapters
    
    class MemcacheAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(datastore)
        @datastore = case datastore
        when MemCache
          datastore
        else
          MemCache.new(datastore)
        end
      end
      
      def query(args = {})
        ids = args.has_key?(:key_prefix) ? args[:ids].collect {|i| "#{args[:key_prefix]}#{i}"} : args[:ids]
        @datastore.get_multi(*ids).values
      end
      
    end

  end
end