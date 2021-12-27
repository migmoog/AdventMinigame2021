package;

import flixel.system.FlxSound;
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
	var loseJingle:FlxSound = new FlxSound();

	var player:Player;

	var board:FlxNestedSprite;
	var spots:FlxTypedGroup<Icicle>;

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
		if (FlxG.sound.music == null)
			FlxG.sound.playMusic('assets/music/play_theme.mp3', 0.35);

		loseJingle.loadStream(AssetPaths.lose_jingle__mp3, false, false, () -> {
			FlxG.switchState(new Lose());
		});

		var bg = new FlxSprite('assets/images/bg.png');
		add(bg);
		
		spots = new FlxTypedGroup<Icicle>();
		add(spots);
		
		player = new Player();
		add(player);
		
		yeti = new Yeti(0, 0, player);
		yeti.screenCenter();
		add(yeti);

		board = new FlxNestedSprite(0, 0, 'assets/images/board.png');
		board.screenCenter(X);
		for (i in 0...3)
		{
			var s = new Display(
				switch i {
					case 0: RED;
					case 1: BLUE;
					case 2: GREEN;
					default: RED;
				}
			);
			s.relativeX = switch i {
				case 0: 10;
				case 1: 24;
				case 2: 38;
				default: 0;
			};
			s.relativeY = 10;

			board.add(s);
			s.visible = false;
		}
		add(board);

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
		FlxG.overlap(player, yeti, executeYetiKill, function(p:Player, y:Yeti) {return y.state == y.hunt;});

		super.update(elapsed);
	}

	function executeYetiKill(player:Player, y:Yeti)
	{
		if (!loseJingle.playing)
		{
			FlxG.sound.music.stop();
			
			forEach((child) -> {
				child.active = false;
			}, true);
			loseJingle.play();
		}
	}

	function executeSpotOverlap(p:Player, s:Icicle)
	{
		s.allowCollisions = NONE;
		s.animation.finishCallback = (n) ->
		{
			if (n == 'shatter')
				s.kill();
			if (spots.getFirstAlive() == null)
			{
				FlxG.sound.play('assets/sounds/win_jingle.mp3', 0.5);
				yeti.animation.play('freeze', true);
				score++;
				returnBoard();
			}
		}
		s.animation.play('shatter');
		iSpot++;
	}

	function processSpotOverlap(p:Player, s:Icicle):Bool
	{
		if (s.clr == tileSeq[iSpot] && s.index == iSpot)
		{
			return true;
		}
		else
		{
			if (seqMax > 1)
				seqMax--;

			returnBoard();
			for (i in spots)
				i.destroy();

			return false;
		}
	}

	function pickSequence()
	{
		FlxG.random.shuffle(allColors);
		tileSeq = [];

		for (i in 0...seqMax)
			tileSeq.push(FlxG.random.getObject(allColors));
		
		if (seqMax < 26)
			seqMax++;
			
		playBoard();
	}

	function playBoard(?_:FlxTimer)
	{
		for (light in board.children)
		{
			var l:Display = cast light;
			if (l.clr == tileSeq[lightsShown] && !light.visible)
			{
				l.sf.play();
				l.visible = true;
				break;
			}
		}

		seqTimer.start(lightShowTime, (_) ->
		{
			for (i in board.children)
				if (i.visible)
					i.visible = false;

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

			var vi:Null<Int> =
			{
				if (dupls != 0)
					colorInsts[tileSeq[i]]
				else if (dupls == 0 && colorInsts[tileSeq[i]] <= 1)
					null
				else
					colorInsts[tileSeq[i]];
			};

			// I'm just gonna keep it this way because it's too much of a pain in the ass to have FlxNestedTexts
			var spt = new Icicle((FlxG.random.int(0, 15) * 30), (FlxG.random.int(0, 8) * 30), i, vi);

			while (spt.overlaps(player))
				spt.setPosition((FlxG.random.int(0, 15) * 30), (FlxG.random.int(0, 8) * 30));

			spt.color = spt.clr = tileSeq[i];
			spots.add(spt);
			spt.animation.play('emerge');
			prevClr = tileSeq[i];
		}
	}

	function returnBoard()
	{
		if (spots.getFirstAlive() == null)
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
	public var sf:FlxSound;

	public function new(clr:LightColor) {
		super(0, 0, 'assets/images/circle_display.png');
		
		color = this.clr = clr;

		sf = new FlxSound().loadStream('assets/sounds/${
			switch clr {
				case RED:'red';
				case BLUE:'blue';
				case GREEN:'green';
			}
		}.mp3');
	}
}

class Icicle extends FlxNestedSprite
{
	public var index:Int;
	public var clr:LightColor;
	public var used:Bool = false;

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
			txt.relativeX = (width / 2) - (txt.width / 2);
			txt.relativeY = (height / 2) - (txt.height / 2);
			add(txt);
		}
	}
}

enum abstract LightColor(FlxColor) to FlxColor
{
	var RED = FlxColor.RED;
	var BLUE = FlxColor.BLUE;
	var GREEN = FlxColor.GREEN;
}
