package modcharting;


import lime.utils.Assets;
import haxe.Json;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxDestroyUtil;
#if (flixel < "5.3.0")
import flixel.system.FlxSound;
#else
import flixel.sound.FlxSound;
#end
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;

import modcharting.*;
import modcharting.PlayfieldRenderer.StrumNoteType;
import modcharting.modifiers.*;
import modcharting.Modifier;
import modcharting.ModchartFile;

import backend.Debug;
import backend.ui.*;
import objects.note.Note;
import objects.note.StrumArrow;
import objects.note.Strumline;
import substates.MusicBeatSubState;
import utils.SoundUtil;

using StringTools;

class ModchartEditorEvent extends FlxSprite
{
    public var data:Array<Dynamic>;
    public function new (data:Array<Dynamic>)
    {
        this.data = data;
        super(-300, 0);
        frames = Paths.getSparrowAtlas('eventArrowModchart', 'shared');
        animation.addByPrefix('note', 'idle0');
        animation.play('note');
        setGraphicSize(ModchartEditorState.gridSize, ModchartEditorState.gridSize);
        updateHitbox();
        antialiasing = true;
    }
    public function getBeatTime():Float { return data[ModchartFile.EVENT_DATA][ModchartFile.EVENT_TIME]; }
}
class ModchartEditorState extends states.MusicBeatState
{
    var hasUnsavedChanges:Bool = false;
    override function closeSubState()
    {
		persistentUpdate = true;
		super.closeSubState();
    }

    public static function getBPMFromSeconds(time:Float){
        return Conductor.getBPMFromSeconds(time);
    }

    //pain
    //tried using a macro but idk how to use them lol
    /**
     * *Order for Modifiers with Transformationes like regular, Drunk, Bumpy, ZigZag all have this order
     * *X, Y, Z, Angle, Scale, ScaleX, ScaleY, Skew, SkewY, SkewZ
     * *Other Modifiers edit the notes or strums or both or just the lanes, some edit the way the notes spawn, begin, move.
     */
    public static var defaultModifiers:Array<Class<Modifier>> = [
        //Basic Modifiers with no curpos math
        XModifier, YModifier, YDModifier, ZModifier, ConfusionModifier, ConfusionXModifier, ConfusionYModifier,
        ScaleModifier, ScaleXModifier, ScaleYModifier,
        SkewModifier, SkewXModifier, SkewYModifier, SkewXOffsetModifier, SkewYOffsetModifier, SkewZOffsetModifier,
        MiniModifier,
        //Modifiers with curpos math!!!
        //Drunk Modifiers
         DrunkXModifier, DrunkYModifier, DrunkZModifier, DrunkAngleModifier,
        DrunkScaleModifier,  DrunkScaleXModifier, DrunkScaleYModifier,
        DrunkSkewModifier,  DrunkSkewXModifier, DrunkSkewYModifier,
        TanDrunkXModifier, TanDrunkYModifier, TanDrunkZModifier, TanDrunkAngleModifier,
        TanDrunkScaleModifier, TanDrunkScaleXModifier, TanDrunkScaleYModifier,
        TanDrunkSkewModifier, TanDrunkSkewXModifier, TanDrunkSkewYModifier,
        CosecantXModifier, CosecantYModifier, CosecantZModifier, CosecantAngleModifier,
        CosecantScaleModifier, CosecantScaleXModifier, CosecantScaleYModifier,
        CosecantSkewModifier, CosecantSkewXModifier, CosecantSkewYModifier,
        //Tipsy Modifiers
         TipsyXModifier, TipsyYModifier, TipsyZModifier, TipsyAngleModifier,
        TipsyScaleModifier, TipsyScaleXModifier, TipsyScaleYModifier,
        TipsySkewModifier, TipsySkewXModifier, TipsySkewYModifier,
        //Wave Modifiers
        WaveXModifier, WaveYModifier, WaveZModifier, WaveAngleModifier,
        WaveScaleModifier, WaveScaleXModifier, WaveScaleYModifier,
        WaveSkewModifier, WaveSkewXModifier, WaveSkewYModifier,
        TanWaveXModifier, TanWaveYModifier, TanWaveZModifier, TanWaveAngleModifier,
        TanWaveScaleModifier, TanWaveScaleXModifier, TanWaveScaleYModifier,
        TanWaveSkewModifier, TanWaveSkewXModifier, TanWaveSkewYModifier,
        //Scroll Modifiers
         ReverseModifier, CrossModifier, SplitModifier, AlternateModifier,
        SpeedModifier, BoostModifier, BrakeModifier, BoomerangModifier, WaveingModifier,
        TwirlModifier, RollModifier,
        //Stealth Modifiers
         AlphaModifier, NoteAlphaModifier, TargetAlphaModifier,
        StealthModifier, DarkModifier, StealthColorModifier, DarkColorModifier, SDColorModifier,
        SuddenModifier, HiddenModifier, VanishModifier, BlinkModifier,
        //Path Modifiers
        IncomingAngleModifier, InvertSineModifier, DizzyModifier,
        //Tornado Modifiers
         TornadoModifier, TornadoYModifier, TornadoZModifier, TornadoAngleModifier,
        TornadoScaleModifier, TornadoScaleXModifier, TornadoScaleYModifier,
        TornadoSkewModifier, TornadoSkewXModifier, TornadoSkewYModifier,
        TanTornadoModifier, TanTornadoYModifier, TanTornadoZModifier, TanTornadoAngleModifier,
        TanTornadoScaleModifier, TanTornadoScaleXModifier, TanTornadoScaleYModifier,
        TanTornadoSkewModifier, TanTornadoSkewXModifier, TanTornadoSkewYModifier,
        //EaseCurve Modifiers
        EaseCurveModifier, EaseCurveXModifier, EaseCurveYModifier, EaseCurveZModifier, EaseCurveAngleModifier,
        EaseCurveScaleModifier, EaseCurveScaleXModifier, EaseCurveScaleYModifier,
        EaseCurveSkewModifier, EaseCurveSkewXModifier, EaseCurveSkewYModifier,
        //Bounce Modifiers
        BounceXModifier, BounceYModifier, BounceZModifier, BounceAngleModifier,
        BounceScaleModifier, BounceScaleXModifier, BounceScaleYModifier,
        BounceSkewModifier, BounceSkewXModifier, BounceSkewYModifier,
        //Bumpy Modifiers
        BumpyXModifier, BumpyYModifier, BumpyModifier, BumpyAngleModifier,
        BumpyScaleModifier, BumpyScaleXModifier, BumpyScaleYModifier,
        BumpySkewModifier, BumpySkewXModifier, BumpySkewYModifier,
        //TanBumpy Modifiers
        TanBumpyXModifier, TanBumpyYModifier, TanBumpyModifier, TanBumpyAngleModifier,
        TanBumpyScaleModifier, TanBumpyScaleXModifier, TanBumpyScaleYModifier,
        TanBumpySkewModifier, TanBumpySkewXModifier, TanBumpySkewYModifier,
        //Beat Modifiers
        BeatXModifier, BeatYModifier, BeatZModifier, BeatAngleModifier,
        BeatScaleModifier, BeatScaleXModifier, BeatScaleYModifier,
        BeatSkewModifier, BeatSkewXModifier, BeatSkewYModifier,
        //Shrink Mod
        ShrinkModifier,
        //ZigZag Modifiers
        ZigZagXModifier, ZigZagYModifier, ZigZagZModifier, ZigZagAngleModifier,
        ZigZagScaleModifier, ZigZagScaleXModifier, ZigZagScaleYModifier,
        ZigZagSkewModifier, ZigZagSkewXModifier, ZigZagSkewYModifier,
        //SawTooth Modifiers
        SawToothXModifier, SawToothYModifier, SawToothZModifier, SawToothAngleModifier,
        SawToothScaleModifier, SawToothScaleXModifier, SawToothScaleYModifier,
        SawToothSkewModifier, SawToothSkewXModifier, SawToothSkewYModifier,
        //Square Modifiers
        SquareXModifier, SquareYModifier, SquareZModifier, SquareAngleModifier,
        SquareScaleModifier, SquareScaleXModifier, SquareScaleYModifier,
        SquareSkewModifier, SquareSkewXModifier, SquareSkewYModifier,
        //Target Modifiers
        RotateModifier, StrumLineRotateModifier, Rotate3DModifier, JumpTargetModifier,
        LanesModifier,
        //Notes Modifiers
        TimeStopModifier, JumpNotesModifier,
        NotesModifier,
        //Strum Modifiers
        StrumsModifier, InvertModifier, FlipModifier, JumpModifier, CenterModifier,
        StrumAngleModifier, DrivenModifier, CenterModifier,
        //Ease Modifiers
        EaseXModifier, EaseYModifier, EaseZModifier, EaseAngleModifier,
        EaseScaleModifier, EaseScaleXModifier, EaseScaleYModifier,
        EaseSkewModifier, EaseSkewXModifier, EaseSkewYModifier,
        //Attenuate Modifiers
        AttenuateModifier, AttenuateYModifier, AttenuateZModifier, AttenuateAngleModifier,
        AttenuateScaleModifier, AttenuateScaleXModifier, AttenuateScaleYModifier,
        AttenuateSkewModifier, AttenuateSkewXModifier, AttenuateSkewYModifier,
        //Pivot Modifiers,
        PivotXOffsetModifier, PivotYOffsetModifier, PivotZOffsetModifier,
        //Fov Modifiers
        FovXOffsetModifier, FovYOffsetModifier,
        //misc
        ShakyNotesModifier, ParalysisModifier, SpiralHoldsModifier,
        ArrowPath,
        //custom
        StrumCircleModifier, StrumBounceModifier,
        //Lines
        LineAlphaModifier, LineLengthForwardModifier, LineLengthBackwardModifier, LineGrainModifier
    ];

    public static var easeList:Array<String> = [
        "backIn",
        "backInOut",
        "backOut",
        "backOutIn",
        "bounce",
        "bounceIn",
        "bounceInOut",
        "bounceOut",
        "bounceOutIn",
        "bell",
        "circIn",
        "circInOut",
        "circOut",
        "circOutIn",
        "cubeIn",
        "cubeInOut",
        "cubeOut",
        "cubeOutIn",
        "elasticIn",
        "elasticInOut",
        "elasticOut",
        "elasticOutIn",
        "expoIn",
        "expoInOut",
        "expoOut",
        "expoOutIn",
        "inverse",
        "instant",
        "linear",
        "pop",
        "popelastic",
        "pulse",
        "pulseelastic",
        "quadIn",
        "quadInOut",
        "quadOut",
        "quadOutIn",
        "quartIn",
        "quartInOut",
        "quartOut",
        "quartOutIn",
        "quintIn",
        "quintInOut",
        "quintOut",
        "quintOutIn",
        "sineIn",
        "sineInOut",
        "sineOut",
        "sineOutIn",
        "spike",
        "smoothStepIn",
        "smoothStepInOut",
        "smoothStepOut",
        "smootherStepIn",
        "smootherStepInOut",
        "smootherStepOut",
        "tap",
        "tapelastic",
        "tri"
    ];

    //used for indexing
    public static var MOD_NAME:Int = ModchartFile.MOD_NAME; //the modifier name
    public static var MOD_CLASS:Int = ModchartFile.MOD_CLASS; //the class/custom mod it uses
    public static var MOD_TYPE:Int = ModchartFile.MOD_TYPE; //the type, which changes if its for the player, opponent, a specific lane or all
    public static var MOD_PF:Int = ModchartFile.MOD_PF; //the playfield that mod uses
    public static var MOD_LANE:Int = ModchartFile.MOD_LANE; //the lane the mod uses

    public static var EVENT_TYPE:Int = ModchartFile.EVENT_TYPE; //event type (set or ease)
    public static var EVENT_DATA:Int = ModchartFile.EVENT_DATA; //event data
    public static var EVENT_REPEAT:Int = ModchartFile.EVENT_REPEAT; //event repeat data

    public static var EVENT_TIME:Int = ModchartFile.EVENT_TIME; //event time (in beats)
    public static var EVENT_SETDATA:Int = ModchartFile.EVENT_SETDATA; //event data (for sets)
    public static var EVENT_EASETIME:Int = ModchartFile.EVENT_EASETIME; //event ease time
    public static var EVENT_EASE:Int = ModchartFile.EVENT_EASE; //event ease
    public static var EVENT_EASEDATA:Int = ModchartFile.EVENT_EASEDATA; //event data (for eases)

    public static var EVENT_REPEATBOOL:Int = ModchartFile.EVENT_REPEATBOOL; //if event should repeat
    public static var EVENT_REPEATCOUNT:Int = ModchartFile.EVENT_REPEATCOUNT; //how many times it repeats
    public static var EVENT_REPEATBEATGAP:Int = ModchartFile.EVENT_REPEATBEATGAP; //how many beats in between each repeat

    public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
    public var notes:FlxTypedGroup<Note> = new FlxTypedGroup<Note>();
    public var arrowPaths:FlxTypedGroup<ArrowPathSegment> = new FlxTypedGroup<ArrowPathSegment>();

    private var strumLine:FlxSprite;
    public var strumLineNotes:Strumline = new Strumline(8);
	public var opponentStrums:Strumline = new Strumline(4);
	public var playerStrums:Strumline = new Strumline(4);

	public var unspawnNotes:Array<Note> = [];
    public var loadedNotes:Array<Note> = []; //stored notes from the chart that unspawnNotes can copy from
    public var vocals:FlxSound;
    public var opponentVocals:FlxSound;

    public static var gridSize:Int = 64;
    private var grid:FlxBackdrop;
    private var line:FlxSprite;
    public var eventSprites:FlxTypedGroup<ModchartEditorEvent>;
    public var highlight:FlxSprite;
    public var debugText:FlxText;

    var highlightedEvent:Array<Dynamic> = null;
    var stackedHighlightedEvents:Array<Array<Dynamic>> = [];

    var beatTexts:Array<FlxText> = [];
    var generatedMusic:Bool = false;

    var UI_box:PsychUIBox;

    var playbackSpeed:Float = 1;

    var activeModifiersText:FlxText;

    var selectedEventBox:FlxSprite;

    var inst:FlxSound;

    public var opponentMode:Bool = false;

	var col:FlxColor = 0xFFFFD700;
	var col2:FlxColor = 0xFFFFD700;

	var beat:Float = 0;
	var dataStuff:Float = 0;

    override public function create()
    {
        Paths.clearStoredMemory();
        Paths.clearUnusedMemory();

        camGame = initPsychCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
        FlxG.cameras.add(camHUD, false);

		persistentUpdate = true;
		persistentDraw = true;

        opponentMode = (ClientPrefs.getGameplaySetting('opponent') && !PlayState.SONG.options.blockOpponentMode);
	    CoolUtil.opponentModeActive = opponentMode;

        var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menuDesat'));
        bg.setGraphicSize(Std.int(FlxG.width), Std.int(FlxG.height));
        add(bg);

        if (PlayState.isPixelStage) //Skew Kills Pixel Notes (How are you going to stretch already pixelated bit by bit notes?)
        {
            defaultModifiers.remove(SkewModifier);
            defaultModifiers.remove(SkewXModifier);
            defaultModifiers.remove(SkewYModifier);
        }

		// Prepare the Conductor.
        Conductor.mapBPMChanges(PlayState.SONG);
        Conductor.bpm = PlayState.SONG.bpm;

	    if(FlxG.sound.music != null) FlxG.sound.music.stop();
        FlxG.mouse.visible = true;

        strumLine = new FlxSprite(ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, 50).makeGraphic(FlxG.width, 10);
        if(ModchartUtil.getDownscroll(this)) strumLine.y = FlxG.height - 150;

		strumLine.scrollFactor.set();
        add(arrowPaths);
		add(strumLineNotes);

		generateSong();

		playfieldRenderer = new PlayfieldRenderer(this, strumLineNotes, notes, arrowPaths);
		playfieldRenderer.cameras = [camHUD];
        playfieldRenderer.inEditor = true;
		add(playfieldRenderer);

        strumLineNotes.cameras = notes.cameras = arrowPaths.cameras =  [camHUD];

        #if ("flixel-addons" >= "3.0.0")
        grid = new FlxBackdrop(FlxGraphic.fromBitmapData(createGrid(gridSize, gridSize, FlxG.width, gridSize)), FlxAxes.X, 0, 0);
        #else
        grid = new FlxBackdrop(FlxGraphic.fromBitmapData(createGrid(gridSize, gridSize, FlxG.width, gridSize)), 0, 0, true, false);
        #end

        // #if ("flixel-addons" >= "3.0.0")
        // grid = new FlxBackdrop(FlxGraphic.fromBitmapData(createGrid(gridSize, gridSize, Std.int(gridSize*48), gridSize)), FlxAxes.X, 0, 0);
        // #else
        // grid = new FlxBackdrop(FlxGraphic.fromBitmapData(createGrid(gridSize, gridSize, Std.int(gridSize*48), gridSize)), 0, 0, true, false);
        // #end

        add(grid);

        for (i in 0...12)
        {
            var beatText = new FlxText(-50, gridSize, 0, i+"", 32);
            add(beatText);
            beatTexts.push(beatText);
        }

        eventSprites = new FlxTypedGroup<ModchartEditorEvent>();
        add(eventSprites);

        highlight = new FlxSprite().makeGraphic(gridSize,gridSize);
        highlight.alpha = 0.5;
        add(highlight);

        selectedEventBox = new FlxSprite().makeGraphic(32,32);
        selectedEventBox.y = gridSize*0.5;
        selectedEventBox.visible = false;
        add(selectedEventBox);

        updateEventSprites();

        line = new FlxSprite().makeGraphic(10, gridSize);
        line.color = FlxColor.BLACK;
        add(line);

        generateStaticArrows(0);
        generateStaticArrows(1);
        NoteMovement.getDefaultStrumPosEditor(this);

        //gridGap = FlxMath.remapToRange(Conductor.stepCrochet, 0, Conductor.stepCrochet, 0, gridSize); //idk why i even thought this was how i do it
        //trace(gridGap);

        debugText = new FlxText(0, gridSize*2, 0, "", 16);
        debugText.alignment = FlxTextAlign.LEFT;

        UI_box = new PsychUIBox(100, gridSize*2, FlxG.width-200, 500, ['Editor', 'Modifiers', 'Events', 'Playfields']);
		UI_box.scrollFactor.set();
        add(UI_box);

        add(debugText);

        if (ClientPrefs.data.quantNotes && !PlayState.SONG.options.disableNoteRGB && !PlayState.SONG.options.disableStrumRGB && !PlayState.SONG.options.disableNoteQuantRGB) setUpNoteQuant();

        super.create(); //do here because tooltips be dumb
        setupModifierUI();
        setupEventUI();
        setupEditorUI();
        setupPlayfieldUI();

        var hideNotes:PsychUIButton = new PsychUIButton(0, FlxG.height, 'Show/Hide Notes', function ()
        {
            //camHUD.visible = !camHUD.visible;
            playfieldRenderer.visible = !playfieldRenderer.visible;
        }, 80, 28);
        hideNotes.y -= hideNotes.height;
        add(hideNotes);

        var hidenHud:Bool = false;
        var hideUI:PsychUIButton = new PsychUIButton(FlxG.width, FlxG.height, 'Show/Hide UI', function ()
        {
            hidenHud = !hidenHud;
            UI_box.alpha = debugText.alpha = !hidenHud ? 0.6 : 0;
        });
        hideUI.y -= hideUI.height;
        hideUI.x -= hideUI.width;
        add(hideUI);

    }
    var dirtyUpdateNotes:Bool = false;
    var dirtyUpdateEvents:Bool = false;
    var dirtyUpdateModifiers:Bool = false;
    var totalElapsed:Float = 0;
    override public function update(elapsed:Float)
    {
        if (finishedSetUpQuantStuff)
        {
            if (ClientPrefs.data.quantNotes && !PlayState.SONG.options.disableStrumRGB)
            {
                var group:FlxTypedGroup<StrumArrow> = playerStrums;
                for (this2 in group){
                    if (this2.animation.curAnim.name == 'static'){
                        this2.rgbShader.r = 0xFFFFFFFF;
                        this2.rgbShader.b = 0xFF808080;
                    }
                }
            }
        }
        totalElapsed += elapsed;
        highlight.alpha = 0.8+Math.sin(totalElapsed*5)*0.15;
        super.update(elapsed);
        if(inst.time < 0) {
			inst.pause();
			inst.time = 0;
		}
		else if(inst.time > inst.length) {
			inst.pause();
			inst.time = 0;
		}

        playfieldRenderer.updateToCurrentElapsed(totalElapsed);

        // Update the conductor.
        Conductor.songPosition = inst.time; // Normal conductor update.

        var songPosPixelPos = (((Conductor.songPosition/Conductor.stepCrochet)%4)*gridSize);
        grid.x = -curDecStep*gridSize;
        line.x = gridSize*4;

        for (i in 0...beatTexts.length)
        {
            beatTexts[i].x = -songPosPixelPos + (gridSize*4*(i+1)) - 16;
            beatTexts[i].text = ""+ (Math.floor(Conductor.songPosition/Conductor.crochet)+i);
        }
        var eventIsSelected:Bool = false;
        for (i in 0...eventSprites.members.length)
        {
            var pos = grid.x + (eventSprites.members[i].getBeatTime()*gridSize*4)+(gridSize*4);
            //var dec = eventSprites.members[i].beatTime-Math.floor(eventSprites.members[i].beatTime);
            eventSprites.members[i].x = pos; //+ (dec*4*gridSize);
            if (highlightedEvent != null)
                if (eventSprites.members[i].data == highlightedEvent)
                {
                    eventIsSelected = true;
                    selectedEventBox.x = pos;
                }

        }
        selectedEventBox.visible = eventIsSelected;

        if (PsychUIInputText.focusOn == null)
        {
            ClientPrefs.toggleVolumeKeys(true);
            if (FlxG.keys.justPressed.SPACE)
            {
                if (inst.playing)
                {
                    inst.pause();
                    if(vocals != null) vocals.pause();
                    if(opponentVocals != null) opponentVocals.pause();
                    playfieldRenderer.editorPaused = true;
                }
                else
                {
                    if(opponentVocals != null) {
                        opponentVocals.play();
                        opponentVocals.pause();
                        opponentVocals.time = inst.time;
                        opponentVocals.play();
                    }
                    if(vocals != null) {
                        vocals.play();
                        vocals.pause();
                        vocals.time = inst.time;
                        vocals.play();
                    }
                    inst.play();
                    playfieldRenderer.editorPaused = false;
                    dirtyUpdateNotes = true;
                    dirtyUpdateEvents = true;
                }
            }
            var shiftThing:Int = 1;
            if (FlxG.keys.pressed.SHIFT)
                shiftThing = 4;
            if (FlxG.mouse.wheel != 0)
            {
                inst.pause();
                if(vocals != null) vocals.pause();
                if(opponentVocals != null) opponentVocals.pause();
                inst.time += (FlxG.mouse.wheel * Conductor.stepCrochet*0.8*shiftThing);
                if(vocals != null) {
                    vocals.pause();
                    vocals.time = inst.time;
                }
                if(opponentVocals != null) {
                    opponentVocals.pause();
                    opponentVocals.time = inst.time;
                }
                playfieldRenderer.editorPaused = true;
                dirtyUpdateNotes = true;
                dirtyUpdateEvents = true;
            }

            if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT)
            {
                inst.pause();
                if(vocals != null) vocals.pause();
                if(opponentVocals != null) opponentVocals.pause();
                inst.time += (Conductor.crochet*4*shiftThing);
                dirtyUpdateNotes = true;
                dirtyUpdateEvents = true;
            }
            if (FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT)
            {
                inst.pause();
                if(vocals != null) vocals.pause();
                if(opponentVocals != null) opponentVocals.pause();
                inst.time -= (Conductor.crochet*4*shiftThing);
                dirtyUpdateNotes = true;
                dirtyUpdateEvents = true;
            }
            var holdingShift = FlxG.keys.pressed.SHIFT;
            var holdingLB = FlxG.keys.pressed.LBRACKET;
            var holdingRB = FlxG.keys.pressed.RBRACKET;
            var pressedLB = FlxG.keys.justPressed.LBRACKET;
            var pressedRB = FlxG.keys.justPressed.RBRACKET;

            var curSpeed = playbackSpeed;

            if (!holdingShift && pressedLB || holdingShift && holdingLB)
                playbackSpeed -= 0.01;
            if (!holdingShift && pressedRB || holdingShift && holdingRB)
                playbackSpeed += 0.01;
            if (FlxG.keys.pressed.ALT && (pressedLB || pressedRB || holdingLB || holdingRB))
                playbackSpeed = 1;
            //
            if (curSpeed != playbackSpeed)
                dirtyUpdateEvents = true;
        }

        if (playbackSpeed <= 0.5)
            playbackSpeed = 0.5;
        if (playbackSpeed >= 3)
            playbackSpeed = 3;

        playfieldRenderer.speed = playbackSpeed; //adjust the speed of tweens
        #if FLX_PITCH
        inst.pitch = playbackSpeed;
        vocals.pitch = playbackSpeed;
        if (opponentVocals != null) opponentVocals.pitch = playbackSpeed;
        #end

        if (unspawnNotes[0] != null)
        {
            var time:Float = unspawnNotes[0].spawnTime;
            if(PlayState.SONG.speed < 1) time /= PlayState.SONG.speed;

            while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
            {
                var dunceNote:Note = unspawnNotes[0];
                notes.insert(0, dunceNote);
                dunceNote.spawned=true;
                var index:Int = unspawnNotes.indexOf(dunceNote);
                unspawnNotes.splice(index, 1);
            }
        }

        var noteKillOffset = 350 / PlayState.SONG.speed;

        notes.forEachAlive(function(daNote:Note) {
            if (Conductor.songPosition >= daNote.strumTime)
            {
                daNote.wasGoodHit = true;
                var spr:StrumNoteType = null;
                if(!daNote.mustPress) {
                    spr = opponentStrums.members[daNote.noteData];
                } else {
                    spr = playerStrums.members[daNote.noteData];
                }
                if (ClientPrefs.data.vanillaStrumAnimations)
                {
                    if (daNote.isSustainNote) spr.holdConfirm();
                    else spr.playAnim("confirm", false, false);
                }else{
                    spr.playAnim("confirm", true);
                }
                spr.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackSpeed;
                if (PlayState.SONG != null && !PlayState.SONG.options.disableStrumRGB)
                {
                    spr.rgbShader.r = daNote.rgbShader.r;
                    spr.rgbShader.g = daNote.rgbShader.g;
                    spr.rgbShader.b = daNote.rgbShader.b;
                }
                if (!daNote.isSustainNote)
                {
                    //daNote.kill();
                    notes.remove(daNote, true);
                    //daNote.destroy();
                }
            }

            if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
            {
                if (ClientPrefs.data.vanillaStrumAnimations)
                {
                    var spr:StrumNoteType = null;
                    if(!daNote.mustPress) {
                        spr = opponentStrums.members[daNote.noteData];
                        if ((daNote.isSustainNote && daNote.isHoldEnd)
                            || !daNote.isSustainNote) spr.playAnim('static', true);
                    } else {
                        spr = playerStrums.members[daNote.noteData];
                        if (daNote.isSustainNote && daNote.isHoldEnd) spr.playAnim('static', true);
                        else spr.playAnim('static', true);
                    }
                }
                daNote.active = false;
                daNote.visible = false;

                //daNote.kill();
                notes.remove(daNote, true);
                //daNote.destroy();
            }
        });

        if (FlxG.mouse.y < grid.y+grid.height && FlxG.mouse.y > grid.y) //not using overlap because the grid would go out of world bounds
        {
            if (FlxG.keys.pressed.SHIFT)
                highlight.x = FlxG.mouse.x;
            else
                highlight.x = (Math.floor((FlxG.mouse.x-(grid.x%gridSize))/gridSize)*gridSize)+(grid.x%gridSize);
            if (FlxG.mouse.overlaps(eventSprites))
            {
                if (FlxG.mouse.justPressed)
                {
                    stackedHighlightedEvents = []; //reset stacked events
                }
                eventSprites.forEachAlive(function(event:ModchartEditorEvent)
                {
                    if (FlxG.mouse.overlaps(event))
                    {
                        if (FlxG.mouse.justPressed)
                        {
                            highlightedEvent = event.data;
                            stackedHighlightedEvents.push(event.data);
                            onSelectEvent();
                            //trace(stackedHighlightedEvents);
                        }
                        if (FlxG.keys.justPressed.BACKSPACE)
                            deleteEvent();
                    }
                });
                if (FlxG.mouse.justPressed)
                {
                    updateStackedEventDataStepper();
                }
            }
            else
            {
                if (FlxG.mouse.justPressed)
                {
                    var timeFromMouse = ((highlight.x-grid.x)/gridSize/4)-1;
                    //trace(timeFromMouse);
                    var event = addNewEvent(timeFromMouse);
                    highlightedEvent = event;
                    onSelectEvent();
                    updateEventSprites();
                    dirtyUpdateEvents = true;
                }
            }
        }
        else ClientPrefs.toggleVolumeKeys(false);

        if (dirtyUpdateNotes)
        {
            clearNotesAfter(Conductor.songPosition+2000); //so scrolling back doesnt lag shit
            unspawnNotes = loadedNotes.copy();
            clearNotesBefore(Conductor.songPosition);
            dirtyUpdateNotes = false;
        }
        if (dirtyUpdateModifiers)
        {
            playfieldRenderer.modifierTable.clear();
            playfieldRenderer.modchart.loadModifiers();
            dirtyUpdateEvents = true;
            dirtyUpdateModifiers = false;
        }
        if (dirtyUpdateEvents)
        {
            playfieldRenderer.tweenManager.completeAll();
            playfieldRenderer.eventManager.clearEvents();
            playfieldRenderer.modifierTable.resetMods();
            playfieldRenderer.modchart.loadEvents();
            dirtyUpdateEvents = false;
            playfieldRenderer.update(0);
            updateEventSprites();
        }

        if (playfieldRenderer.modchart.data.playfields != playfieldCountStepper.value)
        {
            playfieldRenderer.modchart.data.playfields = Std.int(playfieldCountStepper.value);
            playfieldRenderer.modchart.loadPlayfields();
        }


        if (FlxG.keys.justPressed.ESCAPE)
        {
            var exitFunc = function()
            {
                ClientPrefs.toggleVolumeKeys(true);
                FlxG.mouse.visible = false;
                inst.stop();
                if(vocals != null) vocals.stop();
                if(opponentVocals != null) opponentVocals.stop();
                backend.StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PlayState());
            };
            if (hasUnsavedChanges)
            {
                persistentUpdate = false;
                openSubState(new ModchartEditorExitSubstate(exitFunc));
            }
            else
                exitFunc();

        }
        var curBpmChange = getBPMFromSeconds(Conductor.songPosition);
        if (curBpmChange.songTime <= 0)
        {
            curBpmChange.bpm = PlayState.SONG.bpm; //start bpm
        }
        if (curBpmChange.bpm != Conductor.bpm)
        {
            Conductor.bpm = curBpmChange.bpm;
        }

        debugText.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2)) + " / " + Std.string(FlxMath.roundDecimal(inst.length / 1000, 2)) +
		"\nBeat: " + Std.string(curDecBeat).substring(0,4) +
		"\nStep: " + curStep + "\n";

        var leText = "Active Modifiers: \n";
        for (modName => mod in playfieldRenderer.modifierTable.modifiers)
        {
            if (mod.currentValue != mod.baseValue)
            {
                leText += modName + ": " + FlxMath.roundDecimal(mod.currentValue, 2);
                for (subModName => subMod in mod.subValues)
                {
                    leText += "    " + subModName + ": " + FlxMath.roundDecimal(subMod.value, 2);
                }
                leText += "\n";
            }
        }

        activeModifiersText.text = leText;
    }

    function addNewEvent(time:Float)
    {
        var event:Array<Dynamic> = ['ease', [time, 1, 'cubeInOut', ','], [false, 1, 1]];
        if (highlightedEvent != null) //copy over current event data (without acting as a reference)
        {
            event[EVENT_TYPE] = highlightedEvent[EVENT_TYPE];
            if (event[EVENT_TYPE] == 'ease')
            {
                event[EVENT_DATA][EVENT_EASETIME] = highlightedEvent[EVENT_DATA][EVENT_EASETIME];
                event[EVENT_DATA][EVENT_EASE] = highlightedEvent[EVENT_DATA][EVENT_EASE];
                event[EVENT_DATA][EVENT_EASEDATA] = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
            }
            else
            {
                event[EVENT_DATA][EVENT_SETDATA] = highlightedEvent[EVENT_TYPE][EVENT_SETDATA];
            }
            event[EVENT_REPEAT][EVENT_REPEATBOOL] = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBOOL];
            event[EVENT_REPEAT][EVENT_REPEATCOUNT] = highlightedEvent[EVENT_REPEAT][EVENT_REPEATCOUNT];
            event[EVENT_REPEAT][EVENT_REPEATBEATGAP] = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBEATGAP];

        }
        playfieldRenderer.modchart.data.events.push(event);
        hasUnsavedChanges = true;
        return event;
    }

    function updateEventSprites()
    {
        // var i = eventSprites.length - 1;
        // while (i >= 0) {
        //     var daEvent:ModchartEditorEvent = eventSprites.members[i];
        //     var beat:Float = playfieldRenderer.modchart.data.events[i][1][0];
        //     if(curBeat < beat-4 && curBeat > beat+16)
        //     {
        //         daEvent.active = false;
        //         daEvent.visible = false;
        //         daEvent.alpha = 0;
        //         eventSprites.remove(daEvent, true);
        //         trace(daEvent.getBeatTime());
        //         trace("removed event sprite "+ daEvent.getBeatTime());
        //     }
        //     --i;
        // }
        eventSprites.clear();
        for (i in 0...playfieldRenderer.modchart.data.events.length)
        {
            var beat:Float = playfieldRenderer.modchart.data.events[i][1][0];
            if (curBeat > beat-5  && curBeat < beat+5)
            {
                var daEvent:ModchartEditorEvent = new ModchartEditorEvent(playfieldRenderer.modchart.data.events[i]);
                eventSprites.add(daEvent);
                //trace("added event sprite "+beat);
            }
        }
    }

    function deleteEvent()
    {
        if (highlightedEvent == null) return;
        for (i in 0...playfieldRenderer.modchart.data.events.length)
        {
            if (highlightedEvent == playfieldRenderer.modchart.data.events[i])
            {
                playfieldRenderer.modchart.data.events.remove(playfieldRenderer.modchart.data.events[i]);
                dirtyUpdateEvents = true;
                break;
            }
        }
        updateEventSprites();
    }

    override public function beatHit()
    {
        updateEventSprites();
        //trace("beat hit");
        super.beatHit();
    }

    override public function draw()
    {

        super.draw();
    }

    public function clearNotesBefore(time:Float)
    {
        var i:Int = unspawnNotes.length - 1;
        while (i >= 0) {
            var daNote:Note = unspawnNotes[i];
            if(daNote.strumTime+350 < time)
            {
                daNote.active = false;
                daNote.visible = false;
                //daNote.ignoreNote = true;

                //daNote.kill();
                unspawnNotes.remove(daNote);
                //daNote.destroy();
            }
            --i;
        }

        i = notes.length - 1;
        while (i >= 0) {
            var daNote:Note = notes.members[i];
            if(daNote.strumTime+350 < time)
            {
                daNote.active = false;
                daNote.visible = false;
                //daNote.ignoreNote = true;

                //daNote.kill();
                notes.remove(daNote, true);
                //daNote.destroy();
            }
            --i;
        }
    }
    public function clearNotesAfter(time:Float)
    {
        var i = notes.length - 1;
        while (i >= 0) {
            var daNote:Note = notes.members[i];
            if(daNote.strumTime > time)
            {
                daNote.active = false;
                daNote.visible = false;
                //daNote.ignoreNote = true;

                //daNote.kill();
                notes.remove(daNote, true);
                //daNote.destroy();
            }
            --i;
        }
    }


    public function generateSong():Void
    {
        final songData = PlayState.SONG;
        final boyfriendVocals:String = getVocalFromCharacter(songData.characters.player);
		final dadVocals:String = getVocalFromCharacter(songData.characters.opponent);
        final currentPrefix:String = (PlayState.SONG.options.vocalsPrefix != null ? PlayState.SONG.options.vocalsPrefix : '');
        final currentSuffix:String = (PlayState.SONG.options.vocalsSuffix != null ? PlayState.SONG.options.vocalsSuffix : '');

        vocals = new FlxSound();
        opponentVocals = new FlxSound();
        try
        {
            final vocalPl:String = (boyfriendVocals == null || boyfriendVocals.length < 1) ? 'Player' : boyfriendVocals;
            final normalVocals = Paths.voices(currentPrefix, songData.songId, currentSuffix);
            var playerVocals = SoundUtil.findVocal({song: songData.songId, prefix: currentPrefix, suffix: currentSuffix, externVocal: vocalPl, character: songData.characters.player, difficulty: Difficulty.getString()});
            vocals.loadEmbedded(playerVocals != null ? playerVocals : normalVocals);
        }
        catch(e:Dynamic){}

        try
        {
            final vocalOp:String = (dadVocals == null || dadVocals.length < 1) ? 'Opponent' : dadVocals;
            var oppVocals = SoundUtil.findVocal({song: songData.songId, prefix: currentPrefix, suffix: currentSuffix, externVocal: vocalOp, character: songData.characters.opponent, difficulty: Difficulty.getString()});
            if(oppVocals != null) opponentVocals.loadEmbedded(oppVocals);
        }
        catch(e:Dynamic){}
        FlxG.sound.list.add(vocals);
        FlxG.sound.list.add(opponentVocals);

        inst = new FlxSound();
        try
        {
            inst.loadEmbedded(Paths.inst((PlayState.SONG.options.instrumentalPrefix != null ? PlayState.SONG.options.instrumentalPrefix : ''), PlayState.SONG.songId, (PlayState.SONG.options.instrumentalSuffix != null ? PlayState.SONG.options.instrumentalSuffix : '')));
        }
        catch(e){}
        FlxG.sound.list.add(inst);

        inst.onComplete = function()
        {
            inst.pause();
            Conductor.songPosition = 0;
            if(vocals != null) {
                vocals.pause();
                vocals.time = 0;
            }
            if(opponentVocals != null) {
                opponentVocals.pause();
                opponentVocals.time = 0;
            }
        };

        notes = new FlxTypedGroup<Note>();
        add(notes);


        var playerCounter:Int = 0;

        var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

        //var songName:String = Paths.formatToSongPath(PlayState.SONG.song);

        var oldNote:Note = null;
        var sectionsData:Array<backend.song.SongData.SwagSection> = PlayState.SONG.notes;
        for (section in sectionsData)
        {
            for (songNotes in section.sectionNotes)
            {
                var strumTime:Float = songNotes[0];
                var noteData:Int = Std.int(songNotes[1] % 4);
                var gottaHitNote:Bool = true;
                if (songNotes[1] > 3 && !opponentMode) gottaHitNote = false;
                else if (songNotes[1] <= 3 && opponentMode) gottaHitNote = false;

                var swagNote:Note = new Note(strumTime, noteData, false, PlayState.SONG?.options?.arrowSkin, oldNote, this, PlayState.SONG?.speed, gottaHitNote ? playerStrums : opponentStrums, false);
                swagNote.setupNote(gottaHitNote, gottaHitNote ? 1 : 0, daBeats, songNotes[3]);
                swagNote.sustainLength = songNotes[2];
                swagNote.scrollFactor.set();

                #if SCEFEATURES_ALLOWED
                if (swagNote.texture.contains('pixel') || swagNote.noteSkin.contains('pixel')){
                    swagNote.containsPixelTexture = true;
                }

                if (ClientPrefs.getGameplaySetting('sustainnotesactive')) swagNote.sustainLength = songNotes[2] / playbackSpeed;
                else swagNote.sustainLength = 0;
                #end

                unspawnNotes.push(swagNote);

                final susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
                final floorSus:Int = Math.floor(susLength);

                if(floorSus > 0) {
                    for (susNote in 0...floorSus + 1)
                    {
                        oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

                        var sustainNote:Note = new Note(strumTime + (Conductor.stepCrochet * susNote), noteData, true, PlayState.SONG?.options?.arrowSkin, oldNote, this, PlayState.SONG?.speed, gottaHitNote ? playerStrums : opponentStrums, false);
                        sustainNote.setupNote(gottaHitNote, gottaHitNote ? 1 : 0, daBeats, swagNote.noteType);
                        swagNote.tail.push(sustainNote);
                        sustainNote.parent = swagNote;
                        sustainNote.scrollFactor.set();
                        unspawnNotes.push(sustainNote);

                        var isNotePixel:Bool = (sustainNote.texture.contains('pixel') || sustainNote.noteSkin.contains('pixel') || oldNote.texture.contains('pixel') || oldNote.noteSkin.contains('pixel'));
                        if (isNotePixel) {
                            oldNote.containsPixelTexture = true;
                            sustainNote.containsPixelTexture = true;
                        }
                        sustainNote.correctionOffset = swagNote.height / 2;
                        if(!isNotePixel)
                        {
                            if(oldNote.isSustainNote)
                            {
                                oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
                                oldNote.scale.y /= playbackSpeed;
                                oldNote.updateHitbox();
                            }

                            if(ClientPrefs.data.downScroll) sustainNote.correctionOffset = 0;
                        }
                        else if (oldNote.isSustainNote)
                        {
                            oldNote.scale.y /= playbackSpeed;
                            oldNote.updateHitbox();
                        }

                        if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2; // general offset
                        else if(ClientPrefs.data.middleScroll)
                        {
                            sustainNote.x += 310;
                            if(noteData > 1) //Up and Right
                                sustainNote.x += FlxG.width / 2 + 25;
                        }
                    }
                }
                if (swagNote.mustPress)
                {
                    swagNote.x += FlxG.width / 2; // general offset
                }
                else if(ClientPrefs.data.middleScroll)
                {
                    swagNote.x += 310;
                    if(noteData > 1) //Up and Right
                        swagNote.x += FlxG.width / 2 + 25;
                }

                oldNote = swagNote;
            }
            daBeats += 1;
        }

        unspawnNotes.sort(sortByTime);
        loadedNotes = unspawnNotes.copy();
        generatedMusic = true;
    }
    function sortByTime(Obj1:Dynamic, Obj2:Dynamic):Int
    {
        return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
    }
    private function generateStaticArrows(player:Int):Void
    {
        var usedKeyCount = 4;

        var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;

		var TRUE_STRUM_X:Float = strumLineX;

		if (PlayState.SONG.options.arrowSkin.contains('pixel'))
		{
			(ClientPrefs.data.middleScroll ? TRUE_STRUM_X += 3 : TRUE_STRUM_X += 2);
		}

        for (i in 0...usedKeyCount)
        {
            // FlxG.log.add(i);
            var targetAlpha:Float = 1;
            if (player < 1)
            {
                if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
            }

            var babyArrow:StrumArrow = new StrumArrow(TRUE_STRUM_X, strumLine.y, i, player, PlayState.SONG.options.arrowSkin);
            babyArrow.downScroll = ClientPrefs.data.downScroll;
            babyArrow.alpha = targetAlpha;
            babyArrow.loadLineSegment();

            var middleScroll:Bool = false;
            middleScroll = ClientPrefs.data.middleScroll;

            if (player == 1)
            {
                if (opponentMode && !middleScroll)
					opponentStrums.add(babyArrow);
				else playerStrums.add(babyArrow);
            }
            else
            {
                if (middleScroll)
                {
                    babyArrow.x += 310;
                    if(i > 1) { //Up and Right
                        babyArrow.x += FlxG.width / 2 + 25;
                    }
                }
                if (opponentMode && !middleScroll)
                    playerStrums.add(babyArrow);
                else opponentStrums.add(babyArrow);
            }

            strumLineNotes.add(babyArrow);
            if (babyArrow.lineSegment != null) arrowPaths.add(babyArrow.lineSegment);
            babyArrow.postAddedToGroup();
        }
    }

	private function round(num:Float, numDecimalPlaces:Int){
		var mult:Float = Math.pow(10, numDecimalPlaces);
		return Math.floor(num * mult + 0.5) / mult;
	}

 	public function setUpNoteQuant()
	{
		var bpmChanges = Conductor.bpmChangeMap;
		var strumTime:Float = 0;
		var currentBPM:Float = PlayState.SONG.bpm;
		var newTime:Float = 0;
		for (note in unspawnNotes)
		{
			strumTime = note.strumTime;
			newTime = strumTime;
			for (i in 0...bpmChanges.length)
				if (strumTime > bpmChanges[i].songTime){
					currentBPM = bpmChanges[i].bpm;
					newTime = strumTime - bpmChanges[i].songTime;
				}
			if (note.quantColorsOnNotes && note.rgbShader.enabled){
				dataStuff = ((currentBPM * (newTime - ClientPrefs.data.noteOffset)) / 1000 / 60);
				beat = round(dataStuff * 48, 0);

				if (!note.isSustainNote)
				{
					if(beat%(192/4)==0){
						col = ClientPrefs.data.arrowRGBQuantize[0][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[0][2];
					}
					else if(beat%(192/8)==0){
						col = ClientPrefs.data.arrowRGBQuantize[1][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[1][2];
					}
					else if(beat%(192/12)==0){
						col = ClientPrefs.data.arrowRGBQuantize[2][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[2][2];
					}
					else if(beat%(192/16)==0){
						col = ClientPrefs.data.arrowRGBQuantize[3][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[3][2];
					}
					else if(beat%(192/20)==0){
						col = ClientPrefs.data.arrowRGBQuantize[4][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[4][2];
					}
					else if(beat%(192/24)==0){
						col = ClientPrefs.data.arrowRGBQuantize[5][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[5][2];
					}
					else if(beat%(192/28)==0){
						col = ClientPrefs.data.arrowRGBQuantize[6][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[6][2];
					}
					else if(beat%(192/32)==0){
						col = ClientPrefs.data.arrowRGBQuantize[7][0];
						col2 = ClientPrefs.data.arrowRGBQuantize[7][2];
					}else{
						col = 0xFF7C7C7C;
						col2 = 0xFF3A3A3A;
					}
					note.rgbShader.r = col;
					note.rgbShader.g = ClientPrefs.data.arrowRGBQuantize[0][1];
					note.rgbShader.b = col2;

				}else{
					note.rgbShader.r = note.prevNote.rgbShader.r;
					note.rgbShader.g = note.prevNote.rgbShader.g;
					note.rgbShader.b = note.prevNote.rgbShader.b;
				}
			}


			for (this2 in opponentStrums)
			{
				this2.rgbShader.r = 0xFFFFFFFF;
				this2.rgbShader.b = 0xFF000000;
				this2.rgbShader.enabled = false;
			}
			for (this2 in playerStrums)
			{
				this2.rgbShader.r = 0xFFFFFFFF;
				this2.rgbShader.b = 0xFF000000;
				this2.rgbShader.enabled = false;
			}
		}
		finishedSetUpQuantStuff = true;
	}

	var finishedSetUpQuantStuff = false;

	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('data/characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		return null;
	}

    public static function createGrid(CellWidth:Int, CellHeight:Int, Width:Int, Height:Int):BitmapData
    {
        // How many cells can we fit into the width/height? (round it UP if not even, then trim back)
        var Color1 = FlxColor.GRAY; //quant colors!!!
        var Color2 = FlxColor.WHITE;
        // var Color3 = FlxColor.LIME;
        var rowColor:Int = Color1;
        var lastColor:Int = Color1;
        var grid:BitmapData = new BitmapData(Width, Height, true);

        // grid.lock();

        // FlxDestroyUtil.dispose(grid);

        // grid = null;

        // If there aren't an even number of cells in a row then we need to swap the lastColor value
        var y:Int = 0;
        var timesFilled:Int = 0;
        while (y <= Height)
        {

            var x:Int = 0;
            while (x <= Width)
            {
                if (timesFilled % 2 == 0)
                    lastColor = Color1;
                else if (timesFilled % 2 == 1)
                    lastColor = Color2;
                grid.fillRect(new Rectangle(x, y, CellWidth, CellHeight), lastColor);
                // grid.unlock();
                timesFilled++;

                x += CellWidth;
            }

            y += CellHeight;
        }

        return grid;
    }
    var currentModifier:Array<Dynamic> = null;
    var modNameInputText:PsychUIInputText;
    var modClassInputText:PsychUIInputText;
    var explainText:FlxText;
    var modTypeInputText:PsychUIInputText;
    var playfieldStepper:PsychUINumericStepper;
    var targetLaneStepper:PsychUINumericStepper;
    var modifierDropDown:PsychUIDropDownMenu;
    var mods:Array<String> = [];
    var subMods:Array<String> = [""];

    function updateModList()
    {
        mods = [];
        for (i in 0...playfieldRenderer.modchart.data.modifiers.length)
            mods.push(playfieldRenderer.modchart.data.modifiers[i][MOD_NAME]);
        if (mods.length == 0)
            mods.push('');
        modifierDropDown.list = mods;
        eventModifierDropDown.list = mods;

    }
    function updateSubModList(modName:String)
    {
        subMods = [""];
        if (playfieldRenderer.modifierTable.modifiers.exists(modName))
        {
            for (subModName => subMod in playfieldRenderer.modifierTable.modifiers.get(modName).subValues)
            {
                subMods.push(subModName);
            }
        }
        subModDropDown.list = subMods;
    }

    function setupModifierUI()
    {
        var tab_group = UI_box.getTab('Modifiers').menu;

        for (i in 0...playfieldRenderer.modchart.data.modifiers.length)
            mods.push(playfieldRenderer.modchart.data.modifiers[i][MOD_NAME]);

        if (mods.length == 0)
            mods.push('');

        modifierDropDown = new PsychUIDropDownMenu(25, 50, mods, function(md:Int, mod:String)
        {
            var modName = mod;
            for (i in 0...playfieldRenderer.modchart.data.modifiers.length)
                if (playfieldRenderer.modchart.data.modifiers[i][MOD_NAME] == modName)
                    currentModifier = playfieldRenderer.modchart.data.modifiers[i];

            if (currentModifier != null)
            {
                //trace(currentModifier);
                modNameInputText.text = currentModifier[MOD_NAME];
                modClassInputText.text = currentModifier[MOD_CLASS];
                modTypeInputText.text = currentModifier[MOD_TYPE];
                playfieldStepper.value = currentModifier[MOD_PF];
                if (currentModifier[MOD_LANE] != null)
                    targetLaneStepper.value = currentModifier[MOD_LANE];
            }
        });

        var refreshModifiers:PsychUIButton = new PsychUIButton(25+modifierDropDown.width+10, modifierDropDown.y, 'Refresh Modifiers', function ()
        {
            updateModList();
        }, 80, 28);

        var saveModifier:PsychUIButton = new PsychUIButton(refreshModifiers.x, refreshModifiers.y+refreshModifiers.height+20, 'Save Modifier', function ()
        {
            var alreadyExists = false;
            for (i in 0...playfieldRenderer.modchart.data.modifiers.length)
                if (playfieldRenderer.modchart.data.modifiers[i][MOD_NAME] == modNameInputText.text)
                {
                    playfieldRenderer.modchart.data.modifiers[i] = [modNameInputText.text, modClassInputText.text,
                        modTypeInputText.text, playfieldStepper.value, targetLaneStepper.value];
                    alreadyExists = true;
                }

            if (!alreadyExists)
            {
                playfieldRenderer.modchart.data.modifiers.push([modNameInputText.text, modClassInputText.text,
                    modTypeInputText.text, playfieldStepper.value, targetLaneStepper.value]);
            }
            dirtyUpdateModifiers = true;
            updateModList();
            hasUnsavedChanges = true;
        });

        var removeModifier:PsychUIButton = new PsychUIButton(saveModifier.x, saveModifier.y+saveModifier.height+20, 'Remove Modifier', function ()
        {
            for (i in 0...playfieldRenderer.modchart.data.modifiers.length)
                if (playfieldRenderer.modchart.data.modifiers[i][MOD_NAME] == modNameInputText.text)
                {
                    playfieldRenderer.modchart.data.modifiers.remove(playfieldRenderer.modchart.data.modifiers[i]);
                }
            dirtyUpdateModifiers = true;
            updateModList();
            hasUnsavedChanges = true;
        }, 80, 28);

        modNameInputText = new PsychUIInputText(modifierDropDown.x + 300, modifierDropDown.y, 160, '', 8);
        modClassInputText = new PsychUIInputText(modifierDropDown.x + 500, modifierDropDown.y, 160, '', 8);
        explainText = new FlxText(modifierDropDown.x + 200, modifierDropDown.y + 200, 160, '', 8);
        modTypeInputText = new PsychUIInputText(modifierDropDown.x + 700, modifierDropDown.y, 160, '', 8);
        playfieldStepper = new PsychUINumericStepper(modifierDropDown.x + 900, modifierDropDown.y, 1, -1, -1, 100, 0);
        targetLaneStepper = new PsychUINumericStepper(modifierDropDown.x + 900, modifierDropDown.y+300, 1, -1, -1, 100, 0);

        var modClassList:Array<String> = [];
        for (i in 0...defaultModifiers.length)
        {
            var name:String = Std.string(defaultModifiers[i]).replace("modcharting.", "");
            Debug.logInfo('mods: $i, name: $name');
            modClassList.push(name);
        }

        var modClassDropDown = new PsychUIDropDownMenu(modClassInputText.x, modClassInputText.y+30, modClassList, function(md:Int, mod:String)
        {
            modClassInputText.text = mod;
            if (modClassInputText.text != '')
                explainText.text = ('Current Modifier: ${modClassInputText.text}, Explaination: ' + modifierExplain(modClassInputText.text));
        });
        centerXToObject(modClassInputText, modClassDropDown);
        var modTypeList = ["All", "Player", "Opponent", "Lane"];
        var modTypeDropDown = new PsychUIDropDownMenu(modTypeInputText.x, modClassInputText.y+30, modTypeList, function(mod:Int, type:String)
        {
            modTypeInputText.text = type;
        });
        centerXToObject(modTypeInputText, modTypeDropDown);
        centerXToObject(modTypeInputText, explainText);

        activeModifiersText = new FlxText(50, 180);
        tab_group.add(activeModifiersText);

        tab_group.add(modNameInputText);
        tab_group.add(modClassInputText);
        tab_group.add(explainText);
        tab_group.add(modTypeInputText);
        tab_group.add(playfieldStepper);
        tab_group.add(targetLaneStepper);

        tab_group.add(refreshModifiers);
        tab_group.add(saveModifier);
        tab_group.add(removeModifier);

        tab_group.add(makeLabel(modNameInputText, 0, -15, "Modifier Name"));
        tab_group.add(makeLabel(modClassInputText, 0, -15, "Modifier Class"));
        tab_group.add(makeLabel(explainText, 0, -15, "Modifier Explaination:"));
        tab_group.add(makeLabel(modTypeInputText, 0, -15, "Modifier Type"));
        tab_group.add(makeLabel(playfieldStepper, 0, -15, "Playfield (-1 = all)"));
        tab_group.add(makeLabel(targetLaneStepper, 0, -15, "Target Lane (only for Lane mods!)"));
        tab_group.add(makeLabel(playfieldStepper, 0, 15, "Playfield number starts at 0!"));

        tab_group.add(modifierDropDown);
        tab_group.add(modClassDropDown);
        tab_group.add(modTypeDropDown);
    }

    //Thanks to glowsoony for the idea lol
    function modifierExplain(modifiersName:String):String
    {
        var explainString:String = '';

        switch modifiersName
        {
            case 'DrunkXModifier':
		explainString = "Modifier used to do a wave at X poss of the notes and targets";
            case 'DrunkYModifier':
		explainString = "Modifier used to do a wave at Y poss of the notes and targets";
            case 'DrunkZModifier':
		explainString = "Modifier used to do a wave at Z (Far, Close) poss of the notes and targets";
            case 'TipsyXModifier':
		explainString = "Modifier similar to DrunkX but don't affect notes poss";
            case 'TipsyYModifier':
		explainString = "Modifier similar to DrunkY but don't affect notes poss";
            case 'TipsyZModifier':
		explainString = "Modifier similar to DrunkZ but don't affect notes poss";
            case 'ReverseModifier':
		explainString = "Flip the scroll type (Upscroll/Downscroll)";
            case 'SplitModifier':
		explainString = "Flip the scroll type (HalfUpscroll/HalfDownscroll)";
            case 'CrossModifier':
		explainString = "Flip the scroll type (Upscroll/Downscroll/Downscroll/Upscroll)";
            case 'AlternateModifier':
		explainString = "Flip the scroll type (Upscroll/Downscroll/Upscroll/Downscroll)";
            case 'IncomingAngleModifier':
		explainString = "Modifier that changes how notes come to the target (if X and Y aplied it will use Z)";
            case 'RotateModifier':
		explainString = "Modifier used to rotate the lanes poss between a value aplied with rotatePoint (can be used with Y and X)";
            case 'StrumLineRotateModifier':
		explainString = "Modifier similar to RotateModifier but this one doesn't need a extra value (can be used with Y, X and Z)";
            case 'BumpyModifier':
		explainString = "Modifier used to make notes jump a bit in their own Perspective poss";
            case 'XModifier':
		explainString = "Moves notes and targets X";
            case 'YModifier':
		explainString = "Moves notes and targets Y";
            case 'YDModifier':
        explainString = "Moves notes and targets Y (Automatically reverses in downscroll)";
            case 'ZModifier':
		explainString = "Moves notes and targets Z (Far, Close)";
            case 'ConfusionModifier':
		explainString = "Changes notes and targets angle";
            case 'DizzyModifier':
        explainString = "Changes notes angle making a visual on them";
            case 'ScaleModifier':
		explainString = "Modifier used to make notes and targets bigger or smaller";
            case 'ScaleXModifier':
		explainString = "Modifier used to make notes and targets bigger or smaller (Only in X)";
            case 'ScaleYModifier':
		explainString = "Modifier used to make notes and targets bigger or smaller (Only in Y)";
            case 'SpeedModifier':
		explainString = "Modifier used to make notes be faster or slower";
            case 'StealthModifier':
		explainString = "Modifier used to change notes and targets alpha";
            case 'NoteStealthModifier':
		explainString = "Modifier used to change notes alpha";
            case 'LaneStealthModifier':
		explainString = "Modifier used to change targets alpha";
            case 'InvertModifier':
		explainString = "Modifier used to invert notes and targets X poss (down/left/right/up)";
            case 'FlipModifier':
		explainString = "Modifier used to flip notes and targets X poss (right/up/down/left)";
            case 'MiniModifier':
		explainString = "Modifier similar to ScaleModifier but this one does Z perspective";
            case 'ShrinkModifier':
		explainString = "Modifier used to add a boost of the notes (the more value the less scale it will be at the start)";
            case 'BeatXModifier':
		explainString = "Modifier used to move notes and targets X with a small jump effect";
            case 'BeatYModifier':
		explainString = "Modifier used to move notes and targets Y with a small jump effect";
            case 'BeatZModifier':
		explainString = "Modifier used to move notes and targets Z with a small jump effect";
            case 'BounceXModifier':
		explainString = "Modifier similar to beatX but it only affect notes X with a jump effect";
            case 'BounceYModifier':
		explainString = "Modifier similar to beatY but it only affect notes Y with a jump effect";
            case 'BounceZModifier':
		explainString = "Modifier similar to beatZ but it only affect notes Z with a jump effect";
            case 'EaseCurveModifier':
		explainString = "This enables the EaseModifiers";
            case 'EaseCurveXModifier':
		explainString = "Modifier similar to IncomingAngleMod (X), it will make notes come faster at X poss";
            case 'EaseCurveYModifier':
		explainString = "Modifier similar to IncomingAngleMod (Y), it will make notes come faster at Y poss";
            case 'EaseCurveZModifier':
		explainString = "Modifier similar to IncomingAngleMod (X+Y), it will make notes come faster at Z perspective";
            case 'EaseCurveScaleModifier':
		explainString = "Modifier similar to All easeCurve, it will make notes scale change, usually next to target";
            case 'EaseCurveAngleModifier':
		explainString = "Modifier similar to All easeCurve, it will make notes angle change, usually next to target";
            case 'InvertSineModifier':
		explainString = "Modifier used to do a curve in the notes it will be different for notes (Down and Right / Left and Up)";
            case 'BoostModifier':
		explainString = "Modifier used to make notes come faster to target";
            case 'BrakeModifier':
		explainString = "Modifier used to make notes come slower to target";
            case 'BoomerangModifier':
		explainString = "Modifier used to make notes come in reverse to target";
            case 'WaveingModifier':
		explainString = "Modifier used to make notes come faster and slower to target";
            case 'JumpModifier':
		explainString = "Modifier used to make notes and target jump";
            case 'WaveXModifier':
		explainString = "Modifier similar to drunkX but this one will simulate a true wave in X (don't affect the notes)";
            case 'WaveYModifier':
		explainString = "Modifier similar to drunkY but this one will simulate a true wave in Y (don't affect the notes)";
            case 'WaveZModifier':
		explainString = "Modifier similar to drunkZ but this one will simulate a true wave in Z (don't affect the notes)";
            case 'TimeStopModifier':
		explainString = "Modifier used to stop the notes at the top/bottom part of your screen to make it hard to read";
            case 'StrumAngleModifier':
		explainString = "Modifier combined between strumRotate, Confusion, IncomingAngleY, making a rotation easily";
            case 'JumpTargetModifier':
		explainString = "Modifier similar to jump but only target aplied";
            case 'JumpNotesModifier':
		explainString = "Modifier similar to jump but only notes aplied";
            case 'EaseXModifier':
		explainString = "Modifier used to make notes go left to right on the screen";
            case 'EaseYModifier':
		explainString = "Modifier used to make notes go up to down on the screen";
            case 'EaseZModifier':
		explainString = "Modifier used to make notes go far to near right on the screen";
            case 'HiddenModifier':
        explainString = "Modifier used to make an alpha boost on notes";
            case 'SuddenModifier':
        explainString = "Modifier used to make an alpha brake on notes";
            case 'VanishModifier':
        explainString = "Modifier fushion between sudden and hidden";
            case 'SkewModifier':
        explainString = "Modifier used to make note effects (skew)";
            case 'SkewXModifier':
        explainString = "Modifier based from SkewModifier but only in X";
            case 'SkewYModifier':
        explainString = "Modifier based from SkewModifier but only in Y";
            case 'NotesModifier':
        explainString = "Modifier based from other modifiers but only affects notes and no targets";
            case 'LanesModifier':
        explainString = "Modifier based from other modifiers but only affects targets and no notes";
            case 'StrumsModifier':
        explainString = "Modifier based from other modifiers but affects targets and notes";
            case 'TanDrunkXModifier':
        explainString = "Modifier similar to drunk but uses tan instead of sin in X";
            case 'TanDrunkYModifier':
        explainString = "Modifier similar to drunk but uses tan instead of sin in Y";
            case 'TanDrunkZModifier':
        explainString = "Modifier similar to drunk but uses tan instead of sin in Z";
            case 'TanWaveXModifier':
        explainString = "Modifier similar to wave but uses tan instead of sin in X";
            case 'TanWaveYModifier':
        explainString = "Modifier similar to wave but uses tan instead of sin in Y";
            case 'TanWaveZModifier':
        explainString = "Modifier similar to wave but uses tan instead of sin in Z";
            case 'TwirlModifier':
        explainString = "Modifier that makes the notes incoming rotating in a circle in X";
            case 'RollModifier':
        explainString = "Modifier that makes the notes incoming rotating in a circle in Y";
            case 'BlinkModifier':
        explainString = "Modifier that makes the notes alpha go to 0 and go back to 1 constantly";
            case 'CosecantXModifier':
        explainString = "Modifier similar to TanDrunk but uses cosecant instead of tan in X";
            case 'CosecantYModifier':
        explainString = "Modifier similar to TanDrunk but uses cosecant instead of tan in Y";
            case 'CosecantZModifier':
        explainString = "Modifier similar to TanDrunk but uses cosecant instead of tan in Z";
            case 'TanDrunkAngleModifier':
        explainString = "Modifier similar to TanDrunk but in angle";
            case 'DrunkAngleModifier':
        explainString = "Modifier similar to Drunk but in angle";
            case 'WaveAngleModifier':
        explainString = "Modifier similar to Wave but in angle";
            case 'TanWaveAngleModifier':
        explainString = "Modifier similar to TanWave but in angle";
            case 'ShakyNotesModifier':
        explainString = "Modifier used to make notes shake in their on possition";
            case 'TordnadoModifier':
        explainString = "Modifier similar to invertSine, but notes will do their own path instead";
            case 'ArrowPath':
        explainString = "This modifier its able to make custom paths for the mods so this should be a very helpful tool";
        }

       return explainString;
    }


    function findCorrectModData(data:Array<Dynamic>) //the data is stored at different indexes based on the type (maybe should have kept them the same)
    {
        switch(data[EVENT_TYPE])
        {
            case "ease":
                return data[EVENT_DATA][EVENT_EASEDATA];
            case "set":
                return data[EVENT_DATA][EVENT_SETDATA];
        }
        return null;
    }
    function setCorrectModData(data:Array<Dynamic>, dataStr:String)
    {
        switch(data[EVENT_TYPE])
        {
            case "ease":
                data[EVENT_DATA][EVENT_EASEDATA] = dataStr;
            case "set":
                data[EVENT_DATA][EVENT_SETDATA] = dataStr;
        }
        return data;
    }
    //TODO: fix this shit
    function convertModData(data:Array<Dynamic>, newType:String)
    {
        switch(data[EVENT_TYPE]) //convert stuff over i guess
        {
            case "ease":
                if (newType == 'set')
                {
                    trace('converting ease to set');
                    var temp:Array<Dynamic> = [newType, [
                        data[EVENT_DATA][EVENT_TIME],
                        data[EVENT_DATA][EVENT_EASEDATA],
                    ], data[EVENT_REPEAT]];
                    data = temp.copy();
                }
            case "set":
                if (newType == 'ease')
                {
                    trace('converting set to ease');
                    var temp:Array<Dynamic> = [newType, [
                        data[EVENT_DATA][EVENT_TIME],
                        1,
                        "linear",
                        data[EVENT_DATA][EVENT_SETDATA],
                    ], data[EVENT_REPEAT]];
                    trace(temp);
                    data = temp.copy();
                }
        }
        //trace(data);
        return data;
    }

    function updateEventModData(shitToUpdate:String, isMod:Bool)
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            var dataSplit = dataStr.split(',');
            //the way the data works is it goes "value,mod,value,mod,....." and goes on forever, so it has to deconstruct and reconstruct to edit it and shit

            dataSplit[(getEventModIndex()*2)+(isMod ? 1 : 0)] = shitToUpdate;
            dataStr = stringifyEventModData(dataSplit);
            data = setCorrectModData(data, dataStr);
        }
    }
    function getEventModData(isMod:Bool):String
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            var dataSplit = dataStr.split(',');
            return dataSplit[(getEventModIndex()*2)+(isMod ? 1 : 0)];
        }
        return "";
    }
    function stringifyEventModData(dataSplit:Array<String>) : String
    {
        var dataStr = "";
        for (i in 0...dataSplit.length)
        {
            dataStr += dataSplit[i];
            if (i < dataSplit.length-1)
                dataStr += ',';
        }
        return dataStr;
    }
    function addNewModData()
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            dataStr += ",,"; //just how it works lol
            data = setCorrectModData(data, dataStr);
        }
        return data;
    }
    function removeModData()
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            if (selectedEventDataStepper.max > 0) //dont remove if theres only 1
            {
                var dataStr:String = findCorrectModData(data);
                var dataSplit = dataStr.split(',');
                dataSplit.resize(dataSplit.length-2); //remove last 2 things
                dataStr = stringifyEventModData(dataSplit);
                data = setCorrectModData(data, dataStr);
            }
        }
        return data;
    }
    var eventTimeStepper:PsychUINumericStepper;
    var eventModInputText:PsychUIInputText;
    var eventValueInputText:PsychUIInputText;
    var eventDataInputText:PsychUIInputText;
    var eventModifierDropDown:PsychUIDropDownMenu;
    var eventTypeDropDown:PsychUIDropDownMenu;
    var eventEaseInputText:PsychUIInputText;
    var eventTimeInputText:PsychUIInputText;
    var selectedEventDataStepper:PsychUINumericStepper;
    var repeatCheckbox:PsychUICheckBox;
    var repeatBeatGapStepper:PsychUINumericStepper;
    var repeatCountStepper:PsychUINumericStepper;
    var easeDropDown:PsychUIDropDownMenu;
    var subModDropDown:PsychUIDropDownMenu;
    var builtInModDropDown:PsychUIDropDownMenu;
    var stackedEventStepper:PsychUINumericStepper;
    function setupEventUI()
    {
       var tab_group = UI_box.getTab('Events').menu;
        eventTimeStepper = new PsychUINumericStepper(850, 50, 0.25, 0, 0, 9999, 3);

        repeatCheckbox = new PsychUICheckBox(950, 50, "Repeat Event?");
        repeatCheckbox.checked = false;
        repeatCheckbox.onClick = function()
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                data[EVENT_REPEAT][EVENT_REPEATBOOL] = repeatCheckbox.checked;
                highlightedEvent = data;
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        }
        repeatBeatGapStepper = new PsychUINumericStepper(950, 100, 0.25, 0, 0, 9999, 3);
        repeatBeatGapStepper.name = 'repeatBeatGap';
        repeatCountStepper = new PsychUINumericStepper(950, 150, 1, 1, 1, 9999, 3);
        repeatCountStepper.name = 'repeatCount';
        centerXToObject(repeatCheckbox, repeatBeatGapStepper);
        centerXToObject(repeatCheckbox, repeatCountStepper);

        eventModInputText = new PsychUIInputText(25, 50, 160, '', 8);
        eventModInputText.onChange = function(str:String, str2:String)
        {
            updateEventModData(eventModInputText.text, true);
            var data = getCurrentEventInData();
            if (data != null)
            {
                highlightedEvent = data;
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        };
        eventValueInputText = new PsychUIInputText(25 + 200, 50, 160, '', 8);
        eventValueInputText.onChange = function(str:String, str2:String)
        {
            updateEventModData(eventValueInputText.text, false);
            var data = getCurrentEventInData();
            if (data != null)
            {
                highlightedEvent = data;
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        };

        selectedEventDataStepper = new PsychUINumericStepper(25 + 400, 50, 1, 0, 0, 0, 0);
        selectedEventDataStepper.name = "selectedEventMod";

        stackedEventStepper = new PsychUINumericStepper(25 + 400, 200, 1, 0, 0, 0, 0);
        stackedEventStepper.name = "stackedEvent";

        var addStacked:PsychUIButton = new PsychUIButton(stackedEventStepper.x, stackedEventStepper.y+30, 'Add', function ()
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                var event = addNewEvent(data[EVENT_DATA][EVENT_TIME]);
                highlightedEvent = event;
                onSelectEvent();
                updateEventSprites();
                dirtyUpdateEvents = true;
            }
        });
        centerXToObject(stackedEventStepper, addStacked);

        eventTypeDropDown = new PsychUIDropDownMenu(25 + 500, 50, eventTypes, function(id:Int, t:String)
        {
            var et = t;
            trace(et);
            var data = getCurrentEventInData();
            if (data != null)
            {
                //if (data[EVENT_TYPE] != et)
                data = convertModData(data, et);
                highlightedEvent = data;
                trace(highlightedEvent);
            }
            eventEaseInputText.alpha = 1;
            eventTimeInputText.alpha = 1;
            if (et != 'ease')
            {
                eventEaseInputText.alpha = 0.5;
                eventTimeInputText.alpha = 0.5;
            }
            dirtyUpdateEvents = true;
            hasUnsavedChanges = true;
        });
        eventEaseInputText = new PsychUIInputText(25 + 650, 50+100, 160, '', 8);
        eventTimeInputText = new PsychUIInputText(25 + 650, 50, 160, '', 8);
        eventEaseInputText.onChange = function(str:String, str2:String)
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                if (data[EVENT_TYPE] == 'ease')
                    data[EVENT_DATA][EVENT_EASE] = eventEaseInputText.text;
            }
            dirtyUpdateEvents = true;
            hasUnsavedChanges = true;
        }
        eventTimeInputText.onChange = function(str:String, str2:String)
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                if (data[EVENT_TYPE] == 'ease')
                    data[EVENT_DATA][EVENT_EASETIME] = eventTimeInputText.text;
            }
            dirtyUpdateEvents = true;
            hasUnsavedChanges = true;
        }

        easeDropDown = new PsychUIDropDownMenu(25, eventEaseInputText.y+30, easeList, function(id:Int, ease:String)
        {
            var easeStr = ease;
            eventEaseInputText.text = easeStr;
            eventEaseInputText.onChange("", ""); //make sure it updates
            hasUnsavedChanges = true;
        });
        centerXToObject(eventEaseInputText, easeDropDown);

        eventModifierDropDown = new PsychUIDropDownMenu(25, 50+20, mods, function(id:Int, mod:String)
        {
            var modName = mod;
            eventModInputText.text = modName;
            updateSubModList(modName);
            eventModInputText.onChange("", ""); //make sure it updates
            hasUnsavedChanges = true;
        });
        centerXToObject(eventModInputText, eventModifierDropDown);

        subModDropDown = new PsychUIDropDownMenu(25, 50+80, subMods, function(id:Int, mod:String)
        {
            var modName = mod;
            var splitShit = eventModInputText.text.split(":"); //use to get the normal mod

            if (modName == "")
            {
                eventModInputText.text = splitShit[0]; //remove the sub mod
            }
            else
            {
                eventModInputText.text = splitShit[0] + ":" + modName;
            }

            eventModInputText.onChange("", ""); //make sure it updates
            hasUnsavedChanges = true;
        });
        centerXToObject(eventModInputText, subModDropDown);

        eventDataInputText = new PsychUIInputText(25, 300, 300, '', 8);
        eventDataInputText.onChange = function(str:String, str2:String)
        {
            var data = getCurrentEventInData();
            if (data != null)
            {
                data[EVENT_DATA][EVENT_EASEDATA] = eventDataInputText.text;
                highlightedEvent = data;
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        };

        var add:PsychUIButton = new PsychUIButton(0, selectedEventDataStepper.y+30, 'Add', function ()
        {
            var data = addNewModData();
            if (data != null)
            {
                highlightedEvent = data;
                updateSelectedEventDataStepper();
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                eventModInputText.text = getEventModData(true);
                eventValueInputText.text = getEventModData(false);
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        });
        var remove:PsychUIButton = new PsychUIButton(0, selectedEventDataStepper.y+50, 'Remove', function ()
        {
            var data = removeModData();
            if (data != null)
            {
                highlightedEvent = data;
                updateSelectedEventDataStepper();
                eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                eventModInputText.text = getEventModData(true);
                eventValueInputText.text = getEventModData(false);
                dirtyUpdateEvents = true;
                hasUnsavedChanges = true;
            }
        });
        centerXToObject(selectedEventDataStepper, add);
        centerXToObject(selectedEventDataStepper, remove);
        tab_group.add(add);
        tab_group.add(remove);

        tab_group.add(addStacked);
        //addUI(tab_group, "addStacked", addStacked, 'Add New Stacked Event', 'Adds a new stacked event and duplicates the current one.');

        tab_group.add(eventDataInputText);
        tab_group.add(stackedEventStepper);
        //addUI(tab_group, "eventDataInputText", eventDataInputText, 'Raw Event Data', 'The raw data used in the event, you wont really need to use this.');
        //addUI(tab_group, "stackedEventStepper", stackedEventStepper, 'Stacked Event Stepper', 'Allows you to find/switch to stacked events.');
        tab_group.add(makeLabel(stackedEventStepper, 0, -15, "Stacked Events Index"));

        tab_group.add(eventValueInputText);
        tab_group.add(eventModInputText);
        /*addUI(tab_group, "eventValueInputText", eventValueInputText, 'Event Value', 'The value that the modifier will change to.');
        addUI(tab_group, "eventModInputText", eventModInputText, 'Event Modifier', 'The name of the modifier used in the event.');

        addUI(tab_group, "repeatBeatGapStepper", repeatBeatGapStepper, 'Repeat Beat Gap', 'The amount of beats in between each repeat.');
        addUI(tab_group, "repeatCheckbox", repeatCheckbox, 'Repeat', 'Check the box if you want the event to repeat.');
        addUI(tab_group, "repeatCountStepper", repeatCountStepper, 'Repeat Count', 'How many times the event will repeat.');*/
        tab_group.add(repeatBeatGapStepper);
        tab_group.add(repeatCheckbox);
        tab_group.add(repeatCountStepper);

        tab_group.add(makeLabel(repeatBeatGapStepper, 0, -30, "How many beats in between\neach repeat?"));
        tab_group.add(makeLabel(repeatCountStepper, 0, -15, "How many times to repeat?"));

        tab_group.add(eventEaseInputText);
        tab_group.add(eventTimeInputText);
        /*addUI(tab_group, "eventEaseInputText", eventEaseInputText, 'Event Ease', 'The easing function used by the event (only for "ease" type).');
        addUI(tab_group, "eventTimeInputText", eventTimeInputText, 'Event Ease Time', 'How long the tween takes to finish in beats (only for "ease" type).');*/
        tab_group.add(makeLabel(eventEaseInputText, 0, -15, "Event Ease"));
        tab_group.add(makeLabel(eventTimeInputText, 0, -15, "Event Ease Time (in Beats)"));
        tab_group.add(makeLabel(eventTypeDropDown, 0, -15, "Event Type"));

        tab_group.add(eventTimeStepper);
        tab_group.add(selectedEventDataStepper);
       /* addUI(tab_group, "eventTimeStepper", eventTimeStepper, 'Event Time', 'The beat that the event occurs on.');
        addUI(tab_group, "selectedEventDataStepper", selectedEventDataStepper, 'Selected Event', 'Which modifier event is selected within the event.');*/
        tab_group.add(makeLabel(selectedEventDataStepper, 0, -15, "Selected Data Index"));
        tab_group.add(makeLabel(eventDataInputText, 0, -15, "Raw Event Data"));
        tab_group.add(makeLabel(eventValueInputText, 0, -15, "Event Value"));
        tab_group.add(makeLabel(eventModInputText, 0, -15, "Event Mod"));
        tab_group.add(makeLabel(subModDropDown, 0, -15, "Sub Mods"));

        tab_group.add(subModDropDown);
        tab_group.add(eventModifierDropDown);
        tab_group.add(eventTypeDropDown);
        tab_group.add(easeDropDown);
        /*addUI(tab_group, "subModDropDown", subModDropDown, 'Sub Mods', 'Drop down for sub mods on the currently selected modifier, not all mods have them.');
        addUI(tab_group, "eventModifierDropDown", eventModifierDropDown, 'Stored Modifiers', 'Drop down for stored modifiers.');
        addUI(tab_group, "eventTypeDropDown", eventTypeDropDown, 'Event Type', 'Drop down to swtich the event type, currently there is only "set" and "ease", "set" makes the event happen instantly, and "ease" has a time and an ease function to smoothly change the modifiers.');
        addUI(tab_group, "easeDropDown", easeDropDown, 'Eases', 'Drop down that stores all the built-in easing functions.');*/
    }
    function getCurrentEventInData() //find stored data to match with highlighted event
    {
        if (highlightedEvent == null)
            return null;
        for (i in 0...playfieldRenderer.modchart.data.events.length)
        {
            if (playfieldRenderer.modchart.data.events[i] == highlightedEvent)
            {
                return playfieldRenderer.modchart.data.events[i];
            }
        }

        return null;
    }
    function getMaxEventModDataLength() //used for the stepper so it doesnt go over max and break something
    {
        var data = getCurrentEventInData();
        if (data != null)
        {
            var dataStr:String = findCorrectModData(data);
            var dataSplit = dataStr.split(',');
            return Math.floor((dataSplit.length/2)-1);
        }
        return 0;
    }
    function updateSelectedEventDataStepper() //update the stepper
    {
        selectedEventDataStepper.max = getMaxEventModDataLength();
        if (selectedEventDataStepper.value > selectedEventDataStepper.max)
            selectedEventDataStepper.value = 0;
    }
    function updateStackedEventDataStepper() //update the stepper
    {
        stackedEventStepper.max = stackedHighlightedEvents.length-1;
        stackedEventStepper.value = stackedEventStepper.max; //when you select an event, if theres stacked events it should be the one at the end of the list so just set it to the end
    }
    function getEventModIndex() { return Math.floor(selectedEventDataStepper.value); }
    var eventTypes:Array<String> = ["ease", "set"];
    function onSelectEvent(fromStackedEventStepper = false)
    {
        //update texts and stuff
        updateSelectedEventDataStepper();
        eventTimeStepper.value = Std.parseFloat(highlightedEvent[EVENT_DATA][EVENT_TIME]);
        eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];

        eventEaseInputText.alpha = 0.5;
        eventTimeInputText.alpha = 0.5;
        if (highlightedEvent[EVENT_TYPE] == 'ease')
        {
            eventEaseInputText.alpha = 1;
            eventTimeInputText.alpha = 1;
            eventEaseInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASE];
            eventTimeInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASETIME];
        }
        eventTypeDropDown.selectedLabel = highlightedEvent[EVENT_TYPE];
        eventModInputText.text = getEventModData(true);
        eventValueInputText.text = getEventModData(false);
        repeatBeatGapStepper.value = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBEATGAP];
        repeatCountStepper.value = highlightedEvent[EVENT_REPEAT][EVENT_REPEATCOUNT];
        repeatCheckbox.checked = highlightedEvent[EVENT_REPEAT][EVENT_REPEATBOOL];
        if (!fromStackedEventStepper)
            stackedEventStepper.value = 0;
        dirtyUpdateEvents = true;
    }

    public function UIEvent(id:String, sender:Dynamic)
    {
        if (id == PsychUINumericStepper.CHANGE_EVENT && (sender is PsychUINumericStepper))
        {
            var nums:PsychUINumericStepper = cast sender;
            var wname = nums.name;
            switch(wname)
            {
                case "selectedEventMod": //stupid steppers which dont have normal callbacks
                    if (highlightedEvent != null)
                    {
                        eventDataInputText.text = highlightedEvent[EVENT_DATA][EVENT_EASEDATA];
                        eventModInputText.text = getEventModData(true);
                        eventValueInputText.text = getEventModData(false);
                    }
                case "repeatBeatGap":
                    var data = getCurrentEventInData();
                    if (data != null)
                    {
                        data[EVENT_REPEAT][EVENT_REPEATBEATGAP] = repeatBeatGapStepper.value;
                        highlightedEvent = data;
                        hasUnsavedChanges = true;
                        dirtyUpdateEvents = true;
                    }
                case "repeatCount":
                    var data = getCurrentEventInData();
                    if (data != null)
                    {
                        data[EVENT_REPEAT][EVENT_REPEATCOUNT] = repeatCountStepper.value;
                        highlightedEvent = data;
                        hasUnsavedChanges = true;
                        dirtyUpdateEvents = true;
                    }
                case "stackedEvent":
                    if (highlightedEvent != null)
                    {
                        //trace(stackedHighlightedEvents);
                        highlightedEvent = stackedHighlightedEvents[Std.int(stackedEventStepper.value)];
                        onSelectEvent(true);
                    }
            }
        }
    }

    var playfieldCountStepper:PsychUINumericStepper;
    function setupPlayfieldUI()
    {
        var tab_group = UI_box.getTab('Playfields').menu;

        playfieldCountStepper = new PsychUINumericStepper(25, 50, 1, 1, 1, 100, 0);
        playfieldCountStepper.value = playfieldRenderer.modchart.data.playfields;

        tab_group.add(playfieldCountStepper);
        tab_group.add(makeLabel(playfieldCountStepper, 0, -15, "Playfield Count"));
        tab_group.add(makeLabel(playfieldCountStepper, 55, 25, "Don't add too many or the game will lag!!!"));
    }
    function setupEditorUI()
    {
        var tab_group = UI_box.getTab('Editor').menu;

        var sliderRate:PsychUISlider = new PsychUISlider(20, 120, function(speed:Float)
            {
                playbackSpeed = speed;
                dirtyUpdateEvents = true;
            }, playbackSpeed, 0.1, 3, 250, FlxColor.WHITE, FlxColor.RED);
		sliderRate.label = 'Playback Rate';

        var songSlider:PsychUISlider = new PsychUISlider(20, 200, function(time:Float) {
            inst.time = time;
            vocals.time = inst.time;
            if (opponentVocals != null) opponentVocals.time = inst.time;
            Conductor.songPosition = inst.time;
            dirtyUpdateEvents = true;
            dirtyUpdateNotes = true;
        },  inst.time, 0, inst.length, 250, FlxColor.WHITE, FlxColor.RED);
        songSlider.label = 'Song Time';

        var check_mute_inst = new PsychUICheckBox(10, 20, "Mute Instrumental (in editor)", 100);
		check_mute_inst.checked = false;
		check_mute_inst.onClick = function()
		{
			var vol:Float = 1;

			if (check_mute_inst.checked)
				vol = 0;

			inst.volume = vol;
		};
        var check_mute_vocals = new PsychUICheckBox(check_mute_inst.x + 120, check_mute_inst.y, "Mute Main Vocals (in editor)", 100);
		check_mute_vocals.checked = false;
		check_mute_vocals.onClick = function()
		{
			var vol:Float = 1;
			if (check_mute_vocals.checked)
				vol = 0;

			if (vocals != null) vocals.volume = vol;
		};
        var check_mute_opponent_vocals = new PsychUICheckBox(check_mute_inst.x + 120, check_mute_inst.y + 40, "Mute Opp. Vocals (in editor)", 100);
		check_mute_opponent_vocals.checked = false;
		check_mute_opponent_vocals.onClick = function()
		{
			var vol:Float = 1;
			if (check_mute_opponent_vocals.checked)
				vol = 0;

			if (opponentVocals != null) opponentVocals.volume = vol;
		};

        var resetSpeed:PsychUIButton = new PsychUIButton(sliderRate.x+300, sliderRate.y, 'Reset', function ()
        {
            playbackSpeed = 1.0;
        });

        var saveJson:PsychUIButton = new PsychUIButton(20, 300, 'Save Modchart', function ()
        {
            saveModchartJson(this);
        });
        tab_group.add(saveJson);
        //addUI(tab_group, "saveJson", saveJson, 'Save Modchart', 'Saves the modchart to a .json file which can be stored and loaded later.');
        //tab_group.addAsset(saveJson, "saveJson");
		tab_group.add(sliderRate);
        tab_group.add(resetSpeed);
        //addUI(tab_group, "resetSpeed", resetSpeed, 'Reset Speed', 'Resets playback speed to 1.');
        tab_group.add(songSlider);

        tab_group.add(check_mute_inst);
        tab_group.add(check_mute_vocals);
        tab_group.add(check_mute_opponent_vocals);
    }

    // function addUI(tab_group:FlxUI, name:String, ui:FlxSprite, title:String = "", body:String = "", anchor:Anchor = null)
    // {
    //     tooltips.add(ui, {
	// 		title: title,
	// 		body: body,
	// 		anchor: anchor,
	// 		style: {
    //             titleWidth: 150,
    //             bodyWidth: 150,
    //             bodyOffset: new FlxPoint(5, 5),
    //             leftPadding: 5,
    //             rightPadding: 5,
    //             topPadding: 5,
    //             bottomPadding: 5,
    //             borderSize: 1,
    //         }
	// 	});

    //     tab_group.add(ui);
    // }
    function centerXToObject(obj1:FlxSprite, obj2:FlxSprite) //snap second obj to first
    {
        obj2.x = obj1.x + (obj1.width/2) - (obj2.width/2);
    }
    function makeLabel(obj:FlxSprite, offsetX:Float, offsetY:Float, textStr:String)
    {
        var text = new FlxText(0, obj.y+offsetY, 0, textStr);
        centerXToObject(obj, text);
        text.x += offsetX;
        return text;
    }

    var _file:FileReference;
    public function saveModchartJson(?instance:ModchartMusicBeatState = null) : Void
    {
        if (instance == null)
            instance = PlayState.instance;

		var data:String = Json.stringify(instance.playfieldRenderer.modchart.data, "\t");
        //data = data.replace("\n", "");
        //data = data.replace(" ", "");
        #if sys
        //sys.io.File.saveContent("modchart.json", data.trim());
		if ((data != null) && (data.length > 0))
        {
            _file = new FileReference();
            _file.addEventListener(#if desktop openfl.events.Event.SELECT #else openfl.events.Event.COMPLETE #end, onSaveComplete);
            _file.addEventListener(openfl.events.Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(data.trim(), "modchart.json");
        }
        #end

        hasUnsavedChanges = false;

    }
    function onSaveComplete(_):Void
    {
        _file.removeEventListener(#if desktop openfl.events.Event.SELECT #else openfl.events.Event.COMPLETE #end, onSaveComplete);
        _file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    /**
     * Called when the save file dialog is cancelled.
     */
    function onSaveCancel(_):Void
    {
        _file.removeEventListener(#if desktop openfl.events.Event.SELECT #else openfl.events.Event.COMPLETE #end, onSaveComplete);
        _file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    /**
     * Called if there is an error while saving the gameplay recording.
     */
    function onSaveError(_):Void
    {
        _file.removeEventListener(#if desktop openfl.events.Event.SELECT #else openfl.events.Event.COMPLETE #end, onSaveComplete);
        _file.removeEventListener(openfl.events.Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }
}
class ModchartEditorExitSubstate extends MusicBeatSubState
{
    var exitFunc:Void->Void;
    override public function new(funcOnExit:Void->Void)
    {
        exitFunc = funcOnExit;
        super();
    }

    override public function create()
    {
        super.create();

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});


        var warning:FlxText = new FlxText(0, 0, 0, 'You have unsaved changes!\nAre you sure you want to exit?', 48);
        warning.alignment = CENTER;
        warning.screenCenter();
        warning.y -= 150;
        add(warning);

        var goBackButton:PsychUIButton = new PsychUIButton(0, 500, 'Go Back', function()
        {
            close();
        });
        goBackButton.x = (FlxG.width*0.3)-(goBackButton.width*0.5);
        goBackButton.resize(200, 140);
        add(goBackButton);

        var exit:PsychUIButton = new PsychUIButton(0, 500, 'Exit without saving', function()
        {
            exitFunc();
        });
        exit.x = (FlxG.width*0.7)-(exit.width*0.5);
        exit.resize(200, 140);
        add(exit);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length-1]];
    }
}
