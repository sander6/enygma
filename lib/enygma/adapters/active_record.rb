require 'active_record'
require 'active_support'

module Enygma
  module Adapters
    
    class ActiveRecordAdapter < Enygma::Adapters::AbstractAdapter

      def connect(options)
        ActiveRecord::Base.establish_connection(options)
      end
      
      def query(*args)
        options = args.extract_options!
        raise UnknownActiveRecordClass unless defined? options[:table].to_s.constantize
        klass = options[:table].to_s.constantize
        query = klass.scoped(:conditions => { :id => options[:ids] })
        query = query.scoped(:select => options[:find_options][:select].collect(&:to_s).join(',')) if options[:find_options][:select]
      end
      
      def get_attribute(record, attribute)
        record.read_attribute(attribute)
      end

    end
    
  end
end