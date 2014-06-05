package cn.twodland.video.youku {

	import cn.twodland.common.Logger;
	import cn.twodland.video.IVideoParser;
	import cn.twodland.video.VideoPartData;
	
	import com.hurlant.util.Base64;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	
	import org.as3commons.lang.StringBuffer;

	[Event(name="init", type="flash.events.Event")]
	[Event(name="complete", type="flash.events.Event")]
	public class YoukuParser extends EventDispatcher implements IVideoParser {
		
		private static const YOUKU_PLAYER_URL:String = 'file:///Volumes/Macintosh HD/develop/git/ASLab/ASLab/bin-debug/player_yk.swf';
		private static const CTYPE:int = 10;
		private static const EV:int = 1;
		private static const HD_TYPES:Object = {
			'flv' : '0',
			'flvhd' : '0',
			'mp4' : '1',
			'hd2' : '2',
			'hd3' : '3'
		};
		
		private var clib:* = null;
		private var cRandomProxy:Class = null;
		private var playListData:PlayListData = new PlayListData();

		public function YoukuParser() {}

		/**
		 * 初始化解析器
		 * 加载优酷播放器，并反射出必要的类，供解析使用
		 * 初始化完成时会发布INIT事件
		 */
		public function init():void {
			if(isInited()) {
				dispatchEvent(new Event(Event.INIT));
				return;
			}
			// 初始化上下文
			var context:LoaderContext = new LoaderContext();
			context.applicationDomain = ApplicationDomain.currentDomain;
			// 构造加载器
			var loader:Loader = new Loader();
			var self:YoukuParser = this;
			var handler:Function = function(evt:Event):void {
				Logger.log('player_yk,swf loaded!');
				// 删除事件监听器
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, handler);
				// 获取youku中必要的类
				var domain:ApplicationDomain = ApplicationDomain.currentDomain;
				// 获取随机数代理类
				cRandomProxy = domain.getDefinition('com.youkuet.RandomProxy') as Class;
				// 初始化clib类
				var cLoaderClazz:Class = domain.getDefinition('cmodule.ccYouku.CLibInit') as Class;
				var cLoader:* = new cLoaderClazz();
				self.clib = cLoader.init();
				Logger.log('YoukuParser inited!');
				// 发布初始化完成消息
				self.dispatchEvent(new Event(Event.INIT));
			}
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, handler);
			// 加载youku播放器
			loader.load(new URLRequest(YOUKU_PLAYER_URL), context);
		}
		/**
		 * 解析器是否初始化
		 * @return 
		 */
		public function isInited():Boolean {
			return clib != null;
		}

		private function setSize(data:String):String {
			if(clib == null)
				throw new Error('Parser must be inited first!');
			var ba:ByteArray = clib.setSize(data) as ByteArray;
			return Base64.encodeByteArray(ba);
		}
		private function getSize(data:String):String {
			if(clib == null)
				throw new Error('Parser must be inited first!');
			var ba:ByteArray = Base64.decodeToByteArray(data);
			return clib.getSize(ba, ba.length) as String;
		}
		public function changeSize(data:String):String {
			if(clib == null)
				throw new Error('Parser must be inited first!');
			return clib.changeSize(data);
		}

		/**
		 * 加载视频列表并解析
		 * 解析完成时会发布COMPLETE事件
		 * @param vid videoid
		 */
		public function loadVideos(vid:String):void {
			Logger.logf('load videos for vid: %s', vid);
			
			// TODO: 
			// v.youku.com使用crossdomain.xml限制了flash的访问
			// 需要通过服务器读取数据返回给播放器，或通过其他手段规避crossdomain限制
			
			// 构造URL
			var timezone:String = new Date().toString();
			timezone = timezone.substr(timezone.indexOf('GMT') + 3, 3);
			var url:StringBuffer = new StringBuffer('http://v.youku.com/player/getPlayList/VideoIDS/');
			url.append(vid).append('/timezone/').append(timezone).append('/version/5/source/video');
			// 构造请求
			var req:URLRequest = new URLRequest(url.toString());
			req.method = URLRequestMethod.GET;
			var data:URLVariables = new URLVariables();
			data.ctype = CTYPE;
			data.ev = EV;
			data.n = 3;
			data.password = '';
			data.ran = int(Math.random() * 9999);
			req.data = data;
			// 加载数据
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, playListCompleteHandler);
			loader.load(req);
		}
		private function playListCompleteHandler(evt:Event):void {
			Logger.log('raw videos info getted...');
			var loader:URLLoader = evt.target as URLLoader;
			loader.removeEventListener(Event.COMPLETE, playListCompleteHandler);
			// 获取数据
			var rawData:Object = JSON.parse(String(loader.data));
			parseMainData(rawData.data[0]);
			// 发布处理完成消息
			dispatchEvent(new Event(Event.COMPLETE));
		}
		private function parseMainData(data:Object):void {
			// 保存ip和视频总长度
			playListData.ip = data.ip;
			playListData.seconds = Number(data.seconds);
			playListData.key1 = data.key1;
			playListData.key2 = data.key2;
			// 解析ep
			var epSize:String = this.getSize(data.ep);
			var eps:Array = epSize.split('_');
			playListData.sid = eps[0];
			playListData.tk = eps[1];
			// 获取最清晰的视频流
			var streamType:String = getClearStreamType(data.streamsizes);
			playListData.streamType = streamType;
			// 读取并处理分段信息
			var rawFileId:String = data.streamfileids[streamType];
			var rndProxy:Object = new this.cRandomProxy(data.seed);
			for(var segIndex:uint=0; segIndex < data.segs[streamType].length; segIndex++) {
				var segObj:* = data.segs[streamType][segIndex];
				var segData:SegmentVideoData = new SegmentVideoData();
				segData.no = int(segObj.no);
				segData.size = Number(segObj.size);
				segData.seconds = Number(segObj.seconds);
				segData.key = segObj.k;
				segData.fileId = getFileId(rawFileId, segIndex, rndProxy);
				segData.fileURL = getFileURL(segData);
				playListData.segs.push(segData);
			}
		}
		private function getClearStreamType(sizes:Object):String {
			var streamType:String = 'flv';
			var maxSize:Number = 0;
			for(var st:String in sizes) {
				var size:Number = Number(sizes[st]);
				if(size > maxSize) {
					maxSize = size;
					streamType = st;
				}
			}
			return streamType;
		}
		private function getFileId(rawFileId:String, segIndex:int, rndProxy:Object):String {
			var rndResult:String = rndProxy.cg_fun(rawFileId);
			var segIndexHex:String = segIndex.toString(16);
			if(segIndexHex.length == 1)
				segIndexHex = '0' + segIndexHex;
			var fileId:String = rndResult.slice(0, 8) + segIndexHex.toUpperCase() + rndResult.slice(10, rndResult.length);
			return fileId;
		}
		private function getFileURL(segData:SegmentVideoData):String {
			var noStr:String = segData.no.toString(16);
			if(noStr.length == 1)
				noStr = '0' + noStr;
			// streamType
			var streamType:String = playListData.streamType;
			if(streamType == 'hd2' || streamType == 'hd3') streamType = 'flv';
			// hdType
			var hdType:String = HD_TYPES.hasOwnProperty(playListData.streamType) ? 
				HD_TYPES[playListData.streamType] : '0';
			// EP
			var ep:String = playListData.sid + '_' + segData.fileId + '_' + playListData.tk + '_0';
			var epSize:String = changeSize(ep);
			ep = encodeURIComponent(setSize(ep + '_' + epSize.substr(0, 4)));
			// 拼接URL
			var url:StringBuffer = new StringBuffer('http://k.youku.com/player/getFlvPath/sid/');
			url.append(playListData.sid).append('_').append(noStr);
			url.append('/st/').append(streamType).append('/fileid/').append(segData.fileId);
			url.append('?start=0&K=').append(segData.key).append('&hd=').append(hdType);
			url.append('&myp=0&ts=').append(segData.seconds).append('&ymovie=1&ypp=0');
			url.append('&ctype=').append(CTYPE).append('&ev=').append(EV);
			url.append('&token=').append(playListData.tk).append('&oip=').append(playListData.ip);
			url.append('&ep=').append(ep);
			return url.toString();
		}

		public function getVideos():Vector.<VideoPartData> {
			var videos:Vector.<VideoPartData> = new Vector.<VideoPartData>();
			for each(var seg:SegmentVideoData in playListData.segs) {
				var vpd:VideoPartData = new VideoPartData();
				vpd.url = seg.fileURL;
				vpd.duration = seg.seconds * 1000;
				videos.push(vpd);
			}
			return videos;
		}

	}
}