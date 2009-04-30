module Enygma
  class GeoDistanceProxy
    
    class InvalidUnits < StandardError; end
    
    failproc = Proc.new { |d| raise(InvalidUnits, "\"#{d}\" is not a supported distance unit.") }
    
    UNIT_CONVERSION = Hash.new(failproc).merge({
      :meters     => Proc.new { |d| d },
      :kilometers => Proc.new { |d| d / 1000.0 },
      :feet       => Proc.new { |d| d * 0.3048 },
      :miles      => Proc.new { |d| d / 1609.344 },
      :yards      => Proc.new { |d| d * 0.9144 }
    })
  
    def initialize(delegate, distance)
      @delegate = delegate
      @distance = distance
      @units = :meters
    end
  
    def meters
      @units = :meters
      self
    end
    
    def kilometers
      @units = :kilometers
      self
    end
    
    def feet
      @units = :feet
      self
    end
    
    def miles
      @units = :miles
      self
    end
    
    def yards
      @units = :yards
      self
    end
  
    def of(point_or_lat, lng = nil)
      if lng.nil?
        if point_or_lat.respond_to?(:lat) && point_or_lat.respond_to?(:lng)
          lat, lng = point_or_lat.lat, point_or_lat.lng
        elsif point_or_lat.respond_to?(:coordinates) && point_or_lat.coordinates.respond_to?(:lat) && point_or_lat.coordinates.respond_to?(:lng)
          lat, lng = point_or_lat.coordinates.lat, point_or_lat.coordinates.lng
        elsif point_or_lat.respond_to?(:point) && point_or_lat.point.respond_to?(:lat) && point_or_lat.point.respond_to?(:lng)
          lat, lng = point_or_lat.point.lat, point_or_lat.point.lng
        else
          raise ArgumentError, "#{point_or_lat.inspect} doesn't seem to be a geometry-enabled object!"
        end
      else
        lat, lng = point_or_lat, lng
      end
      @delegate.__send__(:geo_anchor, lat, lng)
      @delegate.filter('@geodist', UNIT_CONVERSION[@units][@distance])
      @delegate
    end
  end
end