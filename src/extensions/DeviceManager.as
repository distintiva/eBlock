package extensions
{
	import flash.filesystem.File;
	
	import cc.customcode.uibot.ui.parts.TopSystemMenu;
	import cc.customcode.util.FileUtil;
	
	import util.JSON;
	import util.SharedObjectManager;

	public class DeviceManager
	{
		private static var _instance:DeviceManager;
		private var _device:String = "";
		private var _board:String = "";
		private var _name:String = "";
		
		private  var _boards:Array =[];
		public var selectedBoard:Object = null;
		
		public var baseDevice:Object = null;  //- base devicde from wich other override extension and info
		
		private const DEVICES_PATH:String = "resources/devices/";
		
				public function LoadBoards():void{
		
			
			var docs:File = File.applicationDirectory.resolvePath( DEVICES_PATH );
			
			var fs:Array = docs.getDirectoryListing();
			
			
			for each(var f:File in fs){
				
				if( f.isDirectory ){
					var boardObj:Object = {};
								
															
					//- parse device.json 
					var boardInfo:File = File.applicationDirectory.resolvePath(DEVICES_PATH + f.name + "/device.json");
					if(!boardInfo.exists) continue;
					
					boardObj = util.JSON.parse(FileUtil.ReadString(boardInfo));
					boardObj.id = f.name;
					
					//boardObj.extObj = getDeviceExtension( f.name ); //- load blocks for this device
					
					
					if(f.name=='_base_'){
						
						boardObj.extObj = getDeviceExtension( f.name ); //- load blocks for this device ( for the rest of devices extObj is loaded on selecting)
						
						this.baseDevice = boardObj;
						continue;
					}
					
					
					//- compruebo si es válido el archivo y lo añado
					if( boardObj.label && boardObj.fqbn) { 
						//- antes compruebo si existe code-template para generar
						var template:File = File.applicationDirectory.resolvePath(DEVICES_PATH + f.name + "/template.c");
						if(template.exists){
							var str:String = FileUtil.ReadString(template);
							boardObj.template = str;
						}
												
						if(boardObj.id =="bbc_microbit"){
							this._boards.insertAt(0,boardObj);
						}else{						
							this._boards.push(boardObj);
						}
					}
					
					
				
				}
											
									
					
				
			}
			
			//- Si no hay ninguna seleccionada seleccionar mBot por defecto
			onSelectBoard(SharedObjectManager.sharedManager().getObject("board","bbc_microbit"));
			
			
		}
		
		
		private function getDeviceExtension(devicename:String):Object{
		
			//- aqui cargo los bloques JSON (de la extension) del device (si existe) 
			var blocksFile:File = File.applicationDirectory.resolvePath(DEVICES_PATH + devicename + "/blocks.json");
			var extObj:Object  = {};
			
			extObj.extensionName = devicename; 
			extObj.blockSpecs = [];
			extObj.srcPath = DEVICES_PATH + devicename+"/";
			extObj.isExtensionBoard = true;
			extObj.javascriptURL = '';
			extObj.menus = {};
			extObj.values = {};
			extObj.removeFromBase = [];
			extObj.callbacks = {};
						
			if(blocksFile.exists) {
				extObj= util.JSON.parse(FileUtil.ReadString(blocksFile));
				extObj.srcPath = blocksFile.url;
				extObj.extensionName = devicename;  //¿?¿?  poner algun prefijo por si alguien hace una extension que se llame igual
				extObj.isExtensionBoard = true;
				extObj.javascriptURL = "blocks.js";  // no hace falta comprobar su existencia,  ya lo hará ScratchExtension
				extObj.extensionPort = 0;
				
			}
			
			return  extObj;
		
		} 
		
		public function openHelp():void{
			
			 eBlock.app.systemMenu.openHelpDialog(selectedDeviceLabel(),  selectedDevicePath() );
			
		}
		
		public function hasReadmeFile():Boolean{
		
			var boardInfo:File = File.applicationDirectory.resolvePath(selectedDevicePath() + "/README.md");
			
			if(!boardInfo.exists) return false;
			
			return true;
		}
		public function selectedDevicePath():String{
			
			return DEVICES_PATH +  this.selectedBoard.id;
		}
		
		public function selectedDeviceLabel():String{
			
			return  this.selectedBoard.label;
		}
		
		//- de arduino:avr:uno  devuelve   arduino:avr
		public function boardArduinoId(): String{
			
			if( this.selectedBoard.fqbn ){
				var parts:Array = this.selectedBoard.fqbn.split(":"); 
				
				return parts[0]+":"+parts[1];
			}		
			
			return null;
		}
		
		
		public function DeviceManager()
		{
			//onSelectBoard(SharedObjectManager.sharedManager().getObject("board","mbot_uno"));
		}
		public static function sharedManager():DeviceManager{
			if(_instance==null){
				_instance = new DeviceManager;
			}
			return _instance;
		}
		private function set board(value:String):void
		{
			_board = value;
			//var tempList:Array = _board.split("_");
			//_device = tempList[tempList.length-1];
		}
		
		
		
		public function onSelectBoard(value:String):void{
			if(_board == value){
				return;
			}
			
			
			//var oldBoard:String = SharedObjectManager.sharedManager().getObject("board");
			
			

			for each( var dvc:Object in this._boards ){
				if(dvc.label == value) {
					this.board = value;
					SharedObjectManager.sharedManager().setObject("board",_board);
					selectedBoard=dvc; break;
				}
			}
			
			if( selectedBoard ==null ) selectedBoard = this._boards[0];
			
			if( selectedBoard ==null ) return;
			
			if(selectedBoard.extObj==null)	selectedBoard.extObj = getDeviceExtension( selectedBoard.id ); //- load blocks for this device
			
			//UploaderEx.Instance.arduinoDeviceAvaliable();
			
			eBlock.app.topBarPart.helpIconOnOff();
			
			//eBlock.app.extensionManager.singleSelectExtension(selectedBoard.extension);
			eBlock.app.extensionManager.clearSelectedExtensions();
			
			//-Restore baseDevice Ooriginal values 
			baseDevice.extObj.menus.digital_pins = this.baseDevice.digital_pins.slice(0);
			//-override and inject Device.json defined pins in its extensions
			if(selectedBoard.digital_pins ){
				baseDevice.extObj.menus.digital_pins = this.selectedBoard.digital_pins.slice(0);
				selectedBoard.extObj.menus.digital_pins = this.selectedBoard.digital_pins.slice(0);
			}
			baseDevice.extObj.menus.analog_pins = this.baseDevice.analog_pins.slice(0);
			//-override and inject Device.json defined pins in its extensions
			if(selectedBoard.analog_pins ){
				baseDevice.extObj.menus.analog_pins = this.selectedBoard.analog_pins.slice(0);
				selectedBoard.extObj.menus.analog_pins = this.selectedBoard.analog_pins.slice(0);
			}
						
				
			eBlock.app.extensionManager.loadRawExtension( baseDevice.extObj );
			if(selectedBoard.extObj){
				eBlock.app.extensionManager.loadRawExtension( selectedBoard.extObj  );
			}
			
			eBlock.app.topBarPart.setBoardName(selectedBoard.label);
			
			//eBlock.app.track("/Device/" + selectedBoard.label );
			
			
			/*if(_board=="picoboard_unknown"){
				MBlock_mod.app.extensionManager.singleSelectExtension("PicoBoard");
			}else{
				if(_board=="mbot_uno"){
					MBlock_mod.app.extensionManager.singleSelectExtension("mBot");
				}else if(_board.indexOf("arduino")>-1){
					MBlock_mod.app.extensionManager.singleSelectExtension("Arduino");
				}else if(_board.indexOf("me/orion_uno")>-1){
					if(oldBoard.indexOf("me/orion_uno") < 0){
						MBlock_mod.app.openOrion();
					}
					MBlock_mod.app.extensionManager.singleSelectExtension("Orion");
				}else if(_board.indexOf("me/baseboard")>-1){
					MBlock_mod.app.extensionManager.singleSelectExtension("BaseBoard");
				}else if(_board.indexOf("me/uno_shield")>-1){
					MBlock_mod.app.extensionManager.singleSelectExtension("UNO Shield");
				}else if(_board.indexOf("me/auriga") >= 0){
					MBlock_mod.app.extensionManager.singleSelectExtension("Auriga");
				}else if(_board.indexOf("me/mega_pi") >= 0){
					MBlock_mod.app.extensionManager.singleSelectExtension("MegaPi");
				}else{
					MBlock_mod.app.extensionManager.singleSelectExtension("PicoBoard");
				}
			}
			*/
			
			eBlock.app.topBarPart.setBoardTitle();
			
			if(eBlock.app.scriptsPart.isArduinoMode){
				eBlock.app.scriptsPart.showArduinoCode();
			}
			
			
			eBlock.app.extensionManager.loadCheckedExtensions();
			
		}
		public function checkCurrentBoard(board:String):Boolean{
			return _board==board;
		}
		
	
		
		public function loadDeviceExtensions():void{
		
		}
		
		public function get currentBoard():String{
//			LogManager.sharedManager().log("currentBoard:"+_board);
			return _board;
		}
		
		public function get allBoards():Array{
			return _boards;
		}
		
		public function get currentDevice():String{
			
			return _device;
		}
	}
}