package ;

import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import iso.FlxIsoTilemap;
import iso.MapUtils;
import openfl.Assets;

class CsvState extends FlxState
{
	static inline var VIEWPORT_WIDTH:Float = 800;
	static inline var VIEWPORT_HEIGHT:Float = 480;

	//Max size tested = 1200x1200 (~850MB mem, no optimization)
	static inline var MAP_WIDTH:Float = 20;
	static inline var MAP_HEIGHT:Float = 20;

	static inline var TILE_WIDTH:Float = 64;
	static inline var TILE_HEIGHT:Float = 96;
	static inline var TILE_HEIGHT_OFFSET:Float = 64;

	var map:FlxIsoTilemap;
  
	override public function create():Void
	{
		super.create();
		
		FlxG.mouse.visible = false;
		
		map = new FlxIsoTilemap(new FlxPoint(VIEWPORT_WIDTH, VIEWPORT_HEIGHT), new FlxPoint(TILE_WIDTH, TILE_HEIGHT), TILE_HEIGHT_OFFSET);
		map.addTileset(AssetPaths.new_pixel_64_96__png, TILE_WIDTH, TILE_HEIGHT);
		map.addTileset(AssetPaths.dynamic_tileset__png, TILE_WIDTH, TILE_HEIGHT);
		map.init(new FlxPoint(MAP_WIDTH, MAP_HEIGHT));
		add(map);
		
		map.addLayer(MapUtils.getLayerFromCsv(Assets.getText("assets/data/level.csv"), [0, 1], 0, TILE_WIDTH, TILE_HEIGHT, TILE_HEIGHT_OFFSET, false, 58));
		map.addLayer(MapUtils.getEmptyLayer(1, MAP_WIDTH, MAP_HEIGHT, TILE_WIDTH, TILE_HEIGHT, TILE_HEIGHT_OFFSET, -1));
		map.addLayer(MapUtils.getLayerFromCsvTileRange(Assets.getText("assets/data/level.csv"), 2, 62, 1, TILE_WIDTH, TILE_HEIGHT, TILE_HEIGHT_OFFSET, true, -1));
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);    
		handleKeyboardInput(elapsed);
	}
  
	function handleKeyboardInput(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ESCAPE) {
			FlxG.switchState(new MenuState());
		}
		
		if (FlxG.keys.pressed.DOWN) {
			FlxG.camera.scroll.y -= 250 * elapsed;
		} 
		
		if (FlxG.keys.pressed.LEFT) {
			FlxG.camera.scroll.x += 250 * elapsed;
		}
		
		if (FlxG.keys.pressed.RIGHT) {
			FlxG.camera.scroll.x -= 250 * elapsed;
		}
		
		if (FlxG.keys.pressed.UP) {
			FlxG.camera.scroll.y += 250 * elapsed;
		}
	}
}
