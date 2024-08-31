package modcharting;

import flixel.math.FlxMath;
import flixel.math.FlxAngle;
import lime.math.Vector2;
import openfl.geom.Vector3D;
import flixel.FlxG;

import states.PlayState;
import objects.note.Note;

using StringTools;

class ModchartUtil
{
    //need to test each engine
    //not expecting all to work
    public static function getDownscroll(instance:ModchartMusicBeatState):Bool return ClientPrefs.data.downScroll;
    public static function getMiddlescroll(instance:ModchartMusicBeatState):Bool return ClientPrefs.data.middleScroll;
    // public static function getScrollSpeed(instance:PlayState):Float
    //     return instance == null ? PlayState.SONG.speed : PlayState.instance?.songSpeed ?? PlayState.SONG.speed; //most engines just use this
    public static function getIsPixelNotes(instance:ModchartMusicBeatState):Bool
        return instance == null ? false : PlayState.isPixelNotes;
    public static function getIsPixelStage(instance:ModchartMusicBeatState):Bool
        return instance == null ? false : PlayState.isPixelStage;
    public static function getNoteOffsetX(daNote:Note, instance:ModchartMusicBeatState):Float
        return daNote.offsetX;

    static var currentFakeCrochet:Float = -1;
    static var lastBpm:Float = -1;

    public static function getFakeCrochet():Float
    {
        if (PlayState.SONG.bpm != lastBpm)
        {
            currentFakeCrochet = (60 / PlayState.SONG.bpm) * 1000; //only need to calculate once
            lastBpm = PlayState.SONG.bpm;
        }
        return currentFakeCrochet;
    }

    public static var zNear:Float = 0;
    public static var zFar:Float = 100;
    public static var defaultFOV:Float = 90;

    /**
        Converts a Vector3D to its in world coordinates using perspective math
    **/
    public static function calculatePerspective(pos:Vector3D, FOV:Float, offsetX:Float = 0, offsetY:Float = 0):Vector3D
    {

        /* math from opengl lol
            found from this website https://ogldev.org/www/tutorial12/tutorial12.html
        */

        //TODO: maybe try using actual matrix???

        var newz = pos.z - 1;
        var zRange = zNear - zFar;
        var tanHalfFOV = FlxMath.fastSin(FOV*0.5)/FlxMath.fastCos(FOV*0.5); //faster tan
        if (pos.z > 1) //if above 1000 z basically
            newz = 0; //should stop weird mirroring with high z values

        //var m00 = 1/(tanHalfFOV);
        //var m11 = 1/tanHalfFOV;
        //var m22 = (-zNear - zFar) / zRange; //isnt this just 1 lol
        //var m23 = 2 * zFar * zNear / zRange;
        //var m32 = 1;

        var xOffsetToCenter = pos.x - (FlxG.width*0.5); //so the perspective focuses on the center of the screen
        var yOffsetToCenter = pos.y - (FlxG.height*0.5);

        var zPerspectiveOffset = (newz+(2 * zFar * zNear / zRange));


        //xOffsetToCenter += (offsetX / (1/-zPerspectiveOffset));
        //yOffsetToCenter += (offsetY / (1/-zPerspectiveOffset));
        xOffsetToCenter += (offsetX * -zPerspectiveOffset);
        yOffsetToCenter += (offsetY * -zPerspectiveOffset);

        var xPerspective = xOffsetToCenter*(1/tanHalfFOV);
        var yPerspective = yOffsetToCenter/(1/tanHalfFOV);
        xPerspective /= -zPerspectiveOffset;
        yPerspective /= -zPerspectiveOffset;

        pos.x = xPerspective+(FlxG.width*0.5); //offset it back to normal
        pos.y = yPerspective+(FlxG.height*0.5);
        pos.z = zPerspectiveOffset;

        //pos.z -= 1;
        //pos = perspectiveMatrix.transformVector(pos);

        return pos;
    }
    /**
        Returns in-world 3D coordinates using polar angle, azimuthal angle and a radius.
        (Spherical to Cartesian)

        @param	theta Angle used along the polar axis.
        @param	phi Angle used along the azimuthal axis.
        @param	radius Distance to center.
    **/
    public static function getCartesianCoords3D(theta:Float, phi:Float, radius:Float):Vector3D
    {
        var pos:Vector3D = new Vector3D();
        var rad = FlxAngle.TO_RAD;
        pos.x = FlxMath.fastCos(theta*rad)*FlxMath.fastSin(phi*rad);
        pos.y = FlxMath.fastCos(phi*rad);
        pos.z = FlxMath.fastSin(theta*rad)*FlxMath.fastSin(phi*rad);
        pos.x *= radius;
        pos.y *= radius;
        pos.z *= radius;

        return pos;
    }

    public static function rotateAround(origin:Vector2, point:Vector2, degrees:Float):Vector2
    {
        // public function rotateAround(origin, point, degrees):FlxBasePoint{
        // public function rotateAround(origin, point, degrees){
        var angle:Float = degrees * (Math.PI / 180);
        var ox = origin.x;
        var oy = origin.y;
        var px = point.x;
        var py = point.y;

        var qx = ox + FlxMath.fastCos(angle) * (px - ox) - FlxMath.fastSin(angle) * (py - oy);
        var qy = oy + FlxMath.fastSin(angle) * (px - ox) + FlxMath.fastCos(angle) * (py - oy);

        // point.x = qx;
        // point.y = qy;

        return (new Vector2(qx, qy));
        // return FlxBasePoint.weak(qx, qy);
        // return qx, qy;
    }

    public static function getTimeFromBeat(beat:Float):Float
    {
        var totalTime:Float = 0;
        var curBpm = Conductor.bpm;
        if (PlayState.SONG != null)
            curBpm = PlayState.SONG.bpm;
        for (i in 0...Math.floor(beat))
        {
            if (Conductor.bpmChangeMap.length > 0)
            {
                for (j in 0...Conductor.bpmChangeMap.length)
                {
                    if (totalTime >= Conductor.bpmChangeMap[j].songTime)
                        curBpm = Conductor.bpmChangeMap[j].bpm;
                }
            }
            totalTime += 60000/curBpm;
        }

        var leftOverBeat = beat - Math.floor(beat);
        totalTime += (15000 * leftOverBeat) / curBpm;
        return totalTime;
    }
}
