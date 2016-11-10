package ;

import AssetPaths;
import coffeegames.mapgen.MapGenerator;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import iso.FlxIsoTilemap;
import lime.system.BackgroundWorker;

class MenuState extends FlxState
{
	var selectionIndicator:FlxText;
	var buttonTop:Int = 30;
	var heighDifference:Int = 40;
	var selection:Int = 0;
	var buttons:Array<FlxButton> = new Array<FlxButton>();
  
	override public function create():Void
	{
		super.create();
		
		var csvButton:FlxButton = new FlxButton(FlxG.width / 2 - 40, buttonTop, "Csv Map", loadPlayState.bind(0));
		add(csvButton);
		buttonTop += heighDifference;
		buttons.push(csvButton);
		
		var mapGenButton:FlxButton = new FlxButton(FlxG.width / 2 - 40, buttonTop, "Map Generator", loadPlayState.bind(1));
		add(mapGenButton);
		buttonTop += heighDifference;
		buttons.push(mapGenButton);
		
		var tiledButton:FlxButton = new FlxButton(FlxG.width / 2 - 40, buttonTop, "Tiled Map", loadPlayState.bind(2));
		add(tiledButton);
		buttonTop += heighDifference;
		buttons.push(tiledButton);
		
		selectionIndicator = new FlxText(FlxG.width / 2 - 60, buttons[selection].y + 3, 20, '->', 8);
		selectionIndicator.alignment = FlxTextAlign.CENTER;
		add(selectionIndicator);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);    
		handleKeyboardInput(elapsed);
	}

	private function loadPlayState(nr:Int):Void
	{
		switch (nr) {
			case 0:
				FlxG.switchState(new CsvState());
			case 1:
				FlxG.switchState(new MapGeneratorState());
			case 2:
				FlxG.switchState(new TiledState());
		}
	}
  
	function handleKeyboardInput(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ENTER) {
			loadPlayState(selection);
		}
		
		if (FlxG.keys.justPressed.UP) {
			if (selection == 0) {
				selection = 2;
			} else {
				selection--;
			}
			selectionIndicator.y = buttons[selection].y + 3;
		} 
		
		if (FlxG.keys.justPressed.DOWN) {
			if (selection == 2) {
				selection = 0;
			} else {
				selection++;
			}
			selectionIndicator.y = buttons[selection].y + 3;
		}
	}
}
