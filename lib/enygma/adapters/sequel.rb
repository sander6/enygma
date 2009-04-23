require 'sequel'

module Enygma
  module Adapters
    
    class SequelAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(db)
        @database = case db
        when Sequel::Model
          @table = db.table_name
          db.db
        when :sqlite
          Sequel.sqlite
        else
          Sequel.connect(db)
        end
      end
      
      def query(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        @database[options[:table] || @table].filter(:id => options[:ids])
      end
      
      def get_attribute(record, attribute)
        record[attribute]
      end
      
    end
    
  end
end