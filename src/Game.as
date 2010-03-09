package {
	/*
	 * TODO: Decouple classes; end reliance on GameRegistry to pass classes around like GameLevelData
	 */
	import com.transmote.flar.FLARManager;
	import com.transmote.flar.marker.FLARMarker;
	import com.transmote.flar.marker.FLARMarkerEvent;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import game.GameBoard;
	import game.GameInventory;
	import game.GameLevelData;
	import game.GameMap;
	import game.GamePapervision;
	import game.GameRegistry;
	
	/* Change output settings */
	[SWF(width="800", height="600", frameRate="25", backgroundColor="#000000")]
	public class Game extends Sprite {
		/* GameRegistry object */
		private var _registry:GameRegistry;
		
		/* GameLevelData object */
		private var _levelData:GameLevelData;
		
		/* GameInventory object */
		private var _inventory:GameInventory;
		
		/* GameBoard object */
		private var _board:GameBoard;
		private var _play:Boolean = false; // Is game playing (true), or paused (false)
		
		/* GameMap object */
		private var _map:GameMap;
		
		/* FLARManager object */
		private var _flarManager:FLARManager;
		
		/* Markers */
		private const _boardPatternId:int = 3;
		private const _objectPatternId:int = 1;
		private const _directionPatternId:int = 0;
		private var _activeMarker:FLARMarker;
		
		/* Papervision object */
		private var _papervision:GamePapervision;
		
		/* Constructor method */
		public function Game() {
			/* Initialise game registry */
			this._registry = GameRegistry.getInstance();
			
			/* Initialise current level data */
			this._initLevelData();	
			
			/* Initialise game inventory system */
			this._initInventory();
			
			/* Initialise game board */
			this._initBoard();
			
			/* Initialise augmented reality */
			this._initFLAR();
			
			/* Initialise keyboard listeners */
			this._initKeyboardListeners();
		}
		
		/* Game level data initialisation */
		private function _initLevelData():void {
			this._levelData = new GameLevelData(0);
			this._registry.setEntry("levelData", this._levelData);
		}
		
		/* Game map initialisation */
		private function _initMap():void {
			this._map = new GameMap();
			
			if (this._levelData)
				this._map.drawGrid(this._levelData.rows, this._levelData.columns);
			
			this.addChild(this._map);
			this._registry.setEntry("gameMap", this._map);
		}
		
		/* Game inventory initialisation */
		private function _initInventory():void {
			this._inventory = new GameInventory();
		}
		
		/* Game board initialisation */
		private function _initBoard():void {
			this._board = new GameBoard();
		}
		
		/* Augmented reality initialisation */
		private function _initFLAR():void {
			/* Initialise FLARManager */
			this._flarManager = new FLARManager("flarConfig.xml");

			/* Event listener for when a new marker is recognised */
			this._flarManager.addEventListener(FLARMarkerEvent.MARKER_ADDED, this._onMarkerAdded);
			/* Event listener for when a marker is removed */
			this._flarManager.addEventListener(FLARMarkerEvent.MARKER_REMOVED, this._onMarkerRemoved);
			
			/* Event listener for when the FLARManager object has loaded */
			this._flarManager.addEventListener(Event.INIT, this._onFlarManagerLoad);
		}
		
		/* Papervision initialisation method */
		private function _initPapervision():void {
			/* Initialise Papervision environment */
			this._papervision = new GamePapervision();
			this._papervision.setFLARCamera(this._flarManager.cameraParams);
			
			/* Add Papervision viewport to the main stage */
			this.addChild(this._papervision.viewport);
			
			/* Add empty board containter to Papervision scene */
			this._papervision.addChildToScene(this._board.container);
			
			/* Add Papervision object to registry */
			this._registry.setEntry("papervision", this._papervision);
			
			/* Initialise board viewport layers and populate board */
			this._board.initViewportLayers();
			this._board.populateBoard();
			
			/* Create event listner to run a method on each frame */
			this.addEventListener(Event.ENTER_FRAME, this._onEnterFrame);
		}
		
		/* Keyboard listeners initialisation */
		private function _initKeyboardListeners():void {
			stage.addEventListener(KeyboardEvent.KEY_DOWN, this._onKeyDown);
		}
		
		/* Run if FLARManager object has loaded */
		private function _onFlarManagerLoad(e:Event):void {
			/* Remove event listener so this method doesn't run again */
			this._flarManager.removeEventListener(Event.INIT, this._onFlarManagerLoad);
			
			/* Display webcam */
			this.addChild(Sprite(this._flarManager.flarSource));
			
			/* Run Papervision initialisation method */
			this._initPapervision();
			
			/* Initialise game map */
			this._initMap();
		}
		
		/* Run when a new marker is recognised */
		private function _onMarkerAdded(e:FLARMarkerEvent):void {
			this._addMarker(e.marker);
		}
		/* Run when a marker is removed */
		private function _onMarkerRemoved(e:FLARMarkerEvent):void {
			this._removeMarker(e.marker);
		}

		/* Add a new marker to the system */
		private function _addMarker(marker:FLARMarker):void {
			this._activeMarker = marker;
			
			switch (marker.patternId) {
				case _boardPatternId: // Board marker
					trace("Added board marker");
					break;
				case _objectPatternId: // Player object marker
					trace("Added player object marker");
					/*var selectedItemName:String = this._inventory.getSelectedItem();
					if (selectedItemName) {
						if (this._board.objectsRemainingByType(selectedItemName) > 0) {
							this._board.addDebugObject();
						} else {
							trace("No more "+selectedItemName+" objects left in invetory")
						}
					}*/
					break;
				case _directionPatternId: // Direction marker
					trace("Added direction marker");
					/*if (this._board.getObjectsInUseByName("direction") < 1) {
						this._board.addDirectionObject();
					}*/
					break;
			}	
		}
		
		/* Remove a marker from the system */
		private function _removeMarker(marker:FLARMarker):void {			
			switch (marker.patternId) {
				case _boardPatternId: // Board marker
					trace("Removed board marker");
					break;
				case _objectPatternId: // Player object marker
					trace("Removed player object marker");
					break;
				case _directionPatternId: // Direction marker
					trace("Removed direction marker");
					break;
			}	
			
			this._map.removeMarker();
			this._activeMarker = null;
		}
		
		/* Method to run on every frame */
		private function _onEnterFrame(e:Event):void {			
			/* Update markers */
			this._updateMarkers();
			
			/* Game is playing and character is alive */
			if (this._play && this._board.character.alive) {
				if (this._board.completed) {
					trace("You win!");
					this._play = false;
					
					/* Show win scenario UI */
				} else {				
					/* Update board objects */
					this._board.updateObjects();
				}
			} else if (this._play && !this._board.character.alive) {
				trace("Character is dead");
				this._play = false;
				
				/* Show lose scenario UI */
			}
			
			this._papervision.render();
		}
		
		/* Update markers method */
		private function _updateMarkers():void {
			if (this._activeMarker) {
				switch (this._activeMarker.patternId) {
					case _boardPatternId: // Board marker
						//trace("Update board marker");
						this._board.updateBoard(this._activeMarker);
						break;
					case _objectPatternId: // Player object marker
						//trace("Update player object marker");
						if (this._board.getTotalPlayerObjects() > 0 && !this._play) { 
							this._board.updateActivePlayerObject(this._activeMarker, this.stage.stageWidth, this.stage.stageHeight);
						}
						break;
					case _directionPatternId: // Direction marker
						//trace("Update direction marker");
						if (this._board.getTotalDirectionObjects() > 0 && this._board.activeDirectionObjectId >= 0 && !this._play) {
							this._board.updateActiveDirectionObject(this._activeMarker, this.stage.stageWidth, this.stage.stageHeight);
						}
						break;
				}
			}
		}
		
		/* Keyboard listeners */
		private function _onKeyDown(e:KeyboardEvent):void {
			trace(e.keyCode);
			switch (e.keyCode) {
				case 32: // Spacebar
					if (!this._play) {
						this._play = true;
					} else {
						this._play = false;
					}
					break;
				case 38: // Up arrow
					trace("Forward");
					this._board.character.container.rotationZ = 0;
					break;
				case 40: // Down arrow
					trace("Backward");
					this._board.character.container.rotationZ = 180;
					break;
				case 37: // Left arrow
					trace("Left");
					this._board.character.container.rotationZ = 90;
					break;
				case 39: // Right arrow
					trace("Right");
					this._board.character.container.rotationZ = -90;
					break;
				case 68: // d
					/* Add new directional object */
					if (this._board.objectsRemainingByType("direction") > 0) {
						this._board.addDirectionObject();
					} else {
						trace("No more directional objects left in invetory")
					}
					break;
				case 82: // r
					var papervision:GamePapervision = this._registry.getEntry("papervision");
					if (papervision) {
						this._play = false;
						this._board.resetBoard();
					}
					break;
				case 87: // w
					/* Add new water object */
					if (this._board.objectsRemainingByType("water") > 0) {
						this._board.addPlayerWaterObject();
					} else {
						trace("No more directional objects left in invetory")
					}
					break;
			}
		}
	}
}