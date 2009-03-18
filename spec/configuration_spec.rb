require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Enygma::Configuration do
  
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
      
      it "should disconnect from the database if passed :none" do
        Enygma::Configuration.adapter(:sequel)
        Enygma::Configuration.database(:sqlite)
        Enygma::Configuration.database.should_not be_nil
        Enygma::Configuration.adapter(:none)
        Enygma::Configuration.database.should be_nil
      end
    end
    
    describe "@@database" do
      it "should default to nil" do
        Enygma::Configuration.database.should be_nil
      end
      
      it "should be set with .database" do
        Enygma::Configuration.adapter(:sequel)
        Enygma::Configuration.database(:sqlite)
        Enygma::Configuration.database.should be_a_kind_of(Sequel::Database)
      end
      
      it "should raise an error if the adapter isn't set" do
        Enygma::Configuration.adapter(:none)
        lambda { Enygma::Configuration.database(:sqlite) }.should raise_error(Enygma::Configuration::AdapterNotSet)
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
        database      :sqlite
        sphinx.port   303
        sphinx.host   'g.host'
      end
      Enygma::Configuration.index_suffix.should == '_index'
      Enygma::Configuration.target_attr.should == 'record_id'
      Enygma::Configuration.adapter.should be_an_instance_of(Enygma::Adapters::SequelAdapter)
      Enygma::Configuration.database.should be_a_kind_of(Sequel::Database)
      Enygma::Configuration.sphinx.should == { :port => 303, :host => 'g.host' }
    end
  end
  
  describe "default instance variables" do
    before(:each) do
      Enygma::Configuration.global do
        index_suffix  '_index'
        target_attr   'record_id'
        adapter       :sequel 
        database      :sqlite
        sphinx.port   303
        sphinx.host   'g.host'        
      end
      @config = Enygma::Configuration.new
    end
    
    it "should set @database to @@database" do
      @config.database.should == Enygma::Configuration.database
    end
    
    it "should set @adapter to @@adapter" do
      @config.adapter.should == Enygma::Configuration.adapter
    end
    
    it "should set @tables to []" do
      @config.tables.should == []
    end
    
    it "should set @indexes to {}" do
      @config.indexes.should == {}
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
    
    it "should add the table name given to the array of tables" do
      @config.table :things
      @config.tables.should include(:things)
    end
    
    it "should the table name to the hash of indexes" do
      @config.table :things
      @config.indexes.should have_key(:things)
    end
    
    it "should interpolate the index name for the table from the table name and default index_suffix" do
      Enygma::Configuration.index_suffix '_idx'
      @config.table :things
      @config.indexes[:things].should include('things_idx')
    end
    
    it "should add the index name (verbatim) given by :index" do
      @config.table :things, :index => :thing_index
      @config.indexes[:things].should include('thing_index')
    end
    
    it "should add the index names (verbatim) given by :indexes" do
      @config.table :things, :indexes => [ :thing_index, :thing_nicknames_index ]
      @config.indexes[:things].should include('thing_index')
      @config.indexes[:things].should include('thing_nicknames_index')
    end
    
    it "should not add the index if :skip_index is true" do
      @config.table :things, :skip_index => true
      @config.indexes.should_not have_key(:things)
    end
  end
  
  describe "index" do
    before(:each) do
      Enygma::Configuration.index_suffix '_idx'
      @config = Enygma::Configuration.new
    end
    
    it "should add the index name, massaged through Enygma.indexify, to the named table's indexes" do
      @config.index :things, :thing_nicknames
      @config.indexes.should have_key(:things)
      @config.indexes[:things].should include('thing_nicknames_idx')
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