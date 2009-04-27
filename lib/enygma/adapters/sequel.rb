require 'sequel'

module Enygma
  module Adapters
    
    class SequelAdapter < Enygma::Adapters::AbstractAdapter
      
      # def connect!(datastore)
      #   @datastore = case datastore
      #   when Sequel::Model
      #     @table = datastore.table_name
      #     datastore.db
      #   end
      # end
      # 
      # def query(args = {})
      #   @datastore[args[:datastore]].filter(:id => args[:ids])
      # end
      # 
      # def get_attribute(record, attribute)
      #   record[attribute]
      # end
      
    end
    
  end
end