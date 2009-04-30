module Enygma
  module Version
    MAJOR = 0
    MINOR = 1
    TINY  = 0 
    
    STRING = [MAJOR, MINOR, TINY].join('.')
  end
  
  def self.version
    Enygma::Version::STRING
  end
end
