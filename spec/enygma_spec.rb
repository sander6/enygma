require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Enygma do
  
  describe "including the module" do
    before(:each) do
      class Thing; end
    end
    
    it "should set <class_name>_ENYGMA_CONFIGURATION on the base class" do
      Thing.__send__(:include, Enygma)
      Thing.const_defined?(:THING_ENYGMA_CONFIGURATION).should be_true
    end
    
    it "should extend the base class with Enygma::ClassMethods" do
      Thing.expects(:extend).with(Enygma::ClassMethods)
      Thing.__send__(:include, Enygma)
    end
  end
  
  describe "enygma_configuration" do
    before(:each) do
      class Thing; include Enygma; end
    end
    
    it "should return the class' <class_name>_ENYGMA_CONFIGURATION" do
      Thing.enygma_configuration.should == Thing.const_get(:THING_ENYGMA_CONFIGURATION)
    end
    
    it "should be an instance of Enygma::Configuration" do
      Thing.enygma_configuration.should be_an_instance_of(Enygma::Configuration)
    end
  end
  
  describe "configure_enygma" do
    before(:each) do
      class Thing; include Enygma; end
    end
    
    it "should instance_eval the block against the class' @enygma_configuration" do
      Thing.enygma_configuration.expects(:instance_eval)
      Thing.configure_enygma { }
    end
  end
  
  describe "search" do
    before(:each) do
      class Thing; include Enygma; end
    end
    
    it "should return an instance of Enygma::Search" do
      Thing.search.should be_an_instance_of(Enygma::Search)
    end
  end
  
  describe ".indexify" do
    before(:each) do
      Enygma::Configuration.index_suffix '_index'
    end
    
    it "should append the default index suffix to the argument" do
      Enygma.indexify('butter').should == 'butter_index'
    end
    
    it "should convert symbols into strings" do
      Enygma.indexify(:butter).should == 'butter_index'
    end
    
    it "should leave arguments that already end in the default suffix alone" do
      Enygma.indexify(:butter_index).should == 'butter_index'
    end
  end
  
end