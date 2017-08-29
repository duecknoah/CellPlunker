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

    // Creates the position directly off of the json data
    Position (JSONObject json) {
        parseJSON(json);
    }

    public void setPos(int x, int y) {
        this.x = x;
        this.y = y;
    }

    @Override
        public String toString() {
        return "{x: " + x + ", y: " + y + "}";
    }

    public JSONObject toJSON() {
        JSONObject pos = new JSONObject();
        pos.setInt("x", x);
        pos.setInt("y", y);
        return pos;
    }

    public void parseJSON(JSONObject json) {
        this.x = json.getInt("x");
        this.y = json.getInt("y");
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

    public String typeToString() {
        if (type == stateUpdate)
            return "stateUpdate";
        if (type == cellUpdate)
            return "cellUpdate";
        return "unknown";
    }
}

// Holds all Cell data and functions to retrieve cell data
class Grid {
    private int xsize;
    private int ysize;
    public boolean viewCellStates = true; // draw cell states? If false, it will draw the label color of the cell instead
    private Cell[][] cells;

    Grid (int width, int height) {
        xsize = width;
        ysize = height;
        resetGrid();
    }

    // Copy constructor
    Grid (Grid toCopy) {
        this.xsize = toCopy.xsize;
        this.ysize = toCopy.ysize;
        resetGrid();
        cells = toCopy.copyGridArea(new Position(0, 0), new Position(toCopy.xsize, toCopy.ysize)).cells;
    }

    // Clears the grid with null cells
    public void resetGrid() {
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
        // Draw the grid shader by setting up the proper arguments and using the shader via 'filter()'
        Position pos = new Position(cam.pos);
        pos.x += width / 2;
        pos.x *= cam.scale;
        pos.x -= width / 2;

        pos.y += height / 2;
        pos.y *= cam.scale;
        pos.y -= height / 2;

        gridShader.set("pos", (float)pos.x, (float)pos.y);
        gridShader.set("scale", (float)cam.scale);
        gridShader.set("grid_dim", (float) grid.getXSize(), (float) grid.getYSize());
        gridShader.set("screen_dim", (float) width, (float) height);
        filter(gridShader);

        // Draw each cell
        for (int ix = 0; ix < xsize; ix ++) {
            for (int iy = 0; iy < ysize; iy ++) {
                // Draw using cells method if a cell exists there
                if (cells[ix][iy] != null) {
                    if (viewCellStates) {
                        cells[ix][iy].drawState();
                    } else {
                        cells[ix][iy].draw();
                    }
                }
            }
        }
    }

    // Draws a preview of the grid at the specified position.
    // This is used when placing a copied section of a grid, as we
    // want to show a preview of the copied grid over the users mouse
    public void drawPreview(Position pos) {
        // Draw each cell
        pushMatrix();
        translate(pos.x, pos.y);
        for (int ix = 0; ix < xsize; ix ++) {
            for (int iy = 0; iy < ysize; iy ++) {
                // Draw using cells method if a cell exists there
                if (cells[ix][iy] != null) {
                    cells[ix][iy].drawPlacePreview();
                }
            }
        }
        popMatrix();
    }

    public Cell cellAt(Position pos) {
        if (inBounds(pos)) {
            return cells[pos.x][pos.y];
        }
        return null;
    }

    // Attempts to place the desired cell at the specified position. Then intializes it
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
        if (cellAt(pos) == null) {
            return false;
        }
        cells[pos.x][pos.y].delete(); // prepare cell for deletion
        // remove any updates involved with this cell from the stateUpdater, as we don't want to update a null Cell!
        stateUpdater.unmarkCellNext(cells[pos.x][pos.y]);
        cells[pos.x][pos.y] = null; // clear cell from grid
        return true;
    }

    // Attempts to place the desired cell at the specified position with the desired orientation. Then intializes it
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
            c.intialize();
        } else throw new IllegalArgumentException("Cannot place a Cell on an orientation when it is not rotatable!"); 
        return true;
    }

    // Attempts to place the desired cell at the specified position, then intializes it
    // Returns true - successful
    // Returns false - failed to place
    public boolean placeCell(Cell c, Position pos) {
        if (inBounds(pos) == false)
            return false;
        if (cellAt(pos) != null)
            return false;
        cells[pos.x][pos.y] = c;
        c.intialize();
        return true;
    }

    // Will force set the cell at the given position on the grid to the Cell supplied
    // unlike placeCell() It will NOT update the cell placed 
    // Returns true if successful
    // Returns false if out of bounds / not successful
    public boolean setCell(Cell c, Position pos) {
        if (c == null)
            throw new IllegalArgumentException("Cannot create a null cell! Use clearCell() instead");
        if (inBounds(pos) == false)
            return false;
        if (cellAt(pos) != null)
            clearCell(pos);
        cells[pos.x][pos.y] = c;
        c.pos = pos;
        return true;
    }

    public int getXSize() {
        return xsize;
    }

    public int getYSize() {
        return ysize;
    }

    // Copies a selection of the grid (tl - top left) (br - bottom right)
    // and returns a Grid which is a copy of that area selected
    // This Grid contains every Cell in the selection, including null Cells
    public Grid copyGridArea(Position tl, Position br) {
        // Loop through grid and fill out array
        int w = br.x - tl.x;
        int h = br.y - tl.y;
        Grid selection = new Grid(w, h);

        for (int ix = tl.x; ix < br.x; ix ++) {
            for (int iy = tl.y; iy < br.y; iy ++) {
                Cell toCopy = cellAt(new Position(ix, iy));
                Cell copiedCell;
                Position relativePos = new Position(ix - tl.x, iy - tl.y);

                if (toCopy == null)
                    continue;
                copiedCell = toCopy.makeCopy();
                selection.setCell(copiedCell, relativePos);
            }
        }

        // Currently, when WirelessCableCells are individually copied, they lose any connections they had. To fix this, we
        // check if their other (the connection) is also within the selection,
        // if it is, mark the new WirelessCableCell (other) that is in the same relative position as its other originally.
        // Otherwise, leave it as an empty connection
        for (int ix = tl.x; ix < br.x; ix ++) {
            for (int iy = tl.y; iy < br.y; iy ++) {
                Position gridPos = new Position(ix, iy);
                Position relativePos = new Position(ix - tl.x, iy - tl.y);
                Cell cOriginal = cellAt(gridPos);
                Cell cCopy = selection.cellAt(relativePos);

                // If a WirelessCableCell at this position
                if (cOriginal instanceof WirelessCableCell) {
                    WirelessCableCell cOriginalWireless = (WirelessCableCell) cOriginal;
                    WirelessCableCell cCopyWireless = (WirelessCableCell) cCopy;

                    WirelessCableCell cOriginalWirelessOther = cOriginalWireless.getConnection();

                    // If there is a connection originally
                    if (cOriginalWirelessOther != null) {
                        // If the connected WirelessCable is inside the selection, then make it so the
                        // copied version also has a connection between the two
                        if (cOriginalWirelessOther.pos.x >= tl.x && cOriginalWirelessOther.pos.y >= tl.y
                            && cOriginalWirelessOther.pos.x < br.x && cOriginalWirelessOther.pos.y < br.y) {
                            // Get the other's position offset relative to the original 
                            Position wirelessOtherOffset = new Position(cOriginalWirelessOther.pos.x - cOriginalWireless.pos.x, cOriginalWirelessOther.pos.y - cOriginalWireless.pos.y);
                            Position cCopyWirelessOtherPos = new Position(cCopyWireless.pos.x + wirelessOtherOffset.x, cCopyWireless.pos.y + wirelessOtherOffset.y);
                            // Now establish the connection!
                            cCopyWireless.connectTo((WirelessCableCell) selection.cellAt(cCopyWirelessOtherPos));
                        }
                    }
                }
            }
        }

        return selection;
    }

    // Selects a part of the grid and removes any cells in it (tl - top left) (br - bottom right)
    public void removeGridArea(Position tl, Position br) {
        for (int ix = tl.x; ix <= br.x; ix ++) {
            for (int iy = tl.y; iy <= br.y; iy ++) {
                clearCell(new Position(ix, iy));
            }
        }
    }

    // Sets the all of the cells in the given selection.
    // tl - top left (starting position of placement)
    // placement - the Grid of cells that will be placed
    public void placeGridArea(Position tl, Grid placement) {
        int w = placement.getXSize();
        int h = placement.getYSize();

        // Loop through each Cell in the grid and clear it, the paste in the Cells
        // from the placement[][] accordingly
        for (int ix = 0; ix < w; ix ++) {
            for (int iy = 0; iy < h; iy ++) {
                Position gridPos = new Position(tl.x + ix, tl.y + iy);
                Position relativePos = new Position(ix, iy);
                Cell toPlace = placement.cellAt(relativePos);

                // If not an empty cell that we are placing from the selection, the overwrite anything there
                if (toPlace != null) {
                    clearCell(gridPos);
                    setCell(toPlace, gridPos);
                }
            }
        }
        // Lastly, do a second pass which will mark anything that will connect the cableunits properly
        for (int ix = 0; ix < w; ix ++) {
            for (int iy = 0; iy < h; iy ++) {
                Position gridPos = new Position(tl.x + ix, tl.y + iy);
                Cell c = cellAt(gridPos);

                if (c instanceof CableCell) {
                    CableCell cCable = (CableCell) c;
                    cCable.cellUpdate();
                }
            }
        }
    }

    // Returns a JSONObject representation of the grid
    public JSONObject toJSON() {
        JSONObject gridData = new JSONObject();
        JSONArray cellData = new JSONArray();
        JSONObject cableUnitData = new JSONObject();
        // Grid
        gridData.setInt("width", grid.getXSize());
        gridData.setInt("height", grid.getYSize());

        // Loop through grid, and for each cell that exists, put its JSON data
        // in the cellData JSONArray
        int cellCount = 0;
        ArrayList<CableUnit> cableUnitList = new ArrayList<CableUnit>();

        for (int ix = 0; ix < this.getXSize(); ix ++) {
            for (int iy = 0; iy < this.getYSize(); iy ++) {
                Cell c = cellAt(new Position(ix, iy));
                if (c != null) {
                    cellData.setJSONObject(cellCount, c.toJSON());

                    // Gathering all instances of CableUnits
                    if (c instanceof CableCell) {
                        CableCell cCable = (CableCell) c;
                        CableUnit unit = cCable.getCableUnit();
                        if (unit != null) {
                            if (!cableUnitList.contains(unit))
                                cableUnitList.add(unit);
                        }
                    }

                    cellCount ++;
                }
            }
        }

        // Put CableUnit ArrayList into JSON Array
        for (CableUnit cu : cableUnitList) {
            cableUnitData.setJSONObject(Integer.toString(cu.hashCode()), cu.toJSON());
        }

        gridData.setJSONArray("cells", cellData);
        gridData.setJSONObject("cableUnits", cableUnitData);
        return gridData;
    }

    // Parses the JSON representation of some grids data and loads it into the games grid.
    // This involves setting the width and height of the grid, placing cells, etc.
    public void parseJSON(JSONObject gridData) {
        xsize = gridData.getInt("width");
        ysize = gridData.getInt("height");
        resetGrid();
        // Iterate through Cells in JSONArray and create them
        JSONArray cellData = gridData.getJSONArray("cells");
        HashMap<Integer, CableUnit> cUnits = new HashMap<Integer, CableUnit>(); // uses the hashCode of the CableUnit to be the index of it in this HashMap
        JSONObject cableUnitsJSON = gridData.getJSONObject("cableUnits");

        for (int i = 0; i < cellData.size(); i ++) {
            JSONObject data = cellData.getJSONObject(i);
            int id = data.getInt("id");
            Cell c = idToCell(id, new Position(data.getJSONObject("pos")));
            c.parseJSON(data);
            cells[c.pos.x][c.pos.y] = c; // forcefully set the cell on the grid, do not intialize yet

            // Make this CableCell (if it is one) be part of the correct CableUnit based off the save
            if (c instanceof CableCell) {
                int cableUnitHashCode = data.getInt("cableUnit");
                CableUnit cUnit;
                CableCell cCable = (CableCell) c;
                // If this cableUnit has already been created and is part of another cell, then
                // we know it is part of another Cells CableUnit already created, so lets join theirs
                if (cUnits.containsKey(cableUnitHashCode)) {
                    cUnit = cUnits.get(cableUnitHashCode);
                    cUnit.cables.add((CableCell) cCable);
                } else {
                    // Else if this cableUnit has not been used / created yet
                    cUnit = new CableUnit((CableCell) cCable);
                    cUnits.put(cableUnitHashCode, cUnit); // add to list of created CableUnits
                }
                cCable.setCableUnit(cUnit);
            }
        }

        // Next run the parseJSONAfter functions for the Cells, this is done as some cells need all the cells to be placed
        // on the grid first before parsing more data for itself.
        // ex. WirelessCableCell needs to get its 'other' cell if it is connected to it
        for (int i = 0; i < cellData.size(); i ++) {
            JSONObject data = cellData.getJSONObject(i);
            Cell c = cellAt(new Position(data.getJSONObject("pos")));
            c.parseJSONAfter(data);
        }

        // Next load neighbor data for all of the CableUnits now that all cells are placed
        for (Integer k : cUnits.keySet()) {
            JSONArray neighborJSON = cableUnitsJSON.getJSONObject(Integer.toString(k)).getJSONArray("neighbors");
            ArrayList<Cell> neighbors = new ArrayList<Cell>();
            // Add each of the neighbors that are apart of this CableUnit to a temporary ArrayList called neighbors
            for (int i = 0; i < neighborJSON.size(); i ++) {
                neighbors.add(cellAt(new Position(neighborJSON.getJSONObject(i))));
            }
            // Now add this to the CableUnit
            CableUnit currentUnit = (CableUnit) cUnits.get(k);
            currentUnit.neighbors = neighbors;
        }
    }
}

// Holds all the data of which cells just updated, then marks all nearby cells
// of the just updated cells to be updated 
class StateUpdater {
    // If a cell is placed, it will update its neighbors via a cell update
    // If a cells state is changed, it will update its neighbors via a state update
    private HashMap<Position, CellUpdateInfo> cellsUpdated; // cells just updated
    private HashMap<Position, CellUpdateInfo> cellsToBeUpdated; // cells to be updated next step
    private int stepsPerSec = 16; // number of steps per second (def 16)
    private float stepTimer = 0;

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

    // Marks an individual cell to update next step
    public void markCellNext(Cell pCell, short updateType) {
        if (cellsToBeUpdated.get(pCell.pos) == null)
            cellsToBeUpdated.put(pCell.pos, new CellUpdateInfo(pCell, updateType));
    }

    // This will unmark a cell that has been marked to be updated next step. This is run
    // When a cell that is marked to be updated next gets deleted.
    public void unmarkCellNext(Cell pCell) {
        cellsToBeUpdated.remove(pCell);
    }

    public void update() {
        if (stepTimer > frameRate / stepsPerSec) {
            step();
            stepTimer = 0;
        } else {
            stepTimer ++;
        }
    }

    // Update cells to be updated and clear the cells updated
    private void step() {
        cellsUpdated.clear();

        HashMap<Position, CellUpdateInfo> toUpdate = new HashMap<Position, CellUpdateInfo>(cellsToBeUpdated);
        cellsToBeUpdated.clear(); // clear, that way new things can be updated the next step

        Iterator it = toUpdate.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry pair = (Map.Entry) it.next();
            if (pair.getValue() == null)
                continue; 
            CellUpdateInfo cInfo = (CellUpdateInfo) pair.getValue();
            switch(cInfo.getType()) {
            case CellUpdateInfo.cellUpdate:
                cInfo.getCell().cellUpdate();
                break;
            case CellUpdateInfo.stateUpdate:
                cInfo.getCell().stateUpdate();
                break;
            default: 
                throw new IllegalArgumentException("Unknown update type: " + cInfo.getType());
            }
        }
    }

    public float getStepsPerSec() {
        return stepsPerSec;
    }
}

// UI for block menu (choosing the type of blocks to place)
class BlockMenuUI {

    public boolean isOpened = false;
    private ArrayList<Cell> blocks = new ArrayList<Cell>(); // an instance of each type of block

    BlockMenuUI() {
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
// UI for block placement and interaction
class BlockPlacementUI {

    Cell previewBlock = idToCell(0, new Position(0, 0)); // the block to preview placing
    Interactable currentInteract = null; // current Cell being interacted with
    private Grid selection = null; // current selection for copying to and from the grid
    private boolean isSelecting = false; // is the user currently selecting a portion of the grid?
    private Position selectionTL, selectionBR; // the top left and bottom right positions of the selection

    public void update() {
        // Allow placement if user is holding a block, and draw a preview of what it
        // would look like placed there
        if (blockMenuUI.isOpened == false) {
            // Block selection ending
            if (Mouse.justReleased) {
                // We use Mouse.buttonRecent as the default mousePressed with Processing will
                // only show the button currently pressed. This means when the mouseButton is released
                // the mouseButton is set to 0 rather than showing which button was most recently pressed.
                if (Mouse.buttonRecent == CENTER) {
                    if (selection == null)
                        endSelection();
                }
            }
            if (mousePressed) {
                if (Mouse.justPressed) {
                    // Selection of blocks and placement of blocks
                    if (mouseButton == CENTER) {
                        if (selection == null) {
                            initSelection();
                        } else {
                            placeSelection();
                        }
                    } else {
                        // Else if another button was pressed, make the selection empty
                        selection = null;
                    }
                }
                // Cell placement
                if (mouseButton == LEFT) {
                    if (previewBlock instanceof RotatableCell) {
                        RotatableCell c = (RotatableCell) previewBlock;
                        grid.placeCell(user.heldBlock, new Position(previewBlock.pos), c.getOrientation());
                    } else grid.placeCell(user.heldBlock, new Position(previewBlock.pos));
                }
                // Cell removal
                if (mouseButton == RIGHT) {
                    Cell blockToRemove = grid.cellAt(previewBlock.pos);
                    if (blockToRemove != null) {
                        grid.clearCell(blockToRemove.pos);
                    }
                }
            }

            boolean isInteracting = (currentInteract == null) ? false : true;
            if (keyPressed) {
                // Cell interaction
                if (key == 'c' || key == 'C') {
                    Cell c = grid.cellAt(previewBlock.pos);
                    if (c instanceof Interactable) {
                        Interactable i = (Interactable) c;
                        // If not currently interacting
                        if (!isInteracting) {
                            i.interact(); // interact!
                            // Now check if that Interactable is done being interacted with, if so. End interaction
                            if (i.isBeingInteracted()) {
                                currentInteract = i;
                            } else isInteracting = false;
                        } else {
                            // If we are currently interacting and we are selecting another Interactable,
                            // then attempt to make them interact together (most of the time this will do nothing)
                            currentInteract.interactWith(i);
                        }
                    } else if (isInteracting) { // end interaction when trying to interact with a Cell that isn't interactable or a null Cell
                        isInteracting = false;
                    }
                }
                // If we are interacting, but the current interact object is mnarked as no longer being
                // interacted with, then reset our current interact
                if (isInteracting) {
                    if (!currentInteract.isBeingInteracted()) {
                        currentInteract = null;
                    }
                }
                keyPressed = false;
            }
        }
        // Block selection
        if (isSelecting) {
            updateSelection();
        }
        // Update preview block position
        previewBlock.pos.x = mouseX;
        previewBlock.pos.y = mouseY;
        previewBlock.pos = cam.screenToGridPos(previewBlock.pos);
        this.draw();
    }

    public void draw() {
        if (user.heldBlock != -1 && selection == null) {
            previewBlock.drawPlacePreview();
        }
        // Block selection highlighting
        if (isSelecting) {
            fill(#C66BF7, 127);
            rect(selectionTL.x, selectionTL.y, selectionBR.x - selectionTL.x, selectionBR.y - selectionTL.y);
            fill(255); // reset
        }
        if (selection != null) {
            selection.drawPreview(previewBlock.pos);
        }
    }

    public void initSelection() {
        isSelecting = true; 
        selectionTL = new Position(previewBlock.pos);
        selectionBR = new Position(previewBlock.pos);
    }

    public void updateSelection() {
        selectionBR = new Position(previewBlock.pos);
    }

    public void endSelection() {
        isSelecting = false;
        // If nothing selected, make selection null
        if (selectionTL.x == selectionBR.x && selectionTL.y == selectionBR.y) {
            selection = null;
            return;
        }
        // Make it so the top left actually is the top left of the selection and make sure the bottom right
        // actually is the bottom right of the selection. This is done as the user may selection from bottom
        // right to top left, from bottom left to top right, etc. Not preventing this would make it copy backwards or upside down
        if (selectionTL.x > selectionBR.x) {
            int hold = selectionTL.x;
            selectionTL.x = selectionBR.x;
            selectionBR.x = hold;
        }
        if (selectionTL.y > selectionBR.y) {
            int hold = selectionTL.y;
            selectionTL.y = selectionBR.y;
            selectionBR.y = hold;
        }
        selection = grid.copyGridArea(selectionTL, selectionBR);
    }

    public void placeSelection() {
        // First make a copy of the selection
        Grid copiedSelection = new Grid(selection);
        grid.placeGridArea(new Position(previewBlock.pos), copiedSelection);
    }
}

class User {
    public int heldBlock = 0; // a # representing the block that the user is holding to place
}

class Camera {
    public Position pos;
    public int scale;
    private final int constrainPadding = 100; // the limits on how far the camera can move out of bounds

    Camera() {
        pos = new Position(0, 0);
        scale = 12;
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

        // When window is resized, recenter camera position to middle of grid
        if (windowWatcher.resized()) {
            int gridXSizeOnScreen = grid.getXSize();
            int gridYSizeOnScreen = grid.getYSize();

            pos.x = -((width - gridXSizeOnScreen) / 2);
            pos.y = -((height - gridYSizeOnScreen) / 2);
        }
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
}

static class Keyboard {
    public static HashMap<Character, Boolean> keys = new HashMap<Character, Boolean>();
}

// This adds some extra useful data about the mouse that Processing's default
// mousePressed and mouseButton do not provide
static class Mouse {
    public static int wheelCount = 0;
    // Mouse events, see void mousePressed() and void mouseReleased() for how they are affected
    public static boolean justPressed = false; // is triggered when the mouse is just pressed
    public static boolean justReleased = false; // is triggered when the mouse is just released
    public static int buttonRecent = 0; // the most recent mouse button pressed

    private static void resetWheelCount() {
        wheelCount = 0;
    }

    // Should be run at the end of each frame to ensure mouse is counted as pressed, released, or
    // scrolling more than it should be
    public static void resetMouseEvents() {
        resetWheelCount();
        justPressed = false;
        justReleased = false;
    }
}

/******************** GUI ********************/

class GUIPosition {
    private float x; // the current x position (affected by halign)
    private float y; // the current y position (affected by valign)
    public float xGoal; // the x we want to achieve (not affected by halign)
    public float yGoal; // the y we want to achieve (not affected by valign)
    // use keywords TOP, LEFT, BOTTOM, RIGHT, to make the x/y values relative to that side of the window.
    // use -1 to make x/y values relative to the top left view of the window
    private int halign; // LEFT, RIGHT
    private int valign; // UP, DOWN

    GUIPosition(float xGoal, float yGoal, int halign, int valign) {
        this.xGoal = xGoal;
        this.yGoal = yGoal;
        this.halign = halign;
        this.valign = valign;
        update(); // initial update
    }

    GUIPosition(float xGoal, float yGoal) {
        this.xGoal = xGoal;
        this.yGoal = yGoal;
        this.halign = LEFT;
        this.valign = TOP;
        update(); // initial update
    }

    // Updates the position, only needed to be run if the window is resized or when this is intialized
    public void update() {
        switch(halign) {
        case LEFT:
            this.x = xGoal;
            break;
        case CENTER:
            this.x = (width / 2) + xGoal;
            break;
        case RIGHT:
            this.x = width + xGoal;
            break;
        default:
            throw new IllegalArgumentException("Illegal halign position! : " + halign + ", legal positiions: LEFT, CENTER, RIGHT");
        }

        switch(valign) {
        case TOP:
            this.y = yGoal;
            break;
        case CENTER:
            this.y = (height / 2) + yGoal;
            break;
        case BOTTOM:
            this.y = height + yGoal;
            break;
        default:
            throw new IllegalArgumentException("Illegal valign position! : " + valign + ", legal positiions: TOP, CENTER, BOTTOM");
        }
    }

    public void setPos(float xGoal, float yGoal) {
        this.xGoal = xGoal;
        this.yGoal = yGoal;
    }

    public float getX() {
        return x;
    }

    public float getY() {
        return y;
    }

    public float getXGoal() {
        return xGoal;
    }

    public float getYGoal() {
        return yGoal;
    }
}

interface GUIObject {
    public void update();
    public void draw();
}

interface GUIClickable extends GUIObject {
    public void clickEvent(); // action performed when the user clicks a gui clickable
    public boolean isClicked(); // returns true if the clickable was just clicked
    public boolean isHovering(); // returns true if the user is hovering over this
    public boolean mouseEntered(); // returns true if the mouse just entered where the button is
    public boolean mouseExited(); // returns true if the mouse just left when the button is
}

// This is here to be used in the gui handler when recognizing if a
// GUI Object is compatible with it. Although a GUIObject could have a direct parent
// of the GUIObject, it is very abstract to which type of gui object it is categorized under.
// so this is meant to keep all of the displayable / non-clickable gui objects under one category
// separate from the other objects like GUIClickable.
interface GUIDisplayable extends GUIObject {
};

abstract class Button implements GUIClickable {
    protected GUIPosition pos; // top left position of the button
    // Images
    protected PImage image_nohover = null;
    protected PImage image_hover = null;
    protected PImage image_click = null;
    // Box data
    protected PImage image_current = null;
    protected int w = 94; // width
    protected int h = 24; // height
    // Event data
    protected boolean isClicked = false; // true when the mouse clicks this buton
    protected boolean isHovering = false; // true the entire time the mouse is hovering over this
    protected boolean mouseEntered = false; // true when the mouse JUST entered
    protected boolean mouseExited = false; // true when the mouse JUST exited
    /* the string of the method/function to run when clicked, it must be a public functions 
     with no args as Processing does not allow method references due to using an older version 
     of Java. However, they do provide a way using the function 'method(String methodName)' to 
     run a public method with no args.
     */
    private String clickEventMethod; 

    Button (GUIPosition pos, String clickEventMethod) {
        this.pos = pos;
        this.clickEventMethod = clickEventMethod;
    }

    public void update() {
        // If mouse is hovering over the button
        if (mouseX >= pos.getX() 
            && mouseX <= pos.getX() + w 
            && mouseY >= pos.getY() 
            && mouseY <= pos.getY() + h) {
            // If not already hovering, mark as mouse just entered
            if (!isHovering) {
                isHovering = true;
                mouseEntered = true;
                image_current = image_hover;
            } else mouseEntered = false;
            // Clicking
            if (mousePressed && mouseButton == LEFT) {
                isClicked = true;
                image_current = image_click;
                mousePressed = false;
                clickEvent();
            } else {
                isClicked = false;
                image_current = image_hover;
            }
        } else {
            // If no longer hovering
            // If was just hovering, change to false and mark the mouse as just exiting
            if (isHovering) {
                mouseExited = true;
                image_current = image_nohover;
                isHovering = false;
            } else mouseExited = false;
        }

        pos.update(); // update gui position (in case window was resized)
    }

    protected void setDimensions(int width, int height) {
        this.w = width;
        this.h = height;
    }

    protected void setImages(PImage image_nohover, PImage image_hover, PImage image_click) {
        this.image_nohover = image_nohover;
        this.image_hover = image_hover;
        this.image_click = image_click;
    }

    protected void setImageCurrent(PImage image_current) {
        this.image_current = image_current;
    }

    public boolean mouseEntered() {
        return mouseEntered;
    }

    public boolean mouseExited() {
        return mouseExited;
    }

    public boolean isClicked() {
        return isClicked;
    }

    public boolean isHovering() {
        return isHovering;
    }

    public void clickEvent() {
        if (clickEventMethod == "")
            return;
        method(clickEventMethod);
    }
}

class ButtonText extends Button {
    private String text;

    ButtonText (GUIPosition pos, String text, String clickEventMethod) {
        super(pos, clickEventMethod);
        this.text = text;
        // Setting Variables extended from Button ...
        setImages(imageDB.gui_button_text_nohover, imageDB.gui_button_text_hover, imageDB.gui_button_text_click);
        setImageCurrent(this.image_nohover);
        setDimensions(94, 24);
    }

    public void draw() {
        image(image_current, pos.getX(), pos.getY());
        fill(255);
        textAlign(CENTER, CENTER);
        text(text, pos.getX() + (w / 2), pos.getY() + (h / 2));
        textAlign(LEFT, TOP); // reset
    }
}

class ButtonSmall extends Button {
    private String text;

    ButtonSmall(GUIPosition pos, String text, String clickEventMethod) {
        super(pos, clickEventMethod); 
        this.text = text;
        // Setting Variables extended from button ...
        setImages(imageDB.gui_button_small_nohover, imageDB.gui_button_small_hover, imageDB.gui_button_small_click);
        setImageCurrent(this.image_nohover);
        setDimensions(26, 26);
    }

    public void draw() {
        image(image_current, pos.getX(), pos.getY());
        fill(255);
        textAlign(CENTER, CENTER);
        text(text, pos.getX() + (w / 2), pos.getY() + (h / 2));
        textAlign(LEFT, TOP); // reset
    }
}

class TextDisplay implements GUIDisplayable {
    public GUIPosition pos;
    public String text;
    public int fontSize;
    public color fontColor;

    TextDisplay(GUIPosition pos, String text) {
        this.pos = pos;
        this.text = text;
        this.fontSize = 12;
        this.fontColor = #ffffff; // white
    }

    TextDisplay(GUIPosition pos, String text, int fontSize, color fontColor) {
        this.pos = pos;
        this.text = text;
        this.fontSize = fontSize;
        this.fontColor = fontColor;
    }

    public void update() {
        pos.update();
    }

    public void draw() {
        fill(fontColor);
        textSize(fontSize);
        text(text, pos.getX(), pos.getY());
        textSize(12); // reset
        fill(255); // reset
    }
}

class ImageDisplay implements GUIDisplayable {
    public GUIPosition pos;
    public PImage image;

    ImageDisplay (GUIPosition pos, PImage image) {
        this.pos = pos;
        this.image = image;
    }

    public void update() {
        pos.update();
    }

    public void draw() {
        image(image, pos.getX(), pos.getY());
    }
}

// This class handles all of the gui drawing and updating
class GUIHandler {
    private ArrayList<GUIClickable> clickables;
    private ArrayList<GUIDisplayable> displayables;

    GUIHandler () {
        init();
    }

    GUIHandler(ArrayList<GUIObject> guiObjects) {
        init();
        addGUIObjects(guiObjects);
    }

    // Initialize
    private void init() {
        clickables = new ArrayList<GUIClickable>();
        displayables = new ArrayList<GUIDisplayable>();
    }

    // Adds an arraylist of guiobjects to the GUIHandler
    public void addGUIObjects(ArrayList<GUIObject> guiObjects) {
        // Add all of the guiObjects into their specific containers
        for (GUIObject i : guiObjects) {
            if (i instanceof GUIClickable) {
                clickables.add((GUIClickable) i); 
                continue;
            }
            if (i instanceof GUIDisplayable) {
                displayables.add((GUIDisplayable) i);
                continue;
            }
            throw new IllegalArgumentException("The GUIObject: (" + i + ") is not compatible with the GUIHandler");
        }
    }

    // Add a single gui object to the GUIHandler
    public void addGUIObject(GUIObject guiObject) {
        ArrayList<GUIObject> toAdd = new ArrayList<GUIObject>(); 
        toAdd.add(guiObject);
        addGUIObjects(toAdd);
    }

    // Updates all of the gui
    public void update() {
        for (GUIClickable i : clickables) {
            i.update();
        }
        for (GUIDisplayable i : displayables) {
            i.update();
        }
    }

    // Updates all of the gui drawing
    public void draw() {
        for (GUIClickable i : clickables) {
            i.draw();
        }
        for (GUIDisplayable i : displayables) {
            i.draw();
        }
    }
}

// Loads all of the images and stores it to be referenced from other objects, this
// is done as to:
// - keep images all in one place
// - prevent having duplicate images in memory
public class ImageLoader {
    // Images
    public PImage gui_button_small_nohover;
    public PImage gui_button_small_hover;
    public PImage gui_button_small_click;

    public PImage gui_button_text_nohover;
    public PImage gui_button_text_hover;
    public PImage gui_button_text_click;

    public PImage gui_increment;
    // Directories
    public final File gui_dir = new File("gui");


    ImageLoader() {
        println("Loading images ...");
        gui_button_small_nohover = loadImage(gui_dir + "/button_small_nohover.png");
        gui_button_small_hover = loadImage(gui_dir + "/button_small_hover.png");
        gui_button_small_click = loadImage(gui_dir + "/button_small_click.png");

        gui_button_text_nohover = loadImage(gui_dir + "/button_text_nohover.png");
        gui_button_text_hover = loadImage(gui_dir + "/button_text_hover.png");
        gui_button_text_click = loadImage(gui_dir + "/button_text_click.png");

        gui_increment = loadImage(gui_dir + "/increment.png");
        println("DONE");
    }
}

// Watches to see if the window is resized, keeps track of width and height of screen
public class WindowWatcher {
    private int widthPrev;
    private int heightPrev;
    private boolean windowResized = false;

    public void watch() {
        if (width != widthPrev || height != heightPrev) {
            windowResized = true;
            widthPrev = width;
            heightPrev = height;
        } else {
            windowResized = false;
        }
    }

    // Returns true if the window was resized, and false if not
    public boolean resized() {
        return windowResized;
    }
}