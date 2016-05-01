package components;
import events.AddedSpriteEvent;
import events.EventObject;
import events.UpdateEvent;
import events.RevealEvent;
import events.HideEvent;
import events.KillEvent;
import events.HurtEvent;
import events.GetSpriteEvent;
import flixel.util.FlxColor;
import flixel.FlxG;
import Util;
/**
 * ...
 * @author ...
 */
class Health extends Component
{



	/**
	 * Int used to decide health using health as a percent of healthMax total
	 */
	public var healthMax:Int = 8;
	/**
	 * simple health bar sprite
	 */
	private var healthBar:TwoDSprite;
	
	/**
	 * simple health bar fill sprite
	 */
	private var healthBarFill:TwoDSprite;
	
	private var health:Float = 1;
	
	private var actorSprite:TwoDSprite;
	
	public function new(name:String) 
	{
		super(name);
	}
	
	override public function init() 
	{
		super.init();
		
		if (Reflect.hasField(entity.eData, "health"))
		{
			this.healthMax = entity.eData.health;
		}
		else
		{
			entity.removeC(name);
		}
		entity.dispatchEvent(GetSpriteEvent.GET, new GetSpriteEvent(attachSprite));
		if (actorSprite == null)
		{
			entity.addEvent(AddedSpriteEvent.ADDED, function(e:AddedSpriteEvent){entity.dispatchEvent(GetSpriteEvent.GET, new GetSpriteEvent(attachSprite));});
		}
		entity.addEvent(RevealEvent.REVEAL, makeVisible);
		entity.addEvent(HideEvent.HIDE, killVisibility);
		entity.addEvent(HurtEvent.HURT, hurt);
		entity.addEvent(UpdateEvent.UPDATE, update);
	}
	
	public function hurt(e:HurtEvent)
	{
		health -= e.damage / healthMax;
	}
	
	/**
	 * sets itself and the health bars to no longer be visible
	 */
	public function killVisibility(e:HideEvent = null)
	{
		healthBar.visible = false;
		healthBarFill.visible = false;
	}

	
	/**
	 * Sets itself and the health bars to be visible
	 */
	public function makeVisible(e:RevealEvent = null)
	{
		healthBar.visible = true;
		healthBarFill.visible = true;
	}
	
	/**
	 * keeps up the position of the health bar, and maintains the fill
	 */
	public function update(e:UpdateEvent = null)
	{
		
		if (actorSprite != null)
		{
			if (healthBarFill != null)
			{
				if (health > 0)
				{
					healthBarFill.scale.set(health, 1);
				}
				else
				{
					healthBarFill.scale.set(0, 1);
				}
				healthBarFill.updateHitbox();
				healthBarFill.x = actorSprite.x;
				healthBarFill.y = actorSprite.y - 1;
				
			}
			if (healthBar != null)
			{
				healthBar.x = actorSprite.x;
				healthBar.y = actorSprite.y - 1;
			}
		}
		if (health <= 0)
		{
			kill();
		}
	}
	
	public function attachSprite(s:TwoDSprite)
	{
		actorSprite = s;			
		healthBar = new TwoDSprite(actorSprite.x, actorSprite.y - 1);
		healthBar.makeGraphic(Std.int(Math.sqrt(entity.currentNodes.length) * 8), 1, FlxColor.BLACK);
		FlxG.state.add(healthBar);
		healthBarFill = new TwoDSprite(actorSprite.x, actorSprite.y - 1);
		healthBarFill.makeGraphic(Std.int(Math.sqrt(entity.currentNodes.length) * 8), 1, FlxColor.RED);
		FlxG.state.add(healthBarFill);	
	}
	
	public function kill(e:EventObject = null)
	{
		FlxG.state.remove(healthBar);
		FlxG.state.remove(healthBarFill);
		entity.dispatchEvent(KillEvent.KILL, new KillEvent());
		entity.kill();
	}
}