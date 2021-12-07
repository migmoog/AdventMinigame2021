package;

import flixel.system.FlxAssets;
import FlxNestedTextSprite;
import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxNestedSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;

/**
	IDEA: Simon says style thing instead of pacman clone
	Spots appear around teh room you gotta run to, jump on top 


	BIG SCREEN that shows order of color spots to walk on across the room
	YETI slowly accelerates after you making you freak the fuck out
	If you get order wrong, yeti fucking kills you    

	TODO: for duplicate nums, make the text appear only if it's a dupe. that maintains the memory aspect of the 
	"simon says"-ing 
**/
class PlayState extends FlxState
{
	var yeti:Yeti;

	// Player stuff
	var player:FlxSprite;

	static inline final SPEED:Float = 100.5;

	// board that shows the sequence of lights
	var board:FlxNestedSprite;
	var currentFloor:FlxColor;
	// tilemap
	var spots:FlxTypedGroup<Light>;

	var tileSeq:Array<LightColor>;
	var allColors:Array<LightColor> = [RED, BLUE, GREEN];
	var seqMax:Int = 3;
	var seqTimer:FlxTimer = new FlxTimer();

	var score:Int = 0;

	static private var lightsShown:Int = 0;
	static private var lightShowTime:Float = 0.5;
	var currentSpotIndex:Int = 0;

	override function create()
	{
		board = new FlxNestedSprite(0, 0, 'assets/images/board.png');
		board.screenCenter(X);
		for (i in 0...3)
		{
			var s = new Light(0, 0);
			s.color = s.clr = switch i
			{
				case 0: RED;
				case 1: BLUE;
				case 2: GREEN;
				default: RED;
			};
			s.relativeX = i * (board.width / 3);
			s.relativeY = board.width / 8;
			
			board.add(s);
			s.visible = false;
		}
		add(board);

		spots = new FlxTypedGroup<Light>();
		add(spots);

		player = new FlxSprite(0, 0).makeGraphic(16, 16, FlxColor.BLUE);
		player.drag.set(375, 375);
		add(player);

		yeti = new Yeti(0, 0, player);
		yeti.screenCenter();
		add(yeti);

		pickSequence();

		super.create();
	}

	override function update(elapsed:Float)
	{
		FlxSpriteUtil.bound(yeti, 0, FlxG.width, 0, FlxG.height);
		FlxSpriteUtil.bound(player, 0, FlxG.width, 0, FlxG.height);

		movePlayer();

		if (spots.members.length > 0) {
			FlxG.overlap(player, spots, executeSpotOverlap, processSpotOverlap);
		}

		super.update(elapsed);
	}

	function executeSpotOverlap(p:FlxSprite, s:Light)
	{
		s.destroy();
		currentSpotIndex++;

		if (spots.getFirstAlive() == null)
		{
			pickSequence();
		}
	}

	function processSpotOverlap(p:FlxSprite, s:Light):Bool
	{
		return s.clr == tileSeq[currentSpotIndex] && s.index == currentSpotIndex;
	}

	function pickSequence()
	{
		tileSeq = [];

		for (i in 0...seqMax++)
			tileSeq.push(FlxG.random.getObject(allColors));

		playBoard();
	}

	function playBoard(?_:FlxTimer)
	{
		currentSpotIndex = 0;
		yeti.state = yeti.waitForStart;

		for (light in board.children)
		{
			var l:Light = cast light;
			if (l.clr == tileSeq[lightsShown] && !light.visible)
			{
				light.visible = true;
				break;
			}
		}

		seqTimer.start(lightShowTime, (_) ->
		{
			for (i in board.children)
			{
				if (i.visible)
					i.visible = false;
			}

			if (lightsShown < tileSeq.length)
				seqTimer.start(lightShowTime, playBoard);
			else
			{
				seqTimer.start(lightShowTime, (_) ->
				{
					for (i in board.children)
						i.visible = false;
					lightsShown = 0;

					lightShowTime -= 0.05;
					boardFinished();
				});
			}
		});
		lightsShown++;
	}

	function boardFinished()
	{
		var duplicateColors:Int = 0;
		var tempClr:LightColor = tileSeq[0];
		for (i in 0...tileSeq.length)
		{
			if (i != 0 && tileSeq[i] == tempClr)
				trace(duplicateColors++); 
			
			var spt = new Light(
				FlxG.random.int(0, 14) * 32,
				FlxG.random.int(0, 7) * 32,
				i
			);

			if (duplicateColors <= 1)
			{
				spt.color = spt.clr = tileSeq[i];
			}
			else
			{
				// FIXME won't brighten colors, probably need new design
				spt.clr = tileSeq[i];
				var asColor:FlxColor = cast spt.clr;
				spt.color = FlxColor.fromHSB(asColor.hue, asColor.saturation - (1-(i*.35)), (10 - i) * 0.35, 1);
			}
			spots.add(spt);

			tempClr = tileSeq[i];
		}

		yeti.state = yeti.hunt;
	}

	function movePlayer()
	{
		var left:Bool = FlxG.keys.anyPressed([A, LEFT]);
		var right:Bool = FlxG.keys.anyPressed([D, RIGHT]);
		var up:Bool = FlxG.keys.anyPressed([W, UP]);
		var down:Bool = FlxG.keys.anyPressed([S, DOWN]);

		if (up && down)
			up = down = false;
		if (left && right)
			left = right = false;

		if (up || down || left || right)
		{
			var newAngle:Float = 0;
			if (up)
			{
				newAngle = -90;
				if (left)
					newAngle -= 45;
				else if (right)
					newAngle += 45;
			}
			else if (down)
			{
				newAngle = 90;
				if (left)
					newAngle += 45;
				else if (right)
					newAngle -= 45;
			}
			else if (left)
				newAngle = 180;
			else if (right)
				newAngle = 0;

			player.velocity.set(SPEED, 0);
			player.velocity.rotate(FlxPoint.weak(0, 0), newAngle);
		}
	}
}

class Light extends FlxNestedSprite
{
	public var index:Int;
	public var clr:LightColor = RED;

	var txt:FlxNestedTextSprite;
	
	public function new(x:Float, y:Float, ?index:Int)
	{
		super(x, y, 'assets/images/spot.png');
		this.index = index;

		// TODO: wait for markl's answer on the path
		if (index != null) {
			txt = new FlxNestedTextSprite(Std.string(index), FlxAssets.FONT_DEFAULT, 10, 0, FlxColor.BLACK, -1, "center", 0);
			add(txt);
			txt.relativeX = (width / 2) - (txt.width / 2);
			txt.relativeY = (height / 2) - (txt.height / 2);
		}
	}

} 

enum abstract LightColor(FlxColor) to FlxColor
{
	var RED = FlxColor.RED;
	var BLUE = FlxColor.BLUE;
	var GREEN = FlxColor.GREEN;
}