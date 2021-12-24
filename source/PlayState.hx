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
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;

class PlayState extends FlxState
{
	var yeti:Yeti;

	// Player stuff
	// static inline final SPEED:Float = 100.5;

	var player:Player;

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
			var s = new Display(0, 0, 'assets/images/circle_display.png');
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

		/* player = new FlxSprite(0, 0).makeGraphic(16, 16, FlxColor.BLUE);
		player.maxVelocity.set(125, 125);
		player.drag.set(375, 375); */
		player = new Player();
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
		s.allowCollisions = NONE;
		s.animation.finishCallback = (n) ->
		{
			// can't destroy these guys, causes a crash
			if (n == 'shatter')
				s.kill();
			if (spots.getFirstAlive() == null)
			{
				// spots.forEachExists((l) -> l.destroy());
				// yeti.state = yeti.waitForStart;

				yeti.animation.play('freeze', true);
				score++;
				boardReturn(true);
			}
		}
		s.animation.play('shatter');
		iSpot++;
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

			boardReturn(false);
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

		playBoard();
	}

	function playBoard(?_:FlxTimer)
	{
		for (light in board.children)
		{
			var l:Display = cast light;
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
		yeti.animation.play('thaw', true);
		var dupls:Int = 0;
		var prevClr:LightColor = tileSeq[0];

		var colorInsts = [RED => 0, BLUE => 0, GREEN => 0];

		for (i in 0...tileSeq.length)
		{
			colorInsts[tileSeq[i]]++;
			if (i > 0 && tileSeq[i] == prevClr)
				dupls++;
			else
				dupls = 0;

			var visualIndex:Null<Int> =
				{
					if (dupls != 0)
						colorInsts[tileSeq[i]]
					else if (dupls == 0 && colorInsts[tileSeq[i]] <= 1)
						null
					else
						colorInsts[tileSeq[i]];
				};

			var spt = new Light((FlxG.random.int(0, 15) * 30), (FlxG.random.int(0, 8) * 30), i, visualIndex);

			while (spt.overlaps(player))
				spt.setPosition((FlxG.random.int(0, 15) * 30), (FlxG.random.int(0, 8) * 30));

			spt.color = spt.clr = tileSeq[i];
			spots.add(spt);
			// TODO: switch to yeti starts ice instead of vice-versa
			// if (i == tileSeq.length - 1)
				// spt.animation.finishCallback = (_) -> yeti.animation.play('thaw');
			spt.animation.play('emerge');
			prevClr = tileSeq[i];
		}
	}

	function boardReturn(success:Bool)
	{
		if (success)
			yeti.state = yeti.waitForStart;
		
		iSpot = 0;
		FlxTween.tween(board, {y: 0}, 0.8, {
			onComplete: (_) -> pickSequence(),
			ease: FlxEase.elasticInOut
		});
	}
}

class Display extends FlxNestedSprite
{
	public var clr:LightColor;
}

class Light extends FlxNestedSprite
{
	public var index:Int;
	public var clr:LightColor;

	var txt:FlxNestedTextSprite;

	public function new(x:Float, y:Float, ?index:Int, ?visualIndex:Int)
	{
		super(x, y);
		loadGraphic('assets/images/icicle.png', true, 30, 30);
		animation.add('emerge', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 15, false);
		animation.add('shatter', [10, 11, 12, 13, 14], 15, false);
		this.index = index;
		setSize(16, 16);
		centerOffsets(true);

		if (visualIndex != null)
		{
			txt = new FlxNestedTextSprite(Std.string(visualIndex), FlxAssets.FONT_DEFAULT, 10, 0, FlxColor.WHITE, -1, "center", 0);

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
