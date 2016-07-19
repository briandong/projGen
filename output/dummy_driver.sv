class dummy_driver extends uvm_driver #(dummy_item);

  dummy_item item;
  virtual dummy_if vif;

  // UVM automation macros for general components
  `uvm_component_utils(dummy_driver)

  // Constructor
  function new (string name = "dummy_driver", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    string inst_name;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dummy_if)::get(this,"","vif",vif))
      uvm_fatal("NOVIF", {"virtual interface must be set for: ",
      get_full_name(),".vif"});
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      // Get the next data item from sequencer (may block)
      seq_item_port.get_next_item(item);
      // Execute the item
      drive_item(item);
      seq_item_port.item_done(); // Consume the request
     end
  endtask: run

  virtual task drive_item (input dummy_item item);
    // Add your logic here.
  endtask: drive_item

endclass: dummy_driver
