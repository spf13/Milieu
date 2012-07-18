require 'mongo'
require './model/mongoModule'
require './model/user'
require './model/venue'
require './model/checkin'

if ENV['RACK_ENV'] == 'production'
  db = URI.parse(ENV['MONGOHQ_URL'])
  db_name = db.path.gsub(/^\//, '')
  DB = Mongo::Connection.new(db.host, db.port).db(db_name)
  DB.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
else
  DB = Mongo::Connection.new("localhost", 27017).db('milieu')
end

USERS      = DB['users']
VENUES     = DB['venues']
CHECKINS   = DB['checkins']
VENUES.ensure_index([["location.geo", Mongo::GEO2D]])
