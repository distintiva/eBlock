package cc.customcode.util
{
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import assets.Resources;
	
	import translation.Translator;

	public class FileUtil
	{
		static private const fs:FileStream = new FileStream();
		
		static public function LoadFile(path:String):String
		{
			return ReadString(File.applicationDirectory.resolvePath(path));
		}
		
		static public function ReadBytes(file:File):ByteArray
		{
			if(!file.exists){
				return new ByteArray();
			}
			var result:ByteArray = new ByteArray();
			try{
				fs.open(file, FileMode.READ);
				fs.readBytes(result);
			}catch(error:Error){
				trace(error);
			}finally{
				fs.close();
			}
			return result;
		}
		
		static public function ReadString(file:File):String
		{
			fs.open(file, FileMode.READ);
			var result:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			return result;
		}
		
		static public function WriteString(file:File, str:String):void
		{
			fs.open(file, FileMode.WRITE);
			fs.writeUTFBytes(str);
			fs.close();
		}
		
		static public function WriteBytes(file:File, bytes:ByteArray):void
		{
			fs.open(file, FileMode.WRITE);
			fs.writeBytes(bytes);
			fs.close();
		}
		
		static public function PrintScreen():void
		{
			var scale:Number = 3;
			var bmd:BitmapData = new BitmapData(
				eBlock.app.stage.stageWidth*scale,
				eBlock.app.stage.stageHeight*scale,true
			);
			var matrix:Matrix = new Matrix();
			matrix.scale(scale,scale);
			eBlock.app.scaleX = eBlock.app.scaleY = scale;
			bmd.drawWithQuality(eBlock.app, matrix, null, null, null, false, StageQuality.BEST);
			eBlock.app.scaleX = eBlock.app.scaleY = 1;
			var jpeg:ByteArray = bmd.encode(bmd.rect, new PNGEncoderOptions());
			bmd.dispose();
			var now:Date = new Date();
			var path:String = "screen_"+Math.floor(now.time)+".png";
			var fileScreen:File = File.desktopDirectory.resolvePath(path);
			FileUtil.WriteBytes(fileScreen, jpeg);
			jpeg.clear();
		}
		
		static public function fixFileName(s:String):String {
			// Replace illegal characters in the given string with dashes.
			const illegal:String = '\\/:*?"<>|%';
			var result:String = '';
			for (var i:int = 0; i < s.length; i++) {
				var ch:String = s.charAt(i);
				if ((i == 0) && ('.' == ch)) ch = '-'; // don't allow leading period
				result += (illegal.indexOf(ch) > -1) ? '-' : ch;
			}
			return result;
		}
		
		static private var spToSave:Sprite;
		static private var spRect:Rectangle;  //- rectángulo que ocupa el codigo
		
		static public function toARGB(rgb:uint, newAlpha:uint):uint{
			var argb:uint = 0;
			argb = (rgb);
			argb += (newAlpha<<24);
			return argb;
		}
		
		static public function fileSaved(e:Event):void {
			
			var fileScreen:File = e.target as File;
			var marco:int = 20;
			
			var scale:Number = 1;
			var bmd:BitmapData = new BitmapData(
				spRect.width*scale + marco*scale*2,
				spRect.height*scale + marco*scale*2 +34,true
			);
			
			
			
			
			var clip:Rectangle = new Rectangle(0 ,0,spRect.width*scale + marco*scale*2, spRect.height*scale + marco*scale*2);
				
			
			var matrix:Matrix = new Matrix();
			matrix.scale(scale,scale);
			matrix.translate(0-spRect.x + marco*scale  , 0- spRect.y + marco*scale  );
			
			
			
			spToSave.scaleX = spToSave.scaleY = scale;
			bmd.drawWithQuality(spToSave, matrix, null, null, clip, false, StageQuality.BEST);
			
			var logo:Bitmap = Resources.createBmp("eblockLogo");
			
			var alphaBitmap:BitmapData = new BitmapData(logo.width, logo.height, true, toARGB(0x000000, (.4 * 255)));  //- imagen Alpha para poder copiar la amnterior con Alpha

			bmd.copyPixels(logo.bitmapData, new Rectangle(0,0,logo.width,logo.height), new Point(bmd.width -logo.width-2 ,bmd.height-logo.height-2) , alphaBitmap, null, true);
			
			
			
			spToSave.scaleX = spToSave.scaleY = 1;
			var jpeg:ByteArray = bmd.encode(bmd.rect, new PNGEncoderOptions());
			bmd.dispose();
			var now:Date = new Date();
			var path:String = "screen_"+Math.floor(now.time)+".png";
			//var fileScreen:File = File.desktopDirectory.resolvePath(path);
			FileUtil.WriteBytes(fileScreen, jpeg);
			jpeg.clear();
			
		}	
		
		static public function SaveCode(sp:Sprite, rect:Rectangle):void
		{
			spToSave = sp;
			spRect = rect;
			
			var defaultName:String = "eblock_export.png";
			var path:String = fixFileName(defaultName);
			var file:File= File.desktopDirectory.resolvePath(path);
			file.addEventListener(Event.SELECT, fileSaved);
			file.browseForSave(Translator.map("Please choose file location to save PNG image ") );
			
			return;
			
			
		}
	}
}