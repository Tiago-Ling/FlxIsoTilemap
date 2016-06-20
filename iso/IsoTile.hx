package iso;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class IsoTile
{
	//Index in tileset
	public var type:Int;
	public var x:Float;
	public var y:Float;
	public var z:Float;
	
	public var c:Int;
	public var r:Int;
	
	public var z_height:Float;
	
	public var isDynamic:Bool;
	public var facing:FlxPoint;
	
	//Testing shadow
	public var hasShadow:Bool;
	public var shadowId:Int;
	public var shadowScale:Float;
	
	public var parent:FlxSprite;
	
	public function new(type:Int, world_x:Float, world_y:Float, iso_x:Int, iso_y:Int, parent:FlxSprite = null)
	{
		this.type = type;
		
		this.x = world_x;
		this.y = world_y;
		this.z = 0;
		this.c = iso_x;
		this.r = iso_y;
		
		z_height = 0;
		
		this.parent = parent;
		this.isDynamic = this.parent == null ? false : true;
		
		facing = new FlxPoint(1, 1);
	}
	
	public function addShadow(id:Int)
	{
		shadowId = id;
		shadowScale = 1.0;
		hasShadow = true;
	}
	
	public function update(elapsed:Float):Void
	{
		if (isDynamic) {
			parent.update(elapsed);
			this.x = parent.x;
			this.y = parent.y;
			if (parent.animation.curAnim != null)
				this.type = parent.animation.curAnim.curIndex;
			else 
				this.type = 66;
		}
	}
	
	public function flipX():Float
	{
		return facing.x = 1 * -1;
	}
	
	public function flipY():Float
	{
		return facing.y = 1 * -1;
	}
	
	public function setFacing(x:Float, y:Float)
	{
		facing.x = x;
		facing.y = y;
	}
}