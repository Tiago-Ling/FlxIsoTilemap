package ;

import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;
import iso.FlxIsoTilemap;
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
    
    map = new FlxIsoTilemap(new FlxPoint(VIEWPORT_WIDTH, VIEWPORT_HEIGHT), new FlxPoint(MAP_WIDTH, MAP_HEIGHT), new FlxPoint(TILE_WIDTH, TILE_HEIGHT), TILE_HEIGHT_OFFSET);
    map.addTileset(AssetPaths.new_pixel_64_96__png, TILE_WIDTH, TILE_HEIGHT);
    map.addTileset(AssetPaths.dynamic_tileset__png, TILE_WIDTH, TILE_HEIGHT);
    add(map);
    
    map.addLayerFromCsv(Assets.getText("assets/level.csv"), [0, 1], 0, false, 58);
    map.addEmptyLayer(1, -1);
    map.addLayerFromCsvTileRange(Assets.getText("assets/level.csv"), 2, 62, 1, true, -1);
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
