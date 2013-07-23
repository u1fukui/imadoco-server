# coding:utf-8
require 'sinatra/base'
require 'openssl'

class ImadocoApp < Sinatra::Base

  # 開発用設定
  configure :development do
    config = YAML.load_file("config/config_dev.yml")

    @@APN = Houston::Client.development
    @@APN.certificate = File.read(config['apn']['certificate'])
    @@APN.passphrase = config['apn']['pass']

    @@decript_key = config['decrypt_key']
  end

  # 本番用設定
  configure :production do
    config = YAML.load_file("config/config_production.yml")

    #@@APN = Houston::Client.production
    @@APN = Houston::Client.development
    @@APN.certificate = File.read(config['apn']['certificate'])
    @@APN.passphrase = config['apn']['pass']

    @@decript_key = config['decrypt_key']
  end
 
  # 指定された端末にpush通信を送る
  def pushNotification(device_id, notification_id)
    notification = Houston::Notification.new(device: device_id)
    notification.alert = "相手からの反応がありました"

    # Notifications can also change the badge count, have a custom sound, indicate available Newsstand content, or pass along arbitrary data.
    notification.badge = 1
    notification.sound = "sosumi.aiff"
    notification.content_available = true
    notification.custom_data = {notification_id: notification_id}

    # And... sent! That's all it takes.
    @@APN.push(notification)
  end

  # 復号処理
  def decrypt(base64_text)
    
    s = base64_text.unpack('m')[0]

    dec = OpenSSL::Cipher::Cipher.new('AES-256-CBC') 
    dec.decrypt
    dec.key = @@decript_key
    dec.iv = "\000"*32
    a = dec.update(s)
    b = dec.final
    
    return a + b
  end

  # 引数の数値を桁数にしたランダムな文字列を生成
  def create_random_string(num)
    return [*1..9, *'A'..'Z', *'a'..'z'].sample(num).join
  end

  # 無効なユーザかを判定
  def is_invalid_user(user_id, cookie)
    user = User.find_by_id_and_cookie(user_id, cookie)
    return user.nil?
  end

  # 端末の登録
  post '/device.json' do
    reqData = JSON.parse(request.body.read.to_s)
    device_id = decrypt(reqData['device_id'])
    user = User.find_by_device_id(device_id)

    request.cookies['foo']


    #  存在しない場合は登録
    if user.nil? then
      user = User.new
      user.device_id = device_id
      user.device_type = reqData['device_type']
      user.cookie = create_random_string(28)
      user.save
    end

    # userIdを返す
    content_type :json, :charset => 'utf-8'
    status 202
    {user_id: user.id, cookie: user.cookie}.to_json 
  
  end

  # 地図URLの生成
  post '/mail.json' do
    reqData = JSON.parse(request.body.read.to_s)
    user_id = reqData['user_id']
    name = reqData['name']
    
    # ユーザ確認
    cookie = request.cookies['user_cookie']
    if is_invalid_user(user_id, cookie) then
      status 401
      return
    end

    public_id = create_random_string(12)
    
    map = Map.new
    map.user_id = user_id
    map.name = name
    map.public_id = public_id
    
    begin
      map.save!
      
      content_type :json, :charset => 'utf-8'
      status 202
      
      url = "http://#{env['HTTP_HOST']}/maps/#{public_id}"
      
      
      {mail_body: url, mail_subject: "imadoco"}.to_json

    rescue ActiveRecord::RecordNotUnique => e
      status 400
    end

  end

  # 地図の表示
  get '/maps/:key' do
    @key = params[:key]
    erb :maps
  end 

  # 位置情報の登録
  post '/position' do
    lat = params[:lat]
    lng = params[:lng]
    key = params[:key]
    message = params[:message]

    map = Map.find_by_public_id(key)
    user = User.find(map.user_id)

    notification = Notification.new
    notification.map_id = map.id
    notification.lat = lat
    notification.lng = lng
    notification.message = message
    
    notification.save!
 
    pushNotification(user.device_id, notification.id)    

    erb :thanks
  end

  # 居場所情報の取得
  get '/notifications/:uid' do
    user_id = params[:uid]

    # ユーザ確認
    cookie = request.cookies['user_cookie']
    if is_invalid_user(user_id, cookie) then
      status 401
      return
    end

   
    content_type :json, :charset => 'utf-8'

    notifications = Map.joins(:notifications).select("notifications.id, maps.name, notifications.lat, notifications.lng, notifications.message, notifications.created_at").where(:user_id => user_id).order("notifications.id DESC")
    #positions = Position.joins(:map).select("positions.id, maps.public_id, positions.lat, positions.lng, positions.message, positions.created_at").where(:user_id => user_id)
    notifications.to_json(:root => false)

  end

  # 予期せぬエラー
  error do
    status 500
    "ERROR"
  end

end
