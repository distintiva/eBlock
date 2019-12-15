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

// TopBarPart.as
// John Maloney, November 2011
//
// This part holds the Scratch Logo, cursor tools, screen mode buttons, and more.

package ui.parts {
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.setTimeout;
	
	import assets.Resources;
	
	import cc.customcode.uibot.util.AppTitleMgr;
	
	import extensions.DeviceManager;
	import extensions.ParseManager;
	
	import translation.Translator;
	
	import uiwidgets.CursorTool;
	import uiwidgets.IconButton;
	import uiwidgets.IndicatorLight;
	import uiwidgets.Menu;
	import uiwidgets.SimpleTooltips;
	
	import util.ApplicationManager;
	import util.Clicker;
	import util.ClickerManager;

	public class TopBarPart extends UIPart {
 
		
		protected var shareMenu:IconButton;
		
		private var copyTool:IconButton;
		private var cutTool:IconButton;
		private var growTool:IconButton;
		private var shrinkTool:IconButton;
		private var helpTool:IconButton;
		
		private var toolOnMouseDown:String;
	
		private var xLabel:TextField;
		
		private var boardLabelMenu:IconButton;
		private var labelBoardText:TextField;
		
		private var indicator:IndicatorLight ;
		
		private var helpIcon:IconButton;
		
		private var readoutLabelFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
		
	
		public function TopBarPart(app:eBlock) {
			this.app = app;
			addButtons();
			refresh();
			
			
			
		}
	
		protected function addButtons():void {

			addTextButtons();
			addToolButtons();
		}
	
		public static function strings():Array {

			return ['File', 'Edit', 'Tips', 'Duplicate', 'Delete', 'Grow', 'Shrink', 'Block help', 'Offline Editor'];
		}
	
		protected function removeTextButtons():void {

		}
	
		public function updateTranslation():void {
			removeTextButtons();
			addTextButtons();
//			updateVersion();
			refresh();
		}

		public function setWidthHeight(w:int, h:int):void {
			this.w = w;
			this.h = h;
			/*
			var g:Graphics = shape.graphics;
			g.clear();
			g.beginFill(CSS.topBarColor);
			g.drawRect(0, 0, w, h);
			g.endFill();
			*/
			fixLayout();
		}
	
		
		public function helpIconOnOff():void{
		
			
			helpIcon.visible = DeviceManager.sharedManager().hasReadmeFile();
		}
		
		protected function fixLayout():void {

			// cursor tool buttons
			var space:int = 3;
//			copyTool.x = 760+(app.stageIsContracted?ApplicationManager.sharedManager().contractedOffsetX:0);
			
			var toolStart:int = 760;
			if(app.stageIsHided){
				toolStart = 280;
			}else if(app.stageIsContracted){
				toolStart = 520;
			}
			
			
			indicator.x = toolStart;//app.palette.width - 30;
			indicator.y = 8;
			updateIndicator(false);
			toolStart+=indicator.width+2;
			
			boardLabelMenu.x = toolStart;
			toolStart+=boardLabelMenu.width+5;
			boardLabelMenu.y=5;
			
			helpIcon.y = 7;
			helpIcon.x = boardLabelMenu.x +boardLabelMenu.width+8;
			
			
			/*labelBoardText.x = toolStart;
			toolStart+=labelBoardText.width+10;
			labelBoardText.y=5;*/
			
/*			copyTool.x = toolStart;
			
			cutTool.x = copyTool.right() + space;
			growTool.x = cutTool.right() + space;
			shrinkTool.x = growTool.right() + space;
			
			
			
			copyTool.y = cutTool.y = shrinkTool.y = growTool.y = 4;//buttonY - 3;
	*/
			
		
		}
	
		public function updateIndicator( onoff:Boolean ):void{
			if(onoff==true){
				indicator.setColorAndMsg(/*0xA4C188*/0xBCEB30, Translator.map('Connected'));
			}else{
				indicator.setColorAndMsg(0xF2F2F2, Translator.map('Disconnected'));
			}
		}
		
		public function refresh():void {
			fixLayout();
		}
	
		protected function addTextButtons():void {
		
		}
	
		
		public function setBoardName(name:String):void{
			boardLabelMenu.setLabel(name,  CSS.panelColor,CSS.enfasisColor, true);
			refresh();
		}
		
		private function addToolButtons():void {
			function selectTool(b:IconButton):void {
				var newTool:String = '';
				if (b == copyTool) newTool = 'copy';
				if (b == cutTool) newTool = 'cut';
				if (b == growTool) newTool = 'grow';
				if (b == shrinkTool) newTool = 'shrink';
				if (b == helpTool) newTool = 'help';
				if (newTool == toolOnMouseDown) {
					clearToolButtons();
					CursorTool.setTool(null);
				} else {
					clearToolButtonsExcept(b);
					CursorTool.setTool(newTool);
				}
			}
			
		
			
			function devicesContextMenu(ignore:*):void {
				//updateIndicator(true);
				var boards:NativeMenuItem = eBlock.app.systemMenu.getMenuBoards();
				boards.submenu.display(eBlock.app.stage, boardLabelMenu.x, boardLabelMenu.y+boardLabelMenu.height);
			}
			
			boardLabelMenu = UIPart.makeMenuButton( "BBC micro:bit", devicesContextMenu, true, CSS.panelColor);
			boardLabelMenu.useHandCursor = true;
			boardLabelMenu.buttonMode = true;
			addChild(boardLabelMenu);
			
			
			function helpIcon_click(ignore:*):void {
				DeviceManager.sharedManager().openHelp()
			}
			
			helpIcon = new IconButton( helpIcon_click , 'extensionHelp');
			addChild(helpIcon);
			
			boardLabelMenu.addEventListener(MouseEvent.CLICK, function(e:Event):void {
				
			}, false, 0, true);
			
			
			//xLabel = makeLabel('Board:', CSS.boardFormat);
			//addChild(xLabel);
			
			indicator= new IndicatorLight(null);
			indicator.addEventListener ( MouseEvent.CLICK, function(e:Event):void {
				//updateIndicator(true);
				var conn:NativeMenu = eBlock.app.systemMenu.getMenuConnect();
				
				conn.display(eBlock.app.stage, indicator.x+6, indicator.y+6);
				
			});
			
			
			addChild(indicator);
			
			
			
			
			/*labelBoardText = makeLabel('BBC micro:bit', CSS.boardTextFormat);
			adChild(labelBoardText);
			*/
			
			/*
			addChild(copyTool = makeToolButton('copyTool', selectTool));
			addChild(cutTool = makeToolButton('cutTool', selectTool));
			addChild(growTool = makeToolButton('growTool', selectTool));
			addChild(shrinkTool = makeToolButton('shrinkTool', selectTool));
			
	
			SimpleTooltips.add(copyTool, {text: 'Duplicate', direction: 'bottom'});
			SimpleTooltips.add(cutTool, {text: 'Delete', direction: 'bottom'});
			SimpleTooltips.add(growTool, {text: 'Grow', direction: 'bottom'});
			SimpleTooltips.add(shrinkTool, {text: 'Shrink', direction: 'bottom'});
			*/
			//SimpleTooltips.add(helpTool, {text: 'Block help', direction: 'bottom'});
		}
	
		public function clearToolButtons():void { clearToolButtonsExcept(null) }
	
		private function clearToolButtonsExcept(activeButton: IconButton):void {
			for each (var b:IconButton in [copyTool, cutTool, growTool, shrinkTool]) {
				if (b != activeButton) b.turnOff();
			}
		}
	
		private function makeToolButton(iconName:String, fcn:Function):IconButton {
			function mouseDown(evt:MouseEvent):void { toolOnMouseDown = CursorTool.tool }
			var onImage:Sprite = toolButtonImage(iconName, 0xcfefff, 1);
			var offImage:Sprite = toolButtonImage(iconName, 0, 0);
			var b:IconButton = new IconButton(fcn, onImage, offImage);
			b.actOnMouseUp();
			b.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown); // capture tool on mouse down to support deselecting
			return b;
		}
	
		private function toolButtonImage(iconName:String, color:int, alpha:Number):Sprite {
			const w:int = 23;
			const h:int = 24;
			var img:Bitmap;
			var result:Sprite = new Sprite();
			var g:Graphics = result.graphics;
			g.clear();
			g.beginFill(color, alpha);
			g.drawRoundRect(0, 0, w, h, 8, 8);
			g.endFill();
			result.addChild(img = Resources.createBmp(iconName));
			img.x = Math.floor((w - img.width) / 2);
			img.y = Math.floor((h - img.height) / 2);
			return result;
		}
	
		protected function makeButtonImg(s:String, c:int, isOn:Boolean):Sprite {
			var result:Sprite = new Sprite();
	
			var label:TextField = makeLabel(Translator.map(s), CSS.topBarButtonFormat, 2, 2);
			label.textColor = CSS.white;
			label.x = 6;
			result.addChild(label); // label disabled for now
	
			var w:int = label.textWidth + 16;
			var h:int = 22;
			var g:Graphics = result.graphics;
			g.clear();
			g.beginFill(c);
			g.drawRoundRect(0, 0, w, h, 8, 8);
			g.endFill();
	
			return result;
		}
		public function setConnectedTitle(title:String):void{
			AppTitleMgr.Instance.setConnectInfo(title);
			/*
			removeChild(connectMenu);
			addChild(connectMenu = makeMenuButton(title, app.showConnectMenu, true));
			this.fixLayout();
			*/
		}
		public function setBoardTitle():void{

		}
	
		public function setDisconnectedTitle():void{
			AppTitleMgr.Instance.setConnectInfo(null);

		}

	}
}
