module Enygma
  
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
    
    ADAPTERS = [ :sequel, :active_record, :datamapper ]
    
    @@index_suffix = '_idx'
    def self.index_suffix(suffix = nil)
      return @@index_suffix if suffix.nil?
      @@index_suffix = suffix
    end
    
    @@target_attr = 'item_id'
    def self.target_attr(name = nil)
      return @@target_attr if name.nil?
      @@target_attr = name
    end
    
    @@adapter = nil
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
      end
    end
    
    @@database = nil    
    def self.database(db = nil)
      return @@database if db.nil?
      raise AdapterNotSet unless @@adapter
      @@database = @@adapter.connect!(db)
    end
    
    @@sphinx = { :port => 3312, :host => "localhost" }
    def self.sphinx
      @@sphinx
    end
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
    
    def self.global(&config)
      self.instance_eval(&config)
    end
    
    attr_reader :database, :adapter, :tables, :indexes, :target_attr, :match_mode, :weights, :latitude, :longitude, :resource
    
    def initialize
      @adapter      = @@adapter
      @database     = @@database
      @tables       = []
      @indexes      = {}
      @target_attr  = @@target_attr
      @match_mode   = :all
      @weights      = {}
      @latitude     = 'lat'
      @longitude    = 'lng'
      @resource     = false
    end
    
    def adapter(name = nil)
      return @adapter if name.nil?
      if name == :none
        @database = nil
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
      end      
    end
    
    def database(db = nil)
      return @database if db.nil?
      raise AdapterNotSet unless @adapter
      @database = @adapter.connect!(db)
    end
    
    def table(table_name, options = {})
      @tables << table_name unless @tables.include?(table_name)
      raise TooManyTables if @resource && @tables.size > 1
      if options[:index] || options[:indexes]
        idxs = options[:index] || options[:indexes]
        @indexes[table_name] = [ *idxs ].collect { |idx| Enygma.indexify(idx) }
      # elsif !options[:skip_index]
      #   idx = Enygma.indexify(table_name)
      #   @indexes[table_name] = [ idx ]
      end
      return @tables
    end
    
    def weight(attribute, value)
      @weights[attribute.to_s] = value
    end
    
    def index(index, table = nil)
      raise AmbiguousIndex if table.nil? && @tables.size != 1
      table ||= @tables.first
      @indexes[table] ||= []
      @indexes[table] << Enygma.indexify(index)
    end
    
    def match_mode(mode = nil)
      return @match_mode if mode.nil?
      @match_mode = mode
    end
    
    def target_attr(name = nil)
      return @target_attr if name.nil?
      @target_attr = name
    end
    
    def resource(bool = nil)
      return @resource if bool.nil?
      @resource = bool
    end
    
    def resource?
      @resource
    end
    
    def sphinx
      @@sphinx
    end
    
  end
  
end