package ;

import AssetPaths;
import coffeegames.mapgen.MapGenerator;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import iso.FlxIsoTilemap;
import lime.system.BackgroundWorker;

class MenuState extends FlxState
{
	static inline var VIEWPORT_WIDTH:Float = 800;
	static inline var VIEWPORT_HEIGHT:Float = 480;
	
	//Max size tested = 1200x1200 (~850MB mem, no optimization)
	static inline var MAP_WIDTH:Float = 600;
	static inline var MAP_HEIGHT:Float = 600;
	
	static inline var TILE_WIDTH:Float = 64;
	static inline var TILE_HEIGHT:Float = 96;
	static inline var TILE_HEIGHT_OFFSET:Float = 64;
	
	var mapGen:MapGenerator;
	var map:FlxIsoTilemap;
	var loadTxt:FlxText;
	
	override public function create():Void
	{
		super.create();
		
		FlxG.mouse.visible = false;
		
		map = new FlxIsoTilemap(new FlxPoint(VIEWPORT_WIDTH, VIEWPORT_HEIGHT), new FlxPoint(MAP_WIDTH, MAP_HEIGHT), new FlxPoint(TILE_WIDTH, TILE_HEIGHT), TILE_HEIGHT_OFFSET);
		map.addTileset(AssetPaths.new_pixel_64_96__png, TILE_WIDTH, TILE_HEIGHT);
		map.addTileset(AssetPaths.dynamic_tileset__png, TILE_WIDTH, TILE_HEIGHT);
		add(map);
		
		mapGen = new MapGenerator(map.map_w, map.map_h, 3, 7, 15, false);
		mapGen.setIndices(41, 53, 45, 49, 25, 37, 29, 33, 1, 1, 1, 1, 0); 
		
		//Async map generation (old map generator can be quite slow for maps > 300 x 300)
		var worker = new BackgroundWorker();
		
		worker.doWork.add (function loadMapData(_) {
			mapGen.generate();
			var mapData:Array<Array<Int>> = mapGen.extractData();
			
			map.addLayerFromTileArray(mapData, [0, 1], 0, false, 58);
			map.addEmptyLayer(1, -1);
			map.addLayerFromTileRange(mapData, 2, 62, 1, true, -1);
			
			worker.sendComplete();
		});
		
		worker.onComplete.add(function onDataLoaded(_) {
			
			FlxTween.manager.clear();
			loadTxt.alpha = 1.0;
			loadTxt.alignment = FlxTextAlign.LEFT;
			loadTxt.setPosition(10, FlxG.height - 30);
			loadTxt.text = 'Use arrow keys to scroll the map';
		});
		
		loadTxt = new FlxText(0, FlxG.stage.stageHeight / 2 - 15, FlxG.width, 'Loading $MAP_WIDTH x $MAP_HEIGHT ...', 20);
		loadTxt.alignment = FlxTextAlign.CENTER;
		FlxTween.tween(loadTxt, { alpha:0 }, 0.5, { type:FlxTween.PINGPONG } );
		add(loadTxt);
		
		worker.run();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		handleKeyboardInput(elapsed);
	}
	
	function handleKeyboardInput(elapsed:Float)
	{
		if (FlxG.keys.pressed.DOWN) {
			map.cameraScroll.y -= 200 * elapsed;
		} 
		
		if (FlxG.keys.pressed.LEFT) {
			map.cameraScroll.x += 200 * elapsed;
		}
		
		if (FlxG.keys.pressed.RIGHT) {
			map.cameraScroll.x -= 200 * elapsed;
		}
		
		if (FlxG.keys.pressed.UP) {
			map.cameraScroll.y += 200 * elapsed;
		}
	}
}
