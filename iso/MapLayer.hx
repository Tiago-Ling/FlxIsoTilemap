package iso;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import iso.Stack;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class MapLayer
{
	public var stacks:Array<Array<Stack>>;
	public var tilesetId:Int;
	
	public var isDynamic:Bool;
	public var dynamicObjects:Array<IsoTile>;
	
	public var map:FlxIsoTilemap;
	
	//Experimental: Tile shadow tests
	var minHeight:Float = 0;
	var maxHeight:Float = 160;
	
	//Helper variables
	var screenPos:FlxPoint;
	var isoPos:FlxPoint;
	
	public function new(stacks:Array<Array<Stack>>, tilesetId:Int, isDynamic:Bool = false) 
	{
		this.stacks = stacks;
		this.tilesetId = tilesetId;
		this.isDynamic = false;
		
		screenPos = new FlxPoint();
		isoPos = new FlxPoint();
	}

	public function addTileAtTilePos(obj:iso.IsoTile)
	{
		stacks[obj.r][obj.c].push(obj);
	}
	
	public function addTileAtWorldPos(obj:IsoTile, x:Float, y:Float)
	{
		var screenPos = map.getWorldToScreen(new FlxPoint(), x, y);
		var tilePos = map.getScreenToIso(new FlxPoint(), screenPos.x, screenPos.y);
		stacks[Std.int(tilePos.y)][Std.int(tilePos.x)].push(obj);
	}
	
	public function addSpriteAtTilePos(obj:FlxSprite, r:Int, c:Int)
	{
		//Create new iso tile and set a reference to the FlxSprite inside it
		var stack = stacks[r][c];
		if (stack == null) return;
		obj.setPosition(stack.root.x, stack.root.y);
		
		var tile = new IsoTile(0, obj.x, obj.y, c, r, obj);
		stack.push(tile);
		
		if (dynamicObjects == null) {
			dynamicObjects = new Array<IsoTile>();
			isDynamic = true;
		}
		
		if (isDynamic) {
			dynamicObjects.push(tile);
		}
	}
	
	public function addSpriteAtWorldPos(obj:FlxSprite, x:Float, y:Float)
	{
		//Create new iso tile and set a reference to the FlxSprite inside it
		obj.setPosition(x, y);
		
		var screenPos = map.getWorldToScreen(new FlxPoint(), x, y);
		var tilePos = map.getScreenToIso(new FlxPoint(), screenPos.x, screenPos.y);
		var tile = new IsoTile(0, x, y, Std.int(tilePos.x), Std.int(tilePos.y), obj);
		stacks[Std.int(tilePos.y)][Std.int(tilePos.x)].push(tile);
		
		if (dynamicObjects == null) {
			dynamicObjects = new Array<IsoTile>();
			isDynamic = true;
		}
		
		if (isDynamic) {
			dynamicObjects.push(tile);
		}
	}

	public function removeObject(obj:iso.IsoTile) {
		stacks[obj.r][obj.c].pop(obj);
		
		if (obj.isDynamic) {
			var id:Int = -1;
			for (dObj in dynamicObjects) {
				if (obj == dObj)
					break;
				id++;
			}
			
			if (id > -1)
				dynamicObjects.splice(id, 1);
				
			if (dynamicObjects.length == 0) {
				isDynamic = false;
				dynamicObjects = null;
			}
		}
	}
	
	public function update(elapsed:Float)
	{
		if (map == null || dynamicObjects == null) return;
		
		for (i in 0...dynamicObjects.length) {
			
			//Check if its position changed
			var tile = dynamicObjects[i];
			
			if (tile == null) continue;
			
/*			//Update position and animation
			tile.update(elapsed);*/
			
			//Checking if the tile moved to another stack
			
			//If it now belongs to a new stack, pop it out of the old one
			map.getWorldToScreen(screenPos, tile.x, tile.y);
			
			//TODO: Find a general offset based on tile size
			map.getScreenToIso(isoPos, screenPos.x - 32, screenPos.y + 32);
			
			if (isoPos.x > map.map_w - 1 || isoPos.y > map.map_h - 1 || isoPos.x < 0 || isoPos.y < 0) continue;
			
			if (tile.c != isoPos.x || tile.r != isoPos.y) {
				
				//Remove from old stack
				removeObject(tile);
				
				//Then update its new iso position (stack row and column)
				tile.c = Std.int(isoPos.x);
				tile.r = Std.int(isoPos.y);
				
				//Add it to the new stack.
				addTileAtTilePos(tile);
			}
			
			//Experimental: Apply gravity
			if (tile.z > stacks[tile.r][tile.c].z_height) {
				var gravity:Float = 200 * elapsed;
				tile.z -= gravity;
				
				if (tile.z <= stacks[tile.r][tile.c].z_height) {
					tile.z = stacks[tile.r][tile.c].z_height;
				}
			}
			
			//Experimental: Update tile shadow
			if (tile.hasShadow) {
				tile.shadowScale = (1 / (maxHeight - minHeight)) * (maxHeight - tile.z);
			}
			
			//Get facing from parent sprite
			if (tile.parent != null) {
				tile.facing.set(tile.parent.flipX ? -1 : 1, tile.parent.flipY ? -1 : 1);
			}
			
			//Update position and animation
			tile.update(elapsed);
		}
	}
	
	function lerp(alpha:Float, a:Float, b:Float):Float
	{
		return (b - a) * alpha + a;
	}
}