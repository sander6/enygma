$:.unshift File.dirname(__FILE__)

require 'api/sphinx'

require 'enygma/version'

require 'enygma/extensions/float'

require 'enygma/adapters/abstract_adapter'
require 'enygma/configuration'
require 'enygma/geodistance_proxy'
require 'enygma/search'

require 'enygma/resource'

module Enygma
  
  class << self
    
    def included(base)
      config_name = :"#{base.name.gsub(/(?!^)([A-Z])/, '_\1').upcase}_ENYGMA_CONFIGURATION"
      base.const_set(config_name, Enygma::Configuration.new) unless base.const_defined?(config_name)
      base.__send__(:extend, Enygma::ClassMethods)
      if defined?(ActiveRecord) && base.ancestors.include?(ActiveRecord::Base)
        configure_for_active_record(base)
      elsif defined?(Sequel) && base.ancestors.include?(Sequel::Model)
        configure_for_sequel_model(base)
      elsif defined?(Datamapper) && base.included_modules.include?(Datamapper::Resource)
        configure_for_datamapper_resource(base)
      end
    end

    def indexify(name)
      name.to_s =~ %r{#{Enygma::Configuration.index_suffix}$} ? name.to_s : name.to_s + Enygma::Configuration.index_suffix
    end

    private
    
    def configure_for_active_record(base)
      base.configure_enygma do
        adapter   :active_record
        table     base
      end
    end
  
    def configure_for_sequel_model(base)
      base.configure_enygma do
        adapter   :sequel
        table     base
      end
    end
  
    def configure_for_datamapper_resource(base)
      raise "Datamapper support isn't implemented yet! Sorry!"
    end
  end  

  module ClassMethods
    
    def enygma_configuration
      self.const_get(:"#{self.name.gsub(/(?!^)([A-Z])/, '_\1').upcase}_ENYGMA_CONFIGURATION")
    end
    
    def configure_enygma(&config)
      enygma_configuration.instance_eval(&config)
    end
    
    def search(table = nil)
      src = Enygma::Search.new(enygma_configuration)
      src.in(table) if table
      return src
    end
    
  end  
end