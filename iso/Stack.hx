package iso;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class Stack
{
	public var z_height:Float;
	public var root:IsoTile;
	public var length:Int;
	var members:Array<IsoTile>;
	
	public function new(root:IsoTile) 
	{
		this.root = root;
		z_height = this.root.z_height;
		members = new Array<IsoTile>();
		push(root);
	}
	
	public function push(obj:IsoTile):Int
	{
		z_height += obj.z_height;
		return length = members.push(obj);
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
	
}