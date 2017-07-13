class Position {
   public int x;
   public int y;
   
   Position (int x, int y) {
      this.x = x;
      this.y = y;
   }
   
   // Copy Constructor
   Position (Position pos) {
     this.x = pos.x;
     this.y = pos.y;
   }
   
   public void setPos(int x, int y) {
      this.x = x;
      this.y = y;
   }
   
   @Override
   public String toString() {
     return "{x: " + x + ", y: " + y + "}"; 
   }
}

class CellUpdateInfo {
  // If a cell is placed, it will update its neighbors via a cell update
  // If a cells state is changed, it will update its neighbors via a state update
  private Cell cell; // the position in the grid of the cell update
  private short type; // type of update at pos
  public final static short stateUpdate = 0;
  public final static short cellUpdate = 1;
  
  CellUpdateInfo (Cell cell, short type) {
    this.cell = cell;
    this.type = type; // cell update by default
  }
  
  CellUpdateInfo (Cell cell) {
    this.cell = cell;
    setTypeAsCellUpdate(); // cell update by default
  }
  
  // Sets the update type as a Normal Cell update
  public void setTypeAsStateUpdate() {
    type = stateUpdate;
  }
  
  public void setTypeAsCellUpdate() {
    type = cellUpdate; 
  }
  
  // Gets the update type
  public short getType() {
    return type; 
  }
  
  // Gets the cell
  public Cell getCell() {
    return cell; 
  }
}

// Holds all Cell data and functions to retrieve cell data
class Grid {
   private final int xsize;
   private final int ysize;
   public boolean viewCellStates = false; // draw cell states? If false, it will draw the label color of the cell instead
   private Cell[][] cells;
   
   Grid (int width, int height) {
     xsize = width;
     ysize = height;
     cells = new Cell[xsize][ysize];
     
     for (int ix = 0; ix < xsize; ix ++) {
       for (int iy = 0; iy < ysize; iy ++) {
           cells[ix][iy] = null; // set cell data as null by default
       }
     }
   }
   
   // Gets the state of a cell at a given position
   public boolean getState(Position pos) {
     if (inBounds(pos)) {
       Cell c = cellAt(pos);
       if (c != null) {
          return c.getState(); 
       }
     }
     return false;
   }
   
   // Returns true if coordinates are in bounds on the grid
   public boolean inBounds(Position pos) {
       if (pos.x < 0 || pos.x > xsize - 1 || pos.y < 0 || pos.y > ysize - 1) {
          return false; 
       }
       return true;
   }
   
   // Draw each cell
   public void draw() {
     for (int ix = 0; ix < xsize; ix ++) {
       for (int iy = 0; iy < ysize; iy ++) {
         // Draw using cells method if a cell exists there
         if (cells[ix][iy] != null) {
            if (viewCellStates) {
              cells[ix][iy].drawState();
            }
            else {
              cells[ix][iy].draw(); 
            }
         }
       }
     }
   }
   
   public Cell cellAt(Position pos) {
      if (inBounds(pos)) {
        return cells[pos.x][pos.y];
      }
      return null;
   }
   
   // Attempts to place the desired cell at the specified position.
   // Returns true - successful
   // Returns false - failed to place
   public boolean placeCell(int id, Position pos) {
     if (inBounds(pos) == false) {
       return false; 
     }
     if (cellAt(pos) != null) {
       return false; 
     }
     cells[pos.x][pos.y] = idToCell(id, pos);
     cells[pos.x][pos.y].intialize();
     return true;
   }
   
   // Attempts to remove the cell at the specified position
   // returns true - succesful
   // returns false - failed to clear cell
   public boolean clearCell(Position pos) {
     if (inBounds(pos) == false) {
       return false; 
     }
     cells[pos.x][pos.y].delete(); // prepare cell for deletion
     cells[pos.x][pos.y] = null; // clear cell from grid
     return true;
   }
   
   // Attempts to place the desired cell at the specified position with the desired orientation.
   // Returns true - successful
   // Returns false - failed to place
   public boolean placeCell(int id, Position pos, int orientation) {
     if (inBounds(pos) == false) {
       return false; 
     }
     if (cellAt(pos) != null) {
       return false; 
     }
     cells[pos.x][pos.y] = idToCell(id, pos);
     if (cells[pos.x][pos.y] instanceof RotatableCell) {
       RotatableCell c = (RotatableCell) cells[pos.x][pos.y];
       c.setOrientation(orientation);
       c.cellUpdate();
     }
     return true;
   }
   
   public int getXSize() {
      return xsize; 
   }
   
   public int getYSize() {
      return ysize; 
   }
}

// Holds all the data of which cells just updated, then marks all nearby cells
// of the just updated cells to be updated 
class StateUpdater {
  // If a cell is placed, it will update its neighbors via a cell update
  // If a cells state is changed, it will update its neighbors via a state update
  private HashMap<Position, CellUpdateInfo> cellsUpdated; // cells just updated
  private HashMap<Position, CellUpdateInfo> cellsToBeUpdated; // cells to be updated next step
  private int stepsPerSec = 16; // number of steps per second (def 8)
  private float stepTimer = 0;
  public int stepNum = 0; // REMOVE ME, ONLY HERE FOR TESTING PURPOSES
  
  StateUpdater () {
     cellsUpdated = new HashMap<Position, CellUpdateInfo>(); 
     cellsToBeUpdated = new HashMap<Position, CellUpdateInfo>();
  }
  
  // Marks cell as just updated to prevent from updating it again in the same step
  // pCell (the cell to mark as updated)
  // updateType (see the static final values via CellUpdateInfo.*)
  public void markCell(Cell pCell, short updateType) {
     // If this cell has not already been updated / marked
     if (cellsUpdated.get(pCell.pos) == null) {
       cellsUpdated.put(pCell.pos, new CellUpdateInfo(pCell, updateType)); 
     }
  }
  
  // Marks all nearby cells around pCell to be updated Next step
  // pCell (the cell to mark as updated)
  // updateType (see the static final values via CellUpdateInfo.*)
  public void markNearbyCellsNext(Cell pCell, short updateType) {
    Cell[] n = pCell.getNeighbors();
    for (Cell i : n) {
      // Prevent adding null cells to update next
      if (i == null)
        continue;
      if (cellsToBeUpdated.get(i.pos) == null) {
        cellsToBeUpdated.put(i.pos, new CellUpdateInfo(i, updateType)); 
      }
    }    
  }
  
  public void update() {
    /*
    if (stepTimer > frameRate / stepsPerSec) {
      step();
      stepTimer = 0;
    }
    else {
      stepTimer ++; 
    }
    */
    int i = 0;
    int maxSteps = 16;
    while(stateUpdater.cellsToBeUpdated.size() > 0 && i < maxSteps) {
      step(); 
      i ++;
    }
  }
  
  // Update cells to be updated and clear the cells updated
  private void step() {
    cellsUpdated.clear();
    
    HashMap<Position, CellUpdateInfo> toUpdate = new HashMap<Position, CellUpdateInfo>(cellsToBeUpdated);
    cellsToBeUpdated.clear(); // clear, that way new things can be updated the next step
    
    Iterator it = toUpdate.entrySet().iterator();
    while(it.hasNext()) {
      Map.Entry pair = (Map.Entry) it.next();
      if (pair.getValue() == null)
        continue; 
      CellUpdateInfo cInfo = (CellUpdateInfo) pair.getValue();
     // println(cInfo.getCell());
      switch(cInfo.getType()) {
        case CellUpdateInfo.cellUpdate:
          cInfo.getCell().cellUpdate();
        break;
        case CellUpdateInfo.stateUpdate:
          cInfo.getCell().stateUpdate();
        break;
        default: throw new IllegalArgumentException("Unknown update type: " + cInfo.getType());
      }
    }
    stepNum ++;
  }
}

// UI for block selection
class BlockSelectionUI {
  
  public boolean isOpened = false;
  private ArrayList<Cell> blocks = new ArrayList<Cell>(); // an instance of each type of block
  
  BlockSelectionUI() {
    // Get all types of blocks in the blocks array, used for the block selection and placement preview
    int i = 0;
    Cell nextBlock = idToCell(i, new Position(0, 0));
    while (nextBlock != null) {
      blocks.add(nextBlock);
      i ++;
      nextBlock = idToCell(i, new Position(0, 0));
    }
  }
  
  public void update() {
    if (isOpened) {
      draw();
    }
  }
  
  // Draw ui for block selection
  public void draw() {
     int BlockDrawScale = 24;
     int totalBlocks = blocks.size();
     int backgroundPadding = 64; // not affected by draw scale
     int backgroundMargin = 64;// not affected by draw scale
     int blockPadding = 2; // padding between blocks, affected by block draw scale
     int backgroundWidth = width - (backgroundMargin * 2);
     int backgroundHeight = height - (backgroundMargin * 2);
     int backgroundX = backgroundMargin;
     int backgroundY = backgroundMargin;
     int contentWidth = backgroundWidth - (blockPadding * 2); // total width of the inner content in the block selection menu
     int contentHeight = backgroundHeight - (blockPadding * 2);
     int contentX = backgroundX + backgroundPadding;
     int contentY = backgroundY + backgroundPadding;
     String blockName = ""; // shows when hovering
     
     fill(#A6C994, 127);
     rect(backgroundX, backgroundY, backgroundWidth, backgroundHeight);
     pushMatrix();
     int xPos = contentX;
     int yPos = contentY;
     translate(contentX, contentY);
     scale(BlockDrawScale);
     int i = 0;
     for (Cell c : blocks) {
        c.pos.x = 0;
        c.pos.y = 0;
        c.draw();
        if (mouseX >= xPos && mouseX <= xPos + BlockDrawScale
        && mouseY >= yPos && mouseY <= yPos + BlockDrawScale) {
          blockName = idToCellName(i);
          if (mousePressed && mouseButton == LEFT) {
            user.heldBlock = i; // holds the id of the block
            blockPlacementUI.previewBlock = idToCell(i, new Position(0, 0));
            mousePressed = false;
          }
        }
        translate(blockPadding, 0);
        xPos += blockPadding * BlockDrawScale;
        i ++;
     }
     popMatrix();
     fill(255);
     textSize(20);
     text(blockName, mouseX, mouseY - 16);
     textSize(12);
  }
}
// UI for block placement
class BlockPlacementUI {
  
  Cell previewBlock = idToCell(0, new Position(0, 0)); // the block to preview placing
  
  public void update() {
    // Allow placement if user is holding a block, and draw a preview of what it
    // would look like placed there
    if (blockSelectionUI.isOpened == false) {
      if (mousePressed) {
        // Cell placement
        if (mouseButton == LEFT && user.heldBlock != -1) {
          if (previewBlock instanceof RotatableCell) {
            RotatableCell c = (RotatableCell) previewBlock;
            grid.placeCell(user.heldBlock, new Position(previewBlock.pos), c.getOrientation());
          }
          else grid.placeCell(user.heldBlock, new Position(previewBlock.pos));
        }
        // Cell removal
        if (mouseButton == RIGHT) {
          Cell blockToRemove = grid.cellAt(previewBlock.pos);
          if (blockToRemove != null) {
            grid.clearCell(blockToRemove.pos);
          }
        }
      }
    }
    this.draw();
  }
  
  public void draw() {
    if (user.heldBlock != -1) {
      previewBlock.pos.x = mouseX;
      previewBlock.pos.y = mouseY;
      previewBlock.pos = cam.screenToGridPos(previewBlock.pos);
      previewBlock.drawPlacePreview();
    }
   }
}

class User {
  public int heldBlock = -1; // a # representing the block that the user is holding to place
}

class Camera {
   public Position pos;
   public int scale;
   
   Camera() {
     pos = new Position(0, 0);
     scale = 1;
   }
   
   public void userControl() {
      float moveSpd = 2;
      
      if (scale > 10) {
         moveSpd = 1; 
      }
      
      if (Keyboard.keys.get('w')) {
         pos.y -= moveSpd; 
      }
      if (Keyboard.keys.get('a')) {
         pos.x -= moveSpd; 
      }
      if (Keyboard.keys.get('s')) {
         pos.y += moveSpd; 
      }
      if (Keyboard.keys.get('d')) {
         pos.x += moveSpd; 
      }
      
      scale -= Mouse.wheelCount;
      scale = constrain(scale, 1, 24);
   }
   
   // Gets a position on the screen and translates it to
   // a position on the grid based off the cameras view
   public Position screenToGridPos(Position pos) {
     // Converted to float for better accuracy during calculations with transformations
     float xpos = pos.x;
     float ypos = pos.y;
     xpos -= width / 2;
     xpos /= cam.scale;
     xpos += width / 2;
     xpos += cam.pos.x;
     
     ypos -= height / 2;
     ypos /= cam.scale;
     ypos += height / 2;
     ypos += cam.pos.y;
     return new Position((int) xpos, (int) ypos);
   }
   
   // Prevents the camera from going outside the grid
   public void restrictInGrid() {
     /*
     Position tl = screenToGridPos(new Position(pos.x, pos.y)); // top left of cam on grid position
     Position br = screenToGridPos(new Position(pos.x + width, pos.y + height)); // bottom right of cam on grid position
     if (tl.x < 0)
       pos.x = 0;
     if (pos.y < 0)
       pos.y = 0;
     
     if (br.x > grid.xsize)
       pos.x = grid.xsize - (width / scale);  
     
     if (pos.y + (height / scale) > grid.ysize)
       pos.y = grid.ysize - (height / scale);
   */
   }
}

static class Keyboard {
   public static HashMap<Character, Boolean> keys = new HashMap<Character, Boolean>();
}

static class Mouse {
   public static int wheelCount = 0;
   
   public static void resetWheelCount() {
      wheelCount = 0; 
   }
}