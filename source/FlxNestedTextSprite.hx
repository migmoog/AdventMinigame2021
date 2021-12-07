package;

import flixel.util.FlxSpriteUtil;
import flixel.addons.display.FlxNestedSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.Assets;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.AssetType;
import flixel.FlxSprite;

/**
    Class is from Markl on the haxe discord, thanks!
**/
class FlxNestedTextSprite extends FlxNestedSprite
{
	public var text:TextField;

	private var fontPath:String;
	private var message:String;
	private var textBoxAlign:String;
	private var size:Int;
	private var textColor:FlxColor;

	public function new(message:String, fontPath:String, size:Int = 10, width:Int = 0, textColor:FlxColor = FlxColor.WHITE, bgColor = -1,
			textBoxAlign:String = "left", leading:Int, padding:Int = 0, borderColor:FlxColor = null, borderThickness:Int = 1)
	{
		super();

		this.message = message;
		this.fontPath = fontPath;
		this.size = size;
		this.textColor = textColor;
		this.textBoxAlign = textBoxAlign;

		var newFontName:String = fontPath;
		if (Assets.exists(fontPath, AssetType.FONT))
		{
			newFontName = Assets.getFont(fontPath).fontName;
		}
		text = new TextField();
		text.text = message;
		text.backgroundColor = bgColor != -1 ? bgColor : 0x0;
		text.background = bgColor != -1;
		text.embedFonts = true;
		text.selectable = false;
		text.sharpness = 300;
		var format = new TextFormat(newFontName, size, textColor.to24Bit(), false, false, false, "", "", textBoxAlign, null, null, null, leading);
		text.setTextFormat(format);

		if (width <= 0)
		{
			width = Std.int(text.textWidth + 1);
		}
		width += padding;

		var bmpData = new openfl.display.BitmapData(Std.int(width), Std.int(text.textHeight), true, 0x00000000);

		var matrix = new openfl.geom.Matrix();
		matrix.translate(width / 2 - text.width / 2, 0);
		bmpData.draw(text, matrix);
		loadGraphic(bmpData);
		if (borderColor != null)
		{
			FlxSpriteUtil.drawRect(this, borderThickness, borderThickness, width - borderThickness * 2, height - borderThickness * 2, FlxColor.TRANSPARENT,
				{color: borderColor, thickness: borderThickness});
		}
	}

	public function getActualHeight():Float
	{
		return text.textHeight;
	}

	public function getActualWidth():Float
	{
		return text.textWidth;
	}

	public static function copyFlxTextToSprite(destinationSprite:FlxSprite, sourceText:FlxText):Void
	{
		sourceText.update(0);
		sourceText.drawFrame(true);
		destinationSprite.loadGraphicFromSprite(sourceText);
	}
}
