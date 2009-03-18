module Enygma
  module Extensions
    module EnumerableExtensions
      
      def group_by
        
      end
      
    end
  end
end

Enumerable.__send__(:include, Enygma::Extensions::EnumerableExtensions)