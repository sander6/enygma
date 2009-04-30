require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + '/../lib/enygma')
require 'spec'
require 'mocha'

Spec::Runner.configure do |config|
  config.mock_with :mocha
  
  config.before do
    Sphinx::Client.any_instance.stubs(:SetServer)
  end
end

