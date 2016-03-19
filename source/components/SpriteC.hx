package components;
import events.MoveToEvent;
import flixel.FlxSprite;
import events.AnimateAttackEvent;
import events.MoveAnimEvent;
import events.IdleAnimationEvent;
import events.StopEvent;
import events.KillEvent;
import events.HideEvent;
import events.HurtEvent;
import events.RevealEvent;
import flixel.FlxG;
import flixel.tweens.FlxTween;

/**
 * ...
 * @author John Doughty
 */
class SpriteC extends Component
{
	var sprite:FlxSprite;
	var idleFrame:Int;
	public function new(name:String) 
	{
		super(name);
	}
	
	override public function init() 
	{
		super.init();
		var assetPath:String;
		
		
		if (Reflect.hasField(entity.eData, "spriteFile") && Reflect.hasField(entity.eData, "speed") && entity.currentNodes.length > 0)
		{
			assetPath = "assets" + entity.eData.spriteFile.substr(2);
			sprite = new FlxSprite(entity.currentNodes[0].x, entity.currentNodes[0].y);
			sprite.loadGraphic(assetPath, true, 8, 8);
			sprite.animation.add("active", [0, 1], 5, true);
			sprite.animation.add("attack", [0, 2], 5, true);
			sprite.animation.add("idle", [0], 5, true);
			entity.addEvent(RevealEvent.REVEAL, makeVisible);
			entity.addEvent(HideEvent.HIDE, killVisibility);
			entity.addEvent(KillEvent.KILL, kill);
			entity.addEvent(IdleAnimationEvent.IDLE, idleAnim);
			entity.addEvent(AnimateAttackEvent.ATTACK, attackAnim);
			entity.addEvent(MoveAnimEvent.MOVE, activeAnim);
			entity.addEvent(MoveToEvent.MOVE, moveTo);
			entity.width = sprite.width;
			entity.height = sprite.height;
			
			FlxG.state.add(sprite);
		}
		else
		{
			entity.removeC(name);
		}
	}	
	/**
	 * sets itself and the health bars to no longer be visible
	 */
	public function killVisibility(e:HideEvent)
	{
		sprite.visible = false;
	}

	
	/**
	 * Sets itself and the health bars to be visible
	 */
	public function makeVisible(e:RevealEvent)
	{
		sprite.visible = true;
	}
	
	public function kill(e:KillEvent)
	{
		sprite.kill();
	}
	
	public function attackAnim(e:AnimateAttackEvent)
	{
		sprite.animation.play("attack");
	}
	
	public function activeAnim(e:MoveAnimEvent)
	{
		sprite.animation.play("active");
	}
	
	public function idleAnim(e:IdleAnimationEvent)
	{
		sprite.animation.play("idle");
	}
	
	public function moveTo(e:MoveToEvent)
	{
		FlxTween.tween(sprite, { x:e.x, y:e.y }, entity.eData.speed / 1000);
		FlxTween.tween(entity, { x:e.x, y:e.y }, entity.eData.speed / 1000);
	}
}