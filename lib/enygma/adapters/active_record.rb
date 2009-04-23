require 'active_record'
require 'active_support'

module Enygma
  module Adapters
    
    class ActiveRecordAdapter < Enygma::Adapters::AbstractAdapter
      
      class InvalidActiveRecordDatabase < StandardError
        def message
          "The provided database object isn't an ActiveRecord::Base subclass!"
        end
      end

      def connect!(klass)        
        raise InvalidActiveRecordDatabase unless klass.is_a?(Class) && klass.ancestors.include?(ActiveRecord::Base)
        @database = klass
      end
      
      def query(*args)
        options = args.extract_options!
        @database.scoped(:conditions => { :id => options[:ids] })
      end
      
      def get_attribute(record, attribute)
        record.read_attribute(attribute)
      end

    end
  end
end