package iso;
import flixel.math.FlxPoint;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
class IsoTile
{
	public var type:Int;
	//DEPRECATED
	//public var drawIndex:Int;
	public var world_x:Float;
	public var world_y:Float;
	public var world_z:Float;
	public var iso_x:Int;
	public var iso_y:Int;
	
	public var z_height:Float;
	
	//Animation stuff
	public var animated:Bool;
	var animations:Map<String, Array<Int>>;
	var currentAnimation:Array<Int>;
	var currentFrame:Int;
	var elapsed:Float;
	var frameChangeTime:Float;
	
	public var facing:FlxPoint;
	
	//Testing shadow
	public var hasShadow:Bool;
	public var shadowId:Int;
	public var shadowScale:Float;
	
	public function new(type:Int, world_x:Float, world_y:Float, iso_x:Int, iso_y:Int)
	{
		this.type = type;
		this.world_x = world_x;
		this.world_y = world_y;
		this.world_z = 0;
		this.iso_x = iso_x;
		this.iso_y = iso_y;
		
		z_height = 0;
		
		facing = FlxPoint.get(1, 1);
	}
	
	public function addShadow(id:Int)
	{
		shadowId = id;
		shadowScale = 1.0;
		hasShadow = true;
	}
	
	public function addAnimation(name:String, frames:Array<Int>, fps:Int)
	{
		//FPS could be defined by the last frame (maybe too confusing and error-prone?)
		frames.push(fps);
		
		if (animations == null)
			animations = new Map<String, Array<Int>>();
		
		animations.set(name, frames);
	}
	
	public function playAnimation(name:String)
	{
		currentAnimation = animations.get(name);
		currentFrame = 0;
		elapsed = 0;
		
		frameChangeTime = 1 / currentAnimation[currentAnimation.length - 1];
		
		animated = true;
	}
	
	public function updateAnimation(delta:Float)
	{
		elapsed += delta;
		if (elapsed >= frameChangeTime) {
			elapsed = 0;
			
			type = currentAnimation[currentFrame];
			
			if (currentFrame < currentAnimation.length - 2) {
				currentFrame++;
			} else {
				//Loops
				currentFrame = 0;
			}
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