require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Enygma::BasicObject do
  
  it "should have no instance methods except for __id__ and __send__" do
    supermethods = Enygma::BasicObject.ancestors.inject([]) do |methods, mod|
      methods += mod.instance_methods
    end.uniq
    methods = Enygma::BasicObject.instance_methods - supermethods
    methods.sort == %w{ __id__ __send__ }
  end
  
end