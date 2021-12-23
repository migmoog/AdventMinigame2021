package;

import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
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

class PlayState extends FlxState
{
	var yeti:Yeti;

	// Player stuff
	static inline final SPEED:Float = 100.5;
	var player:FlxSprite;


	var board:FlxNestedSprite;
	var spots:FlxTypedGroup<Light>;

	var tileSeq:Array<LightColor>;
	var allColors:Array<LightColor> = [RED, BLUE, GREEN];
	var seqMax:Int = 2;
	var seqTimer:FlxTimer = new FlxTimer();

	var score:Int = 0;
	var scoreText:FlxText;
	
	var lightsShown:Int = 0;
	var lightShowTime:Float = 0.5;

	var iSpot:Int = 0;

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
		player.maxVelocity.set(125, 125);
		player.drag.set(375, 375);
		add(player);

		yeti = new Yeti(0, 0, player);
		yeti.screenCenter();
		add(yeti);

		scoreText = new FlxText(FlxG.width - 16, 0, 0, Std.string(score));
		add(scoreText);

		pickSequence();

		super.create();
	}

	override function update(elapsed:Float)
	{
		FlxSpriteUtil.bound(yeti, 0, FlxG.width, 0, FlxG.height);
		FlxSpriteUtil.bound(player, 0, FlxG.width, 0, FlxG.height);

		movePlayer();
		scoreText.text = Std.string(score);

		FlxG.overlap(player, spots, executeSpotOverlap, processSpotOverlap);
		FlxG.overlap(player, yeti, executeYetiKill, processYetiKill);

		super.update(elapsed);
	}

	function executeYetiKill(player:FlxSprite, y:Yeti) 
	{
		FlxG.switchState(new Lose());
	}

	function processYetiKill(player:FlxSprite, y:Yeti):Bool 
	{
		return yeti.state == yeti.hunt;
	}

	function executeSpotOverlap(p:FlxSprite, s:Light)
	{
		s.destroy();
		iSpot++;

		if (spots.getFirstAlive() == null)
		{
			// yeti.state = yeti.waitForStart;
			yeti.animation.play('freeze', true);
			score++;
			boardReturn();
		}
	}

	function processSpotOverlap(p:FlxSprite, s:Light):Bool
	{
		if (s.clr == tileSeq[iSpot] && s.index == iSpot) 
		{
			return true;
		} 
		else 
		{
			if (seqMax > 0)
				seqMax--;
			
			boardReturn();
			for (i in spots)
				i.destroy();

			return false;
		}
	}

	function pickSequence()
	{
		FlxG.random.shuffle(allColors);
		tileSeq = [];

		for (i in 0...seqMax++)
			tileSeq.push(FlxG.random.getObject(allColors));

		yeti.animation.play('freeze', true);
		playBoard();
	}

	function playBoard(?_:FlxTimer)
	{
		yeti.state = yeti.waitForStart;
		// yeti.animation.play('freeze', true);

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
					FlxTween.tween(board, {y: -board.width}, 1.75, {
						onComplete: (_) -> boardFinished(),
						ease: FlxEase.elasticIn
					});
				});
			}
		});

		lightsShown++;
	}

	function boardFinished()
	{
		var dupls:Int = 0;
		// VISUAL INDEX BUG: originates from the beginning of the loop because prev at 0 is tileSeq[0] 
		var prevClr:LightColor = tileSeq[0];

		var colorInsts = [RED=>0, BLUE=>0, GREEN=>0];

		for (i in 0...tileSeq.length)
		{
			colorInsts[tileSeq[i]]++;
			if (i > 0 && tileSeq[i] == prevClr)
				dupls++;
			else
				dupls = 0;

			var visualIndex:Null<Int> = {
				if (dupls != 0)
					colorInsts[tileSeq[i]]
				else if (dupls == 0 && colorInsts[tileSeq[i]] <= 1)
					null
				else
					colorInsts[tileSeq[i]];
			};
			
			var spt = new Light(
				(FlxG.random.int(0, 15) * 30), 
				(FlxG.random.int(0, 8) * 30), 
				i, 
				visualIndex
			);

			while (spt.overlaps(player))
				spt.setPosition((FlxG.random.int(0, 15) * 30), (FlxG.random.int(0, 8) * 30));

			spt.color = spt.clr = tileSeq[i];
			spots.add(spt);
			prevClr = tileSeq[i];
		}

		// yeti.state = yeti.hunt;
		yeti.animation.play('thaw');
	}

	function boardReturn() 
	{
		iSpot = 0;
		FlxTween.tween(board, {y: 0}, 0.8, {
			onComplete: (_) -> pickSequence(),
			ease: FlxEase.elasticInOut
		});
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
			player.acceleration.set(SPEED, 0);
			player.acceleration.rotate(FlxPoint.weak(0, 0), newAngle);
		}
		else
		{
			player.acceleration.set(0, 0);
		}
	}
}

class Light extends FlxNestedSprite
{
	public var index:Int;
	public var clr:LightColor = RED;

	var txt:FlxNestedTextSprite;

	public function new(x:Float, y:Float, ?index:Int, ?visualIndex:Int)
	{
		super(x, y, 'assets/images/spot.png');
		this.index = index;
		setSize(16, 16);
		centerOffsets(true);

		// TODO: wait for markl's answer on the path
		if (visualIndex != null)
		{
			txt = new FlxNestedTextSprite(
				Std.string(visualIndex), 
				FlxAssets.FONT_DEFAULT, 
				10, 
				0, 
				FlxColor.BLACK, 
				-1, 
				"center", 
				0
			);

			add(txt);
			txt.relativeX = (graphic.width / 2) - (txt.relativeX + txt.graphic.width / 2);
			txt.relativeY = (graphic.height / 2) - (txt.relativeY + txt.graphic.height / 2);
		}
	}
}

enum abstract LightColor(FlxColor) to FlxColor
{
	var RED = FlxColor.RED;
	var BLUE = FlxColor.BLUE;
	var GREEN = FlxColor.GREEN;
}
