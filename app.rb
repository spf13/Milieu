require 'sinatra'
require './helpers/sinatra'
require './helpers/milieu'
require './model/mongodb'
require 'haml'
require 'digest/md5'
require 'googlestaticmap'


configure do
  enable :sessions
end

before do
  unless session[:user] == nil
    @suser = session[:user]
  end
end

get '/' do
  haml :index
end

get '/user' do
  redirect '/user/' + session[:user].email + '/profile'
end

get '/about' do
  haml :about
end

get '/login' do
  haml :login
end

post '/login' do
  if session[:user] = User.auth(params["email"], params["password"])
    flash("Login successful")
    redirect "/user/" << session[:user].email << "/dashboard"
  else
    flash("Login failed - Try again")
    redirect '/login'
  end
end

get '/logout' do
  session[:user] = nil
  flash("Logout successful")
  redirect '/'
end

get '/register' do
  haml :register
end

post '/register' do
  u            = User.new
  u.email      = params[:email]
  u.password   = params[:password]
  u.name       = params[:name]
  #u.email_hash = Digest::MD5.hexdigest(params[:email].downcase)

  if u.save()
    flash("User created")
    session[:user] = User.auth( params["email"], params["password"])
    redirect '/user/' << session[:user].email.to_s << "/dashboard"
  else
    tmp = []
    u.errors.each do |e|
      tmp << (e.join("<br/>"))
    end
    flash(tmp)
    redirect '/create'
  end
end

get '/user/:email/dashboard' do
  haml :user_dashboard
end

get '/user/:email/profile' do
  @user = User.new_from_email(params[:email])
  haml :user_profile
end

get '/list' do
  @users = USERS.find
  haml :list
end

get '/venues/?:page?' do
  @page = params.fetch('page', 1).to_i
  num_per_page = 10
  @venues = VENUES.find.skip(( @page - 1 ) * num_per_page).limit(num_per_page)
  @total_pages = (VENUES.count.to_i / num_per_page).ceil
  haml :venues
end

get '/venue/:_id' do
  object_id = BSON::ObjectId.from_string(params[:_id])
  @venue = VENUES.find_one({ :_id => object_id })
  @user = User.new_from_email(@suser.email)
  @nearby_venues = VENUES.find(
      { :'location.geo' => 
          { :$near => [ @venue['location']['geo'][0],
              @venue['location']['geo'][1]]
          }
      }).limit(4).skip(1)
  haml :venue
end

# Add lots of comments here
get '/venue/:_id/checkin' do
  object_id = BSON::ObjectId.from_string(params[:_id])
  @venue = VENUES.find_one({ :_id => object_id })
  user = USERS.find_and_modify(:query => { :_id => @suser._id}, :update => {:$inc => { "venues." << object_id.to_s => 1 } }, :new => 1)
  if user['venues'][params[:_id]] == 1
      VENUES.update({ :_id => @venue['_id']}, { :$inc => { :'stats.usersCount' => 1, :'stats.checkinsCount' => 1}})
  else
      VENUES.update({ _id: @venue['_id']}, { :$inc => { :'stats.checkinsCount' => 1}})
  end
  flash('Thanks for checking in')
  redirect '/venue/' + params[:_id]
end

get '/checkin/:location' do
   @venues = VENUES.find( )
   haml :venues
end
