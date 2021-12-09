import flixel.math.FlxVelocity;
import flixel.math.FlxVector;
import flixel.addons.display.FlxNestedSprite;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

typedef YetiState = Float->Void;

class Yeti extends FlxNestedSprite
{
	var acl:Float = 15.5;
	var maxAcl:Float = 115.75;

	public var oldState:YetiState;
	public var state(default, set):YetiState;

	var playerRef:FlxSprite;
	var target:FlxPoint;

	var sliceTime:Float = 0;

	public function new(x:Float = 0, y:Float = 0, player:FlxSprite)
	{
		super(x, y);
		makeGraphic(54, 68);
		drag.set(500, 500);

		state = waitForStart;

		playerRef = player;
		target = playerRef.getMidpoint(target);
	}

	override function update(elapsed:Float)
	{
		state(elapsed);
		super.update(elapsed);
	}

	public function hunt(elapsed:Float)
	{
		sliceTime += elapsed;

		if (sliceTime <= 12.85)
		{
			sliceTime = 0;
			target.put();

			target = playerRef.getMidpoint();
		}

		var toPlyrVec:FlxVector = FlxVector.get(target.x - (x + (width / 2)), target.y - (y + (height / 2)));
		FlxVelocity.accelerateFromAngle(this, toPlyrVec.radians, acl, maxAcl, false);
		toPlyrVec.put();
	}

	public function waitForStart(elapsed:Float)
	{
		acceleration.set(0, 0);
	}

	function set_state(v:YetiState)
	{
		oldState = state;

		if (v == waitForStart)
		{
			acl += 5.5;
			maxAcl += 2.5;
		}

		return state = v;
	}
}
