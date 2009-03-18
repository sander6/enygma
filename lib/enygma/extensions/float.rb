module Enygma
  module Extensions
    module FloatExtensions

      def to_rad
        (self * 2.0 * Math::PI) / 360.0
      end

    end
  end
end

Float.__send__(:include, Enygma::Extensions::FloatExtensions)