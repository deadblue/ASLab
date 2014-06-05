package {
	
	import cn.twodland.common.Logger;
	import cn.twodland.video.VideoPartData;
	import cn.twodland.video.youku.YoukuParser;
	
	import com.hurlant.util.Base64;
	
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.ByteArray;
	
	import org.as3commons.lang.StringBuffer;
	
	public class ASLab extends Sprite {

		public function ASLab() {
			Logger.setDebug(true);
			// 初始化youku解析器
			var youku:YoukuParser = new YoukuParser();
			youku.addEventListener(Event.INIT, parserInitHandler);
			youku.addEventListener(Event.COMPLETE, parserCompleteHandler);
			youku.init();
		}
		
		protected function parserInitHandler(evt:Event):void {
			var youku:YoukuParser = evt.target as YoukuParser;
			youku.removeEventListener(Event.INIT, parserInitHandler);
			youku.loadVideos('XNDk3MzczMTI0');
		}
		
		protected function parserCompleteHandler(evt:Event):void {
			var youku:YoukuParser = evt.target as YoukuParser;
			youku.removeEventListener(Event.COMPLETE, parserCompleteHandler);
			Logger.log('parse complete');
			var datas:Vector.<VideoPartData> = youku.getVideos();
			for each(var data:VideoPartData in datas) {
				Logger.log(data.url);
			}
		}
		
	}
}