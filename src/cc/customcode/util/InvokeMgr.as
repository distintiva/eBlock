package cc.customcode.util
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.ClipboardTransferMode;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragActions;
	import flash.desktop.NativeDragManager;
	import flash.desktop.NotificationType;
	import flash.display.InteractiveObject;
	import flash.display.NativeWindowDisplayState;
	import flash.events.InvokeEvent;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.text.TextField;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;

	public class InvokeMgr
	{
		public function InvokeMgr()
		{
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, __onInvoked);
			
			eBlock.app.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, __onDragEnter);
			eBlock.app.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, __onDragDrop);
		}
		
		private function __onDragEnter(evt:NativeDragEvent):void
		{
			NativeDragManager.dropAction = NativeDragActions.LINK;
			NativeDragManager.acceptDragDrop(evt.currentTarget as InteractiveObject);
		}
		
		private function __onDragDrop(evt:NativeDragEvent):void
		{
			var fileList:Object = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT);
			if(fileList == null){
				return;
			}
			var file:File = fileList[0];
			if(file.extension != "sb2"){
				return;
			}
			eBlock.app.runtime.selectedProjectFile(file);
		}
		private function __onInvoked(evt:InvokeEvent):void
		{
			if(evt.arguments.length <= 0){
				return;
			}
			var arg:String = evt.arguments.join(" ");
			var file:File = new File(arg);
			evt.arguments.forEach(function(element:String,index:int,arr:Array):void{
				eBlock.app.showMessage("fileName="+element);
			});
			
			if(!file.exists)
			{
				var d:DialogBox = new DialogBox;
				d.setTitle(Translator.map('Open the file with "File/Load project"'));
				var text:String = Translator.map('Sorry that you cannot open the files with consecutive spaces by double clicking. Use "File/Load project" in the menu instead.');
				var textField:TextField = new TextField();
				textField.defaultTextFormat = CSS.normalTextFormat;
				textField.wordWrap = true;
				textField.text = text;
				textField.width = 300;
				textField.height = textField.textHeight + 8;
				d.addBlock(textField);
				d.addButton('Close', function():void{
					d.cancel();
				});
				d.showOnStage(eBlock.app.stage);
				return;
			}
			
			if(eBlock.app.stage.nativeWindow.displayState==NativeWindowDisplayState.MINIMIZED)
			{
				eBlock.app.stage.nativeWindow.restore();
			}
			eBlock.app.stage.nativeWindow.notifyUser(NotificationType.INFORMATIONAL);
			eBlock.app.stage.nativeWindow.alwaysInFront = true;
			var result:Boolean = eBlock.app.stage.nativeWindow.orderToFront();
			eBlock.app.runtime.selectedProjectFile(new File(arg));
			eBlock.app.stage.nativeWindow.alwaysInFront = false;
		}
	}
}