package cn.twodland.video.youku {
	
	public class PlayListData {

		public var ip:Number = 0;
		public var seconds:Number = 0;
		public var streamType:String = null;
		public var key1:String = null;
		public var key2:String = null;

		public var sid:String = null;
		public var tk:String = null;

		public var segs:Vector.<SegmentVideoData> = new Vector.<SegmentVideoData>();

		public function PlayListData() {}
		
	}
}