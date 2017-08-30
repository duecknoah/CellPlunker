// Returns an instance of a cell based off
// its id
public Cell idToCell(int id, Position pos) {
    switch(id) {
    case 0:
        return new ConstantCell(pos);
    case 1:
        return new SwitchCell(pos);
    case 2:
        return new CableCell(pos);
    case 3:
        return new InverterCell(pos);
    case 4:
        return new WirelessCableCell(pos);
    default:
        return null;
    }
}

// Returns a id from an instance of a Cell
public int cellToId(Cell c) {
    if (c instanceof ConstantCell)
        return 0;
    if (c instanceof SwitchCell)
        return 1;
    if (c instanceof CableCell) {
        if (c instanceof WirelessCableCell)
            return 4;
        return 2;
    }
    if (c instanceof InverterCell)
        return 3;
    return -1;
}

public String idToCellName(int id) {
    switch(id) {
    case 0:
        return "Constant Cell";
    case 1:
        return "Switch Cell";
    case 2:
        return "Cable Cell";
    case 3:
        return "Inverter Cell";
    case 4:
        return "WirelessCable Cell";
    default:
        return "?";
    }
}

// Creates a game save, see save_layout.json to see an example output
public void createSave() {
    // The Save data json as a whole, this is the one the contains everything and is actually saved
    JSONObject saveData = new JSONObject();
    // The jsons within saveData
    JSONObject gridData = grid.toJSON();
    JSONObject stateUpdaterData = new JSONObject();
    // StateUpdater
    stateUpdaterData.setFloat("stepsPerSec", stateUpdater.getStepsPerSec());

    // Finally put all of this into saveData and save
    saveData.setJSONObject("grid", gridData);
    saveData.setJSONObject("stateUpdater", stateUpdaterData);

    // TODO, save as compressed file not in raw json
    saveJSONObject(saveData, "save.json");
}

// Button functions (clickEvent functions)
public void loadSave() {
    selectInput("Select a save to load:", "loadSelected");
}

public void loadSelected(File fileSelected) {
    if (fileSelected == null) {
        println("No file selection made");
    } else {
        // Load save
        println("Loading save: " + fileSelected.getAbsolutePath());
        JSONObject saveData = loadJSONObject(fileSelected);
        try {
            grid.parseJSON(saveData.getJSONObject("grid"));
            println("Save loaded successfully with no errors");
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}

public void setSlowStepSpd() {
    stateUpdater.stepsPerSec = 2;
}

public void setFastStepSpd() {
    stateUpdater.stepsPerSec = 16;
}

// Toggles viewing of the help menu. This is run when the '?' button at the top right of the screen
// is pressed
public void toggleHelpMenu() {
    helpMenu.setIsEnabled(!helpMenu.getIsEnabled());
}