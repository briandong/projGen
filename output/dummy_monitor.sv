class dummy_monitor extends uvm_monitor;

  virtual dummy_if vif;

  bit checks_enable = 1; // Control checking in monitor and interface
  bit coverage_enable = 1; // Control coverage in monitor and interface
  uvm_analysis_port #(dummy_item) item_collected_port;
  event cov_transaction; // Events needed to trigger covergroups
  protected dummy_item trans_collected;

  // UVM automation macros for general components
  `uvm_component_utils_begin(dummy_monitor)
    `uvm_field_int(checks_enable, UVM_ALL_ON)
    `uvm_field_int(coverage_enable, UVM_ALL_ON)
  `uvm_component_utils_end

  // Coverage
  covergroup cov_trans @cov_transaction;
  option.per_instance = 1;
    // Coverage bins definition
  endgroup: cov_trans

  // Constructor
  function new (string name = "dummy_monitor", uvm_component parent);
    super.new(name, parent);
      cov_trans = new();
      cov_trans.set_inst_name({get_full_name(), ".cov_trans"});
      trans_collected = new();
      item_collected_port = new("item_collected_port", this);
  endfunction: new

  function void build_phase(uvm_phase phase);
    string inst_name;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual dummy_if)::get(this,"","vif",vif))
      uvm_fatal("NOVIF", {"virtual interface must be set for: ",
      get_full_name(),".vif"});
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    collect_transactions(); // collector task
  endtask: run

  virtual protected task collect_transactions();
    forever begin
      @(posedge vif.clock);
      // Collect the data from the bus into trans_collected
      if (checks_enable)
        perform_transfer_checks();
      if (coverage_enable)
        perform_transfer_coverage();
      item_collected_port.write(trans_collected);
    end
  endtask: collect_transactions

  virtual protected function void perform_transfer_coverage();
    -> cov_transaction;
  endfunction : perform_transfer_coverage

  virtual protected function void perform_transfer_checks();
    // Perform data checks on trans_collected.
  endfunction : perform_transfer_checks

endclass: dummy_monitor
