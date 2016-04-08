package ;

import flixel.FlxG;
import flixel.FlxState;

class TiledState extends FlxState
{
  override public function create():Void
  {
    super.create();

    // Add Tiled Tilemap logic here
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
