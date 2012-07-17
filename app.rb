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

# This runs prior to all requests.
# It passes along the logged in user's object (from the session)
before do
  unless session[:user] == nil
    @suser = session[:user]
  end
end

get '/' do
  haml :index
end

get '/login' do
  haml :login
end

# The login post routine will take the provided params and run the auth routine.
# If the auth routine is successful it will return the user object, else nil
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
	if params[:admin] and !session[:user].admin
		flash("Not an admin.")
		redirect '/'
	end

  # Creating and populating a new user object from the DB
  u            = User.new
  u.email      = params[:email]
  u.password   = params[:password]
  u.name       = params[:name]
	if params[:admin]
		u.admin = true
	else
		u.admin = false
	end

  # Attempt to save the user to the DB
  if u.save()
    flash("User created")

    # If user saved, authenticate from the database
    session[:user] = User.auth( params["email"], params["password"])
    redirect '/user/' << session[:user].email.to_s << "/dashboard"
  else
    # Else, display errors
    tmp = []
    u.errors.each do |e|
      tmp << (e.join("<br/>"))
    end
    flash(tmp)
    redirect '/create'
  end
end

get '/user/:email/dashboard' do
  # Get the user's details.
  @user = USERS.find_one({:_id => session[:user]._id})

  # Compute stats
  @user['stats'] = {}
  @user['stats']['num_locations'] = 0
  @user['stats']['total_checkins'] = 0
  if @user['venues'] != nil
    @user['stats']['num_locations'] = @user['venues'].count.to_i
    @user['venues'].values.each do |v|
      @user['stats']['total_checkins'] += v['count'].to_i
    end
    # Get the venues for this user into a variable.
    @venues = Array.new
    @user['venues'].keys.each do |k|
      venue = VENUES.find_one({:_id => BSON::ObjectId(k)})
      @venues.push(venue)
    end
  end
  haml :user_dashboard
end

get '/user' do
  if logged_in?
      redirect '/user/' + session[:user].email + '/profile'
  else
      redirect '/'
  end
end

get '/user/:email/profile' do
  @user = User.new_from_email(params[:email])
  haml :user_profile
end

get '/list' do
  @users = USERS.find
  haml :list
end

# Listing the venues.
# As a warning, this approach to pagination isn't especially effective
# when dealing with very large result sets.
get '/venues/p/?:page?' do
  @page = params.fetch('page', :page).to_i
  num_per_page = 10
  @venues = VENUES.find.skip(( @page - 1 ) * num_per_page).limit(num_per_page)
  @total_pages = (VENUES.count.to_f / num_per_page).ceil
  haml :venues
end

get '/venue/:_id' do
  # Converting the string _id from the url into an ObjectId
  object_id = BSON::ObjectId.from_string(params[:_id])

  # Query for the venue from MongoDB based on the ObjectId
  @venue = VENUES.find_one({ :_id => object_id })

  # Grab the session user from the db to accurately provide stats
  @user = User.new_from_email(@suser.email) if logged_in?

  # Find 4 closest venues to this one
  @nearby_venues = VENUES.find(
      { :'location.geo' =>
          { :$near => [ @venue['location']['geo'][0],
              @venue['location']['geo'][1]]
          }
      }).limit(4).skip(1)

  # Get the mayor user's name.
  @mayor = USERS.find_one({:_id => @venue['mayor']})

  # Render the template
  haml :venue
end

get '/venue/:_id/checkin' do
  # Converting the string _id from the url into an ObjectId
  object_id = BSON::ObjectId.from_string(params[:_id])

  # Query for the venue from MongoDB based on the ObjectId
  @venue = VENUES.find_one({ :_id => object_id })
  mayor = USERS.find_one({:_id => @venue['mayor']})

  # Simultaneously add the users checkin to the venue & return it.
  user = USERS.find_and_modify(:query => { :_id => @suser._id}, :update => {:$inc => { "venues." << object_id.to_s << ".count" => 1 },
                                                                            :$push => { "venues." << object_id.to_s << ".timestamp" => Time.now },
                                                                            :$set => { "last_checkin_ts" => Time.now}}, :new => 1)

  # If it's the first time, increment both checkins and users counts
  if user['venues'][params[:_id]]['count'] == 1
      VENUES.update({ :_id => @venue['_id']}, { :$inc => { :'stats.usersCount' => 1, :'stats.checkinsCount' => 1}})
  # Else, just the increment the checkins
  else
      VENUES.update({ _id: @venue['_id']}, { :$inc => { :'stats.checkinsCount' => 1}})
  end
  
  if mayor
    if mayor['venues'][object_id.to_s]['count'] < user['venues'][object_id.to_s]['count']
      VENUES.update({:_id => @venue['_id']}, {:$set => {:'mayor' => @suser._id}})
    end
  else
    VENUES.update({:_id => @venue['_id']}, {:$set => {:'mayor' => @suser._id}})
  end
  flash('Thanks for checking in')
  redirect '/venue/' + params[:_id]
end

get '/venues/create' do
  if session[:user].admin
    haml :venues_create
  else
    flash('Not an admin')
    redirect '/'
  end
end

post '/venues/create' do
  if !session[:user].admin
    flash('Not an admin')
    redirect '/'
  end
  v = Venue.new
  v.name = params[:name]
  v.location = {
    'address' => params[:address],
    'cc' => params[:cc],
    'city' => params[:city],
    'country' => params[:country],
    'geo' => [params[:longitude].to_f, params[:latitude].to_f],
    'postalCode' => params[:postalCode],
    'state' => params[:state],
  }
  v.stats = {
    'checkinsCount' => 0,
    'usersCount' => 0
  }
  
  # Attempt to save the venue to the DB
  if v.save()
    flash("Venue Created")
    redirect '/venues/p/1'
  else
    # Else, display errors
    tmp = []
    u.errors.each do |e|
      tmp << (e.join("<br/>"))
    end
    flash(tmp)
    redirect 'venues/create'
  end
end