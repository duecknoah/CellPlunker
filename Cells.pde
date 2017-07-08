abstract class Cell {
  public static final int onCol = #ffffff;
  public static final int offCol = 0;
  public final static int labelCol = #ff0000;
  protected boolean state = false;
  protected Position pos;
  
  Cell (Position pos) {
   this.pos = pos; 
   stateUpdater.markNearbyCellsNext(this);
  }
  
  // copy constructor
  Cell (Cell c) {
    this.pos = new Position(c.pos);
    this.state = c.state;
  }
   
  // Sets state, then marks this as just updated
  public void setState(boolean newState) {
     if (state != newState) {
       state = newState;
       stateUpdater.markCell(this);
       stateUpdater.markNearbyCellsNext(this);
     }
  }
  
  public boolean getState() {
     return state; 
  }
  
  // Gets this cells neighbors (RIGHT, UP, LEFT, DOWN)
  public Cell[] getNeighbors() {
     Cell[] neighbors = new Cell[4];
     neighbors[0] = grid.cellAt(new Position(this.pos.x + 1, this.pos.y)); // RIGHT
     neighbors[1] = grid.cellAt(new Position(this.pos.x, this.pos.y - 1)); // UP
     neighbors[2] = grid.cellAt(new Position(this.pos.x - 1, this.pos.y)); // LEFT
     neighbors[3] = grid.cellAt(new Position(this.pos.x, this.pos.y + 1)); // DOWN
     //println(pos);
     return neighbors;
  }
  
  // Gets this cells neighbors only if there state is true.
  // InverterCells will only be counted if their state is true AND there orientation faces this cell (outputs to it)
  public Cell[] getStateNeighbors() {
    Cell[] stateNeighbors = getNeighbors();
    
    int i = 0;
    for (Cell n : stateNeighbors) {
      if (n instanceof InverterCell) {
         InverterCell n2 = (InverterCell) n; 
         // If this neighboring InverterCell is facing this, 
         // then we are affected by its state, so keep it in the array
         if (n2.getCellInFront() == this) {
           continue;
         }
         stateNeighbors[i] = null; // don't count this
      }
      i ++;
    }
    
    return stateNeighbors;
  }
  
  public void delete() {
    // By default do nothing, however the delete event for any cell will be run when that cell is being removed from the grid.
  }
  
  // Draws the colored label that represents this cell
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
  }
  
  // Update for cells
  public abstract void update();
  
  // Draws the state (black or white) (on or off)
  public void drawState() {
    draw();
    int col = ((state) ? onCol : offCol);
    fill(col, 125);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
  }
  
  public void drawPlacePreview() {
    if (grid.cellAt(pos) == null) {
      draw();
    }
  }
}

abstract class RotatableCell extends Cell {
  protected int orientation = 0;
  
  RotatableCell(Position pos) {
    super(pos); 
  }
  
  public void rotateLeft() {
    orientation ++;
    orientation = orientation % 4;
  }
  
  public void rotateRight() {
    orientation --;
    if (orientation < 0) {
      orientation = 3; 
    }
  }
  
  public int getOrientation() {
    return orientation; 
  }
  
  // Gets the cell in front of this one based off the orientation of this one
  public Cell getCellInFront() {
    switch(orientation) {
      case 0: // facing right
        return grid.cellAt(new Position(pos.x + 1, pos.y));
      case 1: // facing up
        return grid.cellAt(new Position(pos.x, pos.y - 1));
      case 2: // facing left
        return grid.cellAt(new Position(pos.x - 1, pos.y));
      case 3: // facing down
        return grid.cellAt(new Position(pos.x, pos.y + 1));
      default: throw new IllegalArgumentException("Invalid Orientation!");
    }
  }
  
  // Gets the cell behind this one based off the orientation of this one
  public Cell getCellBehind() {
    switch(orientation) {
      case 0: // facing right
        return grid.cellAt(new Position(pos.x - 1, pos.y));
      case 1: // facing up
        return grid.cellAt(new Position(pos.x, pos.y + 1));
      case 2: // facing left
        return grid.cellAt(new Position(pos.x + 1, pos.y));
      case 3: // facing down
        return grid.cellAt(new Position(pos.x, pos.y - 1));
      default: throw new IllegalArgumentException("Invalid Orientation!");
    }
  }
  
  // Constrains 
  public void setOrientation(int orientation) {
    if (orientation < 0 || orientation > 3) {
      throw new IllegalArgumentException("Invalid orientation: " + orientation + ", must be a number between 0-3"); 
    }
    this.orientation = orientation;
  }
  
  // Draw the label color and orientation
  @Override
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
    // Draw orientation arrow based off inverted label color
    int invertedCol = color(255 - red(labelCol), 255 - green(labelCol), 255 - blue(labelCol));
    PVector centerPos = new PVector(pos.x + 0.5, pos.y + 0.5);
    float d = 0.25; // distance from center the points on the triangle will reach
    PVector t, bl, br;
    switch(orientation) {
      case 0: // facing right
        t = new PVector(centerPos.x + d, centerPos.y);
        bl = new PVector(centerPos.x - d, centerPos.y - d);
        br = new PVector(centerPos.x - d, centerPos.y + d);
      break;
      case 1: // facing up
        t = new PVector(centerPos.x, centerPos.y - d);
        bl = new PVector(centerPos.x - d, centerPos.y + d);
        br = new PVector(centerPos.x + d, centerPos.y + d);
      break;
      case 2: // facing left
        t = new PVector(centerPos.x - d, centerPos.y);
        bl = new PVector(centerPos.x + d, centerPos.y + d);
        br = new PVector(centerPos.x + d, centerPos.y - d);
      break;
      case 3: // facing down
        t = new PVector(centerPos.x, centerPos.y + d);
        bl = new PVector(centerPos.x + d, centerPos.y - d);
        br = new PVector(centerPos.x - d, centerPos.y - d);
      break;
      default: throw new IllegalArgumentException("Illegal Orientation " + orientation);
    }
    fill(invertedCol);
    triangle(t.x, t.y, bl.x, bl.y, br.x, br.y);
    //rect(pos.x, pos.y, centerPos.x - pos.x, centerPos.y - pos.y);
  }
}

// A cell that is constantly on and cannot be turned off
class ConstantCell extends Cell {
  public final static int labelCol = #001eff;
  ConstantCell(Position pos) {
     super(pos);
     state = true;
     stateUpdater.markNearbyCellsNext(this);
  }
  
  @Override
  public void setState(boolean newState) {
     // Not legal, don't allow 
     throw new IllegalArgumentException("Cannot set the state of a constant cell!");
  }
  
  public void update() {
    // do nothing 
  }
  
  // Draws the colored label that represents this cell
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
  }
}

// A static cell that can be turned on or off
class SwitchCell extends Cell {
   public final static int labelCol = #7f8eff;
   SwitchCell (Position pos) {
      super(pos);
   }
   
  public void update() {
    // do nothing 
  }
  
  // Draws the colored label that represents this cell
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
  }
}

interface Moveable {
  public Position posPrev = null; 
}

// Holds all data for a connected unit of cable cells, this way they update together.
class CableUnit {
  private ArrayList<CableCell> cables; // the cable cells that form this cable unit 
  private ArrayList<Cell> neighbors; // neighboring cells that are touching this cable unit
  
  CableUnit (ArrayList<CableCell> cables) {
    this.cables = cables;
    this.neighbors = new ArrayList<Cell>();
  }
  
  public void update() {
    updateStateNeighbors();
    boolean finalState = false;
    
    // If any of the neighboring cells have an on state, this entire cable
    // units state is on. Otherwise the final state will be false for all of
    // the cables in this cable unit
    for (Cell i : neighbors) {
       if (i.state == true) {
        finalState = true;
        break;
       }
    }
    // Lastly update the entire cables state
    for (CableCell c : cables) {
      c.setState(finalState);
    }
  }
  
  // Updates this entire cableunits neighbors that would affect this cable units state
  private void updateStateNeighbors() {
    neighbors.clear();
    int totalCalculations = 0;
    // First gather all neighbors for each cable cell part of this unit
    for (int i = 0; i < cables.size(); i ++) {
       CableCell c = cables.get(i);
       Cell[] n = c.getStateNeighbors(); 
       // Next, loop through and put all of the neighbors that are an
       // existing cell that isn't a cable cell into the neighbors array
       for (Cell j : n) {
         if (j != null) {
            if (!(j instanceof CableCell)) {
              if (!neighbors.contains(j)) {
                neighbors.add(j);
              }
            }
            else {
              if (!cables.contains(j)) {
                cables.add((CableCell) j);
              }
            }
         }
       }
       totalCalculations = cables.size() * (n.length * n.length);
    }
    println("Total array checks: " + totalCalculations + ", cables: " + cables.size());
  }
  
  // Removes the cable from the cableunit if it is part of it
  public void removeFromUnit(CableCell c) {
    cables.remove(c); 
  }
  
  // divides this cable unit into two. Where this unit will only have whats leftover
  // and the new CableUnit will only have otherCables. This is done when cableCells are
  // removed and it splits the cable into two different parts
  public void splitCableUnit(ArrayList<CableCell> otherCables) {
    cables.removeAll(otherCables);
    CableUnit newCu = new CableUnit(otherCables);
    
    // Update all of the CableCells to point to this CableUnit
    for (CableCell i : otherCables) {
      i.setCableUnit(newCu); 
    }
  }
}

// if any of the cells around it are in an 'on' state, its state is on, otherwise its state is off
class CableCell extends Cell {
  private CableUnit cUnit; // the Cableunit that this cablecell is part of
  public final static int labelCol = #ffee7f;
  
  CableCell(Position pos) {
     super(pos); 
     detectCableUnit();
  }
  
  public void update() {
     cUnit.update(); // update the entire cable unit which is therefore also updating this
  }
  
  // Checks to see if there is an existing cable unit that this
  // is connected to, if not, a new cable unit will be created
  public void detectCableUnit() {
    Cell[] n = getNeighbors();
    // Loop through neighbors, if one of them is a CableCell, then
    // join their cableUnit
    for (Cell i : n) {
      if (i instanceof CableCell) {
       CableCell i2 = (CableCell) i;
       this.cUnit = i2.getCableUnit();
       update();
       return;
      }
    }
    // otherwise, create a new cable unit and make this cablecell
    // a part of it
    ArrayList<CableCell> cables = new ArrayList<CableCell>();
    cables.add(this);
    cUnit = new CableUnit(cables);
    update();
  }
  
  public void setCableUnit(CableUnit cUnit) {
    this.cUnit = cUnit; 
  }
  
  public CableUnit getCableUnit() {
   return this.cUnit; 
  }
  
  @Override
  public void delete() {
    // Remove self from cable unit
    cUnit.removeFromUnit(this);
  }
  
  // Draws the colored label that represents this cell
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
  }
}

// if any of the cells around it are in an 'on' state, its state is off, otherwise its state is on
class InverterCell extends RotatableCell implements Moveable {
  
  InverterCell(Position pos) {
     super(pos); 
  }
  
  public void update() {
     boolean sumState = true; // the sum state of all of the surrounding cells, if one cell is true, then the sum state will be false

     Cell cellInput = getCellBehind();
     if (cellInput == null) {
       setState(false);
       return;
     }
     sumState = (cellInput.getState()) ? false : sumState;
     setState(sumState);
  }
}