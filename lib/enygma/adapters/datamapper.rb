module Enygma
  module Adapters
    
    class DatamapperAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(datastore)
        raise "The Datamapper adapter is current not implemented."
      end
      
      def query(args = {})
        raise "The Datamapper adapter is current not implemented."        
      end
      
      def get_attribute(record, attribute)
        raise "The Datamapper adapter is current not implemented."
      end
      
    end
    
  end
end