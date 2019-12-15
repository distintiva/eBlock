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

// PaletteBuilder.as
// John Maloney, September 2010
//
// PaletteBuilder generates the contents of the blocks palette for a given
// category, including the blocks, buttons, and watcher toggle boxes.

package scratch {
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import blocks.Block;
	import blocks.BlockArg;
	
	import extensions.ExtensionManager;
	import extensions.ScratchExtension;
	
	import interpreter.RobotHelper;
	
	import translation.Translator;
	
	import ui.ProcedureSpecEditor;
	import ui.media.MediaLibrary;
	import ui.parts.UIPart;
	
	import uiwidgets.Button;
	import uiwidgets.DialogBox;
	import uiwidgets.IconButton;
	import uiwidgets.IndicatorLight;
	import uiwidgets.Menu;
	import uiwidgets.VariableSettings;

public class PaletteBuilder {

	protected var app:eBlock;
	protected var nextY:int;

	public function PaletteBuilder(app:eBlock) {
		this.app = app;
	}

	public static function strings():Array {
		return [
			'Stage selected:', 'No motion blocks',
			'Make a Block', 'Make a List', 'Make a Variable',
			'New List', 'List name', 'New Variable', 'Variable name'];
	}
	
	public function showBlocksForCategory(selectedCategory:int, scrollToOrigin:Boolean, shiftKey:Boolean = false):void {
		if (app.palette == null) return;
		app.palette.clear(scrollToOrigin);
		nextY = 7;

		if (selectedCategory == Specs.dataCategory) return showDataCategory();
		//if (selectedCategory == Specs.myBlocksCategory) return showMyBlocksPalette(shiftKey, 10);
		
			//*JC*
		showMyBlocksPalette(shiftKey, selectedCategory);

		//- mostrar bloques scratch solo si no estamos en modo Arduino, y si estamos en modo Arduino y en una de las 2 categorias 	
		var ShowScratchBlocks:Boolean = ( selectedCategory==Specs.dataCategory || selectedCategory==Specs.controlCategory || selectedCategory==Specs.operatorsCategory ) ||  !this.app.stageIsArduino;
		
		//- Solo mostrar el separador de Scratch en las categorías donde puedan entrar extensiones
		if(ShowScratchBlocks && Specs.categoriesExtensions.indexOf(selectedCategory)>=0) addScratchSeparator(null); //*JC*		
		
		
		var catColor:int = Specs.blockColor(selectedCategory);
		
		//- Ocultar/mostrar bloques de Scratch en las categorías donde esté el separador
	if( ShowScratchBlocks ){
		if(Specs.categoriesExtensions.indexOf(selectedCategory)<0 || eBlock.app.extensionManager.ShowScratchBlocks )  addBlocksForCategory(selectedCategory, catColor);
	}			
	
		
		updateCheckboxes();
	}
	
	static private function modifyCategory(category):int
	{
		if(eBlock.app.viewedObj() is ScratchSprite){
			return category;
		}
		switch(category){
			case Specs.motionCategory:
			case Specs.looksCategory:
			case Specs.penCategory:
			case Specs.controlCategory:
			case Specs.sensingCategory:
				return category + 100;
		}
		return category;
	}
	
	static private function canShowInArduinoMode(spec:Array):Boolean
	{
		var categoryId:int = parseInt(spec[2]) % 100;
		if(eBlock.app.stageIsArduino && categoryId == Specs.controlCategory){
			switch(spec[3]){
				case "stopScripts":
				case "whenCloned":
				case "createCloneOf":
				case "deleteClone":
					return false;
			}
		}
		return true;
	}

	private function addBlocksForCategory(category:int, catColor:int):void {
		var cmdCount:int;
		var targetObj:ScratchObj = app.viewedObj();
		category = modifyCategory(category);
		for each (var spec:Array in Specs.commands) {
			if ((spec.length > 3) && (spec[2] == category)) {
				if(!canShowInArduinoMode(spec)){
					continue;
				}
				var label:String = spec[0];
				var blockColor:int = (app.interp.isImplemented(spec[3])) ? catColor : 0x505050;
				var defaultArgs:Array = targetObj.defaultArgsFor(spec[3], spec.slice(4));
				
				if(targetObj.isStage && spec[3] == 'whenClicked') label = 'when Stage clicked';
				var block:Block = new Block(label, spec[1], blockColor, spec[3], defaultArgs);   //*JC* se crean bloques y cada bloque lleva a  qué categoría va
				var showCheckbox:Boolean = isCheckboxReporter(spec[3]);
				if (showCheckbox){
					addReporterCheckbox(block);
				}
				addItem(block, showCheckbox);
				cmdCount++;
			} else if(spec.length < 3){
				if (cmdCount > 0) {
					nextY += 10 * spec[0].length; // add some space
					cmdCount = 0;
				}
				addLabelText(spec[1]);
			}
		}
	}
	
	private function addLabelText(text:String):void
	{
		if(!Boolean(text)){
			return;
		}
		var labelTxt:TextField = new TextField();
		labelTxt.mouseEnabled = false;
		labelTxt.autoSize = TextFieldAutoSize.LEFT;
		labelTxt.text = text;
		
		labelTxt.setTextFormat( CSS.extensionSepTextFormat);
		 
		addItem(labelTxt);
	}

	protected function addItem(o:DisplayObject, hasCheckbox:Boolean = false):void {
		
		o.x = hasCheckbox ? 23 : 6;
		o.y = nextY;
		app.palette.addChild(o);
		app.palette.updateSize();
		nextY += o.height + 5;
	}

	private function makeLabel(label:String):TextField {
		var t:TextField = new TextField();
		t.autoSize = TextFieldAutoSize.LEFT;
		t.selectable = false;
		t.background = false;
		t.text = label;
		t.setTextFormat(CSS.normalTextFormat);
		return t;
	}

	private function showMyBlocksPalette(shiftKey:Boolean, category:int):void {
		// show creation button, hat, and call blocks
		//var catColor:int = Specs.blockColor(Specs.procedureColor);
		

	//	addItem(new Button(Translator.map('Add an Extension'), showAnExtension, false, '/help/studio/tips/blocks/add-an-extension/'));
		
		for each (var ext:ScratchExtension in app.extensionManager.allExtensions()) {
			
			if(ext.name!= "_base_" && hasBlocksInCategory(ext, category) ){ //- Se pueden mostrar bloques de la extension en esta categoria ??
				addExtensionSeparator(ext);  //*JC*
				if(ext.showBlocks) addBlocksForExtension(ext, category);
			}
		}

		updateCheckboxes();
	}

	private function showDataCategory():void {
		var catColor:int = Specs.variableColor;

		// variable buttons, reporters, and set/change blocks
		addItem(new Button(Translator.map('Make a Variable'), makeVariable));
		var varNames:Array = app.runtime.allVarNames().sort();
		if (varNames.length > 0) {
			for each (var n:String in varNames) {
				if(RobotHelper.isAutoVarName(n)){
					continue;
				}
				addVariableCheckbox(n, false);
				addItem(new Block(n, 'r', catColor, Specs.GET_VAR), true);
			}
			nextY += 10;
			addBlocksForCategory(Specs.dataCategory, catColor);
			nextY += 15;
		}

		// lists
		//if(!app.stageIsArduino){
			catColor = Specs.listColor;
			addItem(new Button(Translator.map('Make a List'), makeList));
	
			var listNames:Array = app.runtime.allListNames().sort();
			if (listNames.length > 0) {
				for each (n in listNames) {
					if(n==null)
					{
						continue;
					}
					addVariableCheckbox(n, true);
					addItem(new Block(n, 'r', catColor, Specs.GET_LIST), true);
				}
				nextY += 10;
				addBlocksForCategory(Specs.listCategory, catColor);
			}
		//}
		
		
		addItem(new Button(Translator.map('Make a Block'), makeNewBlock, false, '#'));
		var definitions:Array = app.viewedObj().procedureDefinitions();
		if (definitions.length > 0) {
			nextY += 5;
			for each (var proc:Block in definitions) {
				var b:Block = new Block(proc.spec, ' ', Specs.procedureColor, Specs.CALL, proc.defaultArgValues);
				addItem(b);
			}
			nextY += 5;
		}
		updateCheckboxes();
	}

	protected function createVar(name:String, varSettings:VariableSettings):* {
		var obj:ScratchObj = (varSettings.isLocal) ? app.viewedObj() : app.stageObj();
		var variable:* = (varSettings.isList ? obj.lookupOrCreateList(name) : obj.lookupOrCreateVar(name));

		app.runtime.showVarOrListFor(name, varSettings.isList, obj);
		app.setSaveNeeded();

		return variable;
	}

	private function makeVariable():void {
		function makeVar2():void {
			var n:String = d.fields['Variable name'].text.replace(/^\s+|\s+$/g, '');
			if (n.length == 0) return;

			createVar(n, varSettings);
		}

		var d:DialogBox = new DialogBox(makeVar2);
		var varSettings:VariableSettings = makeVarSettings(false, app.viewedObj().isStage);
		d.addTitle('New Variable');
		d.addField('Variable name', 150);
		d.addWidget(varSettings);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function makeList():void {
		function makeList2(d:DialogBox):void {
			var n:String = d.fields['List name'].text.replace(/^\s+|\s+$/g, '');
			if (n.length == 0) return;

			createVar(n, varSettings);
		}
		var d:DialogBox = new DialogBox(makeList2);
		var varSettings:VariableSettings = makeVarSettings(true, app.viewedObj().isStage);
		d.addTitle('New List');
		d.addField('List name', 150);
		d.addWidget(varSettings);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	protected function makeVarSettings(isList:Boolean, isStage:Boolean):VariableSettings {
		return new VariableSettings(isList, isStage);
	}

	private function makeNewBlock():void {
		function addBlockHat(dialog:DialogBox):void {
			var spec:String = specEditor.spec().replace(/^\s+|\s+$/g, '');
			if (spec.length == 0) return;
			var newHat:Block = new Block(spec, 'p', Specs.procedureColor, Specs.PROCEDURE_DEF);
			newHat.parameterNames = specEditor.inputNames();
			newHat.defaultArgValues = specEditor.defaultArgValues();
			newHat.warpProcFlag = specEditor.warpFlag();
			newHat.setSpec(spec);
			newHat.x = 10 - app.scriptsPane.x + Math.random() * 100;
			newHat.y = 10 - app.scriptsPane.y + Math.random() * 100;
			app.scriptsPane.addChild(newHat);
			app.scriptsPane.saveScripts();
			app.runtime.updateCalls();
			app.updatePalette();
			app.setSaveNeeded();
		}
		var specEditor:ProcedureSpecEditor = new ProcedureSpecEditor('', [], false);
		var d:DialogBox = new DialogBox(addBlockHat);
		d.addTitle(Translator.map('New Block'));
		d.addWidget(specEditor);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage, true);
		specEditor.setInitialFocus();
	}

	private function showAnExtension():void {
		function addExt(ext:ScratchExtension):void {
			app.extensionManager.setEnabled(ext.name, true)
			app.updatePalette();
		}
		var lib:MediaLibrary = new MediaLibrary(app, 'extension', addExt);
		lib.open();
	}

	protected function addReporterCheckbox(block:Block):void {
		var b:IconButton = new IconButton(toggleWatcher, 'checkbox');
		b.disableMouseover();
		var targetObj:ScratchObj = isSpriteSpecific(block.op) ? app.viewedObj() : app.stagePane;
		b.clientData = {
			type: 'reporter',
			targetObj: targetObj,
			cmd: block.op,
			block: block,
			color: block.base.color
		};
		b.x = 6;
		b.y = nextY + 5;
		app.palette.addChild(b);
	}

	static private const checkboxReporters: Array = [
		'xpos', 'ypos', 'heading', 'costumeIndex', 'scale', 'volume', 'timeAndDate',
		'backgroundIndex', 'sceneName', 'tempo', 'answer', 'timer', 'soundLevel', 'isLoud',
		'sensor:', 'sensorPressed:', 'senseVideoMotion', 'xScroll', 'yScroll',
		'getDistance', 'getTilt'];
	protected function isCheckboxReporter(op:String):Boolean {
		return checkboxReporters.indexOf(op) > -1;
	}

	private function isSpriteSpecific(op:String):Boolean {
		const spriteSpecific: Array = ['costumeIndex', 'xpos', 'ypos', 'heading', 'scale', 'volume'];
		return spriteSpecific.indexOf(op) > -1;
	}

	private function getBlockArg(b:Block, i:int):String {
		var arg:BlockArg = b.args[i] as BlockArg;
		if (arg) return arg.argValue;
		return '';
	}

	private function addVariableCheckbox(varName:String, isList:Boolean):void {
		var b:IconButton = new IconButton(toggleWatcher, 'checkbox');
		b.disableMouseover();
		var targetObj:ScratchObj = app.viewedObj();
		if (isList) {
			if (targetObj.listNames().indexOf(varName) < 0) targetObj = app.stagePane;
		} else {
			if (targetObj.varNames().indexOf(varName) < 0) targetObj = app.stagePane;
		}
		b.clientData = {
			type: 'variable',
			isList: isList,
			targetObj: targetObj,
			varName: varName
		};
		b.x = 6;
		b.y = nextY + 5;
		app.palette.addChild(b);
	}

	private function toggleWatcher(b:IconButton):void {
		var data:Object = b.clientData;
		if (data.block) {
			switch (data.block.op) {
			case 'senseVideoMotion':
				data.targetObj = getBlockArg(data.block, 1) == 'Stage' ? app.stagePane : app.viewedObj();
			case 'sensor:':
			case 'sensorPressed:':
			case 'timeAndDate':
				data.param = getBlockArg(data.block, 0);
				break;
			}
		}
		var showFlag:Boolean = !app.runtime.watcherShowing(data);
		app.runtime.showWatcher(data, showFlag);
		b.setOn(showFlag);
		app.setSaveNeeded();
	}

	private function updateCheckboxes():void {
		for (var i:int = 0; i < app.palette.numChildren; i++) {
			var b:IconButton = app.palette.getChildAt(i) as IconButton;
			if (b && b.clientData) {
				b.setOn(app.runtime.watcherShowing(b.clientData));
			}
		}
	}

	private function addExtensionSeparator(ext:ScratchExtension):void {
		function extensionMenu(ignore:*):void {
			/*var m:Menu = new Menu();
			//m.addItem(Translator.map('About') + ' ' + ext.name + ' ' + Translator.map('extension') + '...', showAbout);
			if(ext.showBlocks) m.addItem('Hide Extension', hideExtension);
			else m.addItem('Show Extension', showExtension);
			m.showOnStage(app.stage);*/
		}
		function showAbout():void {
			// Open in the tips window if the URL starts with /info/ and another tab otherwise
			if (ext.url) {
				if (ext.url.indexOf('/info/') === 0) app.showTip(ext.url);
				else navigateToURL(new URLRequest(ext.url));
			}
		}
		function hideExtension():void {
			app.extensionManager.setEnabled(ext.name, false);
			app.updatePalette();
		}
		function showExtension():void {
			app.extensionManager.setEnabled(ext.name, true);
			app.updatePalette();
		}
		nextY += 7;

		var titleButton:IconButton = UIPart.makeMenuButton( ext.name, extensionMenu, true, CSS.panelColor);
		titleButton.x = 5;
		titleButton.y = nextY;
		titleButton.useHandCursor = true;
		titleButton.buttonMode = true;
		
		//*JC* Mostramos u ocultamos extensión al click (si menu)
		titleButton.addEventListener(MouseEvent.CLICK, function(e:Event):void {
			if( ext.showBlocks ){
				app.extensionManager.setEnabled(ext.name, false);
								
				app.updatePalette();
			}else{
				app.extensionManager.setEnabled(ext.name, true);
				app.updatePalette();
			}
		}, false, 0, true);
		
		app.palette.addChild(titleButton);

		var x:int = titleButton.width + 12;
		addLine(x, nextY + 9, 230 - x);

		var indicator:IndicatorLight = new IndicatorLight(ext);
		indicator.addEventListener(MouseEvent.CLICK, function(e:Event):void {
			eBlock.app.showTip('extensions');}, false, 0, true);
		app.extensionManager.updateIndicator(indicator, ext);
		indicator.x = 179+60;//app.palette.width - 30;
		indicator.y = nextY + 2;
		indicator.visible = false;  //*JC* parque para que funcione el indicador global , así no eliminamos estos indicadores
		app.palette.addChild(indicator);

		nextY += titleButton.height + 10;
	}
	
	
	//*JC*
	private function addScratchSeparator(ext:ScratchExtension):void {
		function extensionMenu(ignore:*):void {
			
		}
		function showAbout():void {
			// Open in the tips window if the URL starts with /info/ and another tab otherwise
			/*if (ext.url) {
				if (ext.url.indexOf('/info/') === 0) app.showTip(ext.url);
				else navigateToURL(new URLRequest(ext.url));
			}*/
		}
		function hideExtension():void {
			eBlock.app.extensionManager.ShowScratchBlocks = false;
			app.updatePalette();
		}
		function showExtension():void {
			eBlock.app.extensionManager.ShowScratchBlocks = true;
			app.updatePalette();
		}
		nextY += 7;
		
		
				
		var titleButton:IconButton = UIPart.makeMenuButton("Scratch", extensionMenu, true, CSS.panelColor);
		titleButton.x = 5;
		titleButton.y = nextY;
		titleButton.useHandCursor = true;
		titleButton.buttonMode= true;
		
		
		
		//*JC* Mostramos u ocultamos extensión al click (si menu)
		titleButton.addEventListener(MouseEvent.CLICK, function(e:Event):void {
			if( eBlock.app.extensionManager.ShowScratchBlocks ){
				eBlock.app.extensionManager.ShowScratchBlocks = false;
				
				app.updatePalette();
			}else{
				eBlock.app.extensionManager.ShowScratchBlocks = true;
				app.updatePalette();
			}
		}, false, 0, true);
		
		app.palette.addChild(titleButton);
		
		var x:int = titleButton.width + 12;
		addLine(x, nextY + 9, 230 - x);
		
		/*var indicator:IndicatorLight = new IndicatorLight(ext);
		indicator.addEventListener(MouseEvent.CLICK, function(e:Event):void {
			MBlock_mod.app.showTip('extensions');}, false, 0, true);
		app.extensionManager.updateIndicator(indicator, ext);
		indicator.x = 179+60;//app.palette.width - 30;
		indicator.y = nextY + 2;
		app.palette.addChild(indicator);*/
		
		nextY += titleButton.height + 10;
	}

	//*JC* Crea los bloques de cada extensión*
	private function addBlocksForExtension(ext:ScratchExtension,  category:int):void {
		//var blockColor:int = Specs.extensionsColor;
		var opPrefix:String = ext.useScratchPrimitives ? '' : ext.name + '.';
		
		//*JC* 
		var blockCat:int  = category;// 10; //- default Robots 
		
		var blockColor:int = Specs.blockColor(blockCat);
		
		
		//var allBlocks:Array = eBlock.app.extensionManager.getBlocksOverride(ext);
		
		for each (var spec:Array in ext.blockSpecs /* allBlocks*/) {
			
			if (spec.length < 3 && spec[0]== 'category'){
				blockCat =ExtensionManager.catIdFromSpec(spec[1]);// Number(spec[1]);
			}
			if( blockCat != category) continue; //- solo mostrar los bloques de la categoria
			blockColor = Specs.blockColor(blockCat);
						
			
			if (spec.length >= 3) {
				//var op:String = opPrefix + spec[2];
				var op:String = spec[2];
				if( op.indexOf("_base_.")== -1 ) op = opPrefix + op;
				
				var defaultArgs:Array = spec.slice(3);
				var block:Block = new Block(spec[1], spec[0], blockColor, op, defaultArgs);
				var showCheckbox:Boolean = (spec[0] == 'r' && defaultArgs.length == 0);
				if (showCheckbox) addReporterCheckbox(block);
				addItem(block, showCheckbox);
			} else if (spec[0]=="-"){
				nextY += 10 * spec[0].length; // add some space
				addLabelText(spec[1]);
			}
		}
	}

	//- devuelve true si hay bloques que mostrar en esta categoria	
	private function hasBlocksInCategory(ext:ScratchExtension,  category:int):Boolean {
		
		//*JC* 
		var blockCat:int  = 10; //- default Robots 
		
		//var blockColor:int = Specs.blockColor(blockCat);
		
		//var allBlocks:Array = eBlock.app.extensionManager.getBlocksOverride(ext);
		
		for each (var spec:Array in ext.blockSpecs /*allBlocks*/) {
			
			if (spec.length < 3 && spec[0]== 'category'){ //- encontramos un bloque de definicion de categoria
				blockCat = ExtensionManager.catIdFromSpec(spec[1]);
			}else{
				//- tiene que haber al menos un bloque normal dentro de la categoria seleccionada para poder mostrarla en la paleta
				if( blockCat == category) return true; //- solo mostrar los bloques de la categoria
			}
			
		}
		
		return false;
	}
	
	private function addLine(x:int, y:int, w:int):void {
		const light:int = 0xF2F2F2;
		const dark:int = CSS.borderColor - 0x141414;
		var line:Shape = new Shape();
		var g:Graphics = line.graphics;

		g.lineStyle(1, dark, 1, true);
		g.moveTo(0, 0);
		g.lineTo(w, 0);

		g.lineStyle(1, light, 1, true);
		g.moveTo(0, 1);
		g.lineTo(w, 1);
		line.x = x;
		line.y = y;
		app.palette.addChild(line);
	}

}}

