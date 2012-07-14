require 'mongo'
require './model/mongoModule'
require './model/user'

if ENV['RACK_ENV'] == production
    CONNECTION = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
else
    CONNECTION = Mongo::Connection.new("localhost", 27017)
end

DB         = CONNECTION.db('milieu')
USERS      = DB['users']
VENUES     = DB['venues']
CHECKINS   = DB['checkins']

