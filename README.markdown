# Enygma: a Sphinx toolset #

Sphinx is awesome, but it's sometimes kind of unwieldly to use, requiring a bunch of moving parts just to see what a certain Sphinx query would yank out of your database. Some solutions for working with Sphinx exist, but it's hard to justify spinning up an entire new Rails project just to search through some HTML documents you've got lying on your hard drive.

For this reason, Enygma exists to be an awesome little Sphinx toolset usable just about anywhere.

## Requirements ##

Eyngma requires the following things:
- Sphinx v.0.9.9rc1 or higher

For some types of geospatial searching, Enygma requires GeoRuby.

The Enygma database adapters require the related libraries. For example, the `Enygma::Adapters::ActiveRecordAdapter` requires the active_record gem, and the `Enygma::Adapters::SequelAdapter` requires the sequel gem.

## Indexing ##

For the time being, Enygma doesn't build a conf file or help set up your indexes for you.

This is actually not that hard to do yourself, and you'll find you've got much more control over what gets indexed than a Sphinx solution such as, say, thinking_sphinx offers. Read [the Sphinx documentation](http://www.sphinxsearch.com/docs/manual-0.9.9.html) for information on writing your own conf file. Once you've done it yourself, you'll feel like a genius.

That being said, Enygma plans to eventually support guided Sphinx configuration.

## Usage ##

#### Configuration ####

Take your favorite class and `include Enygma`. Then declare your global and class-specific configuration. For example:

    Enygma::Configuration.global do
      adapter   :sequel
      database  "postgres://user@localhost/db"
    end

    class SearchyThing
      include Enygma
        
      configure_enygma do
        sphinx[:host] = 'localhost'
        sphinx[:port] = 3312
        
        table :posts,     :indexes => [ :posts_idx, :comments_idx ]
        table :comments,  :indexes => [ :comments_idx ]
      end    
    end

This appends the `search` method to the included class.

#### Searching ####

To search all tables:

    SearchyThing.search.for("funtimes")

This returns a hash of results for each table.

    # => { :posts => [...], :comments => [...] }

To search a specific table:

    SearchyThing.search(:posts).for("funtimes")

This just returns an array of posts (hashes or instances of a class, depending on your adapter).

    # => [ { :id => 1, ... }, { :id => 2, ... }, ... ]

Adding filters:

    SearchyThing.search(:comments).for("funtimes").filter("post_id", 1..10)
    SearchyThing.search(:comments).for("funtimes").exclude("post_id", 50..100)

Returning only certain attributes from the matches records:

    SearchyThing.search(:comments).for("funtimes").return(:author_id)

Iterating over the records:

    SearchyThing.search(:posts).for("funtimes").each do |post|
      post.tag!(Tag.new("funtimes!"))
    end

#### Geospatial Searching ####

Enygma's geospatial searching abilities are naive at present.

To search in a given radius of a latitude/longitude pair:

    SearchyThing.search(:places).around(40.747778, -73.985556, 500)

Where `500` means 500 meters. Latitudes and longitudes should be given in degrees, which will be converted to the radians required by Sphinx.

Instead of a lat/lng pair, you can pass a GeoRuby::SimpleFeatures::Point.

    point = GeoRuby::SimpleFeatures::Point.from_lon_lat(-73.985556, 40.747778)
    SearchyThing.search(:places).around(point, 500)

Or you can pass any object which responds to `coordinates`, which should in turn respond to both `lat` and `lng` (good for, say, ActiveRecord models with a point attribute).

    arbys = Place.filter(:name => "Arby's").first
    SearchyThing.search(:places).around(arbys, 500)

Should you want to, you can search within an annulus (the area bewteen two concentric circles) by passing a range as the radius argument.

    SearchyThing.search(:places).around(point, 500..1000)

***
## Speculative features ##


### Resources ###

Subclasses of ActiveRecord::Base and Sequel::Model and classes including Datamapper::Resource can be extended using Enygma::Resource to give them searching superpowers.

Including Enygma::Resource in one of the above types of classes will relfect on the table associated with the class and automatically scope Enygma searches to that table and its related indexes.

    class Post < ActiveRecord::Base
      include Enygma::Resource
    end
    
    Post.search.for("turkey").each { |post| puts post.title }

Classes with Enygma::Resource can call `include` to include assocations with their results.

    Post.search.for("turkey").include(:comments)

More in-depth per-adapter superpowers detailed below:

#### ActiveRecord::Base ####

An ActiveRecord::Base subclass that includes Enygma::Resource will, instead of returning the actual results of the database query, return an anonymous scope searching for record ids in the set of ids returned by Sphinx. This helps ease integration with will\_paginate, as well as allowing the appending of additional named\_scopes (should you want to).

#### Sequel::Model ####

Like above, a Sequel::Model with Enygma::Resource will not automatically kick off the query, but just return a prepared Sequel::Query object for further filtering.

#### Datamapper ####

Nothing special about Datamapper so far.