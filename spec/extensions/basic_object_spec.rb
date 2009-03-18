require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Enygma::BasicObject do
  
  it "should descend from Object" do
    # Ruby 1.9's BasicObject doesn't descend from Object!
    Enygma::BasicObject.ancestors.should include(Object)
  end
  
  it "should include Kernel" do
    # Ruby 1.9's BasicObject doesn't include Kernel!
    Enygma::BasicObject.included_modules.should include(Kernel)
  end
  
  it "should have no instance methods except for __id__ and __send__" do
    supermethods = Enygma::BasicObject.ancestors.inject([]) do |methods, mod|
      methods += mod.instance_methods
    end.uniq - %w{ __id__ __send__ }
    methods = Enygma::BasicObject.instance_methods - supermethods
    methods.sort.should == %w{ __id__ __send__ }
  end
  
end