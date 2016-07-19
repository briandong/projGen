class dummy_agent extends uvm_agent;

  // UVM automation macros
  `uvm_component_utils(dummy_agent)

  // Constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  uvm_sequencer #(dummy_item) sequencer;
  dummy_driver driver;
  dummy_monitor monitor;

  // Use build_phase to create agents's subcomponents
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase)
    monitor = dummy_monitor::type_id::create("monitor",this);
    if (is_active == UVM_ACTIVE) begin
      // Build the sequencer and driver
      sequencer =
      uvm_sequencer#(dummy_item)::type_id::create("sequencer",this);
      driver = dummy_driver::type_id::create("driver",this);
    end

  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    if(is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction: connect_phase

endclass: dummy_agent
