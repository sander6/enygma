module Enygma
  module Resource
    
    class InvalidInclusionClass < StandardError; end
    
    class << self
      def included(base)
        if defined?(ActiveRecord) && base.ancestors.include?(ActiveRecord::Base)
          configure_for_active_record(base)
        elsif defined?(Sequel) && base.ancestors.include?(Sequel::Model)
          configure_for_sequel_model(base)
        elsif defined?(Datamapper) && base.included_modules.include?(Datamapper::Resource)
          configure_for_datamapper_resource(base)
        else
          raise InvalidInclusionClass, "Enygma::Resource has to be included in a subclass of ActiveRecord::Base or Sequel::Model or a class including Datamapper::Resource! You might want to try just including Enygma."
        end
      end
    
      private
      
      def configure_for_active_record(base)
        base.__send__(:include, Enygma)
        base.configure_enygma do
          adapter   :active_record
          table     base
        end
      end
    
      def configure_for_sequel_model(base)
        base.__send__(:include, Enygma)
        base.configure_enygma do
          adapter   :sequel
          table     base
        end
      end
    
      def configure_for_datamapper_resource(base)
        raise "Datamapper support isn't implemented yet! Sorry!"
      end
    end
    
  end
end