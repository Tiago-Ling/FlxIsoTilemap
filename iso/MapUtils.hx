package iso;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import haxe.xml.Fast;
import openfl.geom.Rectangle;

/**
 * Utility methods for the iso tilemap class
 * @author Tiago Ling Alexandre
 */
class MapUtils
{
	public static function getLayerFromCsv(MapData:String, tiles:Array<Int>, tilesetId:Int, tw:Float, th:Float, h_offset:Float, isDynamic:Bool = false, fillIndex:Int = -1):MapLayer
	{
		return getLayerFromTileArray(fromCsvStringToArray(MapData), tiles, tilesetId, tw, th, h_offset, isDynamic, fillIndex);
	}

	public static function getLayerFromCsvTileRange(MapData:String, startTile:Int, length:Int, tilesetId:Int, tw:Float, th:Float, h_offset:Float, isDynamic:Bool = false, fillIndex:Int = -1):MapLayer
	{
		return getLayerFromTileRange(fromCsvStringToArray(MapData), startTile, length, tilesetId, tw, th, h_offset, isDynamic, fillIndex);
	}
	
	//Separates a layer of tile types from a 2D array and returns it
	public static function getLayerFromTileArray(indices:Array<Array<Int>>, tiles:Array<Int>, tilesetId:Int, tw:Float, th:Float, h_offset:Float, isDynamic:Bool = false, fillIndex:Int = -1):MapLayer
	{
		var layerData = new Array<Array<iso.Stack>>();
		var layer = new iso.MapLayer([], [], tilesetId, isDynamic);
		
		var layer_h:Int = indices.length;
		var layer_w:Int = indices[0].length;
		
		for (i in 0...layer_h) {
			layerData[i] = new Array<iso.Stack>();
			for (j in 0...layer_w) {
				var x:Float = ((j - i) * (tw / 2));
				var y:Float = ((j + i) * ((th - h_offset) / 2));
				layerData[i][j] = new iso.Stack(new iso.IsoTile(indices[i][j], x, y, j, i));
				
				var changeIndex = true;
				for (k in 0...tiles.length) {
					if (layerData[i][j].root.type == tiles[k])
						changeIndex = false;
				}
				
				if (changeIndex)
					layerData[i][j].root.type = fillIndex;
			}
		}
		
		layer.stacks = layerData;
		return layer;
	}
	
	public static function getLayerFromTileRange(indices:Array<Array<Int>>, startTile:Int, length:Int, tilesetId:Int, tw:Float, th:Float, h_offset:Float, isDynamic:Bool = false, fillIndex:Int = -1):MapLayer
	{
		var layerData = new Array<Array<iso.Stack>>();
		var layer = new iso.MapLayer([], [], tilesetId, isDynamic);
		
		var layer_h:Int = indices.length;
		var layer_w:Int = indices[0].length;
		
		for (i in 0...layer_h) {
			layerData[i] = new Array<iso.Stack>();
			for (j in 0...layer_w) {
				var x:Float = ((j - i) * (tw / 2));
				var y:Float = ((j + i) * ((th - h_offset) / 2));
				layerData[i][j] = new iso.Stack(new iso.IsoTile(indices[i][j], x, y, j, i));
				
				var changeIndex = true;
				for (k in startTile...length) {
					if (layerData[i][j].root.type == k)
						changeIndex = false;
				}
				
				if (changeIndex)
					layerData[i][j].root.type = fillIndex;
			}
		}
		
		layer.stacks = layerData;
		return layer;
	}
	
	public static function getEmptyLayer(tilesetId:Int, lw:Int, lh:Int, tw:Float, th:Float, h_offset:Float, fillIndex:Int = -1):MapLayer
	{
		var layerData = new Array<Array<iso.Stack>>();
		var layer = new iso.MapLayer([], [], tilesetId, false);
		
		for (i in 0...lh) {
			layerData[i] = new Array<iso.Stack>();
			for (j in 0...lw) {
				var x:Float = ((j - i) * (tw / 2));
				var y:Float = ((j + i) * ((th - h_offset) / 2));
				layerData[i][j] = new iso.Stack(new iso.IsoTile(fillIndex, x, y, j, i));
			}
		}
		
		layer.stacks = layerData;
		return layer;
	}
	
	public static function fromCsvStringToArray(MapData:String):Array<Array<Int>>
	{
		var result:Array<Array<Int>> = new Array<Array<Int>>();
		var rowresult:Array<Int> = new Array<Int>();
		var rows:Array<String> = StringTools.trim(MapData).split("\n");
		var row:String;
		
		for (row in rows) {
			
			if (row == "") {
				continue;
			}
			
			var entries:Array<String> = row.split(",");
			var entry:String;
			rowresult = new Array<Int>();
			
			for (entry in entries) {
				if(entry != "") {
					rowresult.push(Std.parseInt(entry));
				}
			}
			result.push(rowresult);
		}
		
		return result;
	}
	
	public static function fromTiledXmlToArray(Data:List<Fast>, w:Int, h:Int):Array<Array<Int>>
	{
		var res = new Array<Array<Int>>();
		for (i in 0...h) {
			res[i] = new Array<Int>();
			for (j in 0...w) {
				res[i][j] = -1;
			}
		}
		
		var count:Int = 0;
		for (tile in Data) {
			var j:Int = Std.int(count % w);
			var i:Int = Std.int(count / w);
			
			var id = Std.parseInt(tile.att.gid);
			
			res[i][j] = id;
			count++;
		}
		
		return res;
	}
	
	/**
	 * Loads a map, adds tilesets, layers and tile data from a .tmx file and returns it
	 * Supports .tmx files with xml or csv encoding
	 * @param	MapData	The string loaded from a .tmx file
	 */
	public static function getMapFromTiled(MapData:String, vp:FlxPoint, ts:FlxPoint, h_offset:Float, imageFolder:String = null):FlxIsoTilemap
	{
		var xmlData = Xml.parse(MapData);
		var fData = new Fast(xmlData.firstElement());
		
		var map = new FlxIsoTilemap(vp, ts, h_offset);
		
		//Tilesets - ID will be given by either custom property "ID" or loop order
		var tilesetCount:Int = 0;
		for (tileset in fData.nodes.tileset) {
			
			//Tileset path from tiled is relative to .tmx location, must pass an image folder or use flixel's default one
			var filename:String = tileset.node.image.att.source.split('/').pop();
			var path:String = imageFolder == null ? 'assets/images/' : imageFolder;
			var res:Int = map.addTileset(path + filename, Std.parseInt(tileset.att.tilewidth), Std.parseInt(tileset.att.tileheight));
			
			//if (res < 0) trace('Tileset at "${path + filename}" not found!');
			
			//TODO: Tileset properties
			//TODO: Tile properties
			
			tilesetCount++;
		}
		
		var layerCount = 0;
		//Layers - ID will be given by loop order. Will work only with tilesets with same ID
		for (l in fData.nodes.layer) {
			
			var tiles:Array<Array<Int>> = null;
			var isCsv:Bool = l.node.data.has.encoding;
			
			//Attribute 'encoding' only appears when using CSV
			if (isCsv) {
				tiles = fromCsvStringToArray(l.node.data.innerHTML);
			} else {
				//When no encoding, it must be XML
				tiles = fromTiledXmlToArray(l.node.data.nodes.tile, Std.parseInt(l.att.width), Std.parseInt(l.att.height));
			}
			
			//TODO: Other encoding formats (Base64)
			
			var layerData = new Array<Array<iso.Stack>>();
			
			//TODO: isDynamic (must check whether an object group with the same id exists
			var layer = new iso.MapLayer([], [], 0, false);
			
			var rows = tiles.length;
			for (i in 0...rows) {
				layerData[i] = new Array<iso.Stack>();
				
				var cols = -1;
				if (isCsv)
					//Removing one from col length as Tiled includes ',' at the end of each row
					cols = i == rows - 1 ? tiles[i].length : tiles[i].length - 1;
				else
					//Xml encoding does not have any problems
					cols = tiles[i].length;
					
				for (j in 0...cols) {
					var x:Float = ((j - i) * (map.tile_width / 2));
					var y:Float = ((j + i) * ((map.tile_height - map.height_offset) / 2));
					layerData[i][j] = new iso.Stack(new iso.IsoTile(tiles[i][j] - 1, x, y, j, i));
				}
			}
			
			layer.stacks = layerData;
			map.addLayer(layer);
			
			//TODO: Layer properties
			
			layerCount++;
		}
		
		//Init map
		map.init(FlxPoint.weak(map.layers[0].stacks.length, map.layers[0].stacks[0].length));
		
		var mapBounds:Rectangle = map.getBounds();
		
		layerCount = 0;
		//Dynamic object layers - ID will be given by loop order. Will be added to the layer with same ID
		//Note: 
		for (objLayer in fData.nodes.objectgroup) {
			
			//TODO: Better / generic way of using tiled properties
			if (objLayer.hasNode.properties) {
				//trace('Object layer has properties!');
				var props:Map<String, Dynamic> = new Map<String, String>();
				for (property in objLayer.node.properties.nodes.property) {
					var propName:String = property.att.name;
					var propValue:String = property.att.value;
					props.set(propName, propValue);
				}
				
				//Overrides layerCount if object layer has custom property name = "Layer", value = Int
				if (props.exists('TilesetID')) {
					layerCount = Std.parseInt(props.get('TilesetID'));
					//trace('layerCount set from tiled : $layerCount');
				}
			}
			
			map.layers[layerCount].isDynamic = true;
			
			for (object in objLayer.nodes.object) {
				
				var pos = FlxPoint.get(fclamp(Std.parseFloat(object.att.x), mapBounds.x, mapBounds.x + mapBounds.width),
									   fclamp(Std.parseFloat(object.att.y), mapBounds.y, mapBounds.y + mapBounds.height));
				
				var screen_pos:FlxPoint = map.getWorldToScreen(pos.x, pos.y);
				
				//TODO: Find a general offset based on tile size
				var iso_pos:FlxPoint = map.getScreenToIso(screen_pos.x - 16, screen_pos.y + 16);
				iso_pos.x = fclamp(iso_pos.x, 0, map.map_w - 1);
				iso_pos.y = fclamp(iso_pos.y, 0, map.map_h - 1);
				
				//TODO: Object properties
				var sprite = new FlxSprite(pos.x, pos.y);
				sprite.loadGraphic(map.getTilesetGraphic(layerCount), true, Std.int(map.tile_width), Std.int(map.tile_height));
				//TODO: Remove hardcoded test values
				sprite.animation.add('Idle', [62, 63, 64, 65, 66], 8, true);
				sprite.animation.play('Idle');
				map.layers[layerCount].addSpriteAtTilePos(sprite, Std.int(iso_pos.y), Std.int(iso_pos.x));
			}
			
			layerCount++;
		}
		
		return map;
	}
	
	public static function fclamp(value:Float, min:Float, max:Float):Float
	{
		if (value < min) value = min else if (value > max) value = max;
		return value;
	}
}