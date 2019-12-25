package extensions
{
		
	
	import flash.events.Event;
	import flash.utils.ByteArray;
	import blockly.signals.Signal;
		
//	import cc.customcode.interpreter.RemoteCallMgr;
	
	

	public class SerialDevice
	{
		private static var _instance:SerialDevice;
		private var _ports:Array = [];
		private var _currPort:String="";
		public function SerialDevice()
		{
		}
		public static function sharedDevice():SerialDevice{
			if(_instance==null){
				_instance = new SerialDevice;
			}
			return _instance;
		}
		public function set port(v:String):void{
			if(_ports.indexOf(v)==-1){
				_ports.push(v);
			}
		}
		
		public function get port():String{
			if(_ports.length>0){
				return _ports[_ports.length-1];
			}
			return "";
		}
		public function get ports():Array{
			return _ports;
		}
		public function get currPort():String
		{
			_currPort = port || _currPort;
			return _currPort;
		}
		public function onConnect(port:String):void{
			this.port = port;
		}
		public function open(param:Object,openedHandle:Function):void{
			var stopBits:uint = param.stopBits
			var bitRate:uint = param.bitRate;
			var ctsFlowControl:uint = param.ctsFlowControl;
			if(ConnectionManager.sharedManager().open(this.port,bitRate)){
				openedHandle(this);
				ConnectionManager.sharedManager().removeEventListener(Event.CHANGE,onReceived);
				ConnectionManager.sharedManager().addEventListener(Event.CHANGE,onReceived);
			}else{
				ConnectionManager.sharedManager().onClose(this.port);
			}
		}
		private var _receiveHandlers:Array=[];
		public function clearAll():void{
			_ports=[];
			_receiveHandlers.length = 0;
		}

		public function clear(v:String):void{
			var index:int = _ports.indexOf(v);
			_ports.splice(index);
			_receiveHandlers.length = 0;
		}
		public function set_receive_handler(name:String,receiveHandler:Function):void{
			if(receiveHandler!=null){
				for(var i:uint = 0;i<_receiveHandlers.length;i++){
					if(name==_receiveHandlers[i].name){
						_receiveHandlers.splice(i);
						break;
					}
				}
				_receiveHandlers.push({name:name,handler:receiveHandler});
			}
		}
		public function send(bytes:Array):void{
			var buffer:ByteArray = new ByteArray();
			for(var i:int=0;i<bytes.length;i++){
				buffer[i] = bytes[i];
			}
			eBlock.app.scriptsPart.onSerialSend(buffer);
			ConnectionManager.sharedManager().sendBytes(buffer);
		}
		
		public function println(text:String):void{
			eBlock.app.scriptsPart.appendMessage( text );
		}
		
		public const dataRecvSignal:Signal = new Signal(Array);
		
		private function onReceived(evt:Event):void
		{
			var _receivedBuffer:ByteArray = ConnectionManager.sharedManager().readBytes();
			//因为在字符模式下，发送的byte被修改过position（可以参考 ScriptsPart::onSerialSend()）,
			//所以接收的byte的position也是有影响的，所以这里要初始化一下position，否则造成无法读取接收的值，导致一系列问题，比如字符模式下发收卡顿问题 谭启亮 20161121
			_receivedBuffer.position=0;
			var _receivedBytes:Array = [];
			while(_receivedBuffer.bytesAvailable > 0){
				_receivedBytes.push(_receivedBuffer.readUnsignedByte());
			}
			_receivedBuffer.clear();
			
			//- Received data from DEVICE ---  then packetParser.parse()
			if(_receivedBytes.length > 0){
				dataRecvSignal.notify(_receivedBytes);
			}
			if(_receiveHandlers.length <= 0 || _receivedBytes.length <= 0){
				return;
			}
			for(var i:int=0;i<_receiveHandlers.length;i++){
				var receiveHandler:Function = _receiveHandlers[i].handler;
				if(receiveHandler!=null){
					try{
						receiveHandler(_receivedBytes);
					}catch(err:*){
						trace(err);
					}
				}
			}
		}
		public function get connected():Boolean{
			return SerialManager.sharedManager().isConnected||HIDManager.sharedManager().isConnected||BluetoothManager.sharedManager().isConnected;
		}
		public function close():void{
//			ConnectionManager.sharedManager().close();
		}
		
		
		
		public function runPackage(... arguments):void{
			sendPackage(arguments, 2);
		}
		
		public function getPackage(... arguments):void{
			var nextID:int = arguments[0];
			//Array.prototype.shift.call(arguments);
			var args:Array = arguments;
			args.shift();
			
			sendPackage( args, 1);
		}
		
		private function sendPackage(argList, type):void{
			var bytes:Array = [0xff, 0x55, 0, 0, type];
			for(var i:int=0;i<argList.length;++i){
				var val:* = argList[i];
				if(val.constructor == "[class Array]"){
					bytes = bytes.concat(val);
				}else{
					bytes.push(val);
				}
			}
			bytes[2] = bytes.length - 3;
			
			//var dev:SerialDevice = SerialDevice.sharedDevice();
			this.send(bytes);
		}
		
		/*public function getPackage2(arguments):ByteArray{
			var nextID:int = arguments[0];
			//Array.prototype.shift.call(arguments);
			var args:Array = arguments;
			args.shift();
			
			return sendPackage2( args, 1);
		}*/
		
		private function sendAndReceivePackage(argList):ByteArray{
			var bytes:Array = [0xff, 0x55, 0, 0, 1];
			for(var i:int=0;i<argList.length;++i){
				var val:* = argList[i];
				if(val.constructor == "[class Array]"){
					bytes = bytes.concat(val);
				}else{
					bytes.push(val);
				}
			}
			bytes[2] = bytes.length - 3;
			
			

			var buffer:ByteArray = new ByteArray();
			for(i=0;i<bytes.length;i++){
				buffer[i] = bytes[i];
			}
			return ConnectionManager.sharedManager().sendBytesAndReceive(buffer);
		}
		
		
		public function reset():void{
		  this.send([0xff, 0x55, 2, 0, 4]);
		}
		
		//-- same function names as eblock.h
		public function pin_set(pin, state):void{
			runPackage([30,pin, state]);
		}
		
		//-- same function names as eblock.h
		public function pin_on(pin):void{
			pin_set(pin, 1);
		}
		public function pin_off(pin):void{
			pin_set(pin, 0);
		}
		public function pin_toggle(pin):void{
			pin_set(pin, 2);
		}
		
		public function pwm(pin, val):void{
			runPackage([32,pin,val]);
		}
		
		public function get_analog(pin):int{
			var command:int=31;
			
			var response:ByteArray = sendAndReceivePackage([command, pin]);
			return getValueFromResponseBuffer(response, command);
		}
		
		
		public function get_analog_perc(pin):int{
			
			var command:int=206;

			var response:ByteArray = sendAndReceivePackage([command, pin]);
			return getValueFromResponseBuffer(response, command);
			
		}
		
			private function getValueFromResponseBuffer(response:ByteArray, command:int):int{
			response.position=0;
			
			response.endian = "littleEndian";
			var v0:int = response.readUnsignedByte();
			var v1:int = response.readUnsignedByte();
			var v2:int = response.readUnsignedByte();  //- debe ser el mismo comando con el que se pide dato al firmware
			
			if(v2!=command && v0!=0xFF &&  v1!=0x55){
				trace("getValueFromResponseBuffer>  wrong response from firmware");
				return 0;
			}
			
			
			
			response.position=4;
			var retVal:int = response.readShort();
			
			
			return retVal;
			
		}
		
		
	}
}