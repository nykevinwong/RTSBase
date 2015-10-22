package pathfinding;
import world.Node;

/**
 * ...
 * @author John Doughty
 */
class AStar
{
	private static var path:Array<Node> = [];
	private static var openList:Array<Node> = [];
	private static var closedList:Array<Node> = [];
	private static var nodes:Array<Node>;
	private static var pathHeiristic:Int;
	private static var costToMove:Int;
	private static var levelWidth:Int;
	private static var levelHeight:Int;
	private static var end:Node;
	private static var diagonal:Bool = false;
	
	public static function newPath(start:Node, endNode:Node):Array<Node>
	{
		nodes = PlayState.getLevel().nodes;
		levelWidth = PlayState.getLevel().width;
		
		cleanParentNodes();//ensure everying this ready
		cleanUp();
		
		path = [];
		levelHeight = Math.floor(nodes.length / levelWidth);
		end = endNode;
		start.heiristic = calculateHeiristic(start.nodeX, start.nodeY, end.nodeX, end.nodeY);
		start.g = 0;
		openList.push(start);
		createNeighbors();
		if (calculate() && start != endNode)
		{
			cleanUp();
			path.push(end);
			createPath(end);
		}
		else
		{
			path = [];
		}
		cleanParentNodes();
		return path;
	}
	
	private static function cleanParentNodes()
	{
		var i:Int;
		for (i in 0...nodes.length)
		{
			nodes[i].parentNode = null;
		}
	}
	
	private static function cleanUp()
	{
		var i:Int;
		for (i in 0...nodes.length)
		{
			nodes[i].animation.play("main");
			nodes[i].g = -1;
			nodes[i].heiristic = -1;
		}
		closedList = [];
		openList = [];
	}
	private static function createPath(node:Node)
	{
		if (node.parentNode != null)
		{
			path.push(node.parentNode);
			createPath(node.parentNode);
		}
	}
	
	public static function getNext():Node
	{
		if(path.length > 1)
			return path[path.length - 2];
		else
			return path[0];
	}

	public static function getHeiristic():Int
	{
		return pathHeiristic;
	}
	
	private static function calculate()
	{
		var i:Int = 0;
        var closestIndex:Int = -1;

        for (i in 0...openList.length) 
		{
            if (closestIndex == -1) 
			{
                closestIndex = i;
            } 
			else if (openList[i].getFinal() < openList[closestIndex].getFinal()) 
			{
                closestIndex = i;
            }
        }

		for (i in 0...openList[closestIndex].neighbors.length) 
		{
			if (SetupChildNode(openList[closestIndex].neighbors[i], openList[closestIndex]))
			{
				return true;
			}
        }
        closedList.push(openList[closestIndex]);
        openList.splice(closestIndex, 1);

        if (openList.length > 0) 
		{
            return calculate();
        }
		else
		{
			return false;
		}
	}
	
	private static function createNeighbors()
	{
		var i:Int;
		var j:Int;
		for (i in 0...levelWidth) 
		{
            for (j in 0...levelHeight) 
			{
				nodes[i + j * levelWidth].neighbors = [];
				if (diagonal)
				{
					if (i - 1 >= 0 && j - 1 >= 0) 
					{
						nodes[i + j * levelWidth].neighbors.push(nodes[i - 1 + (j - 1) * levelWidth]);
					}
					if (i + 1 < levelWidth && j - 1 >= 0) 
					{
						nodes[i + j * levelWidth].neighbors.push(nodes[i + 1 + (j - 1) * levelWidth]);
					}
					if (i - 1 >= 0 && j + 1 < levelHeight) 
					{
						nodes[i + j * levelWidth].neighbors.push(nodes[i - 1 + (j + 1) * levelWidth]);
					}
					if (i + 1 < levelWidth && j + 1 < levelHeight) 
					{
						nodes[i + j * levelWidth].neighbors.push(nodes[i + 1 + (j + 1) * levelWidth]);
					}
				}
                if (j - 1 >= 0) 
				{
                    nodes[i + j * levelWidth].neighbors.push(nodes[i + (j - 1) * levelWidth]);
                }
                if (i - 1 >= 0) 
				{
                    nodes[i + j * levelWidth].neighbors.push(nodes[i - 1 + j * levelWidth]);
                }
                if (i + 1 < levelWidth) 
				{
                    nodes[i + j * levelWidth].neighbors.push(nodes[i + 1 + j * levelWidth]);
                }
                if (j + 1 < levelHeight) 
				{
                    nodes[i + j * levelWidth].neighbors.push(nodes[i + (j + 1) * levelWidth]);
                }
            }
        }
	}
	@:extern private static inline function calculateHeiristic (startX:Int, startY:Int, endX:Int, endY:Int) 
	{
        var h = Std.int(10 * Math.abs(startX - endX) + 10 * Math.abs(startY - endY));
        return h;
    }
	
	

    private static function SetupChildNode(childNode:Node, parentNode:Node):Bool 
	{
        var prospectiveG:Int;
        var i:Int;

        childNode.heiristic = calculateHeiristic(childNode.nodeX, childNode.nodeY, end.nodeX, end.nodeY);

        if (childNode.heiristic == 0) 
		{
            childNode.parentNode = parentNode;
            return true;// done if its the end
        }
		else if (childNode.isPassible() == false)
		{
			return false;
		}
		
        if (parentNode.nodeX == childNode.nodeX || parentNode.nodeY == childNode.nodeY) 
		{
            prospectiveG = parentNode.g + 10;
			if (childNode.occupant != null)
			{
				prospectiveG += 100;
			}
        } 
		else 
		{
            prospectiveG = parentNode.g + 14;//should be 14 but I'm sabotaging the heiristic for diagonals unless last resort
        }
        if (prospectiveG + childNode.heiristic < childNode.getFinal() || childNode.g == -1) 
		{
            childNode.parentNode = parentNode;
            childNode.g = prospectiveG;
			var inOpenList:Bool = false;
            for (i in 0...openList.length) 
			{
                if (childNode == openList[i]) 
				{
                    inOpenList = true;
                }
            }
			if (inOpenList == false)
			{
				for (i in 0...closedList.length) 
				{
					if (childNode == closedList[i]) 
					{
						closedList.splice(i, 1);
						break;
					}
				}
				openList.push(childNode);
			}
        }
        return false;
    }
}