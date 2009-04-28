require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Enygma::Configuration do
  
  describe Enygma::Configuration::InvalidAdapterName do
    it "should be raised when the adapter is set to something not supported" do
      lambda { Enygma::Configuration.adapter(:skull_of_orm) }.should raise_error(Enygma::Configuration::InvalidAdapterName)
    end
    
    it "should come with a message along the lines of 'Invalid adapter type!'" do
      Enygma::Configuration::InvalidAdapterName.new.message.should =~ Regexp.new("Invalid adapter type!")
    end
  end

  describe Enygma::Configuration::AdapterNotSet do
    before do
      @config = Enygma::Configuration.new
    end

    it "should be raised when trying to connect to a database when an adapter isn't set" do
      lambda {
        @config.adapter(:none)
        @config.datastore("postgres://user@localhost/database")
      }.should raise_error(Enygma::Configuration::AdapterNotSet)
    end
    
    it "should come with a message along the lines of 'You haven't chosen an adatper to use.'" do
      Enygma::Configuration::AdapterNotSet.new.message.should =~ Regexp.new("You haven't chosen an adapter to use.")
    end
  end
  
  describe "class variables" do
    
    describe "@@index_suffix" do
      it "should default to '_idx'" do
        Enygma::Configuration.index_suffix.should == '_idx'
      end
      
      it "should be set with .index_suffix" do
        Enygma::Configuration.index_suffix('_index')
        Enygma::Configuration.index_suffix.should == '_index'
      end
    end

    describe "@@target_attr" do
      it "should default to 'item_id'" do
        Enygma::Configuration.target_attr.should == 'item_id'
      end
      
      it "should be set with .target_attr" do
        Enygma::Configuration.target_attr('record_id')
        Enygma::Configuration.target_attr.should == 'record_id'
      end
    end
    
    describe "@@adapter" do
      it "should default to nil" do
        Enygma::Configuration.adapter.should be_nil
      end
      
      it "should be set with .adapter" do
        Enygma::Configuration.adapter(:sequel)
      end
      
      it "should return the adapter after being set" do
        Enygma::Configuration.adapter(:sequel)
        Enygma::Configuration.adapter.should be_an_instance_of(Enygma::Adapters::SequelAdapter)
      end
      
      it "should raise an error if the adapter isn't available" do
        lambda { Enygma::Configuration.adapter(:skull_of_orm) }.should raise_error(Enygma::Configuration::InvalidAdapterName)
      end
      
      it "should reset the adapter to nil if passed :none" do
        Enygma::Configuration.adapter(:sequel)
        Enygma::Configuration.adapter.should_not be_nil
        Enygma::Configuration.adapter(:none)
        Enygma::Configuration.adapter.should be_nil
      end
    end
    
    describe "@@sphinx" do
      it "should default to { :port => 3312, :host => 'localhost' }" do
        Enygma::Configuration.sphinx.should == { :port => 3312, :host => 'localhost' }
      end
      
      it "should return the sphinx configuration hash with .sphinx" do
        Enygma::Configuration.sphinx.should be_an_instance_of(Hash)
      end
      
      it "should be able to be set on a per-key basis just like any other hash" do
        Enygma::Configuration.sphinx[:port] = 303
        Enygma::Configuration.sphinx[:host] = 'g.host'
        Enygma::Configuration.sphinx.should == { :port => 303, :host => 'g.host' }
      end
      
      it "should respond to #port and #host to allow pretty configuration" do
        Enygma::Configuration.sphinx.should respond_to(:port)
        Enygma::Configuration.sphinx.should respond_to(:host)
      end
      
      it "should be able to be configured using the accessor methods instead of []" do
        Enygma::Configuration.sphinx.port(303)
        Enygma::Configuration.sphinx.host('g.host')
        Enygma::Configuration.sphinx.should == { :port => 303, :host => 'g.host' }
      end
    end    
  end

  describe ".global" do
    it "should instance_eval self against the block" do
      Enygma::Configuration.expects(:instance_eval)
      Enygma::Configuration.global { }
    end
  
    it "should set the proper class variable using the accessors" do
      Enygma::Configuration.global do
        index_suffix  '_index'
        target_attr   'record_id'
        adapter       :sequel 
        sphinx.port   303
        sphinx.host   'g.host'
      end
      Enygma::Configuration.index_suffix.should == '_index'
      Enygma::Configuration.target_attr.should == 'record_id'
      Enygma::Configuration.adapter.should be_an_instance_of(Enygma::Adapters::SequelAdapter)
      Enygma::Configuration.sphinx.should == { :port => 303, :host => 'g.host' }
    end
  end
  
  describe "default instance variables" do
    before(:each) do
      Enygma::Configuration.global do
        index_suffix  '_index'
        target_attr   'record_id'
        adapter       :sequel 
        sphinx.port   303
        sphinx.host   'g.host'        
      end
      @config = Enygma::Configuration.new
    end
    
    it "should set @adapter to @@adapter" do
      @config.adapter.should == Enygma::Configuration.adapter
    end
    
    it "should set @table to nil" do
      @config.table.should be_nil
    end
    
    it "should set @indexes to []" do
      @config.indexes.should be_an_instance_of(Array)
      @config.indexes.should be_empty
    end
    
    it "should set @target_attr to @@target_attr" do
      @config.target_attr.should == Enygma::Configuration.target_attr
    end
    
    it "should set @weights to {}" do
      @config.weights.should == {}
    end
    
    it "should set @latitude to 'lat'" do
      @config.latitude.should == 'lat'
    end
    
    it "should set @longitude to 'lng'" do
      @config.longitude.should == 'lng'
    end
  end
  
  describe "sphinx" do
    before(:each) do
      @config = Enygma::Configuration.new
    end
    
    it "should return the class default sphinx configuration" do
      @config.sphinx.should == Enygma::Configuration.sphinx
    end
  end
  
  describe "table" do
    before(:each) do
      @config = Enygma::Configuration.new
    end
    
    it "should set the name as the default table" do
      @config.table :things
      @config.table.should == :things
    end    
  end
  
  describe "index" do
    before(:each) do
      Enygma::Configuration.index_suffix '_idx'
      @config = Enygma::Configuration.new
    end
    
    it "should add the index name, massaged through Enygma.indexify, to the named table's indexes" do
      @config.index :things
      @config.indexes.should include(Enygma.indexify(:things))
    end
  end
  
  describe "weight" do
    before(:each) do
      @config = Enygma::Configuration.new
    end
    
    it "should add the given weight to the given attribute to the hash of weights" do
      @config.weight :name, 20
      @config.weights.should have_key('name')
      @config.weights['name'].should == 20
    end
  end
end