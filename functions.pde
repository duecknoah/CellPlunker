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
  if (c instanceof CableCell)
    return 2;
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
    default:
      return "?";
  }
}