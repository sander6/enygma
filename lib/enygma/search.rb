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

    SORT_MODES = {
      :relevance      => Sphinx::Client::SPH_SORT_RELEVANCE,
      :date_desc      => Sphinx::Client::SPH_SORT_ATTR_DESC,
      :date_asc       => Sphinx::Client::SPH_SORT_ATTR_ASC,
      :time_segments  => Sphinx::Client::SPH_SORT_TIME_SEGMENTS,
      :extended       => Sphinx::Client::SPH_SORT_EXTENDED,
      :expression     => Sphinx::Client::SPH_SORT_EXPR
    }

    class InvalidFragementMatchingScheme < StandardError; end

    frag_proc = Proc.new { |s| raise InvalidFragementMatchingScheme }
    FRAGMENT_MODES = Hash.new(frag_proc).merge({
      :exact    => Proc.new { |s| s },
      :start    => Proc.new { |s| s.split(/\s+/).collect {|f| f + '*'}.join(' ') },
      :end      => Proc.new { |s| s.split(/\s+/).collect {|f| '*' + f }.join(' ') },
      :fragment => Proc.new { |s| s.split(/\s+/).collect {|f| '*' + f + '*' }.join(' ') },
      :fuzzy    => Proc.new { |s| '*' + s.delete(' ').split(//).join('*') + '*' },
      :textmate => Proc.new { |s| '*' + s.delete(' ').split(//).join('*') + '*' }
    })
       
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

      @indexes        = config.indexes
      @term           = overrides[:term] || ""
      @target_attr    = config.target_attr
      @match_mode     = MATCH_MODES[config.match_mode]
      @fragment_mode  = config.fragment_mode
      @key_prefix     = config.key_prefix || ''
      
      @latitude   = config.latitude
      @longitude  = config.longitude

      @limit      = @sphinx.instance_variable_get(:@limit)
      @offset     = @sphinx.instance_variable_get(:@offset)
      @max        = @sphinx.instance_variable_get(:@maxmatches)
      @cutoff     = @sphinx.instance_variable_get(:@cutoff)

      @weights        = config.weights.inject({}) { |weights, (attr, weight)| weights.merge({ attr.to_s => weight })} || {}
      @index_weights  = config.index_weights.inject({}) { |weights, (index, weight)| weights.merge({ Enygma.indexify(index) => weight })} || {}
      @sphinx.SetFieldWeights(@weights)
      @sphinx.SetIndexWeights(@index_weights)

      @fields = []

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
    
    def in_fields(*fields)
      @fields = fields
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
    
    def using_fragment_matching(mode)
      @fragment_mode = mode
      self
    end
    
    def filter(attribute, values, exclude = false)
      attribute = attribute.to_s
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
    
    def sort_by(type, sort_by = '')
      case type
      when :date
        if arg == :asc
          sort_mode = :date_asc
        else
          sort_mode = :date_desc
        end
      when :time
        sort_mode = :time_segments
      when :expression
        sort_mode = :expression
      when String
        sort_mode = :extended
        sort_by = type
      else
        sort_mode = :relevance
      end
      @sphinx.SetSortMode(SORT_MODES[sort_mode], sort_by)
      self
    end
    
    def select(*attributes)
      @sphinx.SetSelect(attributes.join(','))
      self
    end
    
    def limit(value)
      @limit = value
      set_limits
      self
    end
    
    def offset(value)
      @offset = value
      set_limits
      self
    end
    
    def max(value)
      @max = value
      set_limits
      self
    end
    
    def cutoff(value)
      @cutoff = value
      set_limits
      self
    end

    def weight(weights = {})
      @weights.merge!(weights.inject({}) { |weights, (attr, weight)| weights.merge({ attr.to_s => weight })})
      @sphinx.SetFieldWeights(@weights)
      self
    end

    def weight_index(weights = {})
      @index_weights.merge!(weights.inject({}) { |weights, (index, weight)| weights.merge({ Enygma.indexify(index) => weight })})
      @sphinx.SetIndexWeights(@index_weights)
      self
    end
    
    def within(distance)
      Enygma::GeoDistanceProxy.new(self, distance)
    end
    
    def anchor(point_or_lat, lng = nil)
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
      geo_anchor(lat, lng)
      self
    end
    
    private
    
    def geo_anchor(lat, lng)
      @sphinx.SetGeoAnchor(@latitude, @longitude, lat, lng)      
    end
  
    def set_limits
      @sphinx.SetLimits(@offset, @limit, @max, @cutoff)
    end
  
    def query_sphinx
      query_string  = mutate_query_for_field_searching(@term)
      query_string  = FRAGMENT_MODES[@fragment_mode][query_string]
      query_indexes = @indexes.join(', ')
      sphinx_response = @sphinx.Query(query_string, query_indexes)
      raise InvalidSphinxQuery unless sphinx_response
      sphinx_response
    end
      
    def query_database(results)
      ids = results['matches'].collect { |match| match['attrs'][@target_attr] }.uniq
      @database[:adapter].query(:table => @database[:table], :ids => ids, :key_prefix => @key_prefix)
    end
    
    def mutate_query_for_field_searching(query)
      return query if @fields.empty?
      self.using_match_mode(:extended2)
      "@(#{@fields.collect {|f| f.to_s}.join(',')}) #{query}"
    end
  end  
end