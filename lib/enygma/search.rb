module Enygma
  
  class Search

    class InvalidFilter < StandardError; end

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
    
    instance_methods.each { |m| undef_method m unless %w{ __id__ __send__ }.include?(m) }
    
    def initialize(config, overrides = {})
      @config = config
      @db = {
              :adapter      => @config.adapter
            }
      @sphinx = {
                  :client       => Sphinx::Client.new,
                  :indexes      => @config.indexes,
                  :term         => overrides[:term] || "",
                  :target_attr  => @config.target_attr,      
                }
      
      @sphinx[:client].SetServer(@config.sphinx[:host], @config.sphinx[:port])
      @sphinx[:client].SetMatchMode(MATCH_MODES[:all])
      
      @tables       = overrides[:tables] || @config.tables
      
      @postprocess  = [ Proc.new { |object| object } ]
      @postprocess << Proc.new { |results_hash| results_hash[@tables.first] } if @tables.size == 1
    end
    
    def run
      __postprocess__(__query_database__(__query_sphinx__))
    end
    
    def method_missing(name, *args, &block)
      self.run.__send__(name, *args, &block)
    end    
    
    def count
      results = __query_sphinx__
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
      if @tables.size == 1
        @postprocess << Proc.new { |results_hash| results_hash[@tables.first] }
      end
      self
    end
    
    def using_match_mode(match_mode)
      @sphinx[:client].SetMatchMode(MATCH_MODES[@sphinx[:match_mode]])
      self
    end

    def using_indexes(*indexes)
      @sphinx[:indexes] = indexes.collect { |idx| Enygma.indexify(idx) }
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
      if attributes.size == 1
        @postprocess << Proc.new { |records|
          records.collect do |record|
            @db[:adapter].get_attribute(record, attributes.first)
          end
        }
      else
        @postprocess << Proc.new { |records|
          records.collect do |record|
            attributes.inject({}) do |hash, attribute|
              hash.merge({ attribute => @db[:adapter].get_attribute(record, attribute) })
            end
          end
        }
      end
      self
    end
    
    def select(*attributes)
      @sphinx[:client].SetSelect(attributes.join(','))
      self
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
      @sphinx[:client].SetGeoAnchor(@config.latitude, @config.longitude, lat, lng)
      self.filter('@geodist', radius)
    end
        
    private
    
    def __query_sphinx__
      @tables.inject({}) do |agg, table|
        sphinx_response = @sphinx[:client].Query(@sphinx[:term], @sphinx[:indexes][table].join(', '))
        agg.merge({ table => sphinx_response['matches'] })
      end
    end
    
    def __query_database__(results)
      results.inject({}) do |agg, (table, matches)|
        record_ids = matches.collect { |m| m['attrs'][@sphinx[:target_attr]] }.uniq
        agg.merge({ table => @db[:adapter].query(:table => table, :ids => record_ids, :find_options => @db) })
      end
    end
    
    def __postprocess__(results)
      @postprocess.inject(results) { |results, process| process[results] }
    end    
  end
  
end