package iso;
import flixel.math.FlxPoint;
import iso.Stack;
import openfl.display.Tile;
import openfl.display.TilemapLayer;
import openfl.display.Tileset;
import lime.graphics.opengl.GLBuffer;
import lime.utils.Float32Array;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class MapLayer
{
	public var stacks:Array<Array<Stack>>;
	public var viewportTiles:Array<Stack>;
	
	public var tileset:Tileset;
	
	public var isDynamic:Bool;
	public var dynamicObjects:Array<iso.IsoTile>;
	
	public var map:FlxIsoTilemap;
	
	public var length(get, null):Int;
	
	//TEMP
	private var __buffer:GLBuffer;
	private var __bufferData:Float32Array;
	private var __dirty:Bool;
	
	//Experimental: Tile shadow tests
	var minHeight:Float = 0;
	var maxHeight:Float = 160;
	
	public function new(tileset:Tileset, stacks:Array<Array<iso.Stack>>, viewportTiles:Array<Stack>, isDynamic:Bool = false) 
	{
		this.stacks = stacks;
		this.viewportTiles = viewportTiles;
		
		this.tileset = tileset;
		
		this.isDynamic = isDynamic;
		
		//Experimental
		if (isDynamic)
			dynamicObjects = new Array<iso.IsoTile>();
	}
	
	public function clearTiles()
	{
		viewportTiles.splice(0, viewportTiles.length);
	}
	
	public function addObject(obj:iso.IsoTile, isMoveable:Bool)
	{
		stacks[obj.iso_y][obj.iso_x].push(obj);
		
		if (isMoveable)
			dynamicObjects.push(obj);
	}
	
	public function popObject(obj:iso.IsoTile, isMoveable:Bool) {
		stacks[obj.iso_y][obj.iso_x].pop(obj);
		
		if (isMoveable)
			dynamicObjects.remove(obj);
	}
	
	public function update(delta:Float)
	{
		for (i in 0...dynamicObjects.length) {
			
			//Check if its position changed
			var tile = dynamicObjects[i];
			
			//Checking if the tile moved to another stack
			
			//If it now belongs to a new stack, pop it out of the old one
			var screen_pos:FlxPoint = map.getWorldToScreen(tile.x, tile.y);
			
			//TODO: Find a general offset based on tile size 
			var newIso:FlxPoint = map.getScreenToIso(screen_pos.x - 16, screen_pos.y + 16);
			
			if (tile.iso_x != newIso.x || tile.iso_y != newIso.y) {
				
				popObject(tile, true);
				
				//Then update its new iso position (stack row and column)
				tile.iso_x = Std.int(newIso.x);
				tile.iso_y = Std.int(newIso.y);
				
				//DEPRECATED
				//tile.drawIndex = Std.int(newIso.y) * map.map_w + Std.int(newIso.x);
				
				//Add it to the new stack.
				addObject(tile, true);
			}
			
			//Experimental: Apply gravity
			if (tile.z > stacks[tile.iso_y][tile.iso_x].z) {
				var gravity:Float = 200 * delta;
				tile.z -= gravity;
				
				if (tile.z <= stacks[tile.iso_y][tile.iso_x].z) {
					tile.z = stacks[tile.iso_y][tile.iso_x].z;
				}
			}
			
			//Experimental: Update tile shadow
			if (tile.hasShadow) {
				tile.shadowScale = (1 / (maxHeight - minHeight)) * (maxHeight - tile.z);
			}
		}
	}
	
	function lerp(alpha:Float, a:Float, b:Float):Float
	{
		return (b - a) * alpha + a;
	}
	
	public function get_length():Int
	{
		if (viewportTiles == null) return 0;
		
		return viewportTiles.length;
	}
}