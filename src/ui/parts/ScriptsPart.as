/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// ScriptsPart.as
// John Maloney, November 2011
//
// This part holds the palette and scripts pane for the current sprite (or stage).

package ui.parts {
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.html.HTMLLoader;
	import flash.system.ApplicationDomain;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import blocks.Block;
	
	import cc.customcode.uibot.util.AppTitleMgr;
	import cc.customcode.util.HexUtil;
	
	import extensions.ArduinoManager;
	import extensions.ConnectionManager;
	import extensions.SerialDevice;
	import extensions.UploaderEx;
	
	//import assets.Resources;
	
	import scratch.ScratchObj;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;
	
	import translation.Translator;
	
	import ui.BlockPalette;
	import ui.PaletteSelector;
	import ui.parts.TabsPart;
	
	import uiwidgets.Button;
	import uiwidgets.DialogBox;
	import uiwidgets.IconButton;
	import uiwidgets.IndicatorLight;
	import uiwidgets.ScriptsPane;
	import uiwidgets.ScrollFrame;
	import uiwidgets.ZoomWidget;
	
	import util.JSON;

public class ScriptsPart extends UIPart {
	private var htmlLoader:HTMLLoader;
	private var htmlConsole:HTMLLoader;
	
	private var shape:Shape;
	public var selector:PaletteSelector;
	private var spriteWatermark:Bitmap;
	private var paletteFrame:ScrollFrame;
	private var scriptsFrame:ScrollFrame;
	private var arduinoFrame:ScrollFrame;
	private var zoomWidget:ZoomWidget;

	private const readoutLabelFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
	private const readoutFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor);

	private var xyDisplay:Sprite;
	private var xLabel:TextField;
	private var yLabel:TextField;
	private var xReadout:TextField;
	private var yReadout:TextField;
	private var lastX:int = -10000000; // impossible value to force initial update
	private var lastY:int = -10000000; // impossible value to force initial update
	
	
	private var codeBt:Button = new Button(Translator.map("< code >"));
	private var uploadBt:Button;// = new Button(Translator.map("Upload to Board"));
	private var backBt:Button;// = new Button(Translator.map("Cerrar"));
	
	
	private var tabCode:IconButton;
	private var tabConsole:IconButton;
	
	public var tabSelected:int = 1;

	
//	private var sendBt:Button = new Button(Translator.map("Send"));
//	private var sendTextPane:TextPane;
//	
//	private var isByteDisplayMode:Boolean = true;
//	private var displayModeBtn:Button = new Button(Translator.map("binary mode"));
	
//	private var isByteInputMode:Boolean = false;
//	private var inputModeBtn:Button = new Button(Translator.map("char mode"));
	
	private var arduinoCodeText:String = "";
	
	public static var isShowingCode:Boolean = false; 
	
	
	public function ScriptsPart(app:eBlock) {
		this.app = app;

		addChild(shape = new Shape());
		addChild(spriteWatermark = new Bitmap());
		addXYDisplay();
		addChild(selector = new PaletteSelector(app));

		var palette:BlockPalette = new BlockPalette();
		palette.color = CSS.tabColor;
		paletteFrame = new ScrollFrame();
		paletteFrame.allowHorizontalScrollbar = false;
		paletteFrame.setContents(palette);
		addChild(paletteFrame);

		var scriptsPane:ScriptsPane = new ScriptsPane(app);
		scriptsFrame = new ScrollFrame(true);
		scriptsFrame.setContents(scriptsPane);
		addChild(scriptsFrame);
		
		app.palette = palette;
		app.scriptsPane = scriptsPane;

		addChild(zoomWidget = new ZoomWidget(scriptsPane));
		
		codeBt.setColors(CSS.enfasisColor);
		codeBt.setTextColor(CSS.white);
		codeBt.addEventListener(MouseEvent.CLICK, __onShowCode);
		addChild(codeBt);
		
		
		arduinoFrame = new ScrollFrame(false);
		arduinoFrame.visible = true;
		

		
		tabCode = TabsPart.makeTab('Code', __onTabCode);
		tabCode.y = 11;
		tabCode.setOn(true);
		arduinoFrame.addChild(tabCode);
		
		
		tabConsole = TabsPart.makeTab('Console', __onTabConsole);
		tabConsole.y = 11;
		arduinoFrame.addChild(tabConsole);
		
			
		uploadBt= new Button(Translator.map("Upload"));
		backBt = new Button(Translator.map("Cerrar"));
		
		
		backBt.y = 10;
		backBt.setColors(CSS.enfasisColor);
		backBt.setTextColor(CSS.white);
		
		backBt.addEventListener(MouseEvent.CLICK,onHideArduino);
		arduinoFrame.addChild(backBt);
		
		
		uploadBt.y = 10;
		//uploadBt.setColors(CSS.enfasisColor);
		//uploadBt.setTextColor(CSS.white);
				
		uploadBt.addEventListener(MouseEvent.CLICK, __uploadBt_click );
		arduinoFrame.addChild(uploadBt);
		
		

		addChild(arduinoFrame);
		
		 
		
		
		paletteFrame.addEventListener(MouseEvent.ROLL_OVER, __onMouseOver);
		paletteFrame.addEventListener(MouseEvent.ROLL_OUT, __onMouseOut);
		paletteIndex = getChildIndex(paletteFrame);
		
		htmlLoader = new HTMLLoader();
		htmlLoader.placeLoadStringContentInApplicationSandbox = true;
		htmlLoader.runtimeApplicationDomain = ApplicationDomain.currentDomain;
		htmlLoader.window.trace = trace;
		//htmlLoader.window.onSendSerial = onSendSerial;
		//htmlLoader.window.onRecvModeChanged = onRecvModeChanged;
	 
		//htmlLoader.hasFocusableContent = true; 
		    
		
		var bytes:ByteArray = new Specs.arduinoHtmlPanel();
		 
		htmlLoader.loadString( bytes.readUTFBytes( bytes.bytesAvailable ).toString()  );
		
		//htmlLoader.load(new URLRequest("assets/html/index.html"));
		
		//htmlLoader.load(new URLRequest("assets/html/oncode/index.html"));
		
		addChild(htmlLoader);
		
		htmlConsole = new HTMLLoader();
		htmlConsole.placeLoadStringContentInApplicationSandbox = true;
		htmlConsole.runtimeApplicationDomain = ApplicationDomain.currentDomain;
		htmlConsole.window.trace = trace;
		htmlConsole.window.onSendSerial = onSendSerial;
		htmlConsole.window.onRecvModeChanged = onRecvModeChanged;
		
		bytes = new Specs.consoleHtmlPanel();
		htmlConsole.loadString( bytes.readUTFBytes( bytes.bytesAvailable ).toString()  );
		
		htmlConsole.visible = false;
		addChild(htmlConsole);
			
	}
	
	
	public function __uploadBt_click(evt:MouseEvent):void{
		selectTabConsole();
		//ArduinoManager.sharedManager().checkBoardBeforeCompile();
		
		var code:String  = htmlLoader.window.getCode(); 
	trace(code);
		
		// Permitimos compilar código modificado a mano 
		//- ¿?¿?  podriamos ver si el código ha cambiado con (arduinoCodeText == code)
			
		arduinoCodeText  = code;
		
					
		UploaderEx.Instance.afterOkCompile = true;
		UploaderEx.Instance.arduinoDeviceAvaliable();
	}
	
	private function __onTabCode(b:IconButton):void {
		selectTabCode();
	}
	private function __onTabConsole(b:IconButton):void {
		selectTabConsole();
	}
	
	public function selectTabCode():void{
		tabSelected = 1;
		tabCode.setOn(true);
		tabConsole.setOn(false);
		
		htmlLoader.visible = true;
		htmlConsole.visible = false;
	}
	
	public function selectTabConsole():void{
		tabSelected = 2;
		tabCode.setOn(false);
		tabConsole.setOn(true);
		htmlLoader.visible = false;
		htmlConsole.visible = true;
	}
	
	
	private var paletteIndex:int;
	private var maskWidth:int;
	private var _isRecvBinaryMode:Boolean = true;
	
	private function onRecvModeChanged():void
	{
		_isRecvBinaryMode = htmlLoader.window.isRecvBinaryMode();
	}
	
	private function __onShowCode(event:MouseEvent):void
	{   
		selectTabCode();
		showArduinoCode();
	}
	
	
	private function __onMouseOver(event:MouseEvent):void
	{
		setChildIndex(paletteFrame, numChildren-1);
		paletteFrame.addEventListener(Event.ENTER_FRAME, __onEnterFrame);
		maskWidth = 0;
	}
	
	private function __onEnterFrame(event:Event):void
	{
		if(maskWidth < 1200){
			maskWidth += 30;
			paletteFrame.showRightPart(maskWidth);
		}
		if(paletteFrame.mouseX > BlockPalette.WIDTH){
			__onMouseOut(null);
		}
	}
	
	private function __onMouseOut(event:MouseEvent):void
	{
		paletteFrame.removeEventListener(Event.ENTER_FRAME, __onEnterFrame);
		paletteFrame.hideRightPart();
		setChildIndex(paletteFrame, paletteIndex);
	}

	public function appendMessage(msg:String):void{
		appendRawMessage(msg +"\n");
	} 
	public function appendRawMessage(msg:String):void{
		htmlConsole.window.appendInfo(msg );
	}
	public function clearInfo():void
	{
		htmlConsole.window.clearInfo();
	}
	
	public function onSerialSend(bytes:ByteArray):void
	{
		if(isByteInputMode){
			appendMsgWithTimestamp(HexUtil.bytesToString(bytes), true);
		}else{
			bytes.position = 0;
			var str:String = bytes.readUTFBytes(bytes.length);
			appendMsgWithTimestamp(str, true);
		}
	}
	
	public function appendMsgWithTimestamp(msg:String, isOut:Boolean):void
	{
		var sendType:String = isOut ? " > " : " < ";
		appendMessage(formatTime() + sendType + msg);
	}
	
	static private function formatTime():String
	{
		var date:Date = new Date();
		return formatStr(date.hours.toString()  , 2) + ":"
			 + formatStr(date.minutes.toString(), 2) + ":"
			 + formatStr(date.seconds.toString(), 2) + "."
			 + formatStr(date.milliseconds.toString(), 3);
	}
	
	static private function formatStr(str:String, len:int):String
	{
		while(str.length < len){
			str = "0" + str;
		}
		return str;
	}
	
	public function onSerialDataReceived(bytes:ByteArray):void{
		if(htmlConsole.window.isRecvBinaryMode()){
			appendMsgWithTimestamp(HexUtil.bytesToString(bytes), false);
		}else{
			bytes.position = 0;
			var str:String = bytes.readUTFBytes(bytes.length);
			appendMsgWithTimestamp(str, false);
		}
		/*
		return;
		var date:Date = new Date;
		var s:String = SerialManager.sharedManager().asciiString;
		if(s.charCodeAt(0)==20){
			return;
		}
		appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+":"+(date.seconds+date.milliseconds/1000)+" < "+SerialManager.sharedManager().asciiString.split("\r\n").join("")+"\n");
		*/
	}
	private function onSendSerial(str:String):void{
		if(!SerialDevice.sharedDevice().connected){
			return;
		}
		if(str.length <= 0){
			return;
		}
		var bytes:ByteArray;
		if(isByteInputMode){
			bytes = HexUtil.stringToBytes(str);
		}else{
			bytes = new ByteArray();
			bytes.writeUTFBytes(str + "\n");
		}
		onSerialSend(bytes);
		ConnectionManager.sharedManager().sendBytes(bytes);
//		var date:Date = new Date;
//		messageTextPane.append(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+":"+(date.seconds+date.milliseconds/1000)+" > "+sendTextPane.textField.text+"\n");
		
//		messageTextPane.textField.scrollV = messageTextPane.textField.maxScrollV-1;
	}
	public function get isArduinoMode():Boolean{
		return arduinoFrame.visible;
	}
	
	//- lo llama ArduinoManager.sharedManager().checkBoardBeforeCompile() si hubo éxito 
	public function onCompileArduino():void{
		
		//ArduinoManager.sharedManager().checkBoardBeforeCompile();
		//return;
		
		//htmlLoader.window.appendInfo(ArduinoManager.sharedManager().buildAll(arduinoCodeText));
		//return;
		
		//if(SerialManager.sharedManager().isConnected){
		if(SerialDevice.sharedDevice().currPort!=""){
			if(ArduinoManager.sharedManager().isUploading==false){
				htmlConsole.window.clearInfo();
				
				// NO hace falta volver a regenerar el código
				//if(showArduinoCode()){
					htmlConsole.window.appendInfo(ArduinoManager.sharedManager().buildAll(arduinoCodeText));
					ConnectionManager.sharedManager().onClose(SerialDevice.sharedDevice().port);
					AppTitleMgr.Instance.setConnectInfo("Uploading");
				//}
			}
		}else{
			var dialog:DialogBox = new DialogBox();
			dialog.addTitle("Message");
			dialog.addText("Please connect the serial port.");
			function onCancel():void{
				dialog.cancel();
			}
			dialog.addButton("OK",onCancel);
			dialog.showOnStage(app.stage);
		}
	}
	private function onHideArduino(evt:MouseEvent):void{
		
		this.codeBt.visible = true;
		app.toggleArduinoMode();
	}
	/*private function onOpenArduinoIDE(evt:MouseEvent):void{
		if(showArduinoCode()){
			ArduinoManager.sharedManager().openArduinoIDE(arduinoCodeText);
		}
	}*/
	
	/*static private const classNameList:Array = [
		"SoftwareSerial",
		"MeBoard",
		"MeDCMotor",
		"MeServo",
		"MeIR",
		"Me7SegmentDisplay",
		"MeRGBLed",
		"MePort",
		"MeGyro",
		"MeJoystick",
		"MeLight",
		"MeSound",
		"MeStepper",
		"MeEncoderMotor",
		"MeInfraredReceiver",
		"MeTemperature",
		"MeUltrasonicSensor",
		"MeSerial",
		"Servo",
		"mBot",
		"Arduino",
	];*/
	
	public function getSourceCode():String{
		var retcode:String = "";
		try{
			retcode = util.JSON.stringify(app.stagePane);
		}catch(e:*){
			return null;
		}
		var formatCode:String = ArduinoManager.sharedManager().jsonToCpp(retcode);
		
		if(formatCode!=null){
			
			for(var i:uint=0;i<5;i++){
				formatCode = formatCode.split("\r\n\r\n").join("\r\n").split("\r\n\t\r\n").join("\r\n");
			}
			/* Format code :  antes se hacía en el index.html  en setCode() */
			var myPattern1:RegExp = /^\s+|\s+$/g;  
			formatCode = formatCode.replace(myPattern1, "");
			var myPattern2:RegExp = /(\t+|\x20+)\n/g;
			formatCode = formatCode.replace(myPattern2, "");
			var myPattern3:RegExp = /\n{3,}/g;  
			formatCode = formatCode.replace(myPattern3, "\n\n");
		}
		
		return formatCode;
	}
	
	public function showArduinoCode(arg:String=""):Boolean{
		
		//return true;
		
		/*if(ScriptsPart.isShowingCode) return false;
		ScriptsPart.isShowingCode = true;*/
		
	  
		
		var formatCode:String = getSourceCode();
		
		if(formatCode==null){
			ScriptsPart.isShowingCode = false;
			return false;
		}
		if(!app.stageIsArduino){
			app.toggleArduinoMode();
		}
		
	
	
		arduinoCodeText = formatCode;
				
		htmlLoader.window.setCode(arduinoCodeText);
		
		uploadBt.visible = !ArduinoManager.sharedManager().hasUnknownCode;
		fixlayout();
		if( ArduinoManager.sharedManager().hasUnknownCode ){
			if(!isDialogBoxShowing){
				isDialogBoxShowing = true;
				var dBox:DialogBox = new DialogBox();
				dBox.addTitle(Translator.map("unsupported block found, remove them to continue."));
				for each(var b:Block in ArduinoManager.sharedManager().unknownBlocks){
					b.mouseEnabled = false;
					b.mouseChildren = false;
					dBox.addBlock(b);
				}
				function cancelHandle():void{
					isDialogBoxShowing = false;
					dBox.cancel();
				}
				dBox.addButton("OK",cancelHandle);
				dBox.showOnStage(app.stage);
				dBox.fixLayout();
			}
			arduinoFrame.visible = false;
			
			this.codeBt.visible = true;
			
			if(app.stageIsArduino){
				app.toggleArduinoMode();
			}
		}else{
			arduinoFrame.visible = true;
			this.codeBt.visible = false;
		}
		htmlLoader.visible = arduinoFrame.visible;
		
		
		//ScriptsPart.isShowingCode = false;
		
		return true;
	}
	static private var isDialogBoxShowing:Boolean;
//	private function formatKeyword(pattern:RegExp,format:TextFormat,subStart:uint=0,subEnd:uint=0):void
//	{
//		arduinoCodeText = arduinoCodeText.replace(pattern, '<font color="#' + format.color.toString(16) + '">$&</font>');
//	}
	public function resetCategory():void { selector.select(Specs.motionCategory) }

	public function updatePalette():void {
		
		
		selector.updateTranslation();
		if(!eBlock.app.stageIsArduino && eBlock.app.viewedObj() is ScratchStage){
			if(selector.selectedCategory == Specs.motionCategory){
				selector.selectedCategory = Specs.eventsCategory; //*JC* seleccionar categoría por defecto
			}
		}
		selector.select(selector.selectedCategory);
	}
	
		
	public function updateTranslation():void{
		backBt.setLabel("x");
		//backBt.setIcon( Resources.createBmp("eblockLogo") );
		uploadBt.setLabel(Translator.map("Upload")); 
		//openBt.setLabel(Translator.map("Edit with Arduino IDE"));  //*JC*
		if(htmlLoader.loaded){
			htmlLoader.window.updateTranslation();
		}
		if(htmlConsole.loaded){
			htmlConsole.window.updateTranslation();
		}
//		sendBt.setLabel(Translator.map("Send"));
//		displayModeBtn.setLabel(Translator.map(isByteDisplayMode ? "binary mode" :  "char mode"));
//		inputModeBtn.setLabel(Translator.map(isByteInputMode ? "binary mode" :  "char mode"));
	}
	private function get isByteInputMode():Boolean
	{
		return htmlConsole.window.isSendBinaryMode();
	}
	public function updateSpriteWatermark():void {
		var target:ScratchObj = app.viewedObj();
		if (target && !target.isStage) {
			spriteWatermark.bitmapData = target.currentCostume().thumbnail(40, 40, false);
		} else {
			spriteWatermark.bitmapData = null;
		}
	}

	public function step():void {
		// Update the mouse reaadouts. Do nothing if they are up-to-date (to minimize CPU load).
		var target:ScratchObj = app.viewedObj();
		if (target.isStage) {
			if (xyDisplay.visible) xyDisplay.visible = false;
		} else {
			if (!xyDisplay.visible) xyDisplay.visible = true;

			var spr:ScratchSprite = target as ScratchSprite;
			if (!spr) return;
			if (spr.scratchX != lastX) {
				lastX = spr.scratchX;
				xReadout.text = String(lastX);
			}
			if (spr.scratchY != lastY) {
				lastY = spr.scratchY;
				yReadout.text = String(lastY);
			}
		}
		updateExtensionIndicators();
		
		
	}

	private var lastUpdateTime:uint;

	private function updateExtensionIndicators():void {
		if ((getTimer() - lastUpdateTime) < 500) return;
		
		//eBlock.app.extensionManager.updateIndicator(null, null, false);
		
		ConnectionManager.sharedManager().updateIndicator();
		
		lastUpdateTime = getTimer();
		return;
		
		for (var i:int = 0; i < app.palette.numChildren; i++) {
			var indicator:IndicatorLight = app.palette.getChildAt(i) as IndicatorLight;
			if (indicator) app.extensionManager.updateIndicator(indicator, indicator.target);
		}		
		lastUpdateTime = getTimer();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		fixlayout();
		redraw();
	}

	private function fixlayout():void {

		return;
		selector.x = 1;
		selector.y = 5;
		paletteFrame.x = selector.x;
		paletteFrame.y = selector.y + selector.height + 2;
		paletteFrame.setWidthHeight(selector.width + 1, h - paletteFrame.y - 2); // 模块滚动区域宽度
		scriptsFrame.x = selector.x + selector.width + 2;
		scriptsFrame.y = selector.y + 1;
		var arduinoWidth:uint = app.stageIsArduino?(w/2-150):0;
		var arduinoHeight:uint = h - 10;
		arduinoFrame.visible = app.stageIsArduino;
		scriptsFrame.setWidthHeight(w - scriptsFrame.x - 15-arduinoWidth, h - scriptsFrame.y - 5);//代码区
		arduinoFrame.x = scriptsFrame.x+ (w - scriptsFrame.x - 15-arduinoWidth)+8;
		arduinoFrame.y = scriptsFrame.y;
		arduinoFrame.setWidthHeight(arduinoWidth, arduinoHeight);
		
		htmlLoader.visible = (tabSelected==1) ;// arduinoFrame.visible;
		htmlLoader.x = arduinoFrame.x;
		htmlLoader.y = arduinoFrame.y + 40;
		htmlLoader.width = arduinoWidth;
		htmlLoader.height = arduinoHeight - 42;
		
		htmlConsole.visible = (tabSelected==2);
		htmlConsole.x=htmlLoader.x;
		htmlConsole.y=htmlLoader.y;
		htmlConsole.width=htmlLoader.width;
		htmlConsole.height=htmlLoader.height;
		
				
		
		
//		arduinoTextPane.setWidthHeight(arduinoWidth-lineNumWidth-lineNumText.x-5,arduinoHeight-255);
//		arduinoTextPane.x = lineNumText.x+lineNumText.width+5;
//		arduinoTextPane.y = 45;
//		messageTextPane.x = 4;
//		messageTextPane.y = arduinoHeight-200;
//		messageTextPane.setWidthHeight(arduinoWidth-messageTextPane.x,155);
//		openBt.x = arduinoWidth - openBt.width - 10;
//		sendTextPane.x = 8 + 200;
//		sendTextPane.y = arduinoHeight - 33;
//		sendTextPane.setWidthHeight(arduinoWidth-sendBt.width-sendTextPane.x-10,20);
//		sendBt.x = arduinoWidth - sendBt.width - 10;
//		sendBt.y = arduinoHeight - 35;
//		displayModeBtn.x = htmlLoader.width - displayModeBtn.width;
//		displayModeBtn.y = htmlLoader.height - 200;
//		inputModeBtn.x = 4;
//		inputModeBtn.y = sendBt.y;
//		messageTextPane.updateScrollbar(null);
	
		spriteWatermark.x = w - arduinoWidth - 60;
		spriteWatermark.y = scriptsFrame.y + 10;
		xyDisplay.x = spriteWatermark.x + 1;
		xyDisplay.y = spriteWatermark.y + 43;
		zoomWidget.x = w - arduinoWidth - zoomWidget.width - 30;
		zoomWidget.y = h - zoomWidget.height - 15;
		
		
		//codeBt.se

		codeBt.x = w - arduinoWidth - codeBt.width -30;
		codeBt.y = 15;
				
		tabConsole.x  =  htmlLoader.width - backBt.width -35;
		tabCode.x = tabConsole.x -tabCode.width;
		
		backBt.x =  0;
		uploadBt.x = backBt.x +  backBt.width +5;
		
		/*backBt.x =  htmlLoader.width - backBt.width;
		uploadBt.x = backBt.x - uploadBt.width-5;*/
	}

	
	public function RefreshButtons():void{
		
		this.codeBt.visible = !app.stageIsArduino;
		
			
	}
	
	private function redraw():void {
		var paletteW:int = paletteFrame.visibleW();
		var paletteH:int = paletteFrame.visibleH();
		var scriptsW:int = scriptsFrame.visibleW();
		var scriptsH:int = scriptsFrame.visibleH();

		var g:Graphics = shape.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var lineY:int = selector.y + selector.height;
		var darkerBorder:int = CSS.borderColor - 0x141414;
		var lighterBorder:int = 0xF2F2F2;
		g.lineStyle(1, darkerBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY, paletteW - 20);
		g.lineStyle(1, lighterBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY + 1, paletteW - 20);

		g.lineStyle(1, darkerBorder, 1, true);
		g.drawRect(scriptsFrame.x - 1, scriptsFrame.y - 1, scriptsW + 1, scriptsH + 1);
		
		
		
		//- recuadro zona HTMLLoader
		if(isArduinoMode){
			g.lineStyle(1, CSS.borderColor, 1, true);
			g.drawRect(htmlConsole.x-1, htmlConsole.y-1, htmlConsole.width+1, htmlConsole.height+1);
			g.endFill();
		}
	}

	private function hLine(g:Graphics, x:int, y:int, w:int):void {
		g.moveTo(x, y);
		g.lineTo(x + w, y);
	}

	private function addXYDisplay():void {
		
		xyDisplay = new Sprite();
		
		xyDisplay.addChild(xLabel = makeLabel('x:', readoutLabelFormat, 0, 0));
		xyDisplay.addChild(xReadout = makeLabel('-888', readoutFormat, 15, 0));
		xyDisplay.addChild(yLabel = makeLabel('y:', readoutLabelFormat, 0, 13));
		xyDisplay.addChild(yReadout = makeLabel('-888', readoutFormat, 15, 13));
		
		addChild(xyDisplay);
		
	}

}}
