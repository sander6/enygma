require 'mattbauer-dbd'

module Enygma
  module Adapters
    
    class BerkeleyAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(datastore)
        raise "The BerkeleyDB adapter is current not implemented."
      end
      
      def query(args = {})
        raise "The BerkeleyDB adapter is current not implemented."        
      end
      
      def get_attribute(record, attribute)
        raise "The BerkeleyDB adapter is current not implemented."
      end
      
    end

  end
end