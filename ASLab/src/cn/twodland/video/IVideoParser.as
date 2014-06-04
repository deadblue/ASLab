package cn.twodland.video {
	
	public interface IVideoParser {

		function init():void;
		
		function isInited():Boolean;
		
		function loadVideos(vid:String):void;

		function getVideos():Vector.<VideoPartData>;

	}
}