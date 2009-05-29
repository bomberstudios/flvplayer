import com.bomberstudios.utils.Delegate;

class com.bomberstudios.video.Player {
  var audio:Sound;
  var mc:MovieClip;
  var video_mc:MovieClip;
  var ns:NetStream;
  var nc:NetConnection;

  var is_playing:Boolean = false;
  var is_paused:Boolean = false;
  var audio_muted:Boolean;
  var started:Boolean;

  private var videoPath:String;

  // Video Metadata
  var metadata:Object;
  var aspect_ratio:Number = 4/3;

  // Levels for movieclips
  var LEVEL_PLACEHOLDER:Number          = 50;
  var LEVEL_VIDEODISPLAY:Number         = 100;
  var LEVEL_TRANSPORT:Number            = 200;
  var LEVEL_TRANSPORT_BG_LEFT:Number      = 100;
  var LEVEL_TRANSPORT_BG_CENTER:Number    = 200;
  var LEVEL_TRANSPORT_BG_RIGHT:Number     = 300;
  var LEVEL_SOUND:Number                = 300;
  var LEVEL_BTN_PLAY:Number             = 400;
  var LEVEL_ICO_SOUND:Number            = 500;
  var LEVEL_ICO_FULLSCREEN:Number       = 600;

  function Player(_mc:MovieClip){
    Stage.scaleMode = "noScale";
    Stage.align = "TL";
    mc = _mc.createEmptyMovieClip('v',_mc.getNextHighestDepth());
    create_ui();
    setup_video();
  }
  function toString(){
    return "FLVPlayer v1.0";
  }

  // Video Data
  public function get video_path():String {
    return videoPath;
  }
  public function set video_path(s:String) {
    trace("setting video path to " + s);
    videoPath = s;
  }

  // Transport
  function play(){
    is_paused = false;
    if(!is_playing){
      is_playing = true;
      ns.play(video_path);
    } else {
      ns.pause(false);
    }
  }
  function pause(){
    is_paused = true;
    ns.pause();
  }
  function toggle_play(){
    if(is_playing){
      pause();
    } else {
      play();
    }
  }

  // Events
  function on_click_play(){}
  function on_click_audio(){}
  function on_click_fullscreen(){}
  function on_click_btn(btn:MovieClip){ btn._alpha = 10; }
  function on_rollover_btn(btn:MovieClip){ btn._alpha = 70; }
  function on_rollout_btn(btn:MovieClip){ btn._alpha = 100; }
  function on_video_status(s:Object){}
  function on_video_metadata(s:Object){
    // set aspect ratio
    aspect_ratio = s.width / s.height;
    metadata = s;
    for(var key in metadata){
      trace(key + ": " + metadata[key] );
    }
    redraw();
  }

  // UI
  function set_width(w:Number){
    mc.placeholder._width = video_mc._width = w;
    mc.placeholder._height = video_mc._height = w / aspect_ratio;
    redraw_transport();
  }

  private function create_ui(){
    // Video display
    mc.attachMovie('VideoDisplay','VideoDisplay',LEVEL_VIDEODISPLAY);
    video_mc = mc.VideoDisplay.vid;

    // Transport bar
    mc.createEmptyMovieClip('transport',LEVEL_TRANSPORT);
    mc.transport.attachMovie('bg_left','bg_left',LEVEL_TRANSPORT_BG_LEFT);
    mc.transport.attachMovie('bg_center','bg_center',LEVEL_TRANSPORT_BG_CENTER,{_x:mc.transport.bg_left._width});
    mc.transport.attachMovie('bg_right','bg_right',LEVEL_TRANSPORT_BG_RIGHT,{_x:mc.transport.bg_center._x + mc.transport.bg_center._width});

    // Play button
    mc.transport.attachMovie('btn_play','btn_play',LEVEL_BTN_PLAY,{_x:2, _y:2});
    make_button(mc.transport.btn_play,Delegate.create(this,toggle_play));

    // Sound button
    mc.transport.attachMovie('ico_sound','ico_sound',LEVEL_ICO_SOUND,{_x:mc.transport._width - 44, _y:2});
    make_button(mc.transport.ico_sound,Delegate.create(this,toggle_audio));

    // Fullscreen button
    mc.transport.attachMovie('ico_fullscreen','ico_fullscreen',LEVEL_ICO_FULLSCREEN,{_x:mc.transport._width - 22, _y:2});
    make_button(mc.transport.ico_fullscreen,Delegate.create(this,toggle_fullscreen));

    // Placeholder
    mc.attachMovie('placeholder','placeholder',LEVEL_PLACEHOLDER);
  }
  private function redraw(){
    var tentative_video_height = Stage.width / aspect_ratio;
    if(tentative_video_height > Stage.height){
      set_width(Stage.height * aspect_ratio);
    } else {
      set_width(Stage.width);
    }
    redraw_transport();
  }
  private function redraw_transport(){
    mc.transport.bg_center._width = video_mc._width - mc.transport.bg_left._width - mc.transport.bg_right._width;
    mc.transport.bg_right._x = video_mc._width - mc.transport.bg_right._width;
    mc.transport.ico_sound._x = video_mc._width - mc.transport.ico_sound._width - mc.transport.ico_fullscreen._width - 4;
    mc.transport.ico_fullscreen._x = video_mc._width - mc.transport.ico_fullscreen._width - 2;
    mc.transport._y = video_mc._height - mc.transport._height;
  }
  private function toggle_fullscreen(){}

  private function make_button(btn:MovieClip,action:Function){
    btn.onRelease = action;
    btn.onRollOver = Delegate.create(this,on_rollover_btn,btn);
    btn.onRollOut = Delegate.create(this,on_rollout_btn,btn);
  }
  private function setup_video(){
    nc = new NetConnection();
    nc.connect(null);
    ns = new NetStream(nc);
    ns.setBufferTime(5);

    // create and set sound object
    var snd = mc.createEmptyMovieClip("snd", LEVEL_SOUND);
    snd.attachAudio(ns);
    audio = new Sound(snd);

    // attach video
    video_mc.attachVideo(ns);

    // Video events...
    ns.onStatus = Delegate.create(this,on_video_status);
    ns.onMetaData = Delegate.create(this,on_video_metadata);

    // Set play status
    started = false;
    is_playing = false;
  }

  // Audio
  function mute(){
    audio_muted = true;
    mc.transport.attachMovie('ico_sound_muted','ico_sound',LEVEL_ICO_SOUND,{_x:mc.transport._width - 44, _y:2});
    make_button(mc.transport.ico_sound,Delegate.create(this,toggle_audio));
    audio.setVolume(0);
  }
  function unmute(){
    audio_muted = false;
    mc.transport.attachMovie('ico_sound','ico_sound',LEVEL_ICO_SOUND,{_x:mc.transport._width - 44, _y:2});
    make_button(mc.transport.ico_sound,Delegate.create(this,toggle_audio));
    audio.setVolume(100);
  }
  function toggle_audio(){
    if(audio_muted){
      unmute();
    } else {
      mute();
    }
  }
}