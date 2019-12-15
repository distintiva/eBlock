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

// CSS.as
// Paula Bonta, November 2011
//
// Styles for Scratch Editor based on the Upstatement design.

package {
	import flash.text.TextFormat;
	
	import assets.Resources;

public class CSS {

	// Colors  B5CDE9
	public static const white:int = 0xFFFFFF;
	public static const topBarColor:int = 0x4DADFC;
	public static const tabColor:int = 0xEAF6FF;
	public static const panelColor:int = 0x4DADFC;//0xEAF6FF;
	public static const itemSelectedColor:int = 0xD0D0D0;
	public static const borderColor:int = 0xC1DBF9;
	public static const textColor:int = 0x5C5D5F; // 0x6C6D6F
	public static const buttonLabelColor:int = textColor;
	public static const buttonLabelOverColor:int = 0xFBA939;
	public static const offColor:int = 0x8F9193; // 0x9FA1A3
	public static const onColor:int = textColor; // 0x4C4D4F
	public static const overColor:int = 0xF4A02F;//0x179FD7;
	public static const arrowColor:int = 0xA6A8AC;
	public static const disableColor:uint = 0xEEEEEE;
	
	public static const enfasisColor:uint = 0xF4A02F;
	
	// Fonts
	public static const font:String = Resources.chooseFont(['微软雅黑','Arial', 'Verdana', 'DejaVu Sans','Microsoft Yahei']);
	public static const menuFontSize:int = 13;
	
	public static const normalTextFormat:TextFormat = new TextFormat(font, 13, textColor);
	public static const extensionSepTextFormat:TextFormat = new TextFormat(font, 12, 0xB5CDE9);
	
	public static const topBarButtonFormat:TextFormat = new TextFormat(font, 12, white, true);
	public static const titleFormat:TextFormat = new TextFormat(font, 13, textColor);
	
	public static const linkFormat:TextFormat = new TextFormat(font, 13, 0x0F75BC, null, null, true);
	
	public static const boardFormat:TextFormat = new TextFormat(font, 13, 0x4DADFC/*0x0F75BC*/, true, null );
	public static const boardTextFormat:TextFormat = new TextFormat(font, 13, 0x888888, null, null, false);
	
	
	public static const thumbnailFormat:TextFormat = new TextFormat(font, 12, textColor);
	public static const thumbnailExtraInfoFormat:TextFormat = new TextFormat(font, 12, textColor);
	public static const projectTitleFormat:TextFormat = new TextFormat(font, 13, white);
	public static const projectInfoFormat:TextFormat = new TextFormat(font, 12, white);

	// Section title bars
	public static const titleBarColors:Array = [0xC1DBF9,0xC1DBF9];//[white, tabColor];
	public static const titleBarH:int = 30;

}}
