WIDTH = 800
HEIGHT = 600
FPS = 31
PLAYER = 8
BGCOLOR = "#ffffff"
APP = "flvplayer"

require 'rubygems'
require 'sinatra'

helpers do
  def swf_helper
    return "<embed src='/swf' width='#{WIDTH}' height='#{HEIGHT}' type='application/x-shockwave-flash'></embed>"
  end
end

before do
  @server_path = "http://" + request.env["HTTP_HOST"] + request.env["REQUEST_PATH"]
end

get "/" do
  %x(rake)
  erb swf_helper
end
get "/swf" do
  send_file "deploy/#{APP}.swf", :type => 'application/x-shockwave-flash', :disposition => 'inline'
end