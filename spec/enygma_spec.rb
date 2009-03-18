require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Enygma do
  
  describe "including the module" do
    before(:each) do
      class Thing; end
    end
    
    it "should set @enygma_configuration on the base class" do
      Thing.__send__(:include, Enygma)
      Thing.instance_variable_defined?(:@enygma_configuration).should be_true
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
    
    it "should return the class' @enygma_configuration" do
      Thing.enygma_configuration.should == Thing.instance_variable_get(:@enygma_configuration)
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
      stub_sphinx!
      class Thing; include Enygma; end
    end
    
    it "should return an instance of Enygma::Search" do
      Enygma::Search.expects(:new)
      Thing.search
    end
  end
  
  describe ".indexify" do
    before(:each) do
      Enygma::Configuration.index_suffix '_idx'
    end
    
    it "should append the default index suffix to the argument" do
      Enygma.indexify('butter').should == 'butter_idx'
    end
    
    it "should convert symbols into strings" do
      Enygma.indexify(:butter).should == 'butter_idx'
    end
    
    it "should leave arguments that already end in the default suffix alone" do
      Enygma.indexify(:butter_idx).should == 'butter_idx'
    end
  end
  
end