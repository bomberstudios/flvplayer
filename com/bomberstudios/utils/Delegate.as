/**
* 
* Delegate Class, MTASC compatible
* 
**/

class com.bomberstudios.utils.Delegate {
  public static function create(scope:Object,method:Function):Function{
    var params:Array = arguments.splice(2,arguments.length-2);
    var proxyFunc:Function = function():Void{
      method.apply(scope,arguments.concat(params));
    }
    return proxyFunc;
  }
  public static function createR(scope:Object,method:Function):Function{
    var params:Array = arguments.splice(2,arguments.length-2);
    var proxyFunc:Function = function():Void{
      method.apply(scope,params.concat(arguments));
    }
    return proxyFunc;
  }
}