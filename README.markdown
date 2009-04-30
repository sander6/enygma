# Enygma: a Sphinx toolset #

*NOTE: Enygma is currently in a state of disarray, since I hacked it together just enough to work with ActiveRecord. The specs shouldn't run and coverage is inexcusable, which I feel bad about. I'll clean things up incrementally. Until then, consider it in alpha.*

*ANOTHER NOTE: This documentation is unfinished and a little wanky. I'll improve it when time allows. The best way right now to figure out how to use Enygma is to look through the code.*

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

Take your favorite class and `include Enygma`, then give it class-level configuration by calling `configure_enygma`. This will save a constant in the class called `<class_name>_ENYGMA_CONFIGURATION` holding the configuration


    Enygma::Configuration.global do
      adapter       :sequel
      datastore     "postgres://user@localhost/db"
      sphinx.host   'localhost'
      sphinx.port   3312
    end

    class SearchyThing
      include Enygma
        
      configure_enygma do        
        table :posts, :indexes => [ :posts, :comments ]
      end    
    end

This appends the `search` method to the included class.

#### Searching ####

To search, call the `search` method on a class that included Enygma. The way searching works depends a lot on both the kind of class you've included Enygma in and the type of datastore adapter you're using. The fundamentals are the same, though.

For a plain ol' Ruby class, like a controller, call `search` and tell it where to go find the actual objects after it's retrieved the pointers from Sphinx. An example using the `active_record` adapter:

    class PostsController < ApplicationController
      include Enygma
      
      configure_enygma do
        adapter   :active_record
      end
    
      def index
        @posts = search(Post).for(params[:term]).using_index(:posts)
      end
    end
    
An example using the `sequel` adapter:

    include Enygma

    configure_enygma do
      adapter :sequel
    end

    get '/posts' do
      @posts = search(:posts).for(params[:term]).using_index(:posts)
    end

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

    SearchyThing.search(:places).within(500).of(40.747778, -73.985556)

Where `500` means 500 meters. You can set different units like so:

    SearchyThing.search(:places).within(1000).feet.of(40.747778, -73.985556)

Latitudes and longitudes should be given in degrees, which will be converted to the radians required by Sphinx.

Instead of a lat/lng pair, you can pass a GeoRuby::SimpleFeatures::Point.

    point = GeoRuby::SimpleFeatures::Point.from_lon_lat(-73.985556, 40.747778)
    SearchyThing.search(:places).within(500).of(point)

Or you can pass any object which responds to `coordinates`, which should in turn respond to both `lat` and `lng` (good for, say, ActiveRecord models with a point attribute).

    arbys = Place.filter(:name => "Arby's").first
    SearchyThing.search(:places).within(500).of(arbys)

Should you want to, you can search within an annulus (the area between two concentric circles) by passing a range as the radius argument.

    SearchyThing.search(:places).around(point, 500..1000)

#### Kicker Methods ####

An Engyma::Search instance (the things that's returned when you call `search`) will delay execution of the Sphinx query and database query until you call the 'kicker' method `run`. If you send the Search object a missing method, it will run the search and then pass the method on the the return value of the query (what's returned differs slightly based on your database adapter, see below).

For example:

    Model.search.for("Arby's") # => returns an Enygma::Search object
    Model.search.for("Arby's").run # => returns an array of Models
    Model.search.for("Arby's").first # => returns the first Model found

A gotcha: if somehow you have, for example, an ActiveRecord::Base named\_scope that matches the name of a Search method, say `filter`, you should explicitly call `run` on the Search object.

    Model.search.for("Arby's").filter(...) # => sets a Sphinx filter
    Model.search.for("Arby's").run.filter(...) # => runs the filter named_scope

### Resources ###

Subclasses of ActiveRecord::Base and Sequel::Model and classes including Datamapper::Resource can be extended using Enygma::Resource to give them searching superpowers.

Including Enygma::Resource in one of the above types of classes will relfect on the table associated with the class and automatically scope Enygma searches to that table and its related indexes.

    class Post < ActiveRecord::Base
      include Enygma::Resource
    end
    
    Post.search.for("turkey").each { |post| puts post.title }

If a class includes Enygma::Resource, it can only search on one table at a time (meaning that it can only return records of a single type), but can still search for those records using multiple indexes. For example:

    class Post < ActiveRecord::Base
      include Enygma::Resource
      
      configure_enygma do
        index :posts
        index :posts_delta
      end
    end

More in-depth per-adapter documentation detailed below:

#### ActiveRecord::Base ####

An ActiveRecord::Base subclass that includes Enygma::Resource will, instead of returning the actual results of the database query, return an anonymous scope searching for record ids in the set of ids returned by Sphinx. This helps ease integration with will\_paginate, as well as allowing the appending of additional named\_scopes.

For example, to get all Models and their Associations in one go:

    Model.search.for("turkey").all(:include => :association)

#### Sequel::Model ####

Like above, a Sequel::Model with Enygma::Resource will not automatically kick off the query, but just return a prepared Sequel::Query object for further filtering.

#### Datamapper ####

Nothing special about Datamapper so far.

### Using Enygma in a controller ###

What follows is an example of using Enygma in an ActionController::Base subclass in a Rails project, but it should apply to most any controller (or any class, for that matter).

    class PostsController < ApplicationController
      include Enygma
    
      configure_enygma do
        adapter   :active_record
        database  Post
        table     :posts
        index     :posts
        index     :posts_delta
      end
      
      def index
        @posts = search(:posts).for(params[:search]).all(:include => :comments)
      end
    end


## Non-relational Database Stores ##

Enygma is so awesome that you can use it to hook Sphinx up to non-relational database stores and other data-storing structures, such as Memcache, Tokyo Cabinet, and BerkeleyDB (not currently implemented).

Of course, Sphinx can't index content from one of these database types, so it's assumed that the data has been prepopulated and that you have already set up a system to keep the original data source (the one Sphinx indexed from) and the data store in sync.

For example, assume you've taken a large chunk of mostly-static data from your database and put it as marshalled hashes into a Tokyo Cabinet. You can tell Enygma to to query Sphinx for a term, then get the records from the Tokyo Cabinet.

Let's assume that, nightly, you reindex your users table and stuff a bunch of hashes structured like `{ :id => <id>, :username => <username>, :email => <email> }` into a Tokyo Cabinet file called 'usernames.tch', each under the key `user:<id>`. You want to set up a controller to autocomplete the users' names, and you want it to be fast. You can tell Enygma to look for these hashes in the (lightning-fast) Tokyo Cabinet instead of your (glacially-slow) database like so:

    class UserNamesAutocompletionsController < ApplicationController
      include Enygma
      
      configure_enygma do
        adapter     :tokyo_cabinet
        database    'usernames.tch'
        key_prefix  'user:'
        index       :users
      end
      
      def index
        @usernames = search.for(params[:search]).run
      end
    end