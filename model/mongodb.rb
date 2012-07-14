require 'mongo'
require './model/mongoModule'
require './model/user'

if ENV['RACK_ENV'] == 'production'
  db = URI.parse(ENV['MONGOHQ_URL'])
  DB = db.path.gsub(/^\//, '')
  CONNECTION = Mongo::Connection.new(db.host, db.port).db(db_name)
  CONNECTION.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
else
  CONNECTION = Mongo::Connection.new("localhost", 27017)
  DB         = CONNECTION.db('milieu')
end

USERS      = DB['users']
VENUES     = DB['venues']
CHECKINS   = DB['checkins']
