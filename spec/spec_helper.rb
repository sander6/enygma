require 'rubygems'
require 'spec'
require File.expand_path(File.dirname(__FILE__) + '/../lib/enygma')
require 'mocha'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end

Enygma::Configuration.global do
  adapter   :sequel
  database  :sqlite
end