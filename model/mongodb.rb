require 'mongo'
require './model/mongoModule'
require './model/user'

CONNECTION = Mongo::Connection.new("localhost", 27017)
DB         = CONNECTION.db('milieu')
USERS      = DB['users']
VENUES     = DB['venues']
CHECKINS   = DB['checkins']

