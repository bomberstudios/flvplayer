require 'rubygems'
require 'sinatra'
require 'rack/contrib'
require 'rdiscount'

# This class is returned to Rack adapter as response.
# Rack callse "each" on it to get response body
# and sends individual responses to the client.
# This way we avoid loading whole file to memory
class FlvStream
  def initialize(filename, start_pos)
    @filename = filename
    @file = File.new(filename, "rb")
    @start_pos = start_pos
    @file.seek(@start_pos)
  end

  def each
    if @start_pos > 0
      yield "FLV\x01\x01\x00\x00\x00\x09\x00\x00\x00\x09" # If we are not starting from beggining
                                                          # we must prepend FLV header to output
      @start_pos = 0
    end

    begin (chunk = @file.read(4*1024)) # Go and experiment with best buffer size for you
      yield chunk
    end while chunk.size == 4*1024
  end

  def length
    File.size(@filename) - @start_pos
  end
end

configure do
  use Rack::Evil
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
      so.addVariable('aspect_ratio',16/9);
      so.addVariable('placeholder','/placeholder');
      so.addVariable('video_path','/0010.flv');
      so.addVariable('watermark','/watermark.png');
      so.addVariable('watermarkPosition','TR');
      so.addParam('allowFullScreen',true);
      so.addVariable('fullscreen',true);
      // so.addVariable('stealth_mode',false);
      // so.addVariable('autoplay',true);
      // so.addVariable('has_streaming',true);
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
  flv = FlvStream.new("deploy/test_video.flv", params[:start].to_i)
  puts params[:start].to_i
  throw :response, [200, {'Content-Type' => 'application/x-flv', "Content-Length" => flv.length.to_s}, flv]
end
get '/swfobject' do
  send_file "deploy/swfobject.js", :disposition => 'inline'
end
get '/watermark.png' do
  send_file "deploy/watermark.png", :disposition => 'inline'
end