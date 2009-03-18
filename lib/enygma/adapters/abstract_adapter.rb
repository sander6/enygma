module Enygma
  module Adapters
    
    class AbstractAdapter
      
      attr_reader :database
      
      def connect!(db)
        @database = nil
      end
      
      def query(*args)
        []
      end
      
      def get_attribute
        nil
      end
    end
    
  end
end