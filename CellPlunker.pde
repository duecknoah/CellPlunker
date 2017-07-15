import java.util.*;
import java.awt.Toolkit;
import java.awt.event.KeyEvent;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.AbstractQueue;
/*
CellPlunker
A game where there is a grid of cells, every cell can have a state of either on or off. However, there are many different types
of cells that will act differently and make there state or other custom properties change accordinly based on its surroundings or type of cell it is. This allows you to create
interesting and complex systems

cell types:
static
  swsitch cell (can be turned on or off)
  constant cell (is stuck on)
dynamic
  //attracter cell (attracts nearby dynamic cells)
  cable cell (if any of this cells neighbors are in an 'on' state, its state is on, otherwise its state is off.
  inverter cell (the same as a reader cell, but inverted
*/

Grid grid = new Grid(500, 500);
StateUpdater stateUpdater = new StateUpdater();
Camera cam = new Camera();
User user = new User();
BlockPlacementUI blockPlacementUI = new BlockPlacementUI();
BlockSelectionUI blockSelectionUI = new BlockSelectionUI();

void setup() {
  size(500, 500);
  noSmooth();
  Keyboard.keys.put('w', false);
  Keyboard.keys.put('a', false);
  Keyboard.keys.put('s', false);
  Keyboard.keys.put('d', false);
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
  fill(255);
  text("FPS: " + round(frameRate), 16, 16);
  Position mousePos = cam.screenToGridPos(new Position(mouseX, mouseY));
  text("mouseX: " + mousePos.x + ", mouseY: " + mousePos.y, 16, 32);
  text("camX: " + cam.pos.x + ", camY: " + cam.pos.y, 16, 48);
  Mouse.resetWheelCount();
}