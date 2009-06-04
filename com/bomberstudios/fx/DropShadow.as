import flash.filters.DropShadowFilter;

class com.bomberstudios.fx.DropShadow {
  static function create(mc:MovieClip){
    var shadow:DropShadowFilter = new DropShadowFilter();
    shadow.alpha = 100;
    shadow.blurX = shadow.blurY = 2;
    shadow.angle = 90;
    shadow.distance = 1;

    var filters:Array = mc.filters;
    filters.push(shadow);
    mc.filters = filters;
  }
}