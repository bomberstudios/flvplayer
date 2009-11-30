import com.bomberstudios.video.Player;

class flvplayer {
  var _t:MovieClip;
  var _video:com.bomberstudios.video.Player;

  function flvplayer(timeline:MovieClip){
    trace("Starting app...");
    _t = timeline;
    var options:Object = {
      aspect_ratio: _t.aspect_ratio,
      video_path: _t.video_path,
      watermark: _t.watermark,
      has_streaming: _t.has_streaming,
      stealth_mode: _t.stealth_mode,
      fullscreen_enabled: _t.fullscreen,
      placeholder_path: _t.placeholder,
      autoplay: _t.autoplay,
      watermarkPosition: _t.watermarkPosition
    };
    _video = new Player(_t, options);
    _video.set_width(Stage.width);
    if (_t.autoplay != undefined) {
      _video.toggle_play();
    }
  }
  static function main(tl:MovieClip){
    var app:flvplayer = new flvplayer(tl);
  }
}