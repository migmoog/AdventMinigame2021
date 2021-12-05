package;

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
			var s = new Light(0, 0, 'assets/images/spot.png');
			s.color = s.clr = switch i
			{
				case 0: RED;
				case 1: BLUE;
				case 2: GREEN;
				default: RED;
			};
			s.relativeX = i * (board.width / 3);
			s.relativeY = board.width / 4;
			
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
		playBoard();

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

	function executeSpotOverlap(p:FlxSprite, s:Light) {
		s.destroy();
		currentSpotIndex++;

		trace('members remaining in spots: ${spots.members.length}');
		if (spots.getFirstAlive() == null) {
			pickSequence();
			playBoard();
		}
	}

	function processSpotOverlap(p:FlxSprite, s:Light):Bool {
		return s.clr == tileSeq[currentSpotIndex];
	}

	function pickSequence()
	{
		tileSeq = [];

		for (i in 0...seqMax++)
			tileSeq.push(FlxG.random.getObject([LightColor.RED, LightColor.BLUE, LightColor.GREEN]));
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
				trace("Found the light");

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
			{
				seqTimer.start(lightShowTime, playBoard);
			}
			else
			{
				seqTimer.start(lightShowTime, (_) ->
				{
					for (i in board.children)
						i.visible = false;
					lightsShown = 0;

					lightShowTime -= 0.05;
					boardFinished();
					trace("finished");
				});
			}
		});
		lightsShown++;
	}

	function boardFinished()
	{
		// TODO: make this fn set the tilemap tiles and activate the yeti
		trace(tileSeq[currentSpotIndex]);
		
		for (i in 0...tileSeq.length)
		{
			var spt = new Light(
				FlxG.random.int(0, 14) * 32,
				FlxG.random.int(0, 7) * 32,
				'assets/images/spot.png'
			);
			spt.color = spt.clr = tileSeq[i];
			spots.add(spt);
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
	public var clr:LightColor;
}

enum abstract LightColor(FlxColor) to FlxColor
{
	var RED = FlxColor.RED;
	var BLUE = FlxColor.BLUE;
	var GREEN = FlxColor.GREEN;
}