class dummy_item extends uvm_sequence_item;

  rand int unsigned addr;
  rand int unsigned data;
  rand int unsigned delay;

  constraint c1 {addr < 16'h2000;}
  constraint c2 {data < 16'h1000;}

  //UVM automation macros for general objects
  `uvm_object_utils_begin(dummy_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(delay, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new (string name = "dummy_item");
    super.new(name);
  endfunction: new

endclass: dummy_item
