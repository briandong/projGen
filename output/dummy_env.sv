class dummy_env extends uvm_env;

  int num_masters;
  dummy_agent masters[];

  `uvm_component_utils_begin(dummy_env)
    `uvm_field_int(num_masters, UVM_ALL_ON)
  `uvm_component_utils_end

  virtual function void build_phase(phase);
    string inst_name;
    super.build_phase(phase);

    if(num_masters ==0))
      `uvm_fatal("NONUM",{"'num_masters' must be set";

    masters = new[num_masters];
    for(int i = 0; i < num_masters; i++) begin
      $sformat(inst_name, "masters[%0d]", i);
      masters[i] = dummy_agent::type_id::create(inst_name, this);
    end

    // Build slaves and other components

  endfunction

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

endclass
