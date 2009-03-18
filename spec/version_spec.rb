require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Enygma::Version do
  
  it "should have MAJOR, MINOR, TINY, and STRING constants" do
    Enygma::Version.const_defined?(:MAJOR).should be_true
    Enygma::Version.const_defined?(:MINOR).should be_true
    Enygma::Version.const_defined?(:TINY).should be_true
    Enygma::Version.const_defined?(:STRING).should be_true
  end
  
  it "should define STRING to be 'MAJOR.MINOR.TINY'" do
    Enygma::Version::STRING.should == [ Enygma::Version::MAJOR, Enygma::Version::MINOR, Enygma::Version::TINY ].join('.')
  end
  
  it "should define Enygma.version to be Enygma::Version::STRING" do
    Enygma.version.should == Enygma::Version::STRING
  end
  
end