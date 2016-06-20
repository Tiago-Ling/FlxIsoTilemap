package iso;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Stack
{
	public var z_height:Float;
	public var root(get, null):IsoTile;
	public var length(get, null):Int;
	var members:Array<IsoTile>;
	
	public function new(root:IsoTile)
	{
		members = new Array<IsoTile>();
		push(root);
		
		z_height = root.z_height;
	}
	
	public function push(obj:IsoTile):Int
	{
		members.push(obj);
		z_height += obj.z_height;
		return length;
	}
	
	public function pop(obj:IsoTile):Bool
	{
		z_height -= obj.z_height;
		return members.remove(obj);
	}
	
	public function get(index:Int):IsoTile
	{
		return members[index];
	}
	
	public function get_length():Int
	{
		return members.length;
	}
	
	public function get_root():IsoTile
	{
		return members[0];
	}
	
}