Gem::Specification.new do |s|
    s.platform          =   Gem::Platform::RUBY
    s.name              =   "enygma"
    s.version           =   "0.0.6"
    s.author            =   "Sander Hartlage"
    s.email             =   "sander6 at github dot com"
    s.homepage          =   "http://github.com/sander6/enygma"
    s.rubyforge_project =   ""
    s.summary           =   "A Sphinx search toolset"
    s.files             =   %w( README.markdown Rakefile ) + Dir["{lib,spec}/**/*"]
    s.require_path      =   "lib"
    s.test_files        =   Dir.glob('tests/*.rb')
    s.has_rdoc          =   true
    s.extra_rdoc_files  =   ["README.markdown"]
end
