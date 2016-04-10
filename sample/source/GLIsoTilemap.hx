package ;


import flixel.math.FlxPoint;
import iso.FlxIsoTilemap;
import iso.MapLayer;
import iso.Stack;
import lime.graphics.GLRenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.opengl.GLUniformLocation;
import lime.math.Matrix4;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import openfl._internal.renderer.opengl.GLTilemap;
import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.RenderSession;
//import openfl.display.Tilemap;
import openfl.display.Tileset;

@:access(iso.FlxIsoTilemap)
@:access(iso.MapLayer)
@:access(openfl.display.Tileset)
@:access(iso.Stack)


class GLIsoTilemap {
	
	
	private static var glImageUniform:GLUniformLocation;
	private static var glMatrix:Matrix4;
	private static var glMatrixUniform:GLUniformLocation;
	private static var glProgram:GLProgram;
	private static var glTextureAttribute:Int;
	private static var glVertexAttribute:Int;
	
	private static function initialize (gl:GLRenderContext):Void {
		
		if (glProgram == null) {
			
			var vertexSource = "
				
				attribute vec2 aVertexPosition;
				attribute vec2 aTexCoord;
				uniform mat4 uMatrix;
				varying vec2 vTexCoord;
				
				void main (void) {
					
					vTexCoord = aTexCoord;
					gl_Position = uMatrix * vec4 (aVertexPosition, 0.0, 1.0);
					
				}
				
			";
			
			var fragmentSource = 
				
				#if (!desktop || rpi)
				"precision mediump float;" +
				#end
				"varying vec2 vTexCoord;
				uniform sampler2D uImage0;
				
				void main (void) {
					
					gl_FragColor = texture2D (uImage0, vTexCoord);
					
				}
				
			";
			
			glProgram = GLUtils.createProgram (vertexSource, fragmentSource);
			
			glVertexAttribute = gl.getAttribLocation (glProgram, "aVertexPosition");
			glTextureAttribute = gl.getAttribLocation (glProgram, "aTexCoord");
			glMatrixUniform = gl.getUniformLocation (glProgram, "uMatrix");
			glImageUniform = gl.getUniformLocation (glProgram, "uImage0");
			
		}
		
	}
	
	
	public static inline function render (tilemap:FlxIsoTilemap, renderSession:RenderSession):Void {
		
		if (tilemap.layers == null || tilemap.layers.length == 0) return;
		
		// TODO: Smarter matrix
		
		//glMatrix = Matrix4.createOrtho (-tilemap.__renderTransform.tx,
		//tilemap.stage.stageWidth - tilemap.__renderTransform.tx,
		//tilemap.stage.stageHeight - tilemap.__renderTransform.ty,
		//-tilemap.__renderTransform.ty, -1000, 1000);
		
		glMatrix = Matrix4.createOrtho ( -tilemap.viewportBounds.x, tilemap.viewportBounds.width - tilemap.viewportBounds.x, tilemap.viewportBounds.height - tilemap.viewportBounds.y, -tilemap.viewportBounds.y, -1000, 1000);
		
		renderSession.spriteBatch.finish ();
		
		renderSession.shaderManager.setShader (null);
		renderSession.blendModeManager.setBlendMode (null);
		
		var gl = renderSession.gl;
		
		initialize (gl);
		
		gl.useProgram (glProgram);
		
		gl.enableVertexAttribArray (glVertexAttribute);
		gl.enableVertexAttribArray (glTextureAttribute);
		
		gl.activeTexture (gl.TEXTURE0);
		
		#if (desktop && !rpi)
		gl.enable (gl.TEXTURE_2D);
		#end
		
		var tiles, count, bufferData, buffer, previousLength, offset, uvs, uv;
		var cacheTileID = -1, tileWidth = 0, tileHeight = 0;
		var tile, x, y, x2, y2;
		
		// TODO: Support tiles that are not the full tileset size
		
		for (layer in tilemap.layers) {
			
			var scroll:FlxPoint = FlxPoint.weak(Std.int(tilemap.cameraScroll.x), Std.int(tilemap.cameraScroll.y));
			
			if (layer.length == 0 || layer.tileset == null || layer.tileset.bitmapData == null || layer.viewportTiles == null) continue;
			
			gl.bindTexture (gl.TEXTURE_2D, layer.tileset.bitmapData.getTexture (gl));
			
			tiles = layer.viewportTiles;
			
			count = tiles.length;
			uvs = layer.tileset.__uvs;
			
			//Must reset bufferData or else scroll won't work.
			layer.__bufferData = null;
			bufferData = layer.__bufferData;
			
			if (bufferData == null || bufferData.length != count * 24) {
				
				previousLength = 0;
				
				if (bufferData == null) {
					
					bufferData = new Float32Array (count * 24);
					
				} else {
					
					previousLength = Std.int (bufferData.length / 24);
					
					var data = new Float32Array (count * 24);
					
					for (i in 0...bufferData.length) {
						
						data[i] = bufferData[i];
						
					}
					
					bufferData = data;
					
				}
				
				for (i in previousLength...count) {
					
					if (i > tiles.length - 1 || tiles[i].id > uvs.length - 1 || tiles[i].id == -1) continue;
					
					uv = uvs[tiles[i].id];
					
					if (uv == null) continue;
					
					x = uv.x;
					y = uv.y;
					x2 = uv.width;
					y2 = uv.height;
					
					offset = i * 24;
					
					bufferData[offset + 2] = x;
					bufferData[offset + 3] = y;
					bufferData[offset + 6] = x2;
					bufferData[offset + 7] = y;
					bufferData[offset + 10] = x;
					bufferData[offset + 11] = y2;
					
					bufferData[offset + 14] = x;
					bufferData[offset + 15] = y2;
					bufferData[offset + 18] = x2;
					bufferData[offset + 19] = y;
					bufferData[offset + 22] = x2;
					bufferData[offset + 23] = y2;
					
				}
				
				layer.__bufferData = bufferData;
			}
			
			if (layer.__buffer == null) {
				
				layer.__buffer = gl.createBuffer ();
				
			}
			
			gl.bindBuffer (gl.ARRAY_BUFFER, layer.__buffer);
			
			for (i in 0...count) {
				
				tile = tiles[i];
				
				if (tile == null) continue;
				
				if (tile.id != cacheTileID) {
					
					tileWidth = Std.int (layer.tileset.__rects[tile.id].width);
					tileHeight = Std.int (layer.tileset.__rects[tile.id].height);
					cacheTileID = tile.id;
				}
				
				offset = i * 24;
				
				// TODO: Use dirty flag on tiles?
				
				var matrix:flixel.math.FlxMatrix = new flixel.math.FlxMatrix();
				matrix.identity();
				
				//Translate to tile pivot
				matrix.translate(-tileWidth / 2, -80);
				
				//Apply transformations (scale, rotate, skew)
				//matrix.scale(tilemap.scale.x * tile.facing.x, tilemap.scale.y * tile.facing.y);
				matrix.scale(tilemap.scale.x, tilemap.scale.y);
				
				//Translate back from tile pivot
				matrix.translate(tileWidth / 2, 80);
				
				//Actual tile translation
				matrix.translate(tilemap.origin.x + tile.x + scroll.x, tilemap.origin.y + (tile.y - tile.z) + scroll.y);
				
				x = matrix.tx;
				y = matrix.ty;
				x2 = x + tileWidth;
				y2 = y + tileHeight;
				
				//Triangle A
				bufferData[offset + 0] = x;
				bufferData[offset + 1] = y;
				bufferData[offset + 4] = x2;
				bufferData[offset + 5] = y;
				bufferData[offset + 8] = x;
				bufferData[offset + 9] = y2;
				
				//Triangle B
				bufferData[offset + 12] = x;
				bufferData[offset + 13] = y2;
				bufferData[offset + 16] = x2;
				bufferData[offset + 17] = y;
				bufferData[offset + 20] = x2;
				bufferData[offset + 21] = y2;
			}
			
			gl.bufferData (gl.ARRAY_BUFFER, bufferData, gl.DYNAMIC_DRAW);
			
			gl.vertexAttribPointer (glVertexAttribute, 2, gl.FLOAT, false, 4 * Float32Array.BYTES_PER_ELEMENT, 0);
			gl.vertexAttribPointer (glTextureAttribute, 2, gl.FLOAT, false, 4 * Float32Array.BYTES_PER_ELEMENT, 2 * Float32Array.BYTES_PER_ELEMENT);
			
			gl.uniformMatrix4fv (glMatrixUniform, false, glMatrix);
			gl.uniform1i (glImageUniform, 0);
			
			gl.drawArrays (gl.TRIANGLES, 0, tiles.length * 6);
		}
		
		gl.bindBuffer (gl.ARRAY_BUFFER, null);
		gl.bindTexture (gl.TEXTURE_2D, null);
		
		#if (desktop && !rpi)
		gl.disable (gl.TEXTURE_2D);
		#end
		
		gl.disableVertexAttribArray (glVertexAttribute);
		gl.disableVertexAttribArray (glTextureAttribute);
		
		gl.useProgram (null);
	}
	
	
}