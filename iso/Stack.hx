package iso;
import openfl.display.Tile;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Stack
{
	public var id:Int;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	
	public var length(get, null):Int;
	var members:Array<IsoTile>;
	
	public function new(id:Int, x:Float, y:Float, z:Float)
	{
		this.id = id;
		this.x = x;
		this.y = y;
		this.z = z;
	}
	
	public function push(obj:IsoTile):Int
	{
		if (members == null) members = new Array<IsoTile>();
		
		z += obj.z_height;
		return length = members.push(obj);
	}
	
	public function pop(obj:IsoTile):Bool
	{
		z -= obj.z_height;
		return members.remove(obj);
	}
	
	public function get(index:Int):IsoTile
	{
		return members[index];
	}
	
	public function get_length():Int
	{
		if (members == null) return 0;
		
		return members.length;
	}
	
}