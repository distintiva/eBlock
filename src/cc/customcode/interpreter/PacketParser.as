package cc.customcode.interpreter
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	internal class PacketParser
	{
		private var buffer:Array = [];
		private const ba:ByteArray = new ByteArray();
		private var callback:Function;
		
		public function PacketParser(callback:Function)
		{
			ba.endian = Endian.LITTLE_ENDIAN;
			this.callback = callback;
		}
		
		public function append(bytes:Array):void
		{
			if(bytes == null || bytes.length <= 0){
				return;
			}
			buffer.push.apply(null, bytes);
			parse();
		}
		
		private function parse():void
		{
			for(;;){
				if(buffer.length < 4){
					return;
				}
				if(buffer[0] == 0xFF && buffer[1] == 0x55){
					break;
				}
				buffer.shift();
			}
			if(buffer[2] == 0x0D && buffer[3] == 0x0A){
				buffer.splice(0, 4);
				if(callback!=RemoteCallMgr.Instance.onPacketRecv)
				{
					trace("callback！=RemoteCallMgr.Instance.onPacketRecv")
					callback();
				}
			}else{
				ba.clear();
				var index:int = buffer[2];
				var value:*;
				var eventId:* = 0;
				switch(buffer[3]){
					case 1:
						//*JC* modificado para recoger eventos 0x80 y un segundo parámetro
						//- si solo viene el evento del mBotButton  buffer[4]=0x80
						//- si hacemos otros eventos hay que meter un buffer[6]() y el bufferlength será de 8 en lugar de 7
						if(buffer.length < 9){
							return;
						}
						
						value = buffer[4];
						
						//- vemos si no hemos llegado al final de la trama
						if(buffer[5]==13 && buffer[6]==10){ // final (crLF)
							buffer.splice(0, 7);
						}else{// viene un byte más
							eventId = buffer[6];  // porque buffer[5] es el length de buffer 6
							buffer.splice(0, 9);
						}
						
						
						break;
					case 2:
					case 5:
						if(buffer.length < 10){
							return;
						}
						ba.writeByte(buffer[4]);
						ba.writeByte(buffer[5]);
						ba.writeByte(buffer[6]);
						ba.writeByte(buffer[7]);
						ba.position = 0;
						value = ba.readFloat();
						buffer.splice(0, 10);
						break;
					case 3:
						if(buffer.length < 8){
							return;
						}
						ba.writeByte(buffer[4]);
						ba.writeByte(buffer[5]);
						ba.position = 0;
						value = ba.readShort();
						buffer.splice(0, 8);
						break;
					case 4:
						if(buffer.length < 5){
							return;
						}
						var n:int = buffer[4];
						if(buffer.length < n + 7){
							return;
						}
						for(var i:int=0; i<n; ++i){
							ba.writeByte(buffer[5+i]);
						}
						ba.position = 0;
						value = ba.readUTFBytes(n);
						buffer.splice(0, n + 7);
						break;
					case 6:
						if(buffer.length < 10){
							return;
						}
						ba.writeByte(buffer[4]);
						ba.writeByte(buffer[5]);
						ba.writeByte(buffer[6]);
						ba.writeByte(buffer[7]);
						ba.position = 0;
						value = ba.readInt();
						buffer.splice(0, 10);
						break;
					default:
						value = 0;
						buffer.splice(0, 4);
				}
				if(index == 0x80){//mBot button pressed
					eBlock.app.runtime.mbotButtonPressed.notify(Boolean(value));
					
					//- capture other types of device events
					if(eventId){
						//- de momento value no se usa porque con eventId y el array de callbacks definido en la extensión se hace todo ( pero lo dejo implementado por si hiciera falta)
						eBlock.app.runtime.deviceEventReceived.notify( eventId,  value );
					}  
					
				}else{
					if(callback!=RemoteCallMgr.Instance.onPacketRecv)
					{
						callback(value);
						trace("callback！=RemoteCallMgr.Instance.onPacketRecv")
					}					
				}
			}
			parse();
		}
	}
}