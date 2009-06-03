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
  var cue_markers:Array;

  // HTML Variables
  var aspect_ratio:Number = 4/3;
  var $video_path:String;
  var $placeholder_path:String;

  // Some constants for UI redrawing
  var BUTTON_MARGIN = 3;

  // Levels for movieclips
  var LEVEL_VIDEODISPLAY:Number         = 100;
  var LEVEL_PLACEHOLDER:Number          = 150;
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
  var LEVEL_CUE_MARKERS:Number          = 9000;
  

  function Player(_mc:MovieClip){
    Stage.scaleMode = "noScale";
    Stage.align = "TL";
    mc = _mc.createEmptyMovieClip('v',_mc.getNextHighestDepth());
    cue_markers = [];
    create_ui();
    setup_video();
    start_run_loop();
  }
  function toString(){
    return "FLVPlayer v1.0";
  }
  private function setup_video(){
    nc = new NetConnection();
    nc.connect(null);
    ns = new NetStream(nc);
    ns.setBufferTime(BUFFER_TIME);

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


  // Video Data
  public function get video_path():String {
    return $video_path;
  }
  public function set video_path(s:String) {
    $video_path = s;
  }
  public function set placeholder_path(s:String){
    $placeholder_path = s;
    load_placeholder($placeholder_path);
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
    hide_placeholder();
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
    hide_placeholder();
    if(is_playing){
      pause();
    } else {
      play();
    }
  }
  function seek_to(pos:Number){
    ns.seek(pos);
  }

  // Run loop
  private function start_run_loop(){
    run_loop_id = setInterval(Delegate.create(this,on_run_loop),10);
  }
  private function on_run_loop(){

    update_progress_bar();

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
  function on_rollover_btn(btn:MovieClip){
    btn.attachMovie(btn._name + "_over",btn._name,1);
  }
  function on_rollout_btn(btn:MovieClip){
    btn.attachMovie(btn._name,btn._name,1);
  }
  function on_video_status(s:Object){
    for(var key in s){
      trace(key + ": " + s[key]);
    }
    if (s.code == "NetStream.Play.Stop") {
      on_video_end();
    }
  }
  function on_video_metadata(s:Object){
    // set aspect ratio
    aspect_ratio = s.width / s.height;
    metadata = s;
    for(var key in metadata){
      if (key == "cuePoints") {
        on_cue_markers(s[key]);
      }
    }
    redraw();
  }
  function on_cue_markers(markers_array){
    for(var key in markers_array){
      cue_markers.push({id: key, name: markers_array[key].name, time: markers_array[key].time});
    }
  }
  function on_cue_marker_rollover(txt:String){
    trace(txt);
  }
  function onResize(e){
    redraw();
  }
  function on_video_end(){
    seek_to(0);
    pause();
    show_placeholder();
    show_play_button();
  }
  function on_progress_bar_click(){
    hide_placeholder();
    var x_pos = mc._xmouse - (mc.transport._x + mc.transport.progress_bar_bg._x);
    seek_to(position_to_time(x_pos));
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
    show_play_button();

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
    mc.transport.progress_bar_bg.onRelease = Delegate.create(this,on_progress_bar_click);
  }
  private function redraw(){
    var tentative_video_height = Stage.width / aspect_ratio;
    if(tentative_video_height > Stage.height){
      set_width(Stage.height * aspect_ratio);
    } else {
      set_width(Stage.width);
    }
    video_mc._y = Stage.height / 2 - video_mc._height/2;
    video_mc._x = Stage.width / 2 - video_mc._width/2;
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
    mc.transport._x = video_mc._x;
    update_cue_markers();
  }
  private function update_progress_bar(){
    mc.transport.progress_bar_position._width = 0;
    mc.transport.progress_bar_position._width = ((ns.time / metadata.duration) * mc.transport.progress_bar_bg._width) - 2;
    mc.transport.progress_bar_load._width = ((ns.bytesLoaded / ns.bytesTotal) * mc.transport.progress_bar_bg._width) - 2;
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
  private function show_play_button(){
    mc.transport.attachMovie('btn_play','btn_play',LEVEL_BTN_PLAY,{_x:BUTTON_MARGIN, _y:BUTTON_MARGIN});
    make_button(mc.transport.btn_play,Delegate.create(this,toggle_play));
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

  // Placeholder image
  function load_placeholder(uri:String){
    mc.createEmptyMovieClip('placeholder',LEVEL_PLACEHOLDER);
    mc.placeholder.createEmptyMovieClip('bg',100);
    mc.placeholder.createEmptyMovieClip('img',200);
    mc.placeholder.bg.beginFill(0x000000,100);
    mc.placeholder.bg.lineTo(video_mc._width,0);
    mc.placeholder.bg.lineTo(video_mc._width,video_mc._height);
    mc.placeholder.bg.lineTo(0,video_mc._height);
    mc.placeholder.bg.lineTo(0,0);
    mc.placeholder.bg.endFill();
    var loader:MovieClipLoader = new MovieClipLoader();
    loader.onLoadInit = Delegate.create(this,show_placeholder);
    loader.loadClip(uri,mc.placeholder.img);
  }
  function hide_placeholder(){
    mc.placeholder._visible = false;
  }
  function show_placeholder(){
    mc.placeholder._x = video_mc._x + Math.floor(video_mc._width / 2 - mc.placeholder.img._width / 2)
    mc.placeholder._y = video_mc._y + Math.floor(video_mc._height / 2 - mc.placeholder.img._height / 2)
    mc.placeholder._visible = true;
  }

  // Video Markers
  function update_cue_markers(){
    for (var i=0 ; i < cue_markers.length; i++){
      var current_cue = cue_markers[i];
      add_marker(current_cue.id,current_cue.name,current_cue.time);
    }
  }
  function add_marker(id,name,time){
    var marker = mc.transport.attachMovie('cue_marker','cue_marker_'+id,LEVEL_CUE_MARKERS + id,{_x: time_to_position(time)});
    marker.onRelease = Delegate.create(this,seek_to,time);
    marker.onRollOver = Delegate.create(this,on_cue_marker_rollover,name);
  }
  private function time_to_position(time:Number){
    var left = mc.transport.progress_bar_bg._x;
    var max_width = mc.transport.progress_bar_bg._width;
    return Math.floor((time / metadata.duration) * max_width + left - 3);
  }
  private function position_to_time(x_pos:Number):Number{
    trace("position_to_time("+x_pos+")");
    var max_width = mc.transport.progress_bar_bg._width;
    trace(max_width);
    return (x_pos / max_width) * metadata.duration;
  }
}