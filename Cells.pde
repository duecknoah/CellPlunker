abstract class Cell {
  public static final int onCol = #ffffff;
  public static final int offCol = 0;
  public final static int labelCol = #ff0000;
  protected boolean state = false;
  protected Position pos;
  
  Cell (Position pos) {
   this.pos = pos; 
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
       stateUpdater.markCell(this, CellUpdateInfo.stateUpdate);
       stateUpdater.markNearbyCellsNext(this, CellUpdateInfo.stateUpdate);
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
  
  // Used to intialize cell once fully placed on board, this is done
  // to prevent doing checks in the constructor before placement when using functions like idToCell()
  public abstract void intialize();
  
  // Update for when a neighboring cell is placed
  public abstract void cellUpdate();
  
  // State update for when a neighboring cell that could affect this one has a state change
  public abstract void stateUpdate();
  
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
  
  public String toString() {
    return "Cell type: " + this.getClass().getName() + ", Position: " + pos.toString() + ", state: " + state;
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
  }
  
  @Override
  public void setState(boolean newState) {
     // Not legal, don't allow 
     throw new IllegalArgumentException("Cannot set the state of a constant cell!");
  }
  
  @Override
  public void intialize() {
    state = true;
    stateUpdater.markNearbyCellsNext(this, CellUpdateInfo.cellUpdate); 
  }
  
  @Override
  public void stateUpdate() {};
  @Override
  public void cellUpdate() {};
  
  @Override
  public void delete() {
    stateUpdater.markNearbyCellsNext(this, CellUpdateInfo.cellUpdate);
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
  
  @Override
  public void intialize() {
    stateUpdater.markNearbyCellsNext(this, CellUpdateInfo.cellUpdate);
  }
  @Override
  public void stateUpdate() {};
  @Override
  public void cellUpdate() {};
  
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
  
  // type (short) - see CellUpdateInfo.* for update types
  public void update(short type) {
    // If a cell update was detected, then re-update neighbors
    if (type == CellUpdateInfo.cellUpdate)
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
      stateUpdater.markCell(c, CellUpdateInfo.stateUpdate);
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
              if (!neighbors.contains(j)) { // optimize
                neighbors.add(j);
              }
            }
            else {
              if (!cables.contains(j)) { // optimize
                cables.add((CableCell) j);
              }
            }
         }
       }
       totalCalculations = cables.size() * (n.length * n.length);
    }
    //println("Total array checks: " + totalCalculations + ", cables: " + cables.size() + ", " + stateUpdater.stepNum);
  }
  
  // Removes the cable from the cableunit if it is part of it
  public void removeFromUnit(CableCell c) {
    cables.remove(c); 
  }
  
  public void merge(CableUnit other) {
    if (this == other)
      throw new IllegalArgumentException("You cannot merge two of the same CableUnits!");
    // Make all of the cables about to be added to have their cUnit reference refer to this cable unit
    for (CableCell i : other.cables)
      i.cUnit = this;
    this.neighbors.addAll(other.neighbors);
    this.cables.addAll(other.cables);
  }
  
  public String toString() {
    return "Total cables: " + cables.size() + ", Total neighbors: " + neighbors.size(); 
  }
}

// if any of the cells around it are in an 'on' state, its state is on, otherwise its state is off
class CableCell extends Cell {
  private CableUnit cUnit; // the Cableunit that this cablecell is part of
  public final static int labelCol = #ffee7f;
  
  CableCell(Position pos) {
     super(pos); 
  }
  
  @Override
  public void intialize() {
    detectCableUnit();
    cellUpdate();
  }
  
  @Override
  public void cellUpdate() {
     cUnit.update(CellUpdateInfo.cellUpdate); // update the entire cable unit neighbors and then state, which is therefore also updating this
  }
  
  @Override
  public void stateUpdate() {
    cUnit.update(CellUpdateInfo.stateUpdate); // update the entire cable unit's state which is therefore also updating this
  }
  
  @Override
  public void delete() {
    // Remove self from cable unit
    cUnit.removeFromUnit(this);
  }
  
  // Checks to see if there is an existing cable unit that this
  // is connected to, if not, a new cable unit will be created
  public void detectCableUnit() {
    Cell[] n = getNeighbors();
    CableUnit[] nCableUnit = new CableUnit[4];
    // Put neighbors's cableunits in an array called 'nCableUnit'
    for (int i = 0; i < 4; i ++) {
      if (n[i] instanceof CableCell) {
        CableCell i2 = (CableCell) n[i];
        nCableUnit[i] = i2.getCableUnit();
      }
    }
    
    // loop through 'nCableUnit'
    for (int i = 0; i < 4; i ++) {
      for (int j = i+1; j < 4; j ++) {
         if (nCableUnit[i] == nCableUnit[j]) { // if two different neighbors share the same cableUnit, make one of the references null, as we don't want to recount the same cableunit
           nCableUnit[i] = null;
           j = 4; // makes i go onto the next one, as there is no point in comparing j with i since it i is now null
         }
      }
    }
    
    for (CableUnit i : nCableUnit) {
       if (i == null)
         continue;
       if (cUnit == null) // if we are not currently in a cableUnit
         cUnit = i;
       else {
         cUnit.merge(i); 
       }
    }
    
    // otherwise, create a new cable unit and make this cablecell
    // a part of it
    if (cUnit == null) {
      ArrayList<CableCell> cables = new ArrayList<CableCell>();
      cables.add(this);
      cUnit = new CableUnit(cables);
    }
  }
  
  public void setCableUnit(CableUnit cUnit) {
    this.cUnit = cUnit; 
  }
  
  public CableUnit getCableUnit() {
   return this.cUnit; 
  }
  
  // Draws the colored label that represents this cell
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
  }
  
  @Override
  public String toString() {
    return super.toString() + ", CableUnit data: {" + cUnit.toString() + "}"; 
  }
}

// if any of the cells around it are in an 'on' state, its state is off, otherwise its state is on
class InverterCell extends RotatableCell implements Moveable {
  
  InverterCell(Position pos) {
     super(pos); 
  }
  
  @Override
  public void intialize() {
    cellUpdate(); 
  }
  
  @Override
  public void cellUpdate() {
     boolean sumState = true; // the sum state of all of the surrounding cells, if one cell is true, then the sum state will be false

     Cell cellInput = getCellBehind();
     if (cellInput == null) {
       setState(true);
       return;
     }
     sumState = (cellInput.getState()) ? false : sumState;
     setState(sumState);
  }
  
  @Override
  public void stateUpdate() {
   //TODO 
   cellUpdate(); // just do the same as the cellUpdate for now
  }
}