module Enygma
  
  class Search

    class InvalidFilter < StandardError
      def message
        "You can only filter on an Array or Range of values."
      end
    end

    class InvalidSphinxQuery < StandardError
      def message
        "Sphinx rejected the query; perhaps you're trying to search on a non-existent index?"
      end
    end

    class MultipleResultSetsError < StandardError
      def message
        "Results were returned for multiple tables, so some attributes are ambiguous."
      end
    end
    
    class AmbiguousIndexes < StandardError
      def message
        "You haven't specified which indexes go to which table!"
      end
    end
    
    MATCH_MODES = {
      :all        => Sphinx::Client::SPH_MATCH_ALL,
      :any        => Sphinx::Client::SPH_MATCH_ANY,
      :phrase     => Sphinx::Client::SPH_MATCH_PHRASE,
      :boolean    => Sphinx::Client::SPH_MATCH_BOOLEAN,
      :extended   => Sphinx::Client::SPH_MATCH_EXTENDED,
      :full       => Sphinx::Client::SPH_MATCH_FULLSCAN,
      :extended2  => Sphinx::Client::SPH_MATCH_EXTENDED2
    }
    
    GROUP_FUNCTIONS = {
      :day    => Sphinx::Client::SPH_GROUPBY_DAY,
      :week   => Sphinx::Client::SPH_GROUPBY_WEEK, 
      :month  => Sphinx::Client::SPH_GROUPBY_MONTH, 
      :year   => Sphinx::Client::SPH_GROUPBY_YEAR,
      :attr   => Sphinx::Client::SPH_GROUPBY_ATTR,
      :pair   => Sphinx::Client::SPH_GROUPBY_ATTRPAIR
    }
       
    def initialize(config, overrides = {})
      @db     = {
                  :adapter      => config.adapter
                }
      @sphinx = {
                  :client       => Sphinx::Client.new,
                  :indexes      => config.indexes,
                  :term         => overrides[:term] || "",
                  :target_attr  => config.target_attr,
                  :match_mode   => MATCH_MODES[config.match_mode]
                }
      
      @latitude   = config.latitude
      @longitude  = config.longitude
      @resource   = config.resource

      @sphinx[:client].SetServer(config.sphinx[:host], config.sphinx[:port])
      @sphinx[:client].SetMatchMode(@sphinx[:match_mode])

      @return_attributes  = []
      @tables             = overrides[:tables].empty? ? config.tables : overrides[:tables]
    end
    
    def run
      if @resource
        query_database(query_sphinx)
      else
        postprocess(query_database(query_sphinx))
      end
    end
    
    def method_missing(name, *args, &block)
      self.run.__send__(name, *args, &block)
    end
    
    def count
      results = query_sphinx
      if results.size == 1
        results.values.first.size
      else
        results.inject({}) { |agg, (table, matches)| agg.merge({ table => matches.size }) }
      end
    end
    
    def for(*terms)
      @sphinx[:term] = terms.join(" ")
      self      
    end
    
    def in(*tables)
      @tables = tables
      self
    end
    
    def using_match_mode(match_mode)
      @sphinx[:match_mode] = MATCH_MODES[match_mode]
      @sphinx[:client].SetMatchMode(@sphinx[:match_mode])
      self
    end

    def using_indexes(*indexes)
      case indexes
      when Hash
        @sphinx[:indexes] = indexes.inject({}) { |agg, (table, idx)| agg.merge({ table => Enygma.indexify(idx) }) }
      when Array
        raise AmbiguousIndexes unless @tables.size == 1
        @sphinx[:indexes] = { @tables.first => indexes.collect { |idx| Enygma.indexify(idx) } }
      end
      self
    end
    alias_method :using_index,  :using_indexes
        
    def filter(attribute, values, exclude = false)
      case values
      when Array
        @sphinx[:client].SetFilter(attribute, values, exclude)
      when Range
        if values.begin.is_a?(Float) || values.end.is_a?(Float)
          @sphinx[:client].SetFilterFloatRange(attribute, values.begin.to_f, values.end.to_f, exclude)
        else
          @sphinx[:client].SetFilterRange(attribute, values.begin.to_i, values.end.to_i, exclude)
        end
      when Numeric
        @sphinx[:client].SetFilterFloatRange(attribute, 0.0, values.to_f, exclude)
      else
        raise InvalidFilter
      end
      self
    end
    
    def exclude(attribute, values)
      filter(attribute, values, true)
    end
    
    def group_by(attribute, function, sort = "@group DESC")
      @sphinx[:client].SetGroupBy(attribute, GROUP_FUNCTIONS[function], sort)
      self
    end
    
    def return(*attributes)
      @return_attributes = attributes
      self
    end
    
    def select(*attributes)
      @sphinx[:client].SetSelect(attributes.join(','))
      self
    end
    
    def within(distance)
      Enygma::GeoDistanceProxy.new(self, distance)
    end
        
    def around(*args)
      if defined?(GeoRuby) && args.first.is_a?(GeoRuby::SimpleFeatures::Point)
        point = args[0]
        lat, lng = point.lat.to_rad, point.lng.to_rad
        radius = args[1]
      elsif args.first.respond_to?(:coordinates)
        point = args.shift.coordinates
        lat, lng = point.lat.to_rad, point.lng.to_rad
        radius = args[1]
      else
        lat, lng = args[0].to_rad, args[1].to_rad
        radius = args[2]
      end
      radius = (0..radius) unless radius.is_a?(Range)
      @sphinx[:client].SetGeoAnchor(@latitude, @longitude, lat, lng)
      self.filter('@geodist', radius)
    end
        
    private
    
    def geo_anchor(lat, lng)
      @sphinx[:client].SetGeoAnchor(@latitude, @longitude, lat, lng)      
    end
    
    def query_sphinx
      @tables.inject({}) do |agg, table|
        sphinx_response = @sphinx[:client].Query(@sphinx[:term], @sphinx[:indexes][table].join(', '))
        raise InvalidSphinxQuery unless sphinx_response
        agg.merge({ table => sphinx_response['matches'] })
      end
    end
    
    def query_database(results)
      if @resource
        record_ids = results.values.first.collect { |m| m['attrs'][@sphinx[:target_attr]] }.uniq
        @db[:adapter].query(:ids => record_ids)
      else
        results.inject({}) do |agg, (table, matches)|
          record_ids = matches.collect { |m| m['attrs'][@sphinx[:target_attr]] }.uniq
          agg.merge({ table => @db[:adapter].query(:table => table, :ids => record_ids) })
        end
      end
    end
    
    def postprocess(results)
      results = dehashify_results(results) if results.keys.size == 1
      results = extract_attributes(results) unless @return_attributes.empty?
      return results
    end
    
    def extract_attributes(results)
      raise MultipleResultSetsError unless results.is_a?(Array)
      if @return_attributes.size == 1
        results.collect do |record|
          @db[:adapter].get_attribute(record, @return_attributes.first)
        end
      else
        results.collect do |record|
          @return_attributes.inject({}) do |hash, attribute|
            hash.merge({ attribute => @db[:adapter].get_attribute(record, attribute) })
          end
        end
      end
    end
    
    def dehashify_results(results)
      results.respond_to?(:values) ? results.values.flatten : results
    end
  end
  
end