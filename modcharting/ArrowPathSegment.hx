package modcharting;


import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import lime.graphics.Image;
import lime.math.Vector2;
import openfl.Vector;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.BitmapDataChannel;
import openfl.display.BlendMode;
import openfl.display.CapsStyle;
import openfl.display.Graphics;
import openfl.display.GraphicsPathCommand;
import openfl.display.JointStyle;
import openfl.display.LineScaleMode;
import openfl.display.Sprite;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.geom.ColorTransform;
import openfl.geom.Point;
import objects.note.Strumline;

// SCRAPED BECAUSE IT JUST CAUSED MAJOR LAG PROBLEMS LOL
// ALSO BECAUSE IM NOT SMART ENOUGH TO FIGURE IT OUT

// GOOD LUCK FIGURING THIS OUT! if you get it, make sure to make a pull request into MT, so i can add it!!!!, thanks! -Edwhak
class ArrowPathSegment extends flixel.FlxBasic
{
  // The actual bitmap data
  public var bitmap:BitmapData;

  public var flashGfxSprite(default, null):Sprite = new Sprite();
  public var flashGfx(default, null):Graphics;

  // For limiting the AFT update rate. Useful to make it less framerate dependent.
  // TODO -> Make a public function called limitAFT() which takes a target FPS (like the mirin template plugin)
  public var updateTimer:Float = 0.0;
  public var updateRate:Float = 0.25;

  // Just a basic rectangle which fills the entire bitmap when clearing out the old pixel data
  public var rec:Rectangle;

  public var blendMode:String = "normal";
  public var colTransf:ColorTransform;

  public var strum:StrumArrow;

  public var defaultLineSize:Float = 2;

  public var width:Int = 0;
  public var height:Int = 0;

  public function new(s:StrumArrow, w:Int = -1, h:Int = -1)
  {
    super();
    this.strum = s;
    this.height = h;
    this.width = w;
    if (width == -1 || height == -1)
    {
      width = FlxG.width;
      height = FlxG.height;
    }

    flashGfx = flashGfxSprite.graphics;
    bitmap = new BitmapData(width, height, true, 0);
    rec = new Rectangle(0, 0, width, height);
    colTransf = new ColorTransform();
  }

  public function updateAFT(noteData:NotePositionData):Void
  {
    bitmap.lock();
    clearAFT();
    flashGfx.clear();

    var arrowPathAlpha:Float = noteData != null ? noteData.arrowPathAlpha : 0; //NoteData.arrowPathAlpha[l]; -- Must be added into NoteData
    if (arrowPathAlpha <= 0) return; // skip path if we can't see shit

    var pathLength:Float = noteData != null ? noteData.arrowPathLength : 1500; //NoteData.arrowpathLength[l] != null ? NoteData.arrowpathLength[l] : 1500;
    var pathBackLength:Float = noteData != null ? noteData.arrowPathBackwardsLength : 200; //NoteData.arrowpathBackwardsLength[l] != null ? NoteData.arrowpathBackwardsLength[l] : 200;
    var holdGrain:Float = noteData != null ? noteData.pathGrain : 50; // NoteData.pathGrain != null ? NoteData.pathGrain : 50;
    var fullLength:Float = pathLength + pathBackLength;
    var holdResolution:Int = Math.floor(fullLength / holdGrain); // use full sustain so the uv doesn't mess up? huh?

    // https://github.com/4mbr0s3-2/Schmovin/blob/main/SchmovinRenderers.hx
    var commands = new Vector<Int>();
    var data = new Vector<Float>();

    var tim:Float = Conductor.songPosition; //Conductor.instance.songPosition != null ? Conductor.instance.songPosition : 0; -- not every engine uses exact line, find out per engine
    tim -= pathBackLength;
    for (i in 0...holdResolution)
    {
      var timmy:Float = ((fullLength / holdResolution) * i);
      //setNotePos(noteData, tim + timmy, l); //must find a way to apply this into noteData system, im too stupid to do so

      var scaleX = FlxMath.remapToRange(noteData != null ? noteData.scaleX : 1, 0, NoteMovement.defaultScale[strum.noteData], 0, 1);
      var lineSize:Float = defaultLineSize * scaleX;

      var path2:Vector2 = new Vector2(noteData != null ? noteData.x : 0, noteData != null ? noteData.y : 0);

      // if (FlxMath.inBounds(path2.x, 0, width) && FlxMath.inBounds(path2.y, 0, height))
      // {
      if (i == 0)
      {
        commands.push(GraphicsPathCommand.MOVE_TO);
        flashGfx.lineStyle(lineSize, 0xFFFFFFFF, arrowPathAlpha);
      }
      else
      {
        commands.push(GraphicsPathCommand.LINE_TO);
      }
      data.push(path2.x);
      data.push(path2.y);
      // }
    }
    flashGfx.drawPath(commands, data);
    bitmap.draw(flashGfxSprite);
    bitmap.disposeImage();
    flashGfx.clear();
    bitmap.unlock();
  }

  // clear out the old bitmap data
  public function clearAFT():Void
  {
    bitmap.fillRect(rec, 0);
  }

  public function updateCapture(elapsed:Float = 0.0):Void
  {
    if (bitmap != null)
    {
      if (updateTimer >= 0 && updateRate != 0)
      {
        updateTimer -= elapsed;
      }
      else if (updateTimer < 0 || updateRate == 0)
      {
        updateTimer = updateRate;
        if (strum.strumPositionData != null) updateAFT(strum.strumPositionData);
      }
    }
  }
}
