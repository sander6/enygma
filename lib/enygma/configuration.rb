module Enygma
  
  # An Enygma::Configuration object holds the data needed to perform a search query, but
  # without the query-specific parameters. You can create a Configuration object and use it
  # to configure numerous Search object with the same settings.
  class Configuration
    
    class InvalidAdapterName < StandardError
      def message
        "Invalid adapter type! Allowable adapters are #{Enygma::Configuration::ADAPTERS.join(', ')}."
      end
    end
    
    class AdapterNotSet < StandardError
      def message
        "You haven't chosen an adapter to use. Available adapters are #{Enygma::Configuration::ADAPTERS.join(', ')}."
      end
    end
    
    class TooManyTables < StandardError
      def message
        "A class including Enygma::Resource can only search on one table."
      end
    end

    class AmbiguousIndex < StandardError
      def message
        "You must specify which table goes with what index."
      end
    end
    
    # The symbol names of the valid adapter types.
    ADAPTERS = [ :sequel, :active_record, :datamapper, :memcache, :berkeley, :tokyo_cabinet ]
    
    # If all your Sphinx index names end with the same suffix (default is '_idx'), you can refer
    # to them just by their base name.
    #
    # For example, if you have two indexes names 'posts_index' and 'comments_index', declaring the
    # Enygma::Configuration.index_suffix = '_index' will allow you to refer to those indexes as
    # just :posts and :comments respectively. Such as in
    #     search(:posts).for("turkey").using_indexes(:posts, :comments)    
    def self.index_suffix(suffix = nil)
      return @@index_suffix if suffix.nil?
      @@index_suffix = suffix
    end
    @@index_suffix = '_idx'
    
    # The target_attr is the Sphinx attribute that points to the identifier for the original record
    # (usually the record's id). After querying Sphinx, Enygma will use the values returned for this
    # attribute to fetch records from the database. Defaults to 'item_id'.
    def self.target_attr(name = nil)
      return @@target_attr if name.nil?
      @@target_attr = name
    end
    @@target_attr = 'item_id'
    
    # If you're using Enygma in a bunch of different places and always using the same adapter,
    # you can declare it globally. New Configuration objects will default to using the named
    # adapter.
    def self.adapter(name = nil)
      return @@adapter if name.nil?
      if name == :none
        @@database = nil
        @@adapter = nil
        return @@adapter
      end
      raise InvalidAdapterName unless ADAPTERS.include?(name)
      case name
      when :sequel
        require 'enygma/adapters/sequel'
        @@adapter = Enygma::Adapters::SequelAdapter.new
      when :active_record
        require 'enygma/adapters/active_record'
        @@adapter = Enygma::Adapters::ActiveRecordAdapter.new
      when :datamapper
        require 'enygma/adapters/datamapper'
        @@adapter = Enygma::Adapters::DatamapperAdapter.new      
      when :memcache
        require 'enygma/adapters/memcache'
        @@adapater = Enygma::Adapters::MemcacheAdapter.new
      when :berkeley
        require 'enygma/adapters/berkeley'
        @@adapater = Enygma::Adapters::BerkeleyAdapter.new
      when :tokyo_cabinet
        require 'enygma/adapters/tokyo_cabinet'
        @@adapater = Enygma::Adapters::TokyoCabinetAdapter.new
      end
    end
    @@adapter = nil
    
    # Sets the global port and host configuration for Sphinx.
    # Defaults to { :port => 3312, :host => "localhost" }
    def self.sphinx
      @@sphinx
    end
    @@sphinx = { :port => 3312, :host => "localhost" }
    class << @@sphinx
      def port(portname = nil)
        return self[:port] if portname.nil?
        self[:port] = portname
      end
      
      def host(hostname = nil)
        return self[:host] if hostname.nil?
        self[:host] = hostname
      end
    end
    
    # Evals the block against the Enygma::Configuration class to set global configuration.
    def self.global(&config)
      self.instance_eval(&config)
    end
    
    attr_reader :indexes, :weights, :index_weights, :latitude, :longitude
    
    def initialize(attributes = {}, &block)
      @adapter        = @@adapter
      @table          = nil
      @indexes        = []
      @target_attr    = @@target_attr
      @match_mode     = :all
      @fragment_mode  = :exact
      @weights        = {}
      @index_weights  = {}
      @latitude       = 'lat'
      @longitude      = 'lng'
      @key_prefix     = nil
      attributes.each do |name, value|
        self.__send__(name, value)
      end
      self.instance_eval(&block) if block
    end
    
    def adapter(name = nil)
      return @adapter if name.nil?
      if name == :none
        @adapter = nil
        return @adapter
      end
      raise InvalidAdapterName unless ADAPTERS.include?(name)
      case name
      when :sequel
        require 'enygma/adapters/sequel'
        @adapter = Enygma::Adapters::SequelAdapter.new
      when :active_record
        require 'enygma/adapters/active_record'
        @adapter = Enygma::Adapters::ActiveRecordAdapter.new
      when :datamapper
        require 'enygma/adapters/datamapper'
        @adapter = Enygma::Adapters::DatamapperAdapter.new
      when :memcache
        require 'enygma/adapters/memcache'
        @adapter = Enygma::Adapters::MemcacheAdapter.new
      when :berkeley
        require 'enygma/adapters/berkeley'
        @adapter = Enygma::Adapters::BerkeleyAdapter.new
      when :tokyo_cabinet
        require 'enygma/adapters/tokyo_cabinet'
        @adapter = Enygma::Adapters::TokyoCabinetAdapter.new
      end
    end
    
    def datastore(store)
      raise AdapterNotSet unless @adapter
      @adapter.connect!(store)
    end
    
    def key_prefix(prefix = nil)
      return @key_prefix if prefix.nil?
      @key_prefix = prefix
    end
    
    def table(table_name = nil, options = {})
      return @table if table_name.nil?
      @table = table_name
      if idxs = options[:index] || options[:indexes]
        idx_names = [ *idxs ].collect { |idx| Enygma.indexify(idx) }
        @indexes += idx_names
      end
      return @table
    end
    
    def weight(weights = {})
      @weights = weights
    end

    def weight_index(indexes = {})
      @index_weights = indexes
    end
    
    def index(index)
      @indexes << Enygma.indexify(index)
      return @indexes
    end
    
    def match_mode(mode = nil)
      return @match_mode if mode.nil?
      @match_mode = mode
    end

    def fragment_mode(mode = nil)
      return @fragment_mode if mode.nil?
      @fragment_mode = mode
    end
    
    def target_attr(name = nil)
      return @target_attr if name.nil?
      @target_attr = name
    end
    
    def latitude_attr(name = nil)
      return @latitude if name.nil?
      @latitude = name
    end
    
    def longitude_attr(name = nil)
      return @longitude if name.nil?
      @latitude = name
    end
    
    def sphinx
      @@sphinx
    end    
  end
end