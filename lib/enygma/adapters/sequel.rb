require 'sequel'

module Enygma
  module Adapters
    
    class SequelAdapter < Enygma::Adapters::AbstractAdapter
      
      class InvalidTable < StandardError; end
      
      def connect!(datastore)
        @datastore = case datastore
        when Sequel::Model
          @table = datastore.table_name
          datastore.db
        when Sequel::Database
          datastore
        when :sqlite
          Sequel.sqlite
        else
          Sequel.connect(datastore)
        end
      end
      
      def query(args = {})
        get_table(args[:table]).filter(:id => args[:ids])
      end
      
      def get_attribute(record, attribute)
        record[attribute]
      end
      
      private
      
      def get_table(obj = nil)
        case obj
        when Symbol
          @datastore ? @datastore[obj] : raise(InvalidTable)
        when String
          @datastore ? @datastore[obj.to_sym] : raise(InvalidTable)
        when Sequel::Model
          obj
        when Sequel::Database
          @table ? obj[@table] : raise(InvalidTable)
        else
          raise InvalidTable
        end
      end
    end
    
  end
end