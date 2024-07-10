#if !macro
import states.PlayState;
import backend.CoolUtil;
import backend.Conductor;
import backend.ClientPrefs;
import backend.Paths;
import states.LoadingState;
import backend.Difficulty;
import substates.MusicBeatSubState;
import objects.Note;
import objects.StrumArrow;
import backend.song.Song;

#if LUA_ALLOWED
import psychlua.FunkinLua;
import psychlua.HScript as FunkinHScript;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import modcharting.Modifier;
import modcharting.Modifier.ModifierSubValue;
import modcharting.Modifier.ModifierType;

import haxe.ds.List;
import objects.Note;
import lime.math.Vector4;
#end
