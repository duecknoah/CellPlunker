import java.util.*;
import java.awt.Toolkit;
import java.awt.event.KeyEvent;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.AbstractQueue;
/*
CellPlunker
A game where there is a grid of cells, every cell can have a state of either on or off. However, there are many different types
of cells that will act differently and make there state or other custom properties change accordinly based on its surroundings or type of cell it is. This allows you to create
interesting and complex logical systems
cell types:
static
  switch cell (can be turned on or off)
  constant cell (is stuck on)
dynamic
  //attracter cell (attracts nearby dynamic cells)
  cable cell (if any of this cells neighbors are in an 'on' state, its state is on, otherwise its state is off.
  inverter cell (the same as a reader cell, but inverted
*/

PShader gridShader;

Grid grid = new Grid(500, 500);
StateUpdater stateUpdater = new StateUpdater();
Camera cam = new Camera();
User user = new User();
BlockPlacementUI blockPlacementUI = new BlockPlacementUI();
BlockSelectionUI blockSelectionUI = new BlockSelectionUI();
ImageLoader imageDB;
GUIHandler gui;

void setup() {
  size(500, 500, P2D);
  surface.setResizable(true);
  noSmooth();
  
  Keyboard.keys.put('w', false);
  Keyboard.keys.put('a', false);
  Keyboard.keys.put('s', false);
  Keyboard.keys.put('d', false);
  String[] vertSource = {
        "uniform mat4 transform;",
 
        "attribute vec4 vertex;",
 
        "void main() {",
            "gl_Position = transform * vertex;",
        "}"
    };
    String[] fragSource = {
        "uniform vec2 pos;",
        "uniform float scale;",
        
        "void main() {",
            "if(fract((gl_FragCoord.x - pos.x) / (scale * 2)) > 0.5 ^ fract((gl_FragCoord.y - pos.y) / (scale * 2)) > 0.5)",
                "gl_FragColor = vec4(0.1, 0.1, 0.1, 1.0);",
            "else",
                "gl_FragColor = vec4(0.05, 0.05, 0.05, 1.0);",
        "}"
    };
    gridShader = new PShader(this, vertSource, fragSource);
    /////////////////// Image and GUI ///////////////////
    imageDB = new ImageLoader();
    ArrayList<GUIObject> guiObjects = new ArrayList<GUIObject>();
    
    // Add gui objects here, ex.
    // guiObjects.add(new ButtonText(new GUIPosition(16, -16), LEFT, BOTTOM, "Slow", ""));
    guiObjects.add(new ButtonText(new GUIPosition(16, 16), "Save", ""));
    guiObjects.add(new ButtonText(new GUIPosition(16, 48), "Load", "loadSave"));
    guiObjects.add(new TextDisplay(new GUIPosition(16, -96, LEFT, BOTTOM), "Steps:\n...", 12, #ffffff));
    guiObjects.add(new ButtonText(new GUIPosition(16, -64, LEFT, BOTTOM), "Fast", ""));
    guiObjects.add(new ButtonText(new GUIPosition(16, -32, LEFT, BOTTOM), "Slow", ""));
    guiObjects.add(new ButtonSmall(new GUIPosition(-16 + -26, 16, RIGHT, TOP), "?", ""));
    
    gui = new GUIHandler(guiObjects);
}

void keyPressed() {
   Iterator it = Keyboard.keys.entrySet().iterator();
   while(it.hasNext()) {
     Map.Entry pair = (Map.Entry) it.next();
     // If key currently pressed exists in the Keyboard Hashmap
     if ((Character.valueOf(Character.toLowerCase(key))) == pair.getKey()) {
       // Mark key as pressed  
       pair.setValue(true);
     }
   }
   switch(key) {
    case 'e': 
    case 'E':
      grid.viewCellStates = !grid.viewCellStates;
    break;
    case 'q':
    case 'Q':
      blockSelectionUI.isOpened = !blockSelectionUI.isOpened;
    break;
    case 'r': // rotate block selected if that type of block
    case 'R':
      if (blockPlacementUI.previewBlock instanceof RotatableCell) {
        RotatableCell toRotate = (RotatableCell) blockPlacementUI.previewBlock;
        toRotate.rotateLeft();
      }
    break;
    case 'v':
    case 'V':
      if (blockSelectionUI.isOpened == false) {
        Cell hovering = grid.cellAt(blockPlacementUI.previewBlock.pos);
        if (hovering != null) {
          println(hovering.toString()); // prints cell info
        }
      }
    break;
   }
}

void keyReleased() {
   Iterator it = Keyboard.keys.entrySet().iterator();
   while(it.hasNext()) {
     Map.Entry pair = (Map.Entry) it.next();
     // If key currently pressed exists in the Keyboard Hashmap
     if ((Character.valueOf(Character.toLowerCase(key))) == pair.getKey()) {
       // Mark key as pressed  
       pair.setValue(false);
       
     }
   }
}

void mouseWheel(MouseEvent event) {
  Mouse.wheelCount = event.getCount();
}

void draw() {
  cam.userControl();
  //camestrictInGrid();
  
  background(#555555);
  pushMatrix();
  translate(width / 2, height / 2);
  scale(cam.scale);
  translate(-width / 2, -height / 2);
  translate(-cam.pos.x, -cam.pos.y);
  grid.draw();
  blockPlacementUI.update();
  popMatrix();
  fill(255);
  blockSelectionUI.update();
  stateUpdater.update();
  gui.update();
  gui.draw();
  fill(255);
  text("FPS: " + round(frameRate), 16, 16);
  Position mousePos = cam.screenToGridPos(new Position(mouseX, mouseY));
  text("mouseX: " + mousePos.x + ", mouseY: " + mousePos.y, 16, 32);
  text("camX: " + cam.pos.x + ", camY: " + cam.pos.y, 16, 48);
  text("maxSteps: " + stateUpdater.maxSteps, 16, 64);
  Mouse.resetWheelCount();
}