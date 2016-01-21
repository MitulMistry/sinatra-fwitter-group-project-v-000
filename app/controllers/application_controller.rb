require './config/environment'

class ApplicationController < Sinatra::Base

  configure do
    set :public_folder, 'public'
    set :views, 'app/views'
    enable :sessions
    set :session_secret, "secret"
  end

  get '/' do
    erb :index
  end

  get '/signup' do
    #checks if logged in
    if session[:user_id]
      redirect to '/tweets'
    else
      erb :'users/create_user'
    end
  end

  post '/signup' do
    if !params["username"].empty? && !params["email"].empty? && !params["password"].empty?
      @user = User.new(username: params["username"], email: params["email"], password: params["password"])
      @user.save #if password isn't provided because of has_secure_password, it will fail
      session[:user_id] = @user.id
      redirect '/tweets'
    else
      redirect '/signup'
    end
  end

  get '/login' do
    if session[:user_id] #if user is already logged in
      redirect '/tweets'
    else
      erb :'users/login'
    end
  end

  post '/login' do
    user = User.find_by(username: params[:username])
    if user && user.authenticate(params[:password]) #checks if a user was found and authenticates to password digest
      session[:user_id] = user.id
      redirect '/tweets'
    else
      redirect '/login'
    end
  end

  get '/logout' do
    if session[:user_id]
      session.destroy #log out
      redirect to '/login'
    else
      redirect to '/'
    end
  end

  get '/tweets' do
    if session[:user_id]
      @user = User.find_by_id(session[:user_id])
      @tweets = Tweet.all
      erb :'tweets/tweets'
    else
      redirect to '/login'
    end
  end

  get '/users/:user_slug' do
    @user = User.find_by_slug(params[:slug])
    erb :'users/show_user'
  end

  get '/tweets/new' do
    if session[:user_id]
      erb :'tweets/create_tweet'
    else
      redirect to '/login'
    end
  end

  post '/tweets' do
    if params[:content].empty?
      redirect to '/tweets/new'
    else
      @tweet = Tweet.create(content: params[:content], user_id: session[:user_id])
    end
  end

  get '/tweets/:tweet_id' do
    if session[:user_id] #if user is logged in
      @tweet = Tweet.find_by_id(params[:tweet_id])
      erb :'tweets/show_tweet'
    else
      redirect to '/login'
    end
  end

  get '/tweets/:tweet_id/edit' do
    if session[:user_id] #if user is logged in
      @tweet = Tweet.find_by_id(params[:tweet_id])
      if @tweet.user_id == session[:user_id] #make sure the user id of the tweet matches the id of the user currently logged in
        erb :'tweets/edit_tweet'
      else
        redirect to '/tweets'
      end
    else
      redirect to '/login'
    end
  end

  post '/tweets/:tweet_id' do
    if params[:content].empty?
      redirect to "/tweets/#{params[:tweet_id]}/edit"
    else
      @tweet = Tweet.find_by_id(params[:tweet_id])
      @tweet.content = params[:content]
      @tweet.save
      redirect to "/tweets/#{@tweet.id}"
    end
  end

  post '/tweets/:tweet_id/delete' do
    @tweet = Tweet.find_by_id(params[:tweet_id])
    if session[:user_id] #if user is logged in
      if @tweet.user_id == session[:user_id]
        @tweet.delete
      end
      redirect to '/tweets'
    else
      redirect to '/login'
    end
  end

  helpers do #could potentially refactor using these helper methods
    def logged_in?
      !!session[:user_id]
    end

    def current_user
      User.find(session[:user_id])
    end
  end

end