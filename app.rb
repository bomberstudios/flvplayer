require 'rubygems'
require 'sinatra'
require 'rdiscount'

configure do
  WIDTH = 640
  HEIGHT = 360
  FPS = 31
  PLAYER = 8
  BGCOLOR = "#000000"
  APP = "flvplayer"
end

helpers do
  def swf_helper
    return <<-HTML
    <script type="text/javascript" src="/swfobject"></script>
    <div id="flashcontent">
      This text is replaced by the Flash movie.
    </div>
    <script type="text/javascript">
      var so = new SWFObject("/swf", "mymovie", "#{WIDTH}", "#{HEIGHT}", "8", "#{BGCOLOR}");
      so.addParam('allowFullScreen',true);
      so.addVariable('aspect_ratio',16/9);
      so.addVariable('placeholder','/placeholder');
      so.addVariable('video_path','/video');
      so.write("flashcontent");
    </script>
    <p>
      #{RDiscount.new(File.read('README.mdown')).to_html}
    </p>
    HTML
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
get '/placeholder' do
  send_file "assets/placeholder.png", :disposition => 'inline'
end
get '/video' do
  send_file "deploy/test_video.flv", :disposition => 'inline'
end
get '/swfobject' do
  send_file "deploy/swfobject.js", :disposition => 'inline'
end