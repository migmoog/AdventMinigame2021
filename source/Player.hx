import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class Player extends FlxSprite {
	static inline final SPEED:Float = 100.5;
    
    public function new(x:Float = 0, y:Float = 0) 
    {
        super(x, y);
		makeGraphic(16, 16, FlxColor.BLUE);
		maxVelocity.set(125, 125);
		drag.set(375, 375);
    }

    override function update(elapsed:Float) 
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

			velocity.set(SPEED, 0);
			velocity.rotate(FlxPoint.weak(0, 0), newAngle);
			acceleration.set(SPEED, 0);
			acceleration.rotate(FlxPoint.weak(0, 0), newAngle);
		}
		else
		{
			acceleration.set(0, 0);
		}
        super.update(elapsed);
    }
}