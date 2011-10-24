# encoding: UTF-8
%w(sinatra haml sass json pusher).each { |lib| require lib }

def configure_pusher(opts)
  Pusher.app_id   = opts[:id]
  Pusher.key      = opts[:key]
  Pusher.secret   = opts[:secret]
  def Pusher.channel
    'enquete-app'
  end
  def Pusher.pchannel
    'presence-enquete-app'
  end
end

def configure_redis(path)
  require "redis"
  uri = URI.parse(path)
  redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  def redis.H
    "COUNTER"
  end
  redis
end

configure do
  APP_TITLE = "Love Languages?"
  BLOG = {title: "hp12c", url: "http://d.hatena.ne.jp/keyesberry"}
  REDIS = configure_redis(ENV["REDISTOGO_URL"]||"http://localhost:6379")
end

configure :production do
  configure_pusher(id:'YOUR_PUSHER_ID', key:'YOUR_PUSHER_KEY',
                   secret:'YOUR_PUSHER_SECRET')
end

configure :development do
  configure_pusher(id:'YOUR_PUSHER_ID', key:'YOUR_PUSHER_KEY',
                   secret:'YOUR_PUSHER_SECRET')
  disable :logging
end

get '/' do
  haml :index
end

get '/initialize.json' do
  return halt 403 unless request.xhr?
  content_type 'text/json', :charset => 'utf-8'
  get_all_counter_in_hash.to_json
end

post '/enquete.json' do
  return halt 403 unless request.xhr?
  content_type 'text/json', :charset => 'utf-8'
  id = params['id']
  data = {'id' => id, 'cnt' => inc_counter(id)}.to_json
  Pusher[Pusher.channel].trigger('countup', data)
  data
end

post '/pusher/auth' do
  id = params[:socket_id]
  res = Pusher[params[:channel_name]].authenticate(id, :user_id => id)
  res.to_json
end

helpers do
  def get_counter(key)
    REDIS.hget(REDIS.H, key)
  end

  def inc_counter(key)
    REDIS.hincrby(REDIS.H, key, 1)
  end

  def get_all_counter_in_hash
    REDIS.hkeys(REDIS.H).inject({}) { |h, k| h[k] = get_counter(k); h }
  end
end

get '/style.css' do
  scss :style
end

