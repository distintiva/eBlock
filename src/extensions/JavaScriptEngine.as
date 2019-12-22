package extensions
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import cc.customcode.interpreter.RemoteCallMgr;
	import cc.customcode.util.FileUtil;
	
	import org.aswing.JOptionPane;
	
	import util.LogManager;
	
	public class JavaScriptEngine
	{
		private const _htmlLoader:HTMLLoader = new HTMLLoader();
		private var _ext:Object;
		private var _name:String = "";
//		public var port:String = "";
		public function JavaScriptEngine(name:String="")
		{
			_name = name;
			_htmlLoader.placeLoadStringContentInApplicationSandbox = true;
		}
		private function register(name:String,descriptor:Object,ext:Object,param:Object):void{
			_ext = ext;
			if(_ext._getStatus().msg.indexOf("disconnected")>-1 && SerialManager.sharedManager().isConnected)
			{
				//尝试连接
				onConnected(null);
			}
			LogManager.sharedManager().log("registed:"+_ext._getStatus().msg);
			//trace(SerialManager.sharedManager().list());
			//_timer.start();
		}
		public function get connected():Boolean{
			if(_ext){
				return _ext._getStatus().status==2;
			}
			return false;
		}
		public function get msg():String{
			if(_ext){
				return _ext._getStatus().msg;
			}
			return "Disconnected";
		}
		public function call(method:String,param:Array,ext:ScratchExtension):void{
			if(!connected){
				return;
			}
			var handler:Function = _ext[method];
			if(null == handler){
				trace(method + " not provide!");
				responseValue();
				return;
			}
			try{
				if(handler.length > param.length){
					handler.apply(null, [0].concat(param));
				}else{
					handler.apply(null, param);
				}
			}catch(error:Error) {
				trace(error.getStackTrace());
			}
		}

		public function closeDevice():void{
			if(_ext){
				_ext._shutdown();
			}
		}
		private function onConnected(evt:Event):void{
			if(_ext){
				var dev:SerialDevice = SerialDevice.sharedDevice();
				_ext._deviceConnected(dev);
				LogManager.sharedManager().log("register:"+_name);
			}
		}
		private function onClosed(evt:Event):void{
			if(_ext){
				var dev:SerialDevice = SerialDevice.sharedDevice();
				_ext._deviceRemoved(dev);
				LogManager.sharedManager().log("unregister:"+_name);
			}
		}
		private function onRemoved(evt:Event):void{
			if(_ext&&ConnectionManager.sharedManager().extensionName==_name){
				ConnectionManager.sharedManager().removeEventListener(Event.CONNECT,onConnected);
				ConnectionManager.sharedManager().removeEventListener(Event.REMOVED,onRemoved);
				ConnectionManager.sharedManager().removeEventListener(Event.CLOSE,onClosed);
				var dev:SerialDevice = SerialDevice.sharedDevice();
				_ext._deviceRemoved(dev);
				_ext = null;
			}
		}
		public function loadJS(path:String):void{
			
			var dev:SerialDevice = SerialDevice.sharedDevice();
			
			var html:String = "var ScratchExtensions = {};" +
				"ScratchExtensions.register = function(name,desc,ext,param){" +
				"	try{			" +
				"		callRegister(name,desc,ext,param);		" +
				"	}catch(err){			" +
				"		setTimeout(ScratchExtensions.register,10,name,desc,ext,param);	" +
				"	}	" +
				"};";
//			html += FileUtil.ReadString(File.applicationDirectory.resolvePath("js/AIRAliases.js"));
			html += FileUtil.ReadString(new File(path));
			_htmlLoader.window.eval(html);
			_htmlLoader.window.callRegister = register;
			_htmlLoader.window.parseFloat = readFloat;
			_htmlLoader.window.parseShort = readShort;
			_htmlLoader.window.parseDouble = readDouble;
			_htmlLoader.window.float2array = float2array;
			_htmlLoader.window.short2array = short2array;
			_htmlLoader.window.int2array = int2array;
			_htmlLoader.window.string2array = string2array;
			_htmlLoader.window.array2string = array2string;
			_htmlLoader.window.responseValue = responseValue;

			_htmlLoader.window.processDataMProtocol = processDataMProtocol;
			_htmlLoader.window.runPackage =  dev.runPackage;
			_htmlLoader.window.getPackage = dev.getPackage;
			
			
			_htmlLoader.window.trace = trace;
			_htmlLoader.window.interruptThread = interruptThread;
			_htmlLoader.window.air = {"trace":trace};
			ConnectionManager.sharedManager().addEventListener(Event.CONNECT,onConnected);
			ConnectionManager.sharedManager().addEventListener(Event.REMOVED,onRemoved);
			ConnectionManager.sharedManager().addEventListener(Event.CLOSE,onClosed);
		}
		
		
		
		
		
		//-------------- From extension.js to allow smaller extensions code
		
				
		
		
		private var _rxBuf:Array = [];
		//private var inputArray:Array = [];
		private var _isParseStart:Boolean = false;
		private var _isParseStartIndex:int = 0;
		private var responsePreprocessor:Object = {};
		//- process data for protocol created by Makeblock 
		private function processDataMProtocol(bytes:Array):void {
			var len:int = bytes.length;
			if(_rxBuf.length>30){
				_rxBuf = [];
			}
			for(var index:int=0;index<bytes.length;index++){
				var c:int= bytes[index];  // int está bien para char ???????????
				_rxBuf.push(c);
				if(_rxBuf.length>=2){
					if(_rxBuf[_rxBuf.length-1]==0x55 && _rxBuf[_rxBuf.length-2]==0xff){
						_isParseStart = true;
						_isParseStartIndex = _rxBuf.length-2;
					}
					if(_rxBuf[_rxBuf.length-1]==0xa && _rxBuf[_rxBuf.length-2]==0xd&&_isParseStart){
						_isParseStart = false;
						
						var position:int = _isParseStartIndex+2;
						var extId:int = _rxBuf[position];
						position++;
						var type:int = _rxBuf[position];
						position++;
						//1 byte 2 float 3 short 4 len+string 5 double
						var value:*;
						switch(type){
							case 1:{
								value = _rxBuf[position];
								position++;
							}
								break;
							case 2:{
								value = readFloatFromBuff(_rxBuf,position);
								position+=4;
							}
								break;
							case 3:{
								value = readIntFromBuff(_rxBuf,position,2);
								position+=2;
							}
								break;
							case 4:{
								var l:int = _rxBuf[position];
								position++;
								value = readStringFromBuff(_rxBuf,position,l);
							}
								break;
							case 5:{
								value = readDoubleFromBuff(_rxBuf,position);
								position+=4;
							}
								break;
							case 6:
								value = readIntFromBuff(_rxBuf,position,4);
								position+=4;
								break;
						}
						if(type<=6){
							if (responsePreprocessor[extId] && responsePreprocessor[extId] != null) {
								value = responsePreprocessor[extId](value);
								responsePreprocessor[extId] = null;
							}
							/*
							 *antes de hacer un  responseValue deberíamos pasar el value a SerialDevice
							*/
							
								responseValue(extId,value);
							
						}else{
							responseValue();
						}
						_rxBuf = [];
					}
				} 
			}
		}
		
			
		
		
		
		
		
		private function readFloatFromBuff(arr,position):Number{
			var f:Array= [arr[position],arr[position+1],arr[position+2],arr[position+3]];
			return  readFloat(f);//parseFloat(f);
		}
		private function readIntFromBuff(arr,position,count):int{
			var result:int = 0;
			for(var i:int=0; i<count; ++i){
				result |= arr[position+i] << (i << 3);
			}
			return result;
		}
		private function readDoubleFromBuff(arr,position):Number{
			return readFloatFromBuff(arr,position);
		}
		private function readStringFromBuff(arr,position,len):String{
			var value:String = "";
			for(var ii:int=0;ii<len;ii++){
				value += String.fromCharCode(_rxBuf[ii+position]);
			}
			return value;
		}
		
		
		
		private function responseValue(...args):void{
			if(args.length == 0){ //if(args.length < 2){
				RemoteCallMgr.Instance.onPacketRecv();
			}else if(args.length == 1){
				if(args[0] == 0x80){
					eBlock.app.runtime.mbotButtonPressed.notify(Boolean(args[1]));
				}else{
					RemoteCallMgr.Instance.onPacketRecv(args[0]);
				}
			}else{
				RemoteCallMgr.Instance.onPacketRecv(args[1]);
			}
		}
		
		static private function interruptThread(msg:String):void
		{
			RemoteCallMgr.Instance.interruptThread();
			JOptionPane.showMessageDialog("", msg);
		}
		
		static private function readFloat(bytes:Array):Number{
			if(bytes.length < 4){
				return 0;
			}
			for(var i:int=0; i<4; ++i){
				tempBytes[i] = bytes[i];
			}
			tempBytes.position = 0;
			return tempBytes.readFloat();
		}
		static private function readDouble(bytes:Array):Number{
			return readFloat(bytes);
		}
		static private function readShort(bytes:Array):Number{
			if(bytes.length < 2){
				return 0;
			}
			for(var i:int=0; i<2; ++i){
				tempBytes[i] = bytes[i];
			}
			tempBytes.position = 0;
			return tempBytes.readShort();
		}
		static private function float2array(v:Number):Array{
			tempBytes.position = 0;
			tempBytes.writeFloat(v);
			return [tempBytes[0], tempBytes[1], tempBytes[2], tempBytes[3]];
		}
		static private function short2array(v:Number):Array{
			tempBytes.position = 0;
			tempBytes.writeShort(v);
			return [tempBytes[0], tempBytes[1]];
		}
		static private function int2array(v:Number):Array{
			tempBytes.position = 0;
			tempBytes.writeInt(v);
			return [tempBytes[0], tempBytes[1], tempBytes[2], tempBytes[3]];
		}
		static private function string2array(v:String):Array{
			tempBytes.position = 0;
			tempBytes.writeUTFBytes(v);
			var array:Array = [];
			for(var i:int=0;i<tempBytes.position;i++){
				array[i] = tempBytes[i];
			}
			return array;
		}
		static private function array2string(bytes:Array):String{
			for(var i:int=0;i<bytes.length;i++){
				tempBytes[i] = bytes[i];
			}
			tempBytes.position = 0;
			return tempBytes.readUTFBytes(bytes.length);
		}
		static private const tempBytes:ByteArray = new ByteArray();
		tempBytes.endian = Endian.LITTLE_ENDIAN;
	}
}