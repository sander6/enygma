require 'tokyocabinet'

module Enygma
  module Adapters
    
    class TokyoCabinetAdapter < Enygma::Adapters::AbstractAdapter
      
      def connect!(db)
        @database = case db
        when TokyoCabinet::HDB
          db
        when TokyoCabinet::BDB
          db
        when TokyoCabinet::FDB
          db
        when TokyoCabinet::TDB
          db
        when String
          unless File.exist?(db)
            raise InvalidDatabase, "The Tokyo Cabinet database couldn't be found."
          end
          case db
          when /\.tch$/
            tkcab = TokyoCabinet::HDB.new
            tkcab.open(db, TokyoCabinet::HDB::OWRITER | TokyoCabinet::HDB::OCREAT)
            tkcab
          when /\.tcb$/
            tkcab = TokyoCabinet::BDB.new
            tkcab.open(db, TokyoCabinet::BDB::OWRITER | TokyoCabinet::BDB::OCREAT)
            tkcab
          when /\.tcf$/
            tkcab = TokyoCabinet::FDB.new
            tkcab.open(db, TokyoCabinet::FDB::OWRITER | TokyoCabinet::FDB::OCREAT)
            tkcab
          when /\.tct$/
            tkcab = TokyoCabinet::TDB.new
            tkcab.open(db, TokyoCabinet::TDB::OWRITER | TokyoCabinet::TDB::OCREAT)
            tkcab            
          else
            "The Tokyo Cabinet database type couldn't be inferred from the name given."
          end
        else
          raise InvalidDatabase, "The Tokyo Cabinet database couldn't be found."
        end
      end
      
      def query(args = {})
        prefix = args[:key_prefix] || ''
        args[:ids] ||= []
        args[:ids].collect do |i|
          value = @database.get("#{prefix}#{i}")
          begin
            Marshal.load(value)
          rescue TypeError
            value
          end
        end
      end
      
      def get_attribute(record, attribute)
        if record.respond_to?(attribute.to_sym)
          record.__send__(attribute.to_sym)
        elsif record.respond_to?(:[])
          record[attribute]
        else
          record
        end
      end
    end
  end
end