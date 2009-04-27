require 'active_record'
require 'active_support'

module Enygma
  module Adapters
    
    class ActiveRecordAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(datastore)
        unless datastore.is_a?(Class) && datastore.ancestors.include?(ActiveRecord::Base)
          raise InvalidDatabase, "#{datastore.inspect} is not an ActiveRecord::Base subclass!"
        end
        @datastore = datastore
      end
      
      def query(args = {})
        connect!(args[:datastore])
        @datastore.scoped(:conditions => { :id => args[:ids] })
      end
      
      def get_attribute(record, attribute)
        record.read_attribute(attribute)
      end

    end
  end
end