package cc.customcode.uibot.ui.parts
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.ApplicationDomain;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	
	import cc.customcode.media.MediaManager;
	import cc.customcode.menu.MenuUtil;
	import cc.customcode.menu.SystemMenu;
	import cc.customcode.uibot.uiwidgets.errorreport.ErrorReportFrame;
	import cc.customcode.uibot.uiwidgets.extensionMgr.ExtensionUtil;
	import cc.customcode.updater.AppUpdater;
	import cc.customcode.util.FileUtil;
	
	import extensions.ArduinoManager;
	import extensions.BluetoothManager;
	import extensions.ConnectionManager;
	import extensions.DeviceManager;
	import extensions.ExtensionManager;
	import extensions.HIDManager;
	import extensions.SerialDevice;
	import extensions.SerialManager;
	import extensions.UploaderEx;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.JSON;
	import util.SharedObjectManager;
	
	public class TopSystemMenu extends SystemMenu
	{
		
		private var boardMenu:NativeMenuItem;
		
		
		public function getMenuConnect():NativeMenu{
			return getNativeMenu().getItemByName("Connect").submenu;
		}
		
		public function getMenuBoards():NativeMenuItem{
			return getNativeMenu().getItemByName("Device");
		}
		
		public function TopSystemMenu(stage:Stage /*, path:String*/)
		{
			super(stage/*, path*/);
			
			
			
			
			getNativeMenu().getItemByName("File").submenu.addEventListener(Event.DISPLAYING, __onInitFielMenu);
			getNativeMenu().getItemByName("Edit").submenu.addEventListener(Event.DISPLAYING, __onInitEditMenu);
			getNativeMenu().getItemByName("Connect").submenu.addEventListener(Event.DISPLAYING, __onShowConnect);
			getMenuBoards().submenu.addEventListener(Event.DISPLAYING, __onShowBoards);
			
			getNativeMenu().getItemByName("Extensions").submenu.addEventListener(Event.DISPLAYING, __onInitExtMenu);
			getNativeMenu().getItemByName("Language").submenu.addEventListener(Event.DISPLAYING, __onShowLanguage);
			
			
			
					
			
			register("File", __onFile);
			register("Edit", __onEdit);
			register("Connect", __onConnect);
			register("Device", __onSelectBoard);
			register("eBlock", __onHelp);
			register("Manage Extensions", ExtensionUtil.OnManagerExtension);
			register("Restore Extensions", ExtensionUtil.OnLoadExtension);
			register("Clear Cache", ArduinoManager.sharedManager().clearTempFiles);
			//register("Reset Default Program", __onResetDefaultProgram);
			//register("Set FirmWare Mode", __onResetDefaultProgram);
			
			
			
			
			createHelpDialog();
						 
		}
		
		private function __onResetDefaultProgram(item:NativeMenuItem):void
		{
			//var ext:ScratchExtension;
			var filePath:String;
							
			
			filePath = "......  firmare.hex";
			
			/*switch(item.name){
				case "mymBot":
					filePath = "mBlock/resources/boards/mbot_reset.hex";
					break;
				case "Starter":
					filePath = "mBlock/resources/boards/starter_factory_firmware.hex";
					break;
				case "Starter Bluetooth":
					filePath = "mBlock/resources/boards/Starter_Bluetooth.hex";
					break;
				case "mBot Ranger":
					filePath = "mBlock/resources/boards/auriga.hex";
					break;
				case "Mega Pi":
					filePath = "mBlock/resources/boards/mega_pi.hex";
					break;
				case "bluetooth mode":
					ext = MBlock_mod.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [0], null);
					return;
				case "ultrasonic mode":
					ext = MBlock_mod.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [1], null);
					return;
				case "line follower mode":
					ext = MBlock_mod.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [4], null);
					return;
				case "balance mode":
					ext = MBlock_mod.app.extensionManager.extensionByName("Auriga");
					if(ext != null)
						ext.js.call("switchMode", [2], null);
					return;
				default:
					MBlock_mod.app.scriptsPart.appendMessage("Unknow board: " + item.name);
					return;
			}*/
			
			//var file:File = ApplicationManager.sharedManager().documents.resolvePath(filePath);
			
			var file:File = File.applicationDirectory.resolvePath(filePath);
			
			
			if(file.exists){
				SerialManager.sharedManager().upgrade(file.nativePath);
			}else{
				eBlock.app.scriptsPart.appendMessage("File not exist: " + file.nativePath);
			}
		}
		
		public function changeLang():void
		{
			
			MenuUtil.ForEach(getNativeMenu(), changeLangImpl);
		}
		
		private function changeLangImpl(item:NativeMenuItem):*
		{
			var index:int = getNativeMenu().getItemIndex(item);
			if(0 <= index && index < defaultMenuCount){
				return true;
			}
			if(item.name.indexOf("serial_") == 0){
				return;
			}
			var p:NativeMenuItem = MenuUtil.FindParentItem(item);
			if(p != null && p.name == "Extensions"){
				if(p.submenu.getItemIndex(item) > 4){
					return true;
				}
			}
			setItemLabel(item);
			if(item.name == "Boards"){
				if(item.submenu.getItemByName("Others")!=null)	setItemLabel(item.submenu.getItemByName("Others"));
				//return true;
			}
			if(item.name == "Language"){
				item = MenuUtil.FindItem(item.submenu, "set font size");
				setItemLabel(item);
				return true;
			}
		}
		
		private function setItemLabel(item:NativeMenuItem):void
		{
			var newLabel:String = Translator.map(item.name);
			if(item.label != newLabel){
				item.label = newLabel;
			}
		}
		
		private function __onFile(item:NativeMenuItem):void
		{
			switch(item.name)
			{
				case "New":
					eBlock.app.createNewProject();
					break;
				case "Load Project":
					eBlock.app.runtime.selectProjectFile();
					break;
				case "Save Project":
					eBlock.app.saveFile();
					break;
				case "Save Project As":
					eBlock.app.exportProjectToFile();
					break;
				case "Undo Revert":
					eBlock.app.undoRevert();
					break;
				case "Revert":
					eBlock.app.revertToOriginalProject();
					break;
				case "Import Image":
					MediaManager.getInstance().importImage();
					break;
				case "Export Image":
					MediaManager.getInstance().exportImage();
					break;
			}
			
			if(item.data &&  item.data.@action =="save_blocks"){
				eBlock.app.scriptsPane.saveBlocksAsPng();		
				
			}
			
		}
		
		private function __onEdit(item:NativeMenuItem):void
		{
			
			var key:String;
			if(item.data){
				key = item.data.@action;
			}else{
				key = item.name;
			}
			
			switch(key){
				case "Undelete":
					eBlock.app.runtime.undelete();
					break;
				case "Hide stage layout":
					eBlock.app.toggleHideStage();
					break;
				case "Small stage layout":
					eBlock.app.toggleSmallStage();
					break;
				case "Turbo mode":
					eBlock.app.toggleTurboMode();
					break;
				case "arduino_mode":
					eBlock.app.changeToArduinoMode();
					break;
			}
			//eBlock.app.track("/OpenEdit");
		}
		
		private function __onConnect(menuItem:NativeMenuItem):void
		{
			var key:String;
			if(menuItem.data){
				key = menuItem.data.@action;
			}else{
				key = menuItem.name;
			}
			
			ConnectionManager.sharedManager().onConnect(key);
			
		}
		
		private function __onShowLanguage(evt:Event):void
		{
			var languageMenu:NativeMenu = evt.target as NativeMenu;
			if(languageMenu.numItems <= 2){
				for each (var entry:Array in Translator.languages) {
					var item:NativeMenuItem = languageMenu.addItemAt(new NativeMenuItem(entry[1]), languageMenu.numItems-2);
					item.name = entry[0];
					item.checked = Translator.currentLang==entry[0];
				}
				languageMenu.addEventListener(Event.SELECT, __onLanguageSelect);
			}else{
				for each(item in languageMenu.items){
					if(item.isSeparator){
						break;
					}
					MenuUtil.setChecked(item, Translator.currentLang==item.name);
				}
			}
			try{
				var fontItem:NativeMenuItem = languageMenu.items[languageMenu.numItems-1];
				for each(item in fontItem.submenu.items){
					MenuUtil.setChecked(item, Translator.currentFontSize==int(item.label));
				}
			}catch(e:Error){
				
			}
		}
		

		private function __onLanguageSelect(evt:Event):void
		{
			var item:NativeMenuItem = evt.target as NativeMenuItem;
			if(item.name == "setFontSize"){
				Translator.setFontSize(int(item.label));
			}else{
				Translator.setLanguage(item.name);
			}
		}
		
		private function __onInitFielMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			
			MenuUtil.setEnable(menu.getItemByName("Undo Revert"), eBlock.app.canUndoRevert());
			MenuUtil.setEnable(menu.getItemByName("Revert"), eBlock.app.canRevert());
			
			//eBlock.app.track("/OpenFile");
		}
		
		private function __onInitEditMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			MenuUtil.setEnable(menu.getItemByName("Undelete"), eBlock.app.runtime.canUndelete());
			MenuUtil.setChecked(menu.getItemByName("Hide stage layout"), eBlock.app.stageIsHided);
			MenuUtil.setChecked(menu.getItemByName("Small stage layout"), !eBlock.app.stageIsHided && eBlock.app.stageIsContracted);
			MenuUtil.setChecked(menu.getItemByName("Turbo mode"), eBlock.app.interp.turboMode);
			
			
			//MenuUtil.FindItem(getNativeMenu(), "arduino_mode");
			
			MenuUtil.setChecked(  MenuUtil.FindItem(getNativeMenu(), "arduino_mode")  , eBlock.app.stageIsArduino);
			
			
			//eBlock.app.track("/OpenEdit");
		}
		
		private function __onShowConnect(evt:Event):void
		{
			 //SocketManager.sharedManager().probe();
			HIDManager.sharedManager();
			
			var menu:NativeMenu = evt.target as NativeMenu;
			var subMenu:NativeMenu = new NativeMenu();
			
			var enabled:Boolean =  true;//eBlock.app.extensionManager.checkExtensionEnabled();
			var arr:Array = SerialManager.sharedManager().list;
			if(arr.length==0)
			{
				var nullItem:NativeMenuItem = new NativeMenuItem(Translator.map("no serial port"));
				nullItem.enabled = false;
				nullItem.name = "serial_"+"null";
				subMenu.addItem(nullItem);
			}
			else
			{
				for(var i:int=0;i<arr.length;i++){
					var item:NativeMenuItem = subMenu.addItem(new NativeMenuItem(arr[i]));
					item.name = "serial_"+arr[i];
					
					item.enabled = enabled;
					item.checked = SerialDevice.sharedDevice().ports.indexOf(arr[i])>-1 && SerialManager.sharedManager().isConnected;
				}
			}
			
			menu.getItemByName("Serial Port").submenu = subMenu;
			
			var bluetoothItem:NativeMenuItem = menu.getItemByName("Bluetooth");
			
			bluetoothItem.enabled = ApplicationManager.sharedManager().system == ApplicationManager.WINDOWS && BluetoothManager.sharedManager().isSupported
			
			if(bluetoothItem.enabled){ //*JC*
				while(bluetoothItem.submenu.numItems > 3){
					bluetoothItem.submenu.removeItemAt(3);
				}
				if(bluetoothItem.submenu.numItems>2){
					bluetoothItem.submenu.items[0].enabled = enabled;
					bluetoothItem.submenu.items[1].enabled = enabled;
					bluetoothItem.submenu.items[2].enabled = enabled;
				}
				arr = BluetoothManager.sharedManager().history;
				for(i=0;i<arr.length;i++){
					item = bluetoothItem.submenu.addItem(new NativeMenuItem(Translator.map(arr[i])));
					item.name = "bt_"+arr[i];
					item.enabled = enabled;
					item.checked = arr[i]==BluetoothManager.sharedManager().currentBluetooth && BluetoothManager.sharedManager().isConnected;
				}
			}
			
			var tempItem:NativeMenuItem = menu.getItemByName("2.4G Serial").submenu.getItemAt(0);
			tempItem.enabled = enabled;
			tempItem.checked = HIDManager.sharedManager().isConnected;
			
			/*var netWorkMenuItem:NativeMenuItem = MenuUtil.FindItem(getNativeMenu(), "Network");
			subMenu = netWorkMenuItem.submenu;
			arr = SocketManager.sharedManager().list;
			while(subMenu.numItems > 1){
				subMenu.removeItemAt(1);
			}
			for(i=0;i<arr.length;i++){
				var ips:Array = arr[i].split(":");
				if(ips.length<3){
					continue;
				}
				var label:String = Translator.map(ips[0]+" - "+ips[2]);
				item = subMenu.addItem(new NativeMenuItem(label));
				item.name = "net_" + arr[i];
				item.enabled = enabled;
				item.checked = SocketManager.sharedManager().connected(ips[0]);
			}
			netWorkMenuItem.submenu = subMenu;*/
			
			
			
			
			
		}
		
		static private const rangerModeList:Array = ["bluetooth mode","ultrasonic mode","line follower mode","balance mode"];
		
		
		private var d:DialogBox = new DialogBox;
		private var htmlLoader:HTMLLoader = new HTMLLoader();
		private function createHelpDialog():void{
			
			d.setTitle(Translator.map('Help'));
						
			
			htmlLoader.placeLoadStringContentInApplicationSandbox = true;
			htmlLoader.runtimeApplicationDomain = ApplicationDomain.currentDomain;
			
			var bytes:ByteArray = new Specs.infoHtmlPanel();
			
			htmlLoader.loadString( bytes.readUTFBytes( bytes.bytesAvailable ).toString()  );
			//htmlLoader.load(new URLRequest(".../bbc_microbit/info.html"));
			
			htmlLoader.x=0;
			htmlLoader.y=0;
			htmlLoader.width=650 ;
			htmlLoader.height=520 ;
			
			d.addBlock(htmlLoader);
			d.addButton('Close', function():void{
				d.cancel();
			});
			
		}
		
		public function openHelpDialog(title:String, path:String):void{
			
			//var readme:URLRequest = new URLRequest(".../bbc_microbit/info.html")
			path = path+"/";	
			var boardInfo:File = File.applicationDirectory.resolvePath(path + "README.md");
			
			if(!boardInfo.exists) return;
			//var boardObj:Object = util.JSON.parse(FileUtil.ReadString(boardInfo));
			
			htmlLoader.window.setTitle(title);
			htmlLoader.window.setBasePath(path );
			htmlLoader.window.parseMarkDown(FileUtil.ReadString(boardInfo));
			d.showOnStage(eBlock.app.stage);
		}
				
		//import text.markdown.*;
		private function __onSelectBoard(menuItem:NativeMenuItem):void
		{
			var file:File;
			
			var key:String;
			if(menuItem.data){
				key = menuItem.data.@action;
			}else{
				key = menuItem.name;
			}
			
			
			switch(key){
				
				case "download_boards":{
				
					navigateToURL(new URLRequest("https://github.com/distintiva/eBlock-devices"));
					return;
				
				}
				case "open_help":{
					
										
					//openHelpDialog(DeviceManager.sharedManager().selectedDeviceLabel(),  DeviceManager.sharedManager().selectedDevicePath() );
					DeviceManager.sharedManager().openHelp();
				
					
					return;
					/*var file:File = File.applicationDirectory.resolvePath("..." );
					if(file.exists && file.isDirectory){
						file.openWithDefaultApplication();
					}
					return;*/
				}
				case "upgrade_firmware":{
					//*JC*
					//SerialManager.sharedManager().upgrade();
					if( !SerialManager.sharedManager().isConnected ){
						var dialog:DialogBox = new DialogBox();
						dialog.addTitle("Upgrade firmware");
						dialog.addText("Please connect the board with serial port to upgrade firmware.");
						function onCancel():void{
							dialog.cancel();
						}
						dialog.addButton("OK",onCancel);
						dialog.showOnStage(eBlock.app.stage);
					}
					
					var filePath:String;
					filePath =  DeviceManager.sharedManager().selectedDevicePath() + "/" + menuItem.label;
					file = File.applicationDirectory.resolvePath(filePath);
					
					if(file.exists){
						
						UploaderEx.Instance.afterOkCompile = false;
						UploaderEx.Instance.afterOkFirmware = file.nativePath;
						UploaderEx.Instance.arduinoDeviceAvaliable();
						
						//SerialManager.sharedManager().upgrade(file.nativePath);
					}else{
						eBlock.app.scriptsPart.appendMessage("File not exist: " + file.nativePath);
					}
					
					
					return;
				}
				case "driver":{
					//eBlock.app.track("/OpenSerial/InstallDriver");
					var fileDriver:File;
					if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
						//						navigateToURL(new URLRequest("https://github.com/Makeblock-official/Makeblock-USB-Driver"));
						fileDriver = new File(File.applicationDirectory.nativePath+"/resources/drivers/"+ DeviceManager.sharedManager().selectedBoard.driver.mac);
						fileDriver.openWithDefaultApplication();
					}else{
						fileDriver = new File(File.applicationDirectory.nativePath+"/resources/drivers/"+ DeviceManager.sharedManager().selectedBoard.driver.windows);
						fileDriver.openWithDefaultApplication();
					}
					return;
				}
			}
				
			
			
			DeviceManager.sharedManager().onSelectBoard(menuItem.name);
			
			
			
			//getNativeMenu().getItemByName("Boards").label += " "+  DeviceManager.sharedManager().selectedBoard.label;
			
			//getNativeMenu().getItemByName("Boards"). = "hhh";
			
			
			
		}
		
		private function __onShowBoards(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			
			
			var list:Array = DeviceManager.sharedManager().allBoards;
			
			
			for each(var item:NativeMenuItem in menu.items){
				if(item.enabled){
					MenuUtil.setChecked(item, DeviceManager.sharedManager().checkCurrentBoard(item.name));
				}
			}
			
			var hasFirmware:Boolean = false;
			var hasDriver:Boolean = false;
			
			var upgradeMenu:NativeMenuItem = MenuUtil.FindItem(getNativeMenu(), "Upgrade Firmware");
			upgradeMenu.submenu.removeAllItems();
			var driverMenu:NativeMenuItem = MenuUtil.FindItem(getNativeMenu(), "Install Driver");
			
			var helpMenu:NativeMenuItem = MenuUtil.FindItem(getNativeMenu(), "open_help");
			helpMenu.enabled=false;
		
			
			if( DeviceManager.sharedManager().selectedBoard  ){
				
				helpMenu.enabled = DeviceManager.sharedManager().hasReadmeFile();
				eBlock.app.topBarPart.helpIconOnOff();
				//- Firmnware/s
				var hexfile:* = DeviceManager.sharedManager().selectedBoard.hex;
				if( DeviceManager.sharedManager().selectedBoard.hex  is Array ){
					
					for each( var hex:String in hexfile ){
						if(  hex!="" ){
							upgradeMenu.submenu.addItem(  new NativeMenuItem( hex ) ).name="upgrade_firmware";
							hasFirmware = true;
						}
					}
					
				}else{
					if(  hexfile!="" ){
						upgradeMenu.submenu.addItem(  new NativeMenuItem( hexfile ) ).name="upgrade_firmware";
						hasFirmware = true;
					}
				}
				
				//- Driver
				//var dvObj:*= DeviceManager.sharedManager().selectedBoard;
				if( DeviceManager.sharedManager().selectedBoard.driver ){
					if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
						hasDriver = DeviceManager.sharedManager().selectedBoard.driver.mac ==true;
					}else{
						hasDriver = DeviceManager.sharedManager().selectedBoard.driver.windows != null;
					}
				}
				
				
			}  
			upgradeMenu.enabled = hasFirmware;
			driverMenu.enabled = hasDriver;
			
			
			
			
			
			
			if(menu.items.length>6) return;
			
			
			
			//return;
			
			
			
			//*JC* ¿??¿ comprobar si existen
			for(var i:int=0;i<list.length;i++){
				var board:Object= list[i];
				
				var subMenuItem:NativeMenuItem = menu.addItem(new NativeMenuItem( board.label ));
				subMenuItem.name = board.label;//board.id;
				subMenuItem.label = board.label;
				//subMenuItem.checked = MBlock_mod.app.extensionManager.checkExtensionSelected(extName);
				register(board.label, __onSelectBoard);
			}
			
			
			
			for each(item in menu.items){
				if(item.enabled){
					MenuUtil.setChecked(item, DeviceManager.sharedManager().checkCurrentBoard(item.name));
				}
			}
		
			
		}
		
		private var initExtMenuItemCount:int = -1;
		
		private function __onInitExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
//			menuItem.removeEventListener(evt.type, __onInitExtMenu);
//			menuItem.addEventListener(evt.type, __onShowExtMenu);
			var list:Array = []; //eBlock.app.extensionManager.extensionList;
			/*if(list.length==0){
				//eBlock.app.extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",false);
			}*/
			
			var loadExtensions:Boolean = true; 
			
			if(initExtMenuItemCount < 0){
				initExtMenuItemCount = menuItem.numItems;
			}else{
				loadExtensions = false;
				//return;
			}
			
			/*while(menuItem.numItems > initExtMenuItemCount){
				menuItem.removeItemAt(menuItem.numItems-1);
			}*/
			
			list = eBlock.app.extensionManager.extensionList;
//			var subMenu:NativeMenu = menuItem;
			
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				
				if(ExtensionManager.isBoardExt(extName) ) continue;
				
				var subMenuItem:NativeMenuItem ;
				if(loadExtensions){
				     subMenuItem = menuItem.addItem(new NativeMenuItem(Translator.map(extName)));
					subMenuItem.name = extName;
					subMenuItem.label = extName;
					register(extName, __onExtensions);
				}else{
					subMenuItem = menuItem.getItemByName(extName);
				
				}
				subMenuItem.checked = eBlock.app.extensionManager.checkExtensionSelected(extName);
				
			}
		}
		

		/*
		private function __onShowExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
			var list:Array = MBlock_mod.app.extensionManager.extensionList;
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				var subMenuItem:NativeMenuItem = menuItem.getItemAt(i+2);
				subMenuItem.checked = MBlock_mod.app.extensionManager.checkExtensionSelected(extName);
			}
		}
		*/
		private function __onExtensions(menuItem:NativeMenuItem):void
		{
			eBlock.app.extensionManager.onSelectExtension(menuItem.name);
		}
		
		private function __onHelp(menuItem:NativeMenuItem):void
		{
			var path:String = menuItem.data.@url;
			
			var file:File;
			
//			if("Forum" == menuItem.name){
//				path = Translator.map(path);
//			}
			
			var key:String;
			if(menuItem.data){
				key = menuItem.data.@action;
			}else{
				key = menuItem.name;
			}
			
			if(path){
				navigateToURL(new URLRequest(path),"_blank");
				return;
			}
			
			
					/*if(Translator.currentLang == "zh_CN" || Translator.currentLang == "zh_TW"){
						path = menuItem.data.@url_cn;
					}*/
			
			
			switch(key)
			{
				case "Share Your Project":
				///	eBlock.app.track("/OpenShare/");
					break;
				case "FAQ":
				//	eBlock.app.track("/OpenFaq/");
					break;
				default:
				//	eBlock.app.track("/OpenHelp/"+menuItem.data.@key);
			}
			
			switch( key ){
				case "check_app_update":
					AppUpdater.getInstance().start(true);
					break;
				case "open_resources":
					file = File.applicationDirectory.resolvePath("resources/" );
					if(file.exists && file.isDirectory)	file.openWithDefaultApplication();
					break;
				case "open_extensions":
					file = File.applicationDirectory.resolvePath("resources/extensions/" );
					if(file.exists && file.isDirectory)	file.openWithDefaultApplication();
					break;
				case "open_device":
					file = File.applicationDirectory.resolvePath(  DeviceManager.sharedManager().selectedDevicePath()  );
					if(file.exists && file.isDirectory)	file.openWithDefaultApplication();
					break;
				
			}
		}
	}
}