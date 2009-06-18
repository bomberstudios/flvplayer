import com.bomberstudios.video.Player;

class flvplayer {
  var _timeline:MovieClip;
  var _video:com.bomberstudios.video.Player;

  function flvplayer(timeline:MovieClip){
    trace("Starting app...");
    _timeline = timeline;
    _video = new Player(_timeline);
    _video.aspect_ratio = _timeline.aspect_ratio;
    _video.set_width(Stage.width);
    _video.video_path = _timeline.video_path;
    if (_timeline.watermark) {
      _video.load_watermark(_timeline.watermark);
    }
    if (_timeline.has_streaming) {
      _video.has_streaming = _timeline.has_streaming;
    }
    if (_timeline.fullscreen) {
      _video.fullscreen_enabled = true;
    }
    _video.placeholder_path = _timeline.placeholder;
    if (_timeline.autoplay != undefined) {
      _video.toggle_play();
    }
  }
  static function main(tl:MovieClip){
    var app:flvplayer = new flvplayer(tl);
  }
}