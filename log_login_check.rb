#!/usr/bin/ruby
# ログ管理画面へのログインチェック
# 20200317 2秒でタイムアウト　本番化


require "rubygems"
require "net/https"
require "json"
require "uri"
require "timeout"


Login_url = "https://primary-log.sd-air.com/log/check.php"
# Login_url = "http://timeouttestapi.azurewebsites.net/timeout"
Basic_auth_id = "sdair"
Basic_auth_pass = "sdair"
Login_id = "sd-air"
Login_pass = "tjESbt8-9a"

# チェックタイムアウト時間（httpリクエスト毎） 20200313
Timeout_sec = 2


def login_check()
  begin
    Timeout.timeout(Timeout_sec) do
      url = URI.parse(Login_url)

      # 接続
      http = Net::HTTP.new(url.host,url.port)
      if url.port.to_i == 443
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      # リクエスト
      data = Hash.new
      data["login_id"] = Login_id
      data["login_pass"] = Login_pass
      req = Net::HTTP::Post.new(url.path)
      req.basic_auth Basic_auth_id,Basic_auth_pass
      req.set_form_data(data)
      res =  http.request(req)
      return res
    end
  rescue Timeout::Error
    print "Check NG\n#{$!} Timeout #{Login_url}\n"
    exit
  end 
end


res = login_check()
if res.code == "401"
  puts "Check NG"
  puts "Basic認証に失敗しました"
elsif res["Location"] =~ /error\=1/
  puts "Check NG"
  puts "IDまたはパスワードが違います"
elsif res["Location"] =~ /log_list.php/
  puts "Check OK"
end
