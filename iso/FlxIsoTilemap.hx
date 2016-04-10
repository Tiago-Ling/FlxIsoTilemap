package iso;

import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.opengl.GLRenderer;
import flash.display.BitmapData;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.graphics.tile.FlxDrawTilesItem;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxTilemapGraphicAsset;
import iso.IsoTile;
import iso.MapLayer;
import iso.Stack;
import openfl.Assets;
import openfl.display.DisplayObject;
import openfl.display.Graphics;
import openfl.display.Sprite;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.display.Tilesheet;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.Lib;

/**
 * ...
 * @author Tiago Ling Alexandre
 */
//class FlxIsoTilemap extends FlxObject
class FlxIsoTilemap extends DisplayObject
{
	public var map_w:Int;
	public var map_h:Int;
	
	//TODO: Substitute by Flixel's camera
	public var cameraScroll:FlxPoint;
	public var scale:FlxPoint;
	public var layers:Array<iso.MapLayer>;
	public var viewport:Sprite;
	
	//Tileset
	var frameCollections:Array<FlxFramesCollection>;
	var graphics:Array<FlxGraphic>;
	
	//Draw helpers
	var matrix:flixel.math.FlxMatrix;
	var offset:flixel.math.FlxPoint;
	var frame:FlxFrame;
	var drawItem:FlxDrawTilesItem;
	
	var viewportBounds:Rectangle;
	var offsetViewportBounds:Rectangle;
	
	var tile_gfx_width:Float;
	var tile_gfx_height:Float;
	var height_gfx_offset:Float;
	
	//TODO: Make properties out of these
	public var tile_width:Float;
	public var tile_height:Float;
	public var height_offset:Float;
	public var origin:FlxPoint;
	
	//Viewport size, used for tile culling
	var viewportWidth:Float;
	var viewportHeight:Float;
	var topLeft:FlxPoint;
	var topRight:FlxPoint;
	var botLeft:FlxPoint;
	var botRight:FlxPoint;
	
	//var object:Sprite;
	
	public function new(viewport:FlxPoint, sizeInTiles:FlxPoint, tileSize:FlxPoint, tileHeightOffset:Float) 
	{
		super();
		
		viewportWidth = viewport.x;
		viewportHeight = viewport.y;
		
		map_w = Std.int(sizeInTiles.x);
		map_h = Std.int(sizeInTiles.y);
		
		tile_width = tile_gfx_width = tileSize.x;
		tile_height = tile_gfx_height = tileSize.y;
		height_offset = height_gfx_offset = tileHeightOffset;
		
		cameraScroll = new FlxPoint();
		scale = new FlxPoint(1, 1);
		
		layers = new Array<iso.MapLayer>();
		frameCollections = new Array<FlxFramesCollection>();
		graphics = new Array<FlxGraphic>();
		
		//object = new Sprite();
		//Lib.current.stage.addChild(object);
		
		init();
	}
	
	function init()
	{
		//Map size in pixels, used to calculate origin and bounds
		var map_pixel_width = map_h * tile_width + ((map_w - map_h) * (tile_height - height_offset));
		var map_pixel_height = map_w * (tile_height - height_offset) + ((map_h - map_w) * (tile_height - height_offset) / 2);
		trace('Map size in pixels : $map_pixel_width x $map_pixel_height');
		
		//Calculating origin so the map is always centered on the screen (does not take into account walls (height_offset))
		var offset_x = map_pixel_width / 2 - tile_width / 2;
		origin = new FlxPoint(FlxG.stage.stageWidth / 2 - map_pixel_width / 2 + offset_x, FlxG.stage.stageHeight / 2 - map_pixel_height / 2 - height_offset);
		trace('Origin : ${origin.toString()}');
		
		//Tilemap Bounding rectangle, yellow (includes height_offset for walls)
		var mapBounds:Rectangle = new Rectangle(origin.x - (map_h - 1) * tile_width / 2, origin.y, map_pixel_width, map_pixel_height + height_offset);
		trace('MapBounds : ${mapBounds.toString()}');
		
		//User-defined viewport
		viewportBounds = new Rectangle(FlxG.stage.stageWidth / 2 - viewportWidth / 2, FlxG.stage.stageHeight / 2 - viewportHeight / 2, viewportWidth, viewportHeight);
		trace('viewportBounds : ${viewportBounds.toString()}');
		
		//This is needed for mouse detection (TODO: fix)
/*		viewport = new Sprite();
		FlxG.stage.addChild(viewport);
		
		var gfx = viewport.graphics;
		gfx.beginFill(0x0, 0);
		gfx.drawRect(0, 0, viewportWidth, viewportHeight);
		gfx.endFill();*/
		
/*		var gfx = object.graphics;
		gfx.beginFill(0x0, 0.5);
		gfx.drawRect(0, 0, viewportWidth, viewportHeight);
		gfx.endFill();*/
		
		//Actual viewport, used with offset to correctly perform the culling
		offsetViewportBounds = new Rectangle(viewportBounds.x - tile_width,
											 viewportBounds.y - (tile_height - height_offset),
											 viewportBounds.width + 2 * tile_width,
											 viewportBounds.height + 2 * (tile_height - height_offset) + height_offset);	//Add height_offset to account for the wall height at the bottom of the screen
		trace('offsetViewportBounds : ${offsetViewportBounds.toString()}');
		
		//Init draw helpers
		matrix = new FlxMatrix();
		offset = new FlxPoint();
	}
	
	public function updateViewport()
	{
		//Get all viewport corners
		topLeft = getScreenToIso(offsetViewportBounds.x - cameraScroll.x, offsetViewportBounds.y - cameraScroll.y);
		topRight = getScreenToIso(offsetViewportBounds.x + offsetViewportBounds.width - cameraScroll.x, offsetViewportBounds.y - cameraScroll.y);
		botLeft = getScreenToIso(offsetViewportBounds.x - cameraScroll.x, offsetViewportBounds.y + offsetViewportBounds.height - cameraScroll.y);
		botRight = getScreenToIso(offsetViewportBounds.x + offsetViewportBounds.width - cameraScroll.x, offsetViewportBounds.y + offsetViewportBounds.height - cameraScroll.y);
		
		var i_length:Int = Std.int(botLeft.y - topRight.y + 1);
		var i_start:Int = Std.int(topRight.y);
		
		for (k in 0...layers.length) {
			
			var j_start:Int = 0;
			var j_end:Int = 0;
			var alt_count:Int = 0;
			
			layers[k].viewportTiles.splice(0, layers[k].viewportTiles.length);
			
			var layer = layers[k];
			
			if (layer.isDynamic)
				layer.update(1 / 60);
			
			for (i in 0...i_length) {
				
				if (i < i_length / 2) {
					j_start = Std.int(topRight.x - i);
					j_end = Std.int(topRight.x + i);
				} else {
					alt_count++;
					j_start = Std.int(topLeft.x + alt_count);
					j_end = Std.int(botRight.x - alt_count + 1);
				}
				
				var j_length:Int = (j_end - j_start) + 1;
				for (j in 0...j_length) {
					var tX:Int = j_start + j;
					var tY:Int = i_start + i;
					
					if (tX < 0 || tX >= map_w || tY < 0 || tY >= map_h)
						continue;
					
					var stack = layer.stacks[tY][tX];
					
					if (stack == null) continue;
					
					if (stack.length == 0 && stack.id == -1)
						continue;
					
					//Experimental: Tile animation update
					for (l in 0...stack.length) {
						var tile = stack.get(l);
						
						if (tile == null) continue;
						
						if (tile.animated)
							tile.updateAnimation(1 / 60);
					}
					
					layer.viewportTiles.push(stack);
				}
			}	
		}
	}
	
/*	override public function update(elapsed:Float):Void
	{
		updateViewport();
	}
	
	override public function draw():Void
	{
		if (FlxG.stage == null) return;
		
		//var renderSession = @:privateAccess FlxG.stage.__renderer.renderSession;
		var renderer = @:privateAccess cast(Lib.current.stage.__renderer, GLRenderer);
		var renderSession = @:privateAccess renderer.renderSession;
		
		//var gl = renderer.gl;
		//renderer.setViewport (0, 0, renderer.width, renderer.height);
		//
		//gl.bindFramebuffer (gl.FRAMEBUFFER, renderer.defaultFramebuffer);
		//
		//if (renderer.transparent) {
			//
			//gl.clearColor (0, 0, 0, 0);
			//
		//} else {
			//
			////gl.clearColor (Lib.current.stage.__colorSplit[0], Lib.current.stage.__colorSplit[1], Lib.current.stage.__colorSplit[2], 1);
			//gl.clearColor (0, 0, 0, 0);
			//
		//}
		//
		//gl.clear (gl.COLOR_BUFFER_BIT);
		////renderDisplayObject (stage, projection);
		//
		//
		//renderSession.blendModeManager.setBlendMode (openfl.display.BlendMode.NORMAL);
		//
		//renderSession.drawCount = 0;
		//renderSession.currentBlendMode = null;
		//
		//renderer.spriteBatch.begin (renderSession);
		//renderer.filterManager.begin (renderSession, null);
		//
		//GLRenderer.renderBitmap(object, renderSession);
		
		
		//displayObject.__renderGL (renderSession);
		GLIsoTilemap.render(this, renderSession);
		
		//renderer.spriteBatch.finish();
	}*/
	
	override public function __update (transformOnly:Bool, updateChildren:Bool, ?maskGraphics:Graphics = null):Void {
		super.__update(transformOnly, updateChildren, maskGraphics);
		
		updateViewport();
	}
	
	@:noCompletion @:dox(hide) public override function __renderGL (renderSession:RenderSession):Void {
		
		if (stage == null) return;
		if (renderSession == null) return;
		
		GLIsoTilemap.render(this, renderSession);
	}
	
	public function drawViewport()
	{
		for (k in 0...layers.length) {
			var layer = layers[k];
			var count:Int = 0;
			
			//Flixel Renderer
			//drawItem = Camera.startQuadBatch(graphics[layer.tilesetId], false, false, null, false);
			
			for (i in 0...layer.viewportTiles.length) {
				var stack = layer.viewportTiles[i];
				
				for (j in 0...stack.length) {
					
					var tile = stack.get(j);
					if (tile == null) continue;
					
					//Experimental: draw shadows
					if (tile.hasShadow) {
						matrix.identity();
						
						//Translate to tile pivot
						matrix.translate(-tile_width / 2, -80);
						
						//Apply transformations (scale, rotate, skew)
						matrix.scale(tile.shadowScale, tile.shadowScale);
						
						//Translate back from tile pivot
						matrix.translate(tile_width / 2, 80);
						
						//TODO: Fix global scale positioning of shadow
						matrix.translate(origin.x + (tile.x * scale.x) + Std.int(cameraScroll.x), origin.y + (tile.y * scale.y) + Std.int(cameraScroll.y));
						
						//Flixel Renderer
						//var shadowFrame = frameCollections[layer.tilesetId].getByIndex(tile.shadowId);
						
						//Flixel Renderer
						//drawItem.addQuad(shadowFrame, matrix, null);
					}
					
					//Flixel Renderer
					//frame = frameCollections[layer.tilesetId].getByIndex(tile.id);
					
					//When flipping we must add the tile width / height
					offset.set(tile.facing.x < 0 ? tile_width : 0, tile.facing.y < 0 ? tile_height : 0);
					
					matrix.identity();
					
					//Translate to tile pivot
					matrix.translate(-tile_width / 2, -80);
					
					//Apply transformations (scale, rotate, skew)
					matrix.scale(scale.x * tile.facing.x, scale.y * tile.facing.y);
					
					//Translate back from tile pivot
					matrix.translate(tile_width / 2, 80);
					
					//Actual tile translation
					matrix.translate(origin.x + tile.x + Std.int(cameraScroll.x), origin.y + (tile.y - tile.z) + Std.int(cameraScroll.y));
					
					//Flixel Renderer
					//drawItem.addQuad(frame, matrix, null);
					
				}
			}
		}
	}
	
	public function getTileset(gfx:BitmapData, tileWidth:Int, tileHeight:Int):Tileset
	{
		var tileset = new Tileset(gfx);
		
		var widthInTiles:Int = Std.int(gfx.width / tileWidth);
		var totalTileTypes:Int = Std.int(widthInTiles * gfx.height / tileHeight);
		for (i in 0...totalTileTypes) {
			var x:Int = Std.int(i % widthInTiles);
			var y:Int = Std.int(i / widthInTiles);
			
			tileset.addRect(new Rectangle(x * tile_width, y * tile_height, tile_width, tile_height));
		}
		
		return tileset;
	}
	
	public function addTileset(gfx:FlxTilemapGraphicAsset, tileWidth:Int, tileHeight:Int):Int
	{
		if (Std.is(gfx, FlxFramesCollection))
		{
			frameCollections.push(cast gfx);
			graphics.push(cast(gfx, FlxFramesCollection).parent);
			return -1;
		}
		
		var graph:FlxGraphic = FlxG.bitmap.add(cast gfx);
		if (graph == null)
		{
			return -1;
		}
		
		// Figure out the size of the tiles
		tile_width = tileWidth;
		if (tile_width <= 0)
		{
			tile_width = graph.height;
		}
		
		tile_height = tileHeight;
		if (tile_height <= 0)
		{
			tile_height = tile_width;
		}
		
		frameCollections.push(FlxTileFrames.fromGraphic(graph, new FlxPoint(tile_width, tile_height)));
		graphics.push(graph);
		
		return frameCollections.length - 1;
	}

	//Separates a layer of tile types from a 2D array and returns it
	public function addLayerFromTileArray(indices:Array<Array<Int>>, tiles:Array<Int>, tileset:Tileset, isDynamic:Bool = false, fillIndex:Int = -1):Int
	{
		var layerData = new Array<Array<iso.Stack>>();
		var layer = new iso.MapLayer(tileset, [], [], isDynamic);
		layer.map = this;
		
		for (i in 0...map_h) {
			layerData[i] = new Array<iso.Stack>();
			for (j in 0...map_w) {
				var x:Float = ((j - i) * (tile_width / 2));
				var y:Float = ((j + i) * ((tile_height - height_offset) / 2));
				layerData[i][j] = new iso.Stack(indices[i][j], x, y, 0);
				
				var changeIndex = true;
				for (k in 0...tiles.length) {
					if (layerData[i][j].id == tiles[k])
						changeIndex = false;
				}
				
				if (changeIndex)
					layerData[i][j].id = fillIndex;
			}
		}
		
		layer.stacks = layerData;
		layers.push(layer);
		return layers.length - 1;
	}
	
	public function addLayerFromTileRange(indices:Array<Array<Int>>, startTile:Int, length:Int, tileset:Tileset, isDynamic:Bool = false, fillIndex:Int = -1):Int
	{
		var layerData = new Array<Array<iso.Stack>>();
		var layer = new iso.MapLayer(tileset, [], [], isDynamic);
		
		for (i in 0...map_h) {
			layerData[i] = new Array<iso.Stack>();
			for (j in 0...map_w) {
				var x:Float = ((j - i) * (tile_width / 2));
				var y:Float = ((j + i) * ((tile_height - height_offset) / 2));
				layerData[i][j] = new iso.Stack(indices[i][j], x, y, 0);
				var changeIndex = true;
				for (k in startTile...length) {
					if (layerData[i][j].id == k)
						changeIndex = false;
				}
				
				if (changeIndex)
					layerData[i][j].id = fillIndex;
			}
		}
		
		layer.stacks = layerData;
		layers.push(layer);
		return layers.length - 1;
	}
	
	public function addEmptyLayer(tileset:Tileset, fillIndex:Int = -1):Int
	{
		var layerData = new Array<Array<iso.Stack>>();
		var layer = new iso.MapLayer(tileset, [], [], false);
		
		for (i in 0...map_h) {
			layerData[i] = new Array<iso.Stack>();
			for (j in 0...map_w) {
				var x:Float = ((j - i) * (tile_width / 2));
				var y:Float = ((j + i) * ((tile_height - height_offset) / 2));
				layerData[i][j] = new iso.Stack(fillIndex, x, y, 0);
			}
		}
		
		layer.stacks = layerData;
		layers.push(layer);
		return layers.length - 1;
	}
	
	public function getScreenToIso(screen_x:Float, screen_y:Float, offset:FlxPoint = null, asInt:Bool = true):FlxPoint
	{
		var cX = screen_x - origin.x - (tile_height - height_offset);
		var cY = screen_y - origin.y - tile_width;
		
		if (offset != null) {
			//Camera offset (interferes with positioning)
			cX -= offset.x;
			cY -= offset.y;
		}
		
		if (asInt) {
			var mapX:Int = Std.int((cX / (tile_width / 2) + cY / ((tile_height - height_offset) / 2)) / 2);
			var mapY:Int = Std.int((cY / ((tile_height - height_offset) / 2) - cX / (tile_width / 2)) / 2);
			return new FlxPoint(mapX, mapY);
		} else {
			var mapX:Float = (cX / (tile_width / 2) + cY / ((tile_height - height_offset) / 2)) / 2;
			var mapY:Float = (cY / ((tile_height - height_offset) / 2) - cX / (tile_width / 2)) / 2;
			return new FlxPoint(mapX, mapY);
		}
	}
	
	public function getIsoToScreen(iso_x:Float, iso_y:Float, offset:FlxPoint = null):FlxPoint
	{
		var cX = (iso_x - iso_y) * tile_width / 2;
		var cY = (iso_x + iso_y) * ((tile_height - height_offset) / 2);
		
		cX += origin.x + (tile_height - height_offset);
		cY += origin.y + tile_width;
		
		if (offset != null) {
			//Camera offset (interferes with positioning)
			cX += offset.x;
			cY += offset.y;
		}
		
		return new FlxPoint(cX, cY);
	}
	
	public function getWorldToScreen(x:Float, y:Float):FlxPoint
	{
		return new FlxPoint(x + origin.x + (tile_height - height_offset), y + origin.y + tile_width);
	}
	
	public function updateScale(newScale:Float)
	{
		tile_width = tile_gfx_width * scale.x;
		tile_height = tile_gfx_height * scale.y;
		height_offset = height_gfx_offset * scale.y;
		
		//Map size in pixels, used to calculate origin and bounds
		var map_pixel_width = map_h * tile_width + ((map_w - map_h) * (tile_height - height_offset));
		var map_pixel_height = map_w * (tile_height - height_offset) + ((map_h - map_w) * (tile_height - height_offset) / 2);
		
		//Calculating origin so the map is always centered on the screen (does not take into account walls (height_offset))
		var offset_x = map_pixel_width / 2 - tile_width / 2;
		origin = new FlxPoint(FlxG.stage.stageWidth / 2 - map_pixel_width / 2 + offset_x, FlxG.stage.stageHeight / 2 - map_pixel_height / 2 - height_offset);
		
		//Actual viewport, used with offset to correctly perform the culling
		offsetViewportBounds = new Rectangle(viewportBounds.x - tile_width,
											 viewportBounds.y - (tile_height - height_offset),
											 viewportBounds.width + 2 * tile_width,
											 viewportBounds.height + 2 * (tile_height - height_offset) + height_offset);	//Add height_offset to account for the wall height at the bottom of the screen
	}
}