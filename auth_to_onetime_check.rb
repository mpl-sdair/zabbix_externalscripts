#!/usr/bin/ruby

require "rubygems"
require "net/https"
require "json"
require "uri"

# 流れ
# 端末認証をおこなって、トークンを取得
# トークンを使ってプレイリストを取得
# チャンクを取得

# 定数

# プロキシサーバ
Proxy_addr = "172.30.2.252"
Proxy_port = "3128"

# チェックタイムアウト時間（httpリクエスト毎） 20191004
Timeout_sec = 2


#  端末認証API
AUTHApi = "https://api.sd-air.com/apiv2/terminal_authentication.php"
# AUTHApi = "http://timeouttestapi.azurewebsites.net/timeout"
# AUTHApi = "https://211.1.234.119/api/terminal_authentication.php"
# checker用IMEI
IMEI = "867989021152711"
# アプリタイプ 1固定
APPType = "1"

# OnetimeURL取得用API
PListApi = "https://api.sd-air.com/apiv2/playlist.m3u8"
# PListApi = "http://timeouttestapi.azurewebsites.net/timeout"
# ListApi = "https://211.1.234.119/api/playlist.m3u8"
# チャンネル番号
Channel = "400"

# 中で使う変数
@error = Hash.new

def post_data_no_proxy(api,data)
  begin
    Timeout.timeout(Timeout_sec) do
      url = URI.parse(api)
      # 接続
      http = Net::HTTP.new(url.host,url.port)
      if url.port.to_i == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # リクエスト
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(data)
      res = http.request(req)
      return res
    end
  rescue Timeout::Error
    print "Check NG\n#{$!} Timeout #{api} \n"
    exit
  rescue
p $!
  end

end

def get_data_no_proxy(api,data)
  begin
    Timeout.timeout(Timeout_sec) do
      url = URI.parse(api)

      http = Net::HTTP.new(url.host,url.port)
      if url.port.to_i == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # リクエスト
      req = Net::HTTP::Get.new("#{url.path}?channel_number=#{data["channel_number"]}&token=#{data["token"]}&sw=hoge")
    p "#{url.path}?channel_number=#{data["channel_number"]}&token=#{data["token"]}&sw=hoge"
      res =  http.request(req)
    return res
    end
  rescue Timeout::Error
    print "Check NG\n#{$!} Timeout #{api}\n"
    exit
  end
  
end

def get_chank_no_proxy(url)
  begin
    Timeout.timeout(Timeout_sec) do
      url = URI.parse(url)

      # 接続
      http = Net::HTTP.new(url.host,url.port)
      if url.port.to_i == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      # リクエスト
      req = Net::HTTP::Get.new("#{url.path}?#{url.query}")
      res = http.request(req)
        return res
      end
    rescue Timeout::Error
      print "Check NG\n#{$!} Timeout #{url}\n"
    exit
  end
end

# 認証
data = Hash.new
data["app_type"]=APPType
data["uuid"]=IMEI
begin
  auth_result = post_data_no_proxy(AUTHApi,data)
  auth_result_j = JSON.parse(auth_result.body)
  if auth_result_j["result"]["code"] == "9"
    puts "Check NG"
    puts auth_result_j["result"]["message"]
    exit
  end
rescue
  puts "Check NG"
  puts "端末認証失敗 #{$!}"
  exit
end

# 端末認証後、トークンがDBに登録されるまで若干のタイムラグがある
# トークンがDB登録未完了のうちにプレイリスト取得に行くと取得に失敗するため
# しばらく待機してトークンがDBに登録されるのを待つ
sleep 0.1

# おやプレイリスト
data = Hash.new
data["channel_number"] = Channel
data["token"] = auth_result_j["value"]["token"]
begin
  play_list = get_data_no_proxy(PListApi,data)
  # play_list = post_data(PListApi,data)
  play_list_url = play_list.body.split("\n")[-1]
rescue
  puts "Check NG"
  puts "マスタープレイリスト取得失敗-1 #{$!}"
  exit
end

first_check = "OK"

if !play_list_url || play_list_url == ""
  first_check = "NG"
  # 再取得
  sleep 1
  play_list = get_data_no_proxy(PListApi,data)
  play_list_url = play_list.body.split("\n")[-1]
  if !play_list_url || play_list_url == ""
    puts "Check NG"
    puts "マスタープレイリスト取得失敗-2"
    puts "#{PListApi}へ#{data.to_json}を2回問い合わせた結果"
    puts "#{play_list.body} が戻りました"
    puts "#{play_list}"
    exit
  else
  end
end



# 子プレイリスト
begin
  p_list = get_chank_no_proxy(play_list_url)
rescue
  puts "Check NG"
  puts "プレイリスト取得get_chank失敗"
  puts " play_list=#{play_list_url}"
  puts "#{$!}"
  exit
end



if p_list.code =~ /3../ || p_list.code =~ /2../
  if first_check == "NG"
    puts "Check Warning"
    puts "マスタープレイリスト1回目取得失敗　2回目取得成功"
    puts "#{play_list.body}"
  else
    puts "Check OK"
    puts "マスタープレイリスト取得成功"
    puts "#{play_list.body}"
  end
else
  puts "Check NG"
  puts "レイリスト取得失敗"
  puts " play_list=#{play_list_url}"
  puts "ステータスコード=#{p_list.code}"
  puts "#{play_list.body}"
  exit
end
