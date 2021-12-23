import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxState;

class Lose extends FlxState 
{
    var lostTxt:FlxText;
    
    override function create() 
    {
        lostTxt = new FlxText(0, 0, 0, "YOU WERE DISEMBOWELED BY THE YETI\n(click to try again)", 16);
        lostTxt.alignment = CENTER;
        lostTxt.color = FlxColor.LIME;
        lostTxt.screenCenter();
        add(lostTxt);
        
        super.create();
    }

    override function update(elapsed:Float) 
    {
        if (FlxG.mouse.justPressed)
            FlxG.switchState(new PlayState());
        
        super.update(elapsed);
    }
}