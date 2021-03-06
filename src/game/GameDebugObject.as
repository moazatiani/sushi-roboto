package game {
	import org.papervision3d.materials.ColorMaterial;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.primitives.Cube;

	public class GameDebugObject extends GameObject {
		public function GameDebugObject() {
			super();
			this._type = "debug";
			this._interactive = true;
			this._initObject();
		}
		
		private function _initObject():void {
			var material:ColorMaterial = new ColorMaterial(0x0000FF);
			material.interactive = true;
			var materialsList:MaterialsList = new MaterialsList({all: material});
			
			var object:Cube = new Cube(materialsList, 20, 20, 20);
			object.z -= 0.5 * 20;
			
			this.addChild(object);
			
			this._interactiveObject = object;
		}
		
		public override function update():void {
			super.update();
		}
	}
}