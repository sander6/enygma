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
       
    def initialize(*args, &block)
      overrides = args.last.is_a?(Hash) ? args.pop : {}

      config = if args.first.is_a?(Enygma::Configuration)
        args.first
      elsif block_given?
        Enygma::Configuration.new(&block)
      else
        raise NoConfiguration, "You must supply an Enygma::Configuration object or definition block to create an Enygma::Search!"
      end
        
      @database = {
        :adapter  => config.adapter,
        :table    => config.table
      }
      @sphinx   = Sphinx::Client.new

      @indexes      = config.indexes
      @term         = overrides[:term] || ""
      @target_attr  = config.target_attr
      @match_mode   = MATCH_MODES[config.match_mode]
      @key_prefix   = config.key_prefix || ''
      
      @latitude   = config.latitude
      @longitude  = config.longitude

      @return_attributes  = []

      @sphinx.SetServer(config.sphinx[:host], config.sphinx[:port])
      @sphinx.SetMatchMode(@match_mode)
    end
    
    def run
      query_database(query_sphinx)
    end
    
    def method_missing(name, *args, &block)
      self.run.__send__(name, *args, &block)
    end
    
    def count
      query_sphinx['total']
    end
    
    def for(*terms)
      @term = terms.join(" ")
      self      
    end
    
    def in(table)
      @database[:table] = table
      self
    end
    
    def using_match_mode(match_mode)
      @match_mode = MATCH_MODES[match_mode]
      @sphinx.SetMatchMode(@match_mode)
      self
    end

    def using_indexes(*indexes)
      @indexes = indexes.collect { |idx| Enygma.indexify(idx) }
      self
    end
    alias_method :using_index, :using_indexes
        
    def filter(attribute, values, exclude = false)
      case values
      when Array
        @sphinx.SetFilter(attribute, values, exclude)
      when Range
        if values.begin.is_a?(Float) || values.end.is_a?(Float)
          @sphinx.SetFilterFloatRange(attribute, values.begin.to_f, values.end.to_f, exclude)
        else
          @sphinx.SetFilterRange(attribute, values.begin.to_i, values.end.to_i, exclude)
        end
      when Numeric
        @sphinx.SetFilterFloatRange(attribute, 0.0, values.to_f, exclude)
      else
        raise InvalidFilter
      end
      self
    end
    
    def exclude(attribute, values)
      filter(attribute, values, true)
    end
    
    def group_by(attribute, function, sort = "@group DESC")
      @sphinx.SetGroupBy(attribute, GROUP_FUNCTIONS[function], sort)
      self
    end
    
    def select(*attributes)
      @sphinx.SetSelect(attributes.join(','))
      self
    end
    
    def within(distance)
      Enygma::GeoDistanceProxy.new(self, distance)
    end
        
    private
    
      def geo_anchor(lat, lng)
        @sphinx.SetGeoAnchor(@latitude, @longitude, lat, lng)      
      end
    
      def query_sphinx
        sphinx_response = @sphinx.Query(@term, @indexes.join(', '))
        raise InvalidSphinxQuery unless sphinx_response
        sphinx_response
      end
        
      def query_database(results)
        ids = results['matches'].collect { |match| match['attrs'][@target_attr] }.uniq
        @database[:adapter].query(:table => @database[:table], :ids => ids, :key_prefix => @key_prefix)
      end
  end  
end