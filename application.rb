require "sinatra"
require "digest/sha1"
require "rack-flash"
require "mongo_mapper"
require "models/user"

use Rack::Session::Cookie, :secret => 'lksjdio23rlksdlfkj234kljslkdjsdlfkj234klj23lkjlkjsdflkjsdflkj234lkj'
use Rack::Flash

if File::exists?('database_config.rb')
	puts "database config"
	require "database_config"
else
	MongoMapper.database = 'hideaway'
end

def current_user
	if session[:user]
		User.get(:id => session[:user])
	end
	nil
end

def logged_in?
	!!session[:user]
end

def get_db
	MongoMapper.database
end

get '/' do
	if !logged_in?
		redirect '/login'
	else
		@channels = Array.new
		get_db.collection_names.select{ |name| name.starts_with?('channel-') }.each do |name|
			@channels << name.sub(/channel-/, '')
		end
		haml :index
	end
end

get '/log/*' do
	channel_name = params[:splat].to_s
	col_name = 'channel-' + channel_name
	@msgs = get_db[col_name].find(:channel => channel_name).sort(['timestamp', 'ascending'])
	haml :view_log
end

get '/login' do
	if session[:user]
		redirect '/'
	else
		haml :login
	end
end

post '/login' do
	if user = User.authenticate(params[:username], params[:password])
		session[:user] = user.id

		if Rack.const_defined?('Flash')
			flash[:notice] = "Login successful."
		end

		if session[:return_to]
			redirect_url = session[:return_to]
			session[:return_to] = false
			redirect redirect_url
		else
			redirect '/'
		end
	else
		if Rack.const_defined?('Flash')
			flash[:notice] = "The username or password you entered is incorrect."
		end
		redirect '/login'
	end
end

get '/logout' do
	session[:user] = nil
	if Rack.const_defined?('Flash')
		flash[:notice] = "Logout successful."
	end
	redirect '/'
end
