module Enygma
  module Adapters
    
    class AbstractAdapter
      
      class InscrutableRecord < StandardError; end
      class InvalidDatabase < StandardError; end
      
      attr_reader :datastore
      
      def connect!(datastore)
        @datastore = nil
      end
      
      def query(args = {})
        []
      end
      
      def get_attribute(record, attribute)
        if record.respond_to?(attribute.to_sym)
          record.__send__(attribute.to_sym)
        elsif record.respond_to?(:[])
          record[attribute]
        else
          raise InscrutableRecord, "Attribute \"#{attribute}\" could not be extracted for record #{record.inspect}."
        end
      end
    end
    
  end
end