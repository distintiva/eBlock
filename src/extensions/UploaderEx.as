package extensions
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import cc.customcode.uibot.util.AppTitleMgr;
	import cc.customcode.uibot.util.PopupUtil;
	//import cc.customcode.util.UploadSizeInfo;
	
	import org.aswing.JOptionPane;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	//import util.ApplicationManager;
	import util.JSON;

	public class UploaderEx
	{
		static public const Instance:UploaderEx = new UploaderEx();
		
		public var afterOkCompile:Boolean=  true; // establecer antes de llamar a arduinoDeviceAvaliable para que compile
												  // o suuba el firmware,  si es = false hay que establecer la variable afterOkFirmware
		public var afterOkFirmware:String = "";
		
		
		private var _dialog:DialogBox = new DialogBox();
		
		public function UploaderEx()
		{
			_dialog.addTitle(Translator.map('Start Uploading'));
			_dialog.addButton(Translator.map('Close'), _dialog.cancel);
		}
		private function updateDialog():void
		{
			_dialog.setTitle(('Start Uploading'));
			_dialog.setButton(('Close'));
			_dialog.fixLayout();
		}
				
		 
		public function upload(filePath:String):void
		{
			_dialog.setText(Translator.map('Uploading'));
			_dialog.showOnStage(eBlock.app.stage);
			updateDialog();
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.workingDirectory = new File(  ArduinoManager.sharedManager().arduinoCliPath ) ;
						
			info.executable =  new File( ArduinoManager.sharedManager().arduinoCliPath + "/arduino-cli.exe") ; 
			var argList:Vector.<String> = new Vector.<String>();
			argList.push("compile");
			argList.push("-b", DeviceManager.sharedManager().selectedBoard.fqbn );
			
			argList.push("-p", SerialDevice.sharedDevice().currPort);
			argList.push( "-u"); 
			argList.push( "-v");
					 
						
			eBlock.app.scriptsPart.appendMessage("Compilig source ... ");
			
			info.arguments = argList;
			var process:NativeProcess = new NativeProcess();
			
		
			
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, __onData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, __onErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, __onExit);
			process.start(info);
			//sizeInfo.reset();
		}
		
		
		private function __onExit(event:NativeProcessExitEvent):void
		{
			
			ArduinoManager.sharedManager().isUploading = false;
			if(event.exitCode == 0){
				_dialog.setText(Translator.map('Upload Finish'));
			}else{
				
				_dialog.setText(Translator.map('Upload Failed'));

			}
			AppTitleMgr.Instance.setConnectInfo(null);
			//SerialManager.sharedManager().reopen();
		}
		
		private function __onData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var info:String = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable, "gb2312");
			eBlock.app.scriptsPart.appendRawMessage(info);
		}
		
		private function __onErrorData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var info:String = process.standardError.readMultiByte(process.standardError.bytesAvailable, "gb2312");
			eBlock.app.scriptsPart.appendRawMessage(info);
		}
		
		
		
		// ----  core serach
		private var arduinoDeviceAvaliableState:int=0;  // 0 -  primera llamada  1- segundo intento despues de UpdateIndexes
		public function arduinoDeviceAvaliable():void{
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.workingDirectory = new File(  ArduinoManager.sharedManager().arduinoCliPath ) ;
			
			info.executable =  new File( ArduinoManager.sharedManager().arduinoCliPath + "/arduino-cli.exe") ; 
			var argList:Vector.<String> = new Vector.<String>();
			
			argList.push("board");
			argList.push("details", DeviceManager.sharedManager().selectedBoard.fqbn );
			
			argList.push("--format", "json");
			
			if(DeviceManager.sharedManager().selectedBoard.manager_url ){
			//	argList.push("--additional-urls="+ DeviceManager.sharedManager().selectedBoard.manager_url);
			}
			
					
			try{
			eBlock.app.scriptsPart.clearInfo();
			eBlock.app.scriptsPart.appendMessage( "Checking device tools..." )
			}catch(e){
			 return;
			}
			
			info.arguments = argList;
			var process:NativeProcess = new NativeProcess();
			
			
			
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, arduinoDeviceAvaliable_Data);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, arduinoDeviceAvaliable_Data);
			process.addEventListener(NativeProcessExitEvent.EXIT, arduinoDeviceAvaliable_onExit);
			
			
			process.start(info);
			
			
			
		}
		
		
		private function arduinoDeviceAvaliable_onExit(event:NativeProcessExitEvent):void
		{
			//installCurrentBoard();
		}
		
		private function arduinoDeviceAvaliable_Data(event:ProgressEvent):void{
			
			var process:NativeProcess = event.target as NativeProcess;
			
			var info:String = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable, "gb2312");
			var boardData:Object =  util.JSON.parse(info);
			
			if(boardData && boardData.name){
				eBlock.app.scriptsPart.appendRawMessage("Ok, compiler tools found for: "+ boardData.name);
				
				if(this.afterOkCompile){
					eBlock.app.scriptsPart.onCompileArduino();
				}else{
					SerialManager.sharedManager().upgrade(this.afterOkFirmware);
				}
				
			}else{	
				
				eBlock.app.scriptsPart.appendRawMessage("Compiler tools for this device has not been Not Found");
				
				if(arduinoDeviceAvaliableState==0){
					arduinoDeviceAvaliableState=1
					updateIndexes();
					return;
				}
				
				//- Alerta de instalación de placa
				
				var panel:JOptionPane;
				
				
				
				panel = PopupUtil.showConfirm(Translator.map("Compiler tools for this device has not been Not Found"), installCurrentBoard);
				panel.getYesButton().setText(Translator.map("Intall Now"));
				panel.getCancelButton().setText(Translator.map("Close"));
				
				panel.getFrame().setModal(true);
				
				panel.getFrame().setSizeWH(240, 150);
				
				PopupUtil.appendInfo(panel,"Do you want to download it now ?. \n\n(Make sure you have internet connection)");
				//PopupUtil.appendText(panel,"We need to download the related tool to compile source code for this board. \nIf install fails perhaps you need admin rights","http://www.mblock.cc/release-logs-cn");
				arduinoDeviceAvaliableState=0;
			}	
			
		}
		
		
		
		// UPDATE INDEXES
		public function updateIndexes():void{
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.workingDirectory = new File(  ArduinoManager.sharedManager().arduinoCliPath ) ;
			
			info.executable =  new File( ArduinoManager.sharedManager().arduinoCliPath + "/arduino-cli.exe") ; 
			var argList:Vector.<String> = new Vector.<String>();
			
			argList.push("core");
			argList.push("update-index");
			//argList.push("-v");
			
			if(DeviceManager.sharedManager().selectedBoard.manager_url ){
				argList.push("--additional-urls="+ DeviceManager.sharedManager().selectedBoard.manager_url);
			}
			
			
			
			//eBlock.app.scriptsPart.clearInfo();
			eBlock.app.scriptsPart.appendMessage( "Updating board info..." )
			
			info.arguments = argList;
			var process:NativeProcess = new NativeProcess();
			
			
			
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, output_onData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, output_onData);
			process.addEventListener(NativeProcessExitEvent.EXIT, updateIndexes_onExit);
			
			
			//process.start(info);
			
			
			
		}
		
		private function output_onData(event:ProgressEvent):void{
			
			var process:NativeProcess = event.target as NativeProcess;
			
			var info:String = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable, "gb2312");
			eBlock.app.scriptsPart.appendMessage( info )
			
		}
		
		private function updateIndexes_onExit(event:NativeProcessExitEvent):void
		{
			//- un segundo intento de disponibilidad o sino  instalamos los tools
			arduinoDeviceAvaliable();
		}
		
		
		public function installCurrentBoard(value:int):void{
			
			
			if(value != JOptionPane.YES) return;
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.workingDirectory = new File(  ArduinoManager.sharedManager().arduinoCliPath ) ;
			
			info.executable =  new File( ArduinoManager.sharedManager().arduinoCliPath + "/arduino-cli.exe") ; 
			var argList:Vector.<String> = new Vector.<String>();
			
			argList.push("core");
			argList.push("install", DeviceManager.sharedManager().boardArduinoId());
			//argList.push("-v");
			
			if(DeviceManager.sharedManager().selectedBoard.manager_url ){
				argList.push("--additional-urls="+ DeviceManager.sharedManager().selectedBoard.manager_url);
			}
			
			
			
			eBlock.app.scriptsPart.clearInfo();
			eBlock.app.scriptsPart.appendMessage( "Intalling : " + DeviceManager.sharedManager().boardArduinoId() )
			
			//eBlock.app.scriptsPart.appendMessage(argList.join(" "));
			
			//return;
			
			
			info.arguments = argList;
			var process:NativeProcess = new NativeProcess();
			
			
			
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, output_onData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, output_onData);
			//process.addEventListener(NativeProcessExitEvent.EXIT, __onExit);
			
			
			process.start(info);
			
			
			
		}
		
		
		
		
	}
}