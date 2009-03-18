module Enygma
  
  class Configuration
    
    class InvalidAdapterName
      def message
        "Invalid adapter type! Allowable adapters are #{Enygma::Configuration::ADAPTERS.join(', ')}."
      end
    end
    
    ADAPTERS = [ :sequel, :active_record, :datamapper ]
    
    @@index_suffix = '_idx'
    def self.index_suffix(suffix = nil)
      return @@index_suffix if suffix.nil?
      @@index_suffix = suffix
    end
    
    @@target_attr = 'item_id'
    def target_attr(name = nil)
      return @@target_attr if name.nil?
      @@target_attr = name
    end
    
    @@adapter = nil
    def self.adapter(name = nil)
      return @@adapter if name.nil?
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
      @@adapter.connect!(db)
    end
    
    @@sphinx = { :port => 3312, :host => "localhost" }
    def self.sphinx
      @@sphinx
    end
    
    def self.global(&config)
      self.instance_eval(&config)
    end
    
    attr_reader :tables, :indexes, :adapter, :target_attr, :latitude, :longitude
    
    def initialize(database = nil, adapter = nil, tables = nil, indexes = nil, target_attr = nil, latitude = 'lat', longitude = 'lng')
      @database     = database    || @@database
      @adapter      = adapter     || @@adapter
      @tables       = tables      || []
      @indexes      = indexes     || {}
      @target_attr  = target_attr || @@target_attr
      @latitude     = latitude
      @longitude    = longitude
    end
        
    def table(table_name, options = {})
      @tables << table_name
      if options[:index] || options[:indexes]
        idxs = options[:index] || options[:indexes]
        @indexes[table_name] = [ *idxs ]
      elsif !options[:skip_index]
        idx = Enygma.indexify(table_name)
        @indexes[table_name] = [ idx ]
      end
      return @tables
    end
    
    def index(table, index)
      @indexes[table] = [ Enygma.indexify(index) ]
    end
    
    def sphinx
      @@sphinx
    end
    
  end
  
end