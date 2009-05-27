class flvplayer {
  var _timeline:MovieClip;
  function flvplayer(timeline){
    _timeline = timeline;
  }
  static function main(tl:MovieClip){
    var app:flvplayer = new flvplayer(tl);
  }
}
