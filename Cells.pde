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
      if (n instanceof RotatableCell) {
         RotatableCell n2 = (RotatableCell) n; 
         // If this neighboring InverterCell is facing this, 
         // then we are affected by its state, so keep it in the array
         if (n2.isFacing(this)) {
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
    else {
      stroke(#000000);
      if (grid.cellAt(this.pos) instanceof Interactable)
        stroke(#66ff66);
      strokeWeight(0.15);
      noFill();
      rect(pos.x, pos.y, 1, 1); 
      noStroke();
    }
  }
  
  public String toString() {
    return "Cell type: " + this.getClass().getName() + ", Position: " + pos.toString() + ", state: " + state;
  }
  
  public JSONObject toJSON() {
    JSONObject cData = new JSONObject();
    cData.setInt("id", cellToId(this));
    cData.setJSONObject("pos", pos.toJSON());
    cData.setBoolean("state", getState());
    
    return cData;
  }
  
  // parses a representation of the Cell from JSON into this Cell's actual data. This is used when
  // loading saves as the save data is in the JSON format.
  //
  // Note that this same function is inherited and optionally can be Overrided with @Override to customize for other cells.
  public void parseJSON(JSONObject json) {
    pos.parseJSON(json.getJSONObject("pos"));
    state = json.getBoolean("state"); 
  }
  
  // The same as parseJSON, however this is run after all the cells are loaded in rather than during
  // this is done as some cells need all the cells to be placed
  // on the grid first before parsing more data for itself.
  // ex. WirelessCableCell needs to get its 'other' cell if it is connected to it
  //
  // Note that this is empty as it is optionally inherited and used in some
  // other class's that extend Cell
  public void parseJSONAfter(JSONObject json) {};
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
  
  // Returns true if this is facing Cell c
  public boolean isFacing(Cell c) {
    if (getCellInFront() == c)
      return true;
    return false;
  }
  
  @Override
  // Returns a JSON representation of this cell
  public JSONObject toJSON() {
    JSONObject cData = super.toJSON();
    cData.setInt("orientation", getOrientation());
    return cData;
  }
  
  @Override
  public void parseJSON(JSONObject json) {
    super.parseJSON(json);
    setOrientation(json.getInt("orientation"));
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

interface Interactable {
  public void interact();
  public void endInteraction();
  public boolean isBeingInteracted();
  public void interactWith(Interactable other);
}

// A static cell that can be turned on or off
class SwitchCell extends Cell implements Interactable {
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
  
  @Override
  public void delete() {
    stateUpdater.markNearbyCellsNext(this, CellUpdateInfo.cellUpdate);
  }
  
  // Interacting with this inverts the state
  public void interact() {
    setState(!getState()); 
    endInteraction();
  }
  
  // There is nothing written here as the Switch cell is interacted with and ended instantly. This is needed
  // as it implements Interactable
  public void endInteraction() {}
  
  // We return false as it is an instant interaction
  public boolean isBeingInteracted() {
    return false; 
  }
  
  // This will do nothing for the switch cell
  public void interactWith(Interactable other) {
   endInteraction();
  }
  
  // Draws the colored label that represents this cell
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
  }
}

// Holds all data for a connected unit of cable cells, this way they update together.
class CableUnit {
  public ArrayList<CableCell> cables; // the cable cells that form this cable unit 
  private ArrayList<Cell> neighbors; // neighboring cells that are touching this cable unit
  
  CableUnit (ArrayList<CableCell> cables) {
    this.cables = cables;
    this.neighbors = new ArrayList<Cell>();
  }
  
  // Create a CableUnit with only one cable
  CableUnit(CableCell c) {
    this.cables = new ArrayList<CableCell>();
    this.cables.add(c);
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
              if (j instanceof WirelessCableCell) {
                WirelessCableCell jWireless = (WirelessCableCell) j;
                if (jWireless.hasConnection()) {
                  if (!cables.contains(jWireless.getConnection())) {
                     cables.add((WirelessCableCell) jWireless); 
                  }
                }
              }
            }
         }
       }
    }
  }
  
  // Removes the cable from the cableunit if it is part of it
  public void removeFromUnit(CableCell c) {
    Cell[] neighbors = c.getNeighbors();
    CableCell[] cableNeighbors = new CableCell[4];
    int index = 0;
    
    // remove this Cable from this CableUnit
    cables.remove(c);
    
    // Get CableCell neighbors and put them in an array
    for (Cell i : neighbors) {
      if (i instanceof CableCell) {
        cableNeighbors[index] = (CableCell) i;
      }
      else {
        cableNeighbors[index] = null; 
      }
      index ++;
    }
    
    // For each CableCell Neighbor, Reset the entire connected CableUnit and set each of the connected CableCells to have a null CableUnit (this we be assigned soon).
    for (CableCell i : cableNeighbors) {
      if (i == null)
        continue;
      if (i.getCableUnit() != null) {
        i.getCableUnit().reset();
      }
      // Then give the neighbors a new CableUnit each
      i.setCableUnit(new CableUnit(i)); //<>//
    }
    
    // Next, Follow the path of cables from each neighbor, adding them to that neighbors CableUnit only if the cable has not been assigned a CableUnit
    for (CableCell i : cableNeighbors) {
      if (i == null)
        continue;
      // Do not set this CableUnit up as it is already set up (more than one cable connected)
      if (i.getCableUnit().cables.size() > 1)
        continue;
      
      Queue<CableCell> nextCableCell = new LinkedBlockingQueue<CableCell>();
      CableUnit iCableUnit = i.getCableUnit();
      nextCableCell.add(i); // starting node / cell
      
      while (!nextCableCell.isEmpty()) {
        CableCell current = nextCableCell.poll();
        ArrayList<Cell> currentN = new ArrayList<Cell>(Arrays.asList(current.getNeighbors()));
        //Cell[] currentN = current.getNeighbors();
        // Check starting node/cell as well as the neighbors on the first run. This is because the starting node is already a
        // neighbor of the cell we are trying to remove. The other 'neighbors' are neighbors of this starting node.
        if (current == i)
           currentN.add(i);
        
        for (Cell i2 : currentN) {
          if (i2 == null)
            continue;
          // Do not add the cable we are trying to remove!
          if (i2 == c)
            continue;
          if (i2 instanceof CableCell) {
            boolean isWireless = false; // Is this a Wireless Cable?
            CableCell i3 = (CableCell) i2;
            if (i2 instanceof WirelessCableCell) {
              isWireless = true;
            }
            // If neighbor of current is not already checked, then add it to the queue
            if (!iCableUnit.cables.contains(i3)) {
              nextCableCell.add(i3);
            }
            // Trace path to Wireless connection as well if it is a WirelessCable
            if (isWireless) {
              WirelessCableCell i4 = (WirelessCableCell) i3;
              if (i4.hasConnection()) {
                if (!iCableUnit.cables.contains(i4.getConnection())) {
                  nextCableCell.add(i4.getConnection());
                }
              }
            }
          }
        }
        // Finally, mark this cell as checked while adding it to the CableUnit if it is not in another CableUnit
        iCableUnit.cables.add(current);
        current.cUnit = iCableUnit;
      }
    }
  }
  
  public void reset() {
    for (CableCell i : cables) {
      i.cUnit = null; 
    }
    cables.clear();
    neighbors.clear();
  }
  
  // Adds the connected Cables from a single Cable (c) to this CableUnit. Done by tracing the path of neighbors / connections to c if they
  // are not already part of c's CableUnit. Doing this also removes any CableUnits the other cables were originally apart of
  public void joinConnectedCablesFrom(CableCell c) {
    // Next, Follow the path of cables from each CableCell neighbor of c
      Queue<CableCell> nextCableCell = new LinkedBlockingQueue<CableCell>();
      CableUnit cCableUnit = c.getCableUnit();
      nextCableCell.add(c); // starting node's / cell's
      
      while (!nextCableCell.isEmpty()) {
        CableCell current = nextCableCell.poll();
        Cell[] currentN = current.getNeighbors();
        
        for (Cell i2 : currentN) {
          if (i2 == null)
            continue;
          // Do not add the cable we are on!
          if (i2 == c)
            continue;
          if (i2 instanceof CableCell) {
            boolean isWireless = false; // Is this a Wireless Cable?
            CableCell i3 = (CableCell) i2;
            if (i2 instanceof WirelessCableCell) {
              isWireless = true;
            }
            // If neighbor of current is not already checked, then add it to the queue
            if (!cCableUnit.cables.contains(i3)) {
              nextCableCell.add(i3);
            }
            // Trace path to Wireless connection as well if it is a WirelessCable
            if (isWireless) {
              WirelessCableCell i4 = (WirelessCableCell) i3;
              if (i4.hasConnection()) {
                if (!cCableUnit.cables.contains(i4.getConnection())) {
                  nextCableCell.add(i4.getConnection());
                }
              }
            }
          }
        }
        // Finally, mark this cell as checked while adding it to the CableUnit of c
        cCableUnit.cables.add(current);
        current.setCableUnit(cCableUnit); // this will disconnect it from any other CableUnit it was originally apart of
      }
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
  
  // The JSON representation of this CableUnit.
  // NOTE that we do not store the cells that are apart of this CableUnit, as the
  // cells themselves have a reference to the CableUnit they are apart of in the save.
  public JSONObject toJSON() {
    JSONObject cData = new JSONObject();
    JSONArray neighborData = new JSONArray();
      
    for (int i = 0; i < neighbors.size(); i ++) {
      neighborData.setJSONObject(i, neighbors.get(i).pos.toJSON()); 
    }
    cData.setJSONArray("neighbors", neighborData);
    return cData;
  }
  
  // Parses the json data for this CableUnit
  // Note that we are only parsing the neighbors of the json, cables are added during the loading process
  // in the class Grid function parseJSON()
  public void parseJSON(JSONObject json) {
    JSONArray nArray = json.getJSONArray("neighbors");
    
    for (int i = 0; i < nArray.size(); i ++) {
      JSONObject n = nArray.getJSONObject(i);
      Cell nCell = grid.cellAt(new Position(n));
      neighbors.add(nCell);
    }
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
    if (cUnit == null)
      return;
    cUnit.update(CellUpdateInfo.cellUpdate); // update the entire cable unit neighbors and then state, which is therefore also updating this
  }
  
  @Override
  public void stateUpdate() {
    if (cUnit == null)
      return;
    cUnit.update(CellUpdateInfo.stateUpdate); // update the entire cable unit's state which is therefore also updating this
  }
  
  @Override
  public void delete() {
    // Remove self from cable unit
    cUnit.removeFromUnit(this);
    stateUpdater.markNearbyCellsNext(this, CellUpdateInfo.cellUpdate);
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
    return super.toString() + ", CableUnit data: {" + getCableUnit() + "}"; 
  }
  
  @Override
  public JSONObject toJSON() {
    JSONObject cData = super.toJSON();
    if (getCableUnit() != null)
      cData.setInt("cableUnit", getCableUnit().hashCode());
    else
      cData.setInt("cableUnit", -1); // -1 means no cableUnit
    return cData;
  }
}

// if any of the cells around it are in an 'on' state, its state is off, otherwise its state is on
class InverterCell extends RotatableCell {
  
  InverterCell(Position pos) {
     super(pos); 
  }
  
  @Override
  public void intialize() {
    cellUpdate();
    stateUpdater.markCell(this, CellUpdateInfo.cellUpdate);
    stateUpdater.markNearbyCellsNext(this, CellUpdateInfo.cellUpdate);
  }
  
  @Override
  public void cellUpdate() {
     // the sum state of the cell behind it (input cell), if it is true, 
     // then the sumState will be false. If the input cell 
     // is false, then the sumState will be false
     boolean sumState = true;

     Cell cellInput = getCellBehind();
     if (cellInput == null) {
       setState(true);
       return;
     }
     // If the cell input is rotatable, then only count its state if it is facing this.
     if (cellInput instanceof RotatableCell) {
       RotatableCell i = (RotatableCell) cellInput;
       sumState = (i.isFacing(this)) ? !i.getState() : sumState;
     }
     else sumState = (cellInput.getState()) ? false : sumState;
     setState(sumState);
  }
  
  @Override
  public void stateUpdate() {
   //TODO 
   cellUpdate(); // just do the same as the cellUpdate for now
  }
  
  @Override
  public void setState(boolean newState) {
    if (this.state != newState) {
      this.state = newState;
      Cell cFront = getCellInFront();
      if (cFront != null)
        stateUpdater.markCellNext(getCellInFront(), CellUpdateInfo.cellUpdate);
    }
  }
}

class WirelessCableCell extends CableCell implements Interactable {
  
  public final static int labelCol = #ffee7f;
  public final static int markerCol = #333333;
  private WirelessCableCell other; // the Wireless cable cell this is linked with
  public boolean isBeingInteracted = false;
  
  WirelessCableCell (Position pos) {
    super(pos); 
    other = null;
  }
  
  @Override
  public void draw() {
    fill(labelCol);
    noStroke();
    rect(pos.x, pos.y, 1, 1);
    fill(markerCol);
    ellipse(pos.x + 0.5, pos.y + 0.5, 0.35, 0.35);
    if (isBeingInteracted) {
      drawConnectionLine(pos, blockPlacementUI.previewBlock.pos);
    }
    else if (other != null)
      drawConnectionLine(this.pos, other.pos);
  }
  
  public void drawConnectionLine(Position posStart, Position posEnd) {
    stroke(markerCol);
    strokeWeight(0.05);
    line(posStart.x + 0.5, posStart.y + 0.5, posEnd.x + 0.5, posEnd.y + 0.5);
    noStroke();
  }
  
  // Establishes a connection between this and another WirelessCable Cell
  public void connectTo(WirelessCableCell other) {
    // Remove any existing connection from other before connecting to other
    if (other.hasConnection()) {
      other.disconnect(); 
    }
    if (this.hasConnection()) {
     this.disconnect();
    }
    // Connect both WirelessCableCells to each other
    this.connectToOther(other);
    other.connectToOther(this);
    // Lastly, merge their cable units
    CableUnit unit = this.getCableUnit();
    try {
    unit.merge(other.getCableUnit());
    } catch (IllegalArgumentException e) {
       // Catching in case the two wirelessCable Cell's
       // are already apart of the same CableUnit
    }
  }
  
  // Connects this to the other WirelessCableCell, but NOT the other way around. Use connectTo() to establish a proper connection!
  public void connectToOther(WirelessCableCell other) {
     this.other = other;
     stateUpdater.markCellNext(this, CellUpdateInfo.cellUpdate);
  }
  
  // Retuns true if there is a connection currently with another WirelessCableCell
  public boolean hasConnection() {
    if (other != null)
      return true;
    return false;
  }
  
  // Returns the connected WirelessCableCell, will return null if there is none
  public WirelessCableCell getConnection() {
    return other; 
  }
  
  // Removes the connection from both other and this.
  public void disconnect() {
    if (other != null) {
      other.disconnectFromOther(); // disconnect other from this
      disconnectFromOther(); // disconnect this from other
    }
  }
  
  // Removes the connection via THIS END ONLY, use disconnect() to have both WirelessCableCells be disconnected from each other 
  public void disconnectFromOther() {
    other = null;
    setCableUnit(new CableUnit(this));
    getCableUnit().joinConnectedCablesFrom(this);
    stateUpdater.markCellNext(this, CellUpdateInfo.cellUpdate);
  }
  
  public void interact() {
     isBeingInteracted = true;
  }
  
  public void endInteraction() {
    isBeingInteracted = false; 
  }
  
  public boolean isBeingInteracted() {
    return isBeingInteracted; 
  }
  
  public void interactWith(Interactable other) {
    if (other instanceof WirelessCableCell) {
      // If we are not trying to connect to ourself and
      // we are not trying to connect to what we are already connected to
      if (other != this && other != this.other) {
        connectTo((WirelessCableCell) other); 
      }
      else {
       disconnect(); 
      }
    }
    endInteraction();
  }
  
  public void delete() {
    disconnect();
    super.delete(); 
  }
  
  @Override
  public JSONObject toJSON() {
    // First do inherited toJSON methods, then add data specific to this
    // WirelessCableCell
    JSONObject jsonData = super.toJSON();
    // Add data of which other WirelessCableCell this is connected to, if any
    if (hasConnection()) {
      jsonData.setJSONObject("other", getConnection().pos.toJSON());
    }
    else {
      jsonData.setJSONObject("other", null); // no connection 
    }
    return jsonData;
  }
  
  @Override
  public void parseJSONAfter(JSONObject json) {
     // If there is supposed to be a connection and it isn't connected yet, connect it to the cell 'other'
    if (!json.isNull("other") && !hasConnection()) {
        JSONObject other = json.getJSONObject("other");
        // the grid is still considered null if we are loading a file, then parsingJSON from it 
        Cell cOther = grid.cellAt(new Position(other.getInt("x"), other.getInt("y")));
        connectTo((WirelessCableCell) cOther);
    }
  }
}