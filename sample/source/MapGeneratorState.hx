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
import iso.MapLayer;
import iso.MapUtils;
import lime.system.BackgroundWorker;

class MapGeneratorState extends FlxState
{
	static inline var VIEWPORT_WIDTH:Float = 800;
	static inline var VIEWPORT_HEIGHT:Float = 480;
	
	//Max size tested = 1200x1200 (~850MB mem, no optimization)
	static inline var MAP_WIDTH:Float = 1200;
	static inline var MAP_HEIGHT:Float = 1200;
	
	static inline var TILE_WIDTH:Float = 64;
	static inline var TILE_HEIGHT:Float = 96;
	static inline var TILE_HEIGHT_OFFSET:Float = 64;
	
	var isoMap:FlxIsoTilemap;
	var loadTxt:FlxText;
	var mapLoaded:Bool = false;
	
	override public function create():Void
	{
		super.create();
		
		FlxG.mouse.visible = false;
		
		isoMap = new FlxIsoTilemap(new FlxPoint(VIEWPORT_WIDTH, VIEWPORT_HEIGHT), new FlxPoint(TILE_WIDTH, TILE_HEIGHT), TILE_HEIGHT_OFFSET);
		isoMap.addTileset(AssetPaths.new_pixel_64_96__png, TILE_WIDTH, TILE_HEIGHT);
		isoMap.addTileset(AssetPaths.dynamic_tileset__png, TILE_WIDTH, TILE_HEIGHT);
		isoMap.init(new FlxPoint(MAP_WIDTH, MAP_HEIGHT));
		add(isoMap);
		
		//Async map generation (old map generator can be quite slow for maps > 300 x 300)
		var worker = new BackgroundWorker();
		worker.doWork.add (function loadMapData(_) {
			
			var mapGen = new MapGenerator(MAP_WIDTH, MAP_HEIGHT, 3, 7, 15, false);
			mapGen.setIndices(41, 53, 45, 49, 25, 37, 29, 33, 1, 1, 1, 1, 0);
			mapGen.generate();
			
			var mapData:Array<Array<Int>> = mapGen.extractData();
			
			var layers:Array<MapLayer> = new Array<MapLayer>();
			layers.push(MapUtils.getLayerFromTileArray(mapData, [0, 1], 0, TILE_WIDTH, TILE_HEIGHT, TILE_HEIGHT_OFFSET, false, 58));
			layers.push(MapUtils.getEmptyLayer(1, MAP_WIDTH, MAP_HEIGHT, TILE_WIDTH, TILE_HEIGHT, TILE_HEIGHT_OFFSET, -1));
			layers.push(MapUtils.getLayerFromTileRange(mapData, 2, 62, 1, TILE_WIDTH, TILE_HEIGHT, TILE_HEIGHT_OFFSET, true, -1));
			
			worker.sendComplete(layers);
		});
		
		worker.onComplete.add(function onDataLoaded(layers:Array<MapLayer>) {
			
			for (l in layers) {
				isoMap.addLayer(l);
			}
			
			FlxTween.manager.clear();
			
			loadTxt.alpha = 1.0;
			loadTxt.alignment = FlxTextAlign.LEFT;
			loadTxt.setPosition(10, FlxG.height - 30);
			loadTxt.text = 'Use arrow keys to scroll the map';
			
			mapLoaded = true;
		});
		
		loadTxt = new FlxText(0, FlxG.stage.stageHeight / 2 - 15, FlxG.width, 'Loading $MAP_WIDTH x $MAP_HEIGHT ...', 20);
		loadTxt.alignment = FlxTextAlign.CENTER;
		loadTxt.scrollFactor.set();
		FlxTween.tween(loadTxt, { alpha:0 }, 0.5, { type:FlxTween.PINGPONG } );
		add(loadTxt);
		
		worker.run();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!mapLoaded) return;
		
		handleKeyboardInput(elapsed);
	}
	
	function handleKeyboardInput(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(new MenuState());
		}
		
		if (FlxG.keys.pressed.DOWN) {
			FlxG.camera.scroll.y -= 200 * elapsed;
		} 
		
		if (FlxG.keys.pressed.LEFT) {
			FlxG.camera.scroll.x += 200 * elapsed;
		}
		
		if (FlxG.keys.pressed.RIGHT) {
			FlxG.camera.scroll.x -= 200 * elapsed;
		}
		
		if (FlxG.keys.pressed.UP) {
			FlxG.camera.scroll.y += 200 * elapsed;
		}
	}
}
