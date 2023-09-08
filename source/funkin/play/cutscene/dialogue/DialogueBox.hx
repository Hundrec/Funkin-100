package funkin.play.cutscene.dialogue;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.text.FlxText;
import flixel.addons.text.FlxTypeText;
import funkin.util.assets.FlxAnimationUtil;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass.IDialogueScriptedClass;
import flixel.util.FlxColor;

class DialogueBox extends FlxSpriteGroup implements IDialogueScriptedClass
{
  public final dialogueBoxId:String;
  public var dialogueBoxName(get, never):String;

  function get_dialogueBoxName():String
  {
    return boxData?.name ?? 'UNKNOWN';
  }

  var boxData:DialogueBoxData;

  /**
   * Offset the speaker's sprite by this much when playing each animation.
   */
  var animationOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

  /**
   * The current animation offset being used.
   */
  var animOffsets(default, set):Array<Float> = [0, 0];

  function set_animOffsets(value:Array<Float>):Array<Float>
  {
    if (animOffsets == null) animOffsets = [0, 0];
    if ((animOffsets[0] == value[0]) && (animOffsets[1] == value[1])) return value;

    var xDiff:Float = value[0] - animOffsets[0];
    var yDiff:Float = value[1] - animOffsets[1];

    this.x += xDiff;
    this.y += yDiff;

    return animOffsets = value;
  }

  /**
   * The offset of the speaker overall.
   */
  public var globalOffsets(default, set):Array<Float> = [0, 0];

  function set_globalOffsets(value:Array<Float>):Array<Float>
  {
    if (globalOffsets == null) globalOffsets = [0, 0];
    if (globalOffsets == value) return value;

    var xDiff:Float = value[0] - globalOffsets[0];
    var yDiff:Float = value[1] - globalOffsets[1];

    this.x += xDiff;
    this.y += yDiff;
    return globalOffsets = value;
  }

  var boxSprite:FlxSprite;
  var textDisplay:FlxTypeText;

  var text(default, set):String;

  function set_text(value:String):String
  {
    this.text = value;

    textDisplay.resetText(this.text);
    textDisplay.start();

    return this.text;
  }

  public var speed(default, set):Float;

  function set_speed(value:Float):Float
  {
    this.speed = value;
    textDisplay.delay = this.speed * 0.05; // 1.0 x 0.05
    return this.speed;
  }

  public function new(dialogueBoxId:String)
  {
    super();
    this.dialogueBoxId = dialogueBoxId;
    this.boxData = DialogueBoxDataParser.parseDialogueBoxData(this.dialogueBoxId);

    if (boxData == null) throw 'Could not load dialogue box data for box ID "$dialogueBoxId"';
  }

  public function onCreate(event:ScriptEvent):Void
  {
    this.globalOffsets = [0, 0];
    this.x = 0;
    this.y = 0;
    this.alpha = 1;

    this.boxSprite = new FlxSprite(0, 0);
    add(this.boxSprite);

    loadSpritesheet();
    loadAnimations();

    loadText();
  }

  function loadSpritesheet():Void
  {
    trace('[DIALOGUE BOX] Loading spritesheet ${boxData.assetPath} for ${dialogueBoxId}');

    var tex:FlxFramesCollection = Paths.getSparrowAtlas(boxData.assetPath);
    if (tex == null)
    {
      trace('Could not load Sparrow sprite: ${boxData.assetPath}');
      return;
    }

    this.boxSprite.frames = tex;

    if (boxData.isPixel)
    {
      this.boxSprite.antialiasing = false;
    }
    else
    {
      this.boxSprite.antialiasing = true;
    }

    this.flipX = boxData.flipX;
    this.globalOffsets = boxData.offsets;
    this.setScale(boxData.scale);
  }

  public function setText(newText:String):Void
  {
    textDisplay.prefix = '';
    textDisplay.resetText(newText);
    textDisplay.start();
  }

  public function appendText(newText:String):Void
  {
    textDisplay.prefix = this.textDisplay.text;
    textDisplay.resetText(newText);
    textDisplay.start();
  }

  public function skip():Void
  {
    textDisplay.skip();
  }

  /**
   * Reassign this to set a callback.
   */
  function onTypingComplete():Void
  {
    // No save navigation? :(
    if (typingCompleteCallback != null) typingCompleteCallback();
  }

  public var typingCompleteCallback:() -> Void;

  /**
   * Set the sprite scale to the appropriate value.
   * @param scale
   */
  public function setScale(scale:Null<Float>):Void
  {
    if (scale == null) scale = 1.0;
    this.boxSprite.scale.x = scale;
    this.boxSprite.scale.y = scale;
    this.boxSprite.updateHitbox();
  }

  function loadAnimations():Void
  {
    trace('[DIALOGUE BOX] Loading ${boxData.animations.length} animations for ${dialogueBoxId}');

    FlxAnimationUtil.addAtlasAnimations(this.boxSprite, boxData.animations);

    for (anim in boxData.animations)
    {
      if (anim.offsets == null)
      {
        setAnimationOffsets(anim.name, 0, 0);
      }
      else
      {
        setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
      }
    }

    var animNames:Array<String> = this.boxSprite?.animation?.getNameList() ?? [];
    trace('[DIALOGUE BOX] Successfully loaded ${animNames.length} animations for ${dialogueBoxId}');

    boxSprite.animation.callback = this.onAnimationFrame;
    boxSprite.animation.finishCallback = this.onAnimationFinished;
  }

  /**
   * Called when an animation finishes.
   * @param name The name of the animation that just finished.
   */
  function onAnimationFinished(name:String):Void {}

  /**
   * Called when the current animation's frame changes.
   * @param name The name of the current animation.
   * @param frameNumber The number of the current frame.
   * @param frameIndex The index of the current frame.
   *
   * For example, if an animation was defined as having the indexes [3, 0, 1, 2],
   * then the first callback would have frameNumber = 0 and frameIndex = 3.
   */
  function onAnimationFrame(name:String = "", frameNumber:Int = -1, frameIndex:Int = -1):Void
  {
    // Do nothing by default.
    // This can be overridden by, for example, scripts,
    // or by calling `animationFrame.add()`.

    // Try not to do anything expensive here, it runs many times a second.
  }

  function loadText():Void
  {
    textDisplay = new FlxTypeText(0, 0, 300, '', 32);
    textDisplay.fieldWidth = boxData.text.width;
    textDisplay.setFormat('Pixel Arial 11 Bold', boxData.text.size, FlxColor.fromString(boxData.text.color), LEFT, SHADOW,
      FlxColor.fromString(boxData.text.shadowColor ?? '#00000000'), false);
    textDisplay.borderSize = boxData.text.shadowWidth ?? 2;
    textDisplay.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];

    textDisplay.completeCallback = onTypingComplete;

    textDisplay.x += boxData.text.offsets[0];
    textDisplay.y += boxData.text.offsets[1];

    add(textDisplay);
  }

  /**
   * @param name The name of the animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   * @param reversed If true, play the animation backwards, from the last frame to the first.
   */
  public function playAnimation(name:String, restart:Bool = false, reversed:Bool = false):Void
  {
    var correctName:String = correctAnimationName(name);
    if (correctName == null) return;

    this.boxSprite.animation.play(correctName, restart, false, 0);

    applyAnimationOffsets(correctName);
  }

  /**
   * Ensure that a given animation exists before playing it.
   * Will gracefully check for name, then name with stripped suffixes, then 'idle', then fail to play.
   * @param name
   */
  function correctAnimationName(name:String):String
  {
    // If the animation exists, we're good.
    if (hasAnimation(name)) return name;

    trace('[DIALOGUE BOX] Animation "$name" does not exist!');

    // Attempt to strip a `-alt` suffix, if it exists.
    if (name.lastIndexOf('-') != -1)
    {
      var correctName = name.substring(0, name.lastIndexOf('-'));
      trace('[DIALOGUE BOX] Attempting to fallback to "$correctName"');
      return correctAnimationName(correctName);
    }
    else
    {
      if (name != 'idle')
      {
        trace('[DIALOGUE BOX] Attempting to fallback to "idle"');
        return correctAnimationName('idle');
      }
      else
      {
        trace('[DIALOGUE BOX] Failing animation playback.');
        return null;
      }
    }
  }

  public function hasAnimation(id:String):Bool
  {
    if (this.boxSprite.animation == null) return false;

    return this.boxSprite.animation.getByName(id) != null;
  }

  /**
   * Returns the name of the animation that is currently playing.
   * If no animation is playing (usually this means the character is BROKEN!),
   *   returns an empty string to prevent NPEs.
   */
  public function getCurrentAnimation():String
  {
    if (this.animation == null || this.animation.curAnim == null) return "";
    return this.animation.curAnim.name;
  }

  /**
   * Define the animation offsets for a specific animation.
   */
  public function setAnimationOffsets(name:String, xOffset:Float, yOffset:Float):Void
  {
    animationOffsets.set(name, [xOffset, yOffset]);
  }

  /**
   * Retrieve an apply the animation offsets for a specific animation.
   */
  function applyAnimationOffsets(name:String):Void
  {
    var offsets:Array<Float> = animationOffsets.get(name);
    if (offsets != null && !(offsets[0] == 0 && offsets[1] == 0))
    {
      this.animOffsets = offsets;
    }
    else
    {
      this.animOffsets = [0, 0];
    }
  }

  public function isAnimationFinished():Bool
  {
    return this.boxSprite?.animation?.finished ?? false;
  }

  public function onDialogueStart(event:DialogueScriptEvent):Void {}

  public function onDialogueCompleteLine(event:DialogueScriptEvent):Void {}

  public function onDialogueLine(event:DialogueScriptEvent):Void {}

  public function onDialogueSkip(event:DialogueScriptEvent):Void {}

  public function onDialogueEnd(event:DialogueScriptEvent):Void {}

  public function onUpdate(event:UpdateScriptEvent):Void {}

  public function onDestroy(event:ScriptEvent):Void
  {
    if (boxSprite != null) remove(boxSprite);
    boxSprite = null;
    if (textDisplay != null) remove(textDisplay);
    textDisplay = null;

    this.clear();

    this.x = 0;
    this.y = 0;
    this.globalOffsets = [0, 0];
    this.alpha = 0;

    this.kill();
  }

  public function onScriptEvent(event:ScriptEvent):Void {}
}
