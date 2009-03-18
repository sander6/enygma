module Enygma
  module Version
    MAJOR = 0
    MINOR = 0
    TINY  = 2
    
    STRING = [MAJOR, MINOR, TINY].join('.')
  end
  
  def self.version
    Enygma::Version::STRING
  end
end