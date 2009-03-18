require 'riddle'

$:.unshift File.dirname(__FILE__)

require 'api/sphinx'

require 'enygma/version'

require 'enygma/extensions/basic_object'
require 'enygma/extensions/enumerable'
require 'enygma/extensions/float'

require 'enygma/adapters/abstract_adapter'
require 'enygma/configuration'
require 'enygma/search'

module Enygma
  
  def self.included(base)
    base.instance_variable_set(:@enygma_configuration, Enygma::Configuration.new)
    base.__send__(:extend, Enygma::ClassMethods)
  end
  
  module ClassMethods
    
    def enygma_configuration
      self.instance_variable_get(:@enygma_configuration)
    end
    
    def configure_enygma(&config)
      enygma_configuration.instance_eval(&config)
    end
    
    def search(*tables)
      Enygma::Search.new(@enygma_configuration, :tables => tables)
    end
    
  end
  
  def self.indexify(name)
    name.to_s =~ %r{#{Enygma::Configuration.index_suffix}$} ? name.to_s : name.to_s + Enygma::Configuration.index_suffix
  end
end