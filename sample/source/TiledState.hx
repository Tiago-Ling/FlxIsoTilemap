package ;

import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import iso.FlxIsoTilemap;
import openfl.Assets;

class TiledState extends FlxState
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
		
		map = new FlxIsoTilemap(new FlxPoint(VIEWPORT_WIDTH, VIEWPORT_HEIGHT), new FlxPoint(TILE_WIDTH, TILE_HEIGHT), TILE_HEIGHT_OFFSET);
		//Json encoding 
		//map.loadFromTiled(Assets.getText('assets/data/test_tiled.tmx'));
		
		//Xml encoding
		map.loadFromTiled(Assets.getText('assets/data/test_tiled_xml.tmx'));
		add(map);
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
