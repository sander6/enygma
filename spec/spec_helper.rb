require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../lib/enygma')
require 'spec'
require 'mocha'

module SpecHelpers
  
  def stub_sphinx!
    Enygma::Search.any_instance.stubs(:__query_sphinx__).returns({})
  end
  
  def stub_database!
    Enygma::Search.any_instance.stubs(:__query_database__).returns({})
  end
  
end

Spec::Runner.configure do |config|
  config.mock_with :mocha
  config.include(SpecHelpers)
end

