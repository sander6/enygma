Gem::Specification.new do |s|
    s.platform          =   Gem::Platform::RUBY
    s.name              =   "enygma"
    s.version           =   "0.0.7"
    s.author            =   "Sander Hartlage"
    s.email             =   "sander6 at github dot com"
    s.homepage          =   "http://github.com/sander6/enygma"
    s.summary           =   "A Sphinx search toolset"
    s.has_rdoc          =   true
    s.extra_rdoc_files  =   ["README.markdown"]
    s.files             =   %w{
      README.markdown
      Rakefile
      lib/enygma.rb
      lib/api/sphinx.rb
      lib/api/sphinx/client.rb
      lib/api/sphinx/request.rb
      lib/api/sphinx/response.rb
      lib/enygma/configuration.rb
      lib/enygma/geodistance_proxy.rb
      lib/enygma/resource.rb
      lib/enygma/search.rb
      lib/enygma/version.rb
      lib/enygma/adapters/abstract_adapter.rb
      lib/enygma/adapters/active_record.rb
      lib/enygma/adapters/berkeley.rb
      lib/enygma/adapters/datamapper.rb
      lib/enygma/adapters/memcache.rb
      lib/enygma/adapters/sequel.rb
      lib/enygma/adapters/tokyo_cabinet.rb
      lib/enygma/extensions/float.rb
      spec/configuration_spec.rb
      spec/enygma_spec.rb
      spec/geodistance_proxy_spec.rb
      spec/search_spec.rb
      spec/spec_helper.rb
      spec/version_spec.rb
      spec/adapters/abstract_adapter_spec.rb
      spec/adapters/active_record_spec.rb
      spec/adapters/datamapper_spec.rb
      spec/adapters/sequel_spec.rb
      spec/extensions/float_spec.rb
    }
end
