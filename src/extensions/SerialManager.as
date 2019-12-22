package extensions
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import cc.customcode.interpreter.BlockInterpreter;
	import cc.customcode.uibot.util.AppTitleMgr;
	import cc.customcode.util.UploadSizeInfo;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.LogManager;
	import util.SharedObjectManager;

	public class SerialManager extends EventDispatcher
	{
		private var moduleList:Array = [];
		private var _currentList:Array = [];
		private static var _instance:SerialManager;
		public var currentPort:String = "";
		private var _selectPort:String = "";
		public var _app:eBlock;
		private var _board:String = "uno";
		private var _device:String = "uno";
		private var _upgradeBytesLoaded:Number = 0;
		private var _upgradeBytesTotal:Number = 0;
		private var _isInitUpgrade:Boolean = false;
		private var _dialog:DialogBox = new DialogBox();
		private var _hexToDownload:String = ""
			
//		private var _isMacOs:Boolean = ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS;
//		private var _avrdude:String = "";
//		private var _avrdudeConfig:String = "";
		public static function sharedManager():SerialManager{
			if(_instance==null){
				_instance = new SerialManager;
			}
			return _instance;
		}
		private var _serial:AIRSerial;
		
		public function SerialManager()
		{
			_serial = new AIRSerial();
//			_avrdude = _isMacOs?"avrdude":"avrdude.exe";
//			_avrdudeConfig = _isMacOs?"avrdude_mac.conf":"avrdude.conf";
			
			_board = SharedObjectManager.sharedManager().getObject("board","uno");
			_device = SharedObjectManager.sharedManager().getObject("device","uno");
			var timer:Timer = new Timer(4000);
			timer.addEventListener(TimerEvent.TIMER,onTimerCheck);
			timer.start();
		}
		private function onTimerCheck(evt:TimerEvent):void{
			if(_serial.isConnected){
				if(this.list.indexOf(_selectPort)==-1){
					this.close();
				}
			}
		}
		public function setApp(app:eBlock):void{
			_app = app;
		}
		public var asciiString:String = "";
		private function onChanged(evt:Event):void{
			var len:uint = _serial.getAvailable();
			if(len>0){
				ConnectionManager.sharedManager().onReceived(_serial.readBytes());
			}
			return;
			if(len>0){
				var bytes:ByteArray = _serial.readBytes();
				bytes.position = 0;
				asciiString = "";
				var hasNonChar:Boolean = false;
				var c:uint;
				for(var i:uint=0;i<bytes.length;i++){
					c = bytes.readByte();
					asciiString += String.fromCharCode();
					if(c<30){
						hasNonChar = true;
					}
				}
				if(!hasNonChar)dispatchEvent(new Event(Event.CHANGE));
				bytes.position = 0;
				ParseManager.sharedManager().parseBuffer(bytes);
			}
		}
		public function get isConnected():Boolean{
			return _serial.isConnected;
		}
		public function get list():Array{
			try{
				_currentList = formatArray(_serial.list().split(",").sort());
				var emptyIndex:int = _currentList.indexOf("");
				if(emptyIndex>-1){
					_currentList.splice(emptyIndex,emptyIndex+1);
				}
			}catch(e:*){
				
			}
			return _currentList;
		}
		private function formatArray(arr:Array):Array {
			var obj:Object={};
			return arr.filter(function(item:*, index:int, array:Array):Boolean{
				return !obj[item]?obj[item]=true:false
			});
		}
		public function update():void{
			if(!_serial.isConnected){
				eBlock.app.topBarPart.setDisconnectedTitle();
				return;
			}else{
				eBlock.app.topBarPart.setConnectedTitle("Serial Port");
			}
		}
		
		public function sendBytes(bytes:ByteArray):void{
			if(_serial.isConnected){
				_serial.writeBytes(bytes);
			}
		}
		public function sendString(msg:String):int{
			return _serial.writeString(msg);
		}
		public function readBytes():ByteArray{
			var len:uint = _serial.getAvailable();
			if(len>0){
				return _serial.readBytes();
			}
			return new ByteArray;
		}
		
		public function readAllBytes():ByteArray{
			//var len:uint = _serial.getAvailable();
			var tout:int = getTimer();
			while(!_serial.getAvailable() &&  ( getTimer()- tout)<500  ){
			}
			
			var rc:ByteArray =  _serial.readBytes();
			var temp:ByteArray = new ByteArray();
			while( rc.length){
				//trace(rc.toString());
				
				while( rc.bytesAvailable){
					temp.writeByte( rc.readUnsignedByte() );
				}
				/*for( var b:int; b<rc.length;b++){
					trace(rc.readByte());
					temp.writeByte( rc.readByte() );
				}*/
				
				rc =  _serial.readBytes();
			}
			
			
			/*if(len>0){
				return _serial.readBytes();
			}*/
			return temp;
		}
		
		public function get board():String{
			return _board;
		}
		public function set board(s:String):void{
			_board = s;
		}
		public function set device(s:String):void{
			_device = s;
		}
		public function get device():String{
			return _device;
		}
		public function open(port:String,baud:uint=115200):Boolean{
			if(_serial.isConnected){
				_serial.close();
			}
			_serial.addEventListener(Event.CHANGE,onChanged);
			var r:uint = _serial.open(port,baud);
			_selectPort = port;
			ArduinoManager.sharedManager().isUploading = false;
			if(r==0){
				eBlock.app.topBarPart.setConnectedTitle("Serial Port");
			}
			return r == 0;
		}
		public function close():void{
			if(_serial.isConnected){
				SerialDevice.sharedDevice().clearAll();
				BlockInterpreter.Instance.stopAllThreads();
				_serial.removeEventListener(Event.CHANGE,onChanged);
				_serial.close();
				ConnectionManager.sharedManager().onClose(_selectPort);
			}
		}
		public function connect(port:String):int{
			if(SerialDevice.sharedDevice().ports.indexOf(port)>-1&&_serial.isConnected){
				close();
			}else{
				if(_serial.isConnected){
					close();
				}
				setTimeout(ConnectionManager.sharedManager().onOpen,100,port);
			}
			return 0;
		}
		public function upgrade(hexFile:String=""):void{
			if(!isConnected){
				return;
			}
		//	eBlock.app.track("/OpenSerial/Upgrade");
			executeUpgrade();
			_hexToDownload = hexFile;
			eBlock.app.topBarPart.setConnectedTitle(AppTitleMgr.Uploading);
			ArduinoManager.sharedManager().isUploading = false;
			if(DeviceManager.sharedManager().currentDevice.indexOf("leonardo")>-1){
				_serial.close();
				setTimeout(function():void{
					_serial.open(SerialDevice.sharedDevice().port,1200);
				},100);
				if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
					setTimeout( uploadHex,2000, hexFile);
				}
			}else{
				_serial.close();
		//		upgradeFirmware();
				//UploaderEx.Instance.uploadHex(hexFile);
				uploadHex(hexFile);
				
				currentPort = "";
			}
		}
		/*public function openSource():void{
			eBlock.app.track("/OpenSerial/ViewSource");
			var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/firmware/" + getFirmwareName());
			if(file.exists && file.isDirectory){
				file.openWithDefaultApplication();
			}
		}*/
		
		public function disconnect():void{
			currentPort = "";
			eBlock.app.topBarPart.setDisconnectedTitle();
//			MBlock_mod.app.topBarPart.setBluetoothTitle(false);
			ArduinoManager.sharedManager().isUploading = false;
			_serial.close();
			_serial.removeEventListener(Event.CHANGE,onChanged);
		}
		public function reconnectSerial():void{
			if(_serial.isConnected){
				_serial.close();
				setTimeout(function():void{connect(currentPort);},50);
				//setTimeout(function():void{_serial.close();},1000);
			}
		}
		
		private var process:NativeProcess;
				
			
	
		
		public function uploadHex(filePath:String):void
		{
			eBlock.app.topBarPart.setConnectedTitle(AppTitleMgr.Uploading);
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			
			info.workingDirectory = new File(  ArduinoManager.sharedManager().arduinoCliPath ) ;
			
			
			info.executable =  new File( ArduinoManager.sharedManager().arduinoCliPath + "\\arduino-cli.exe") ; 
			var argList:Vector.<String> = new Vector.<String>();
			argList.push("upload");
			argList.push("-b", DeviceManager.sharedManager().selectedBoard.fqbn );
			
			argList.push("-p", SerialDevice.sharedDevice().currPort);
			argList.push("-v");
			argList.push("-i");
			argList.push(filePath.replace("\\", "/") );
			
			//MBlock_mod.app.scriptsPart.appendMessage(/*file.nativePath +*/ " " + argList.join(" "));
			
			info.arguments = argList;
			var process:NativeProcess = new NativeProcess();
			
			
			
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onStandardOutputData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			process.start(info);
		}
		
		private var errorText:String;
		private var sizeInfo:UploadSizeInfo = new UploadSizeInfo();
		private function onStandardOutputData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var msg:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			eBlock.app.scriptsPart.appendRawMessage(msg);
						
		}
		private function onErrorData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var msg:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			if(null == errorText){
				errorText = msg;
			}else{
				errorText += msg;
			}
						
			eBlock.app.scriptsPart.appendRawMessage(msg);
			_dialog.setText(Translator.map('Uploading') + " ... " /*+ sizeInfo.update(msg) + "%"*/);
		}
		
		private function onExit(event:NativeProcessExitEvent):void
		{
			ArduinoManager.sharedManager().isUploading = false;
			LogManager.sharedManager().log("Process exited with "+event.exitCode);
			if(event.exitCode > 0){
				_dialog.setText(Translator.map('Upload Failed'));
				LogManager.sharedManager().log(errorText);
				eBlock.app.scriptsPart.appendMsgWithTimestamp(errorText, true);
			}else{
				_dialog.setText(Translator.map('Upload Finish'));
			}
			setTimeout(open,2000,_selectPort);
			errorText = null;
			//setTimeout(_dialog.cancel,2000);
		}

		public function executeUpgrade():void {
			if(!_isInitUpgrade){
				_isInitUpgrade = true;
				function cancel():void { _dialog.cancel(); }
				_dialog.addTitle(Translator.map('Start Uploading'));
				_dialog.addButton(Translator.map('Close'), cancel);
			}else{
				_dialog.setTitle(('Start Uploading'));
				_dialog.setButton(('Close'));
			}
			_upgradeBytesLoaded = 0;
			_dialog.setText(Translator.map('Executing'));
			_dialog.showOnStage(_app.stage);
		}
		
		public function reopen():void
		{
			open(_selectPort);
		}
	}
}