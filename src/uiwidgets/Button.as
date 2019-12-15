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

package uiwidgets {
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
public class Button extends Sprite {

	private var labelOrIcon:DisplayObject;
	private var color:* = CSS.titleBarColors;
	
	private var colorNormal:* = CSS.titleBarColors;
	private var colorOver:* = CSS.overColor;
	private var colorBorder:* = CSS.borderColor;
	
	private var colorLabel:* = CSS.buttonLabelColor;
	
	
	private var minWidth:int = 40;
	private var compact:Boolean;
	
	private var action:Function;
	private var tipName:String;
	
	

	public function Button(label:String, action:Function = null, compact:Boolean = false, tipName:String = null) {
		this.action = action;
		this.compact = compact;
		this.tipName = tipName;
		addLabel(label);
		mouseChildren = false;
		
		this.buttonMode = true;
		this.useHandCursor = true;
		
		addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
		addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		setColor(this.colorNormal);
	}

	public function setLabel(s:String):void {
		if (labelOrIcon is TextField) {
			TextField(labelOrIcon).text = s;
			setMinWidthHeight(0, 0);
		} else {
			if ((labelOrIcon != null) && (labelOrIcon.parent != null)) labelOrIcon.parent.removeChild(labelOrIcon);
			addLabel(s);
		}
	 }

	public function setIcon(icon:DisplayObject):void {
		if ((labelOrIcon != null) && (labelOrIcon.parent != null)) {
			labelOrIcon.parent.removeChild(labelOrIcon);
		}
		labelOrIcon = icon;
		if (icon != null) addChild(labelOrIcon);
		setMinWidthHeight(0, 0);
	}

	public function setMinWidthHeight(minW:int, minH:int):void {
		if (labelOrIcon != null) {
			if (labelOrIcon is TextField) {
				minW = Math.max(minWidth, labelOrIcon.width + 11);
				minH = compact ? 20 : 25;
			} else {
				minW = Math.max(minWidth, labelOrIcon.width + 12);
				minH = Math.max(minH, labelOrIcon.height + 11);
			}
			labelOrIcon.x = ((minW - labelOrIcon.width) / 2);
			labelOrIcon.y = ((minH - labelOrIcon.height) / 2);
		}
		// outline
		graphics.clear();
		graphics.lineStyle(0.5, this.colorBorder, 1, true);
		if (color is Array) {
	 		var matr:Matrix = new Matrix();
 			matr.createGradientBox(minW, minH, Math.PI / 2, 0, 0);
 			graphics.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], matr);  
  		}
		else graphics.beginFill(color);
		graphics.drawRoundRect(0, 0, minW, minH, 12);
 		graphics.endFill();
	}

	private function mouseOver(evt:MouseEvent):void { setColor(this.colorOver) }
	private function mouseOut(evt:MouseEvent):void { setColor(this.colorNormal) }
	private function mouseDown(evt:MouseEvent):void { Menu.removeMenusFrom(stage) }
	private function mouseUp(evt:MouseEvent):void {
		if (action != null) action();
		evt.stopImmediatePropagation();
	}

	public function handleTool(tool:String, evt:MouseEvent):void {
		if (tool == 'help' && tipName) eBlock.app.showTip(tipName);
	}

	
	public function setColors( normalColor:*, overColor:* = CSS.overColor  ):void{
		this.colorNormal = normalColor;
		this.colorOver = overColor;
		
		this.colorBorder = normalColor;
		
		setColor(normalColor);
	}
	
	public function setTextColor( normalColor:*  ):void{
		
		this.colorLabel = normalColor;
		
		TextField(labelOrIcon).textColor = normalColor;
		
	}
	
	
	private function setColor(c:*):void {
		color = c;
		if (labelOrIcon is TextField) {
			(labelOrIcon as TextField).textColor = (c == CSS.overColor) ? CSS.white : this.colorLabel;
		}
		setMinWidthHeight(5, 5);
	}

	private function addLabel(s:String):void {
		var label:TextField = new TextField();
		label.autoSize = TextFieldAutoSize.LEFT;
		label.selectable = false;
		label.background = false;
		label.defaultTextFormat = CSS.normalTextFormat;
		label.textColor = this.colorLabel;
		label.text = s;
		labelOrIcon = label;
		setMinWidthHeight(0, 0);
		addChild(label);
	}

}}
