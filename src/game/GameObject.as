package game {
	import org.papervision3d.objects.DisplayObject3D;

	public class GameObject extends DisplayObject3D {
		protected var _interactive:Boolean = false;
		protected var _interactiveObject:DisplayObject3D;
		protected var _type:String; 
		
		public function GameObject() {
			super();
		}
		
		public function update():void {
			
		}
		
		public function get interactiveObject():DisplayObject3D {
			return this._interactiveObject;
		}
		
		public function get type():String {
			return this._type;
		}
	}
}