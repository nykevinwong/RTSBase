package components;
import events.AttackEvent;
import events.EventObject;
import events.MoveEvent;
import world.Node;
import actors.Unit;
import systems.AStar;
import actors.ActorState;
import flixel.tweens.FlxTween;
import actors.BaseActor;
import events.StopEvent;
/**
 * ...
 * @author John Doughty
 */
class ControlledUnitAI extends AI
{
	public var targetNode(default, null):Node = null;
	public var targetEnemy:BaseActor = null;

	/**
	 * Nodes that BaseActor scans for threats
	 */
	public var threatNodes:Array<Node> = [];

	/**
	 * How many nodes over can the BaseActor Detect and opponent
	 */
	public var threatRange:Int = 2;
	
	private var state:ActorState = IDLE;
	private	var path:Array<Node> = [];
	private var failedToMove:Bool = false;
	private var aggressive:Bool = false;
	private var lastTargetNode:Node;
	private var needsReset:Bool = false;
	
	/**
	 * initializes threat range. I want to remove this need
	 * sets defaultName to 'AI'
	 * @param	threatRange
	 */
	public function new(threatRange:Int)
	{
		super();
		this.threatRange = threatRange;
		defaultName = "AI";
	}
	/**
	 * adds eventlisteners for Move, Atack, and stop
	 */
	override public function init() 
	{
		super.init();
		entity.addEvent(MoveEvent.MOVE, MoveToNode);
		entity.addEvent(AttackEvent.ATTACK_ACTOR, AttackActor);
		entity.addEvent(StopEvent.STOP, resetStates);
	}
	
	/**
	 * sets target to start either attack or chase sequence
	 * @param	aEvent 	holds target BaseActor, may need qualifier eventually
	 */
	public function AttackActor(aEvent:AttackEvent)
	{
		resetStates();
		targetEnemy = aEvent.target;
	}
	/**
	 * sets node to move to with move sequence, if the event says aggressive, it attacks enemies on the way
	 * if aggressive is off, it will ignore all enemies
	 * @param	moveEvent
	 */
	public function MoveToNode(moveEvent:MoveEvent)
	{
		resetStates();
		targetNode = moveEvent.node;
		aggressive = moveEvent.aggressive;
	}
	
	/**
	 * moves to the next node. If a path doesn't exist to the targetNode, it creates one
	 * It then attepts to move. if blocked a new path will be found
	 */
	private function move():Void
	{
		var nextMove:Node;
		failedToMove = false;
		state = MOVING;
		
		if (aggressive && isEnemyInRange())
		{
			targetEnemy = getEnemyInRange();
			attack();
			return;
		}
		
		if ((targetNode != null && path.length == 0|| targetNode != lastTargetNode) && targetNode.isPassible())
		{
			path = AStar.newPath(entity.currentNodes[0], targetNode);//remember path[0] is the last 
		}
		
		if (path.length > 1 && path[1].occupant == null)
		{
			moveAlongPath();
			
			if (entity.currentNodes[0] == targetNode)
			{
				path = [];
				state = IDLE;//Unlike other cases, this is after the action has been carried out.
			}
		}
		else if (path.length > 1 && path[1].occupant != null)
		{
			newPath();
		}
		else
		{
			targetNode = null;
			state = IDLE;
		}
		lastTargetNode = targetNode;
		if (failedToMove)
		{
			entity.animation.pause();
		}
		else
		{
			entity.animation.play("active");
		}
	}
	
	/**
	 * for the new path, separated for clean code
	 * if the new path's next position fails to be different, it sets failedToMove to true
	 */
	@:extern inline private function newPath()
	{
		var nextMove = path[1];
		path = AStar.newPath(entity.currentNodes[0], targetNode);
		if (path.length > 1 && nextMove != path[1])//In Plain english, if the new path is indeed a new path
		{
			//try new path
			if (state == ActorState.MOVING)
			{
				move();	
			} 
			else if (state == ActorState.CHASING)
			{
				chase();
			}
		}
		else
		{
			failedToMove = true;
		}
	}
	
	
	private function chase()
	{
		var nextMove:Node;
		var i:Int;
		failedToMove = false;
		
		state = CHASING;
		
		if (targetEnemy != null && targetEnemy.alive)
		{
			
			if (isEnemyInRange())
			{
				attack();
			}
			else
			{
				targetNode = targetEnemy.currentNodes[0];
				
				if (path.length == 0 || path[path.length - 1] != targetNode)
				{
					path = AStar.newPath(entity.currentNodes[0], targetNode);
				}
				
				
				if (path.length > 1 && path[1].occupant == null)
				{
					moveAlongPath();
				}
				else
				{
					newPath();
				}
			}
		}
		else
		{
			state = IDLE;
		}
		if (failedToMove)
		{
			entity.animation.pause();
		}
		else
		{
			entity.animation.play("active");
		}
	}
	
	private function attack()
	{
		var i:Int;
		state = ATTACKING;
		if (targetEnemy != null && targetEnemy.alive)
		{
			if (isEnemyInRange())
			{
				hit();
			}
			else
			{
				chase();
			}
		}
		else
		{
			state = IDLE;
		}
		entity.animation.play("attack");
	}
	
	private function idle()
	{
		state = IDLE;
		var i:Int;
		entity.animation.frameIndex = entity.idleFrame;
		entity.animation.pause();
		
		if (targetNode != null)
		{
			move();
		}
		else if (targetEnemy != null)
		{
			attack();
		}
		else if (isEnemyInThreat())
		{
			targetEnemy = getEnemyInThreat();
			attack();
		}
	}
	
	override function takeAction() 
	{
		super.takeAction();
		
		checkView();
		
		if (needsReset)
		{
			resetStates();
		}
		if (state == IDLE)
		{
			idle();
		}
		else if (state == MOVING)
		{
			move();
		}
		else if (state == ATTACKING)
		{
			attack();
		}
		else if (state == CHASING)
		{
			chase();
		}
	}
	
	private function hit()
	{
		targetEnemy.hurt(entity.damage / targetEnemy.healthMax);
		if (targetEnemy.alive == false)
		{
			targetEnemy = null;
		}
	}
	
	public function resetStates(eO:EventObject = null):Void 
	{
		state = IDLE;
		targetEnemy = null;
		aggressive = false;
		targetNode = null;
	}
	
	@:extern inline function moveAlongPath()
	{
		path.splice(0,1)[0].occupant = null;
		entity.currentNodes[0] = path[0];
		entity.currentNodes[0].occupant = entity;
		FlxTween.tween(entity, { x:entity.currentNodes[0].x, y:entity.currentNodes[0].y }, entity.speed / 1000);
	}
	
	private function isEnemyInRange():Bool
	{
		var i:Int;
		var inRange:Bool = false;
		
		for (i in 0...entity.currentNodes[0].neighbors.length)
		{
			if (entity.currentNodes[0].neighbors[i].occupant == targetEnemy && entity.currentNodes[0].neighbors[i].occupant != null || //if your target is close
			targetEnemy == null && entity.currentNodes[0].neighbors[i].occupant != null && entity.team.isThreat(entity.currentNodes[0].neighbors[i].occupant.team.id)) // if you are near an enemy with no target of your own
			{
				inRange = true;
				break;
			}
		}
		
		return inRange;
	}
	
	private function getEnemyInRange():BaseActor
	{
		var result:BaseActor = null;
		var i:Int;
		for (i in 0...entity.currentNodes[0].neighbors.length)
		{
			if (entity.currentNodes[0].neighbors[i].occupant != null && entity.team.isThreat(entity.currentNodes[0].neighbors[i].occupant.team.id))
			{
				result = entity.currentNodes[0].neighbors[i].occupant;
				break;
			}
		}
		return result;
	}
	
	private function isEnemyInThreat():Bool
	{
		var i:Int;
		var inRange:Bool = false;
		
		for (i in 0...threatNodes.length)
		{
			if (threatNodes[i].occupant == targetEnemy && threatNodes[i].occupant != null || //if your target is close
			targetEnemy == null && threatNodes[i].occupant != null && entity.team.isThreat(threatNodes[i].occupant.team.id)) // if you are near an enemy with no target of your own
			{
				inRange = true;
				break;
			}
		}
		
		return inRange;
	}
	
	private function getEnemyInThreat():BaseActor
	{
		var result:BaseActor = null;
		var i:Int;
		for (i in 0...threatNodes.length)
		{
			if (threatNodes[i].occupant != null && entity.team.isThreat(threatNodes[i].occupant.team.id))
			{
				result = threatNodes[i].occupant;
				break;
			}
		}
		return result;
	}
	
	/**
	 * Recursively checks neighboring nodes for nodes in threat range
	 * Expensive if threatRange is too great or too many BaseActors on the field
	 * @param	node 			new Node to check. If not provided, defaults to the currentNode of the Base Actor
	 */
	public function checkView(node:Node = null)
	{
		var n;
		var distance:Float;
		if (node == null)
		{
			node = entity.currentNodes[0];
		}
		for (n in node.neighbors)
		{
			if (threatNodes.indexOf(n) == -1)
			{
				distance = Math.sqrt(Math.pow(Math.abs(entity.currentNodes[0].nodeX - n.nodeX), 2) + Math.pow(Math.abs(entity.currentNodes[0].nodeY - n.nodeY), 2));
				if (distance <= threatRange)
				{
					threatNodes.push(n);
					if (distance < threatRange && n.isPassible())
					{
						checkView(n);
					}
				}
			}
		}
	}
}