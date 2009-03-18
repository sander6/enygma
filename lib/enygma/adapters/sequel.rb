require 'sequel'

module Enygma
  module Adapters
    
    class SequelAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(db)
        if db == :sqlite
          @database = Sequel.sqlite
        else
          @database = Sequel.connect(db)
        end
      end
      
      def query(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        query = @database[options[:table]].filter(:id => options[:ids])
        query.select(*options[:find_options][:select]) if options[:find_options][:select]
        query.all
      end
      
      def get_attribute(record, attribute)
        record[attribute]
      end
      
    end
    
  end
end