require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Enygma::GeoDistanceProxy do
  
  before do
    @config = Enygma::Configuration.new
    @search = Enygma::Search.new(@config)
    @distance = 1000
    @prox = Enygma::GeoDistanceProxy.new(@search, @distance)
    
    Enygma::Search.any_instance.stubs(:query_sphinx).returns({})
    Enygma::Search.any_instance.stubs(:query_database).returns([])
  end
  
  describe "initialization" do    
    describe "instance variables" do
      it "should set @delegate to the input Enygma::Search object" do
        @prox.instance_variable_get(:@delegate).should == @search
      end
      
      it "should set @distance to the given argument" do
        @prox.instance_variable_get(:@distance).should == @distance
      end
      
      it "should set @units to :meters" do
        @prox.instance_variable_get(:@units).should == :meters
      end
    end
    
    describe "initialization from an Enygma::Search object" do
      it "should return a GeoDistanceProxy when a Search is sent .within(distance)" do
        @search.within(1000).class.should == Enygma::GeoDistanceProxy
      end
      
      it "should return the original search object back when the geodistance definition is complete with .of(point)" do
        @search.within(1000).of(40.747778, -73.985556).should == @search
      end
      
      it "should allow units to be set in the middle of the chain only" do
        lambda { @search.within(1000).feet.of(40.747778, -73.985556) }.should_not raise_error(NoMethodError)
        lambda { @search.feet.within(1000).of(40.747778, -73.985556) }.should raise_error(NoMethodError)
        lambda { @search.within(1000).of(40.747778, -73.985556).feet }.should raise_error(NoMethodError)
      end
    end
  end
  
  describe "#of" do
    it "should accept a pair of lat/lng values"
    
    it "should accept an object that responds to both lat and lng"
    
    it "should accept an object that responds to #coordinates, which, in turn, responds to #lat and #lng"
    
    it "should accept an object that responds to #point, which, in turn, responds to #lat and #lng"
  end
  
  describe "unit setters" do
    it "should set @units to :meters when sent .meters" do
      @prox.meters.instance_variable_get(:@units).should == :meters
    end
    
    it "should set @units to :kilometers when sent .kilometers" do
      @prox.kilometers.instance_variable_get(:@units).should == :kilometers
    end
    
    it "should set @units to :feet when sent .feet" do
      @prox.feet.instance_variable_get(:@units).should == :feet
    end
    
    it "should set @units to :yards when sent .yards" do
      @prox.yards.instance_variable_get(:@units).should == :yards
    end
    
    it "should set @units to :miles when sent .miles" do
      @prox.miles.instance_variable_get(:@units).should == :miles
    end
  end
end