import com.bomberstudios.utils.Delegate;
import flash.geom.Rectangle; // needed for fullscreen hardware scaling

class com.bomberstudios.video.Player {
  var audio:Sound;
  var mc:MovieClip;
  var video_mc:MovieClip;
  var ns:NetStream;
  var nc:NetConnection;

  var is_playing:Boolean = false;
  var is_paused:Boolean = false;
  var is_streaming:Boolean = false;
  var audio_muted:Boolean;
  var started:Boolean;
  var run_loop_id:Number;

  // Idle detection
  private var ui_idle_count:Number = 0;
  private var ui_idle_xmouse:Number;
  private var ui_idle_ymouse:Number;

  // Video Metadata
  var metadata:Object;
  var aspect_ratio:Number = 4/3;
  private var videoPath:String;

  // Some constants for UI redrawing
  var BUTTON_MARGIN = 3;

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
  var LEVEL_PROGRESS_BG:Number          = 700;
  var LEVEL_PROGRESS_LOAD:Number        = 800;
  var LEVEL_PROGRESS_POSITION:Number    = 900;
  

  function Player(_mc:MovieClip){
    Stage.scaleMode = "noScale";
    Stage.align = "TL";
    mc = _mc.createEmptyMovieClip('v',_mc.getNextHighestDepth());
    create_ui();
    setup_video();
    start_run_loop();
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
    mc.transport.attachMovie('btn_pause','btn_pause',LEVEL_BTN_PLAY,{_x:BUTTON_MARGIN, _y:BUTTON_MARGIN});
    make_button(mc.transport.btn_pause,Delegate.create(this,toggle_play));
  }
  function pause(){
    if(is_paused){
      mc.transport.attachMovie('btn_pause','btn_pause',LEVEL_BTN_PLAY,{_x:BUTTON_MARGIN, _y:BUTTON_MARGIN});
      make_button(mc.transport.btn_pause,Delegate.create(this,toggle_play));
    } else {
      mc.transport.attachMovie('btn_play','btn_play',LEVEL_BTN_PLAY,{_x:BUTTON_MARGIN, _y:BUTTON_MARGIN});
      make_button(mc.transport.btn_play,Delegate.create(this,toggle_play));
    }
    is_paused = !is_paused;
    ns.pause();
  }
  function toggle_play(){
    if(is_playing){
      pause();
    } else {
      play();
    }
  }

  // Run loop
  private function start_run_loop(){
    run_loop_id = setInterval(Delegate.create(this,on_run_loop),10);
  }
  private function on_run_loop(){

    // Update progress bar
    mc.transport.progress_bar_position._width = ((ns.time / metadata.duration) * mc.transport.progress_bar_bg._width) - 2;
    mc.transport.progress_bar_load._width = ((ns.bytesLoaded / ns.bytesTotal) * mc.transport.progress_bar_bg._width) - 2;

    // Hide / show transport bar
    if (ui_idle_xmouse != mc._xmouse || ui_idle_ymouse != mc._ymouse) {
      ui_idle_count = 0;
    } else {
      ui_idle_count += 1;
    }
    if (ui_idle_count > 100) {
      hide_transport();
    } else {
      show_transport();
    }
    ui_idle_xmouse = mc._xmouse;
    ui_idle_ymouse = mc._ymouse;
  }

  // Events
  function on_click_play(){}
  function on_click_audio(){}
  function on_click_fullscreen(){}
  function on_click_btn(btn:MovieClip){ btn._alpha = 10; }
  function on_rollover_btn(btn:MovieClip){
    btn.attachMovie(btn._name + "_over",btn._name,1);
  }
  function on_rollout_btn(btn:MovieClip){
    btn.attachMovie(btn._name,btn._name,1);
  }
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
  function onResize(e){
    redraw();
  }

  // UI
  function set_width(w:Number){
    video_mc._width = w;
    video_mc._height = w / aspect_ratio;
    redraw_transport();
  }
  function hide_transport(){
    mc.transport._visible = false;
  }
  function show_transport(){
    mc.transport._visible = true;
  }
  private function create_ui(){
    // Video display
    mc.attachMovie('VideoDisplay','VideoDisplay',LEVEL_VIDEODISPLAY);
    video_mc = mc.VideoDisplay.vid;
    video_mc._width  = Stage.width;
    video_mc._height = Stage.height;

    // Transport bar
    mc.createEmptyMovieClip('transport',LEVEL_TRANSPORT);
    mc.transport.attachMovie('bg_left','bg_left',LEVEL_TRANSPORT_BG_LEFT);
    mc.transport.attachMovie('bg_center','bg_center',LEVEL_TRANSPORT_BG_CENTER,{_x:mc.transport.bg_left._width});
    mc.transport.attachMovie('bg_right','bg_right',LEVEL_TRANSPORT_BG_RIGHT,{_x:mc.transport.bg_center._x + mc.transport.bg_center._width});


    // Play button
    mc.transport.attachMovie('btn_play','btn_play',LEVEL_BTN_PLAY,{_x:BUTTON_MARGIN, _y:BUTTON_MARGIN});
    make_button(mc.transport.btn_play,Delegate.create(this,toggle_play));


    // Fullscreen button
    mc.transport.attachMovie('ico_fullscreen','ico_fullscreen',LEVEL_ICO_FULLSCREEN,{_x:mc.transport._width - 22, _y:BUTTON_MARGIN});
    make_button(mc.transport.ico_fullscreen,Delegate.create(this,toggle_fullscreen));

    // Sound button
    mc.transport.attachMovie('ico_sound','ico_sound',LEVEL_ICO_SOUND,{_x:mc.transport._width - 44, _y:BUTTON_MARGIN});
    make_button(mc.transport.ico_sound,Delegate.create(this,toggle_audio));


    // Progress bar
    var progress_bar_position = mc.transport.btn_play._x + mc.transport.btn_play._width + ( BUTTON_MARGIN * 2 );
    mc.transport.attachMovie('progress_bar_bg','progress_bar_bg',LEVEL_PROGRESS_BG,{_x:progress_bar_position});
    mc.transport.attachMovie('progress_bar_load','progress_bar_load',LEVEL_PROGRESS_LOAD,{_x:progress_bar_position,_width: 0});
    mc.transport.attachMovie('progress_bar_position','progress_bar_position',LEVEL_PROGRESS_POSITION,{_x:progress_bar_position,_width:0});

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
    video_mc._y = Stage.height / 2 - video_mc._height/2;
    redraw_transport();
  }
  private function redraw_transport(){
    mc.transport.bg_center._width = video_mc._width - mc.transport.bg_left._width - mc.transport.bg_right._width;
    mc.transport.bg_right._x = video_mc._width - mc.transport.bg_right._width;
    mc.transport.ico_sound._x = video_mc._width - mc.transport.ico_sound._width - mc.transport.ico_fullscreen._width - (BUTTON_MARGIN*2);
    mc.transport.ico_sound_muted._x = video_mc._width - mc.transport.ico_sound_muted._width - mc.transport.ico_fullscreen._width - (BUTTON_MARGIN*2);
    mc.transport.ico_fullscreen._x = video_mc._width - mc.transport.ico_fullscreen._width - BUTTON_MARGIN;
    mc.transport.ico_sound._y = mc.transport.ico_sound_muted._y = mc.transport.ico_fullscreen._y = BUTTON_MARGIN;
    mc.transport.progress_bar_bg._width = mc.transport.ico_sound._x - mc.transport.progress_bar_bg._x - (BUTTON_MARGIN*2);
    mc.transport.progress_bar_load._x = mc.transport.progress_bar_position._x = mc.transport.progress_bar_bg._x + 1;
    mc.transport._y = video_mc._y + video_mc._height - mc.transport._height;
  }
  function toggle_fullscreen(){
    Stage.fullScreenSourceRect = new Rectangle(0,0,Stage.width,Stage.height);
    Stage.addListener(this);
    Stage.displayState == 'fullScreen' ? Stage.displayState = 'normal' : Stage.displayState = 'fullScreen';
  }
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
    mc.transport.attachMovie('ico_sound_muted','ico_sound_muted',LEVEL_ICO_SOUND);
    make_button(mc.transport.ico_sound_muted,Delegate.create(this,toggle_audio));
    audio.setVolume(0);
  }
  function unmute(){
    audio_muted = false;
    mc.transport.attachMovie('ico_sound','ico_sound',LEVEL_ICO_SOUND);
    make_button(mc.transport.ico_sound,Delegate.create(this,toggle_audio));
    audio.setVolume(100);
  }
  function toggle_audio(){
    if(audio_muted){
      unmute();
    } else {
      mute();
    }
    redraw_transport();
  }
}