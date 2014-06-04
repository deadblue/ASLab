package cn.twodland.common {

	import flash.external.ExternalInterface;

	public class Logger {

		public function Logger() {}

		private static var _debug:Boolean = false;

		public static function setDebug(debug:Boolean):void {
			_debug = debug;
		}

		public static function log(msg:String):void {
			if(_debug) {
				msg = printf('[ASLOG] %s', msg);
				jslog(msg);
			}
		}
		public static function logf(pattern:String, ...rest):void {
			if(_debug) {
				var msg:String = printf(pattern, rest);
				msg = printf('[ASLOG] %s', msg);
				jslog(msg);
			}
		}
		private static function jslog(msg:String):void {
			ExternalInterface.call('console.log', msg);
		}

	}
}