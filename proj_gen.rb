#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

# UVM generator - base class
# This is the base class for all UVM generator classes
class UVM_gen_base

    attr_reader :name

    def initialize(name)
        @name = name
    end
    
    def to_s
        s = @name
    end
    
end

# UVM generator - file class
# This class is used to generate a file
class UVM_gen_file < UVM_gen_base

    attr_reader :file

    def initialize(name, file)
        super(name)
        @file = file
    end
    
    def to_f
        puts "Generating file: #{@file}"
        f = File::new(@file, "w")
        f.puts to_s
        f.close
    end

end

# UVM generator - port class
# This class is used to generate a port
class UVM_gen_port < UVM_gen_base

    attr_reader :type, :width

    def initialize(name, type, width)
        super(name)
        @type = type
        @width = width
    end
    
    def to_s
        s = "#{@type} #{@width} #{@name}"
    end

end

# UVM generator - interface class
# This class is used to generate a interface
class UVM_gen_if < UVM_gen_file

    @p_list = []

    def initialize(name, file, port_list)
        super(name, file)
        @p_list = port_list
    end
    
    def to_s
        s = "interface #{@name}_if;\n\n"
        s += "  // Control flags\n"
        s += "  bit has_checks = 1;\n"
        s += "  bit has_coverage = 1;\n\n"
        s += "  // Actual signals\n"
        
        @p_list.each do |p|
            if p.type == "inout"
				s += "  wire "
			else
				s += "  logic "
			end
            s += "#{p.width} #{p.name}; //#{p.type}\n"
        end

        s += "\n"
        s += "endinterface: #{@name}_if\n"
        
    end

end

# UVM generator - data item class
# This class is used to generate a data item
class UVM_gen_item < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_item extends uvm_sequence_item;\n\n"
        s += "  rand int unsigned addr;\n"
        s += "  rand int unsigned data;\n"
        s += "  rand int unsigned delay;\n\n"
        s += "  constraint c1 {addr < 16'h2000;}\n"
        s += "  constraint c2 {data < 16'h1000;}\n\n" 
        s += "  //UVM automation macros for general objects\n"
        s += "  `uvm_object_utils_begin(#{@name}_item)\n"
        s += "    `uvm_field_int(addr, UVM_ALL_ON)\n"
        s += "    `uvm_field_int(data, UVM_ALL_ON)\n"
        s += "    `uvm_field_int(delay, UVM_ALL_ON)\n"
        s += "  `uvm_object_utils_end\n\n" 
        s += "  // Constructor\n"
        s += "  function new (string name = \"#{@name}_item\");\n"
        s += "    super.new(name);\n"
        s += "  endfunction: new\n\n"
        s += "endclass: #{@name}_item\n"
        
    end

end

# UVM generator - driver class
# This class is used to generate a driver
class UVM_gen_drv < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_driver extends uvm_driver #(#{@name}_item);\n\n"
        s += "  #{@name}_item item;\n"
        s += "  virtual #{@name}_if vif;\n\n"
        s += "  // UVM automation macros for general components\n"
        s += "  `uvm_component_utils(#{@name}_driver)\n\n"
        s += "  // Constructor\n"
        s += "  function new (string name = \"#{@name}_driver\", uvm_component parent);\n"
        s += "    super.new(name, parent);\n"
        s += "  endfunction: new\n\n"
        s += "  function void build_phase(uvm_phase phase);\n"
        s += "    string inst_name;\n"
        s += "    super.build_phase(phase);\n"
        s += "    if (!uvm_config_db#(virtual #{@name}_if)::get(this,\"\",\"vif\",vif))\n"
        s += "      `uvm_fatal(\"NOVIF\", {\"virtual interface must be set for: \",\n"
        s += "      get_full_name(),\".vif\"});\n"
        s += "  endfunction: build_phase\n\n"
        s += "  virtual task run_phase(uvm_phase phase);\n"
        s += "    forever begin\n"
        s += "      // Get the next data item from sequencer (may block)\n"
        s += "      seq_item_port.get_next_item(item);\n"
        s += "      // Execute the item\n"
        s += "      drive_item(item);\n"
        s += "      seq_item_port.item_done(); // Consume the request\n"
        s += "    end\n"
        s += "  endtask: run_phase\n\n"
        s += "  virtual task drive_item (input #{@name}_item item);\n"
        s += "    // Add your logic here.\n"
		s += "    `uvm_info(get_type_name(), \"driving item\", UVM_LOW)\n\n"
	    s += "    fork\n"
	    s += "      begin\n"
	    s += "      end\n"
	    s += "      begin\n"
	    s += "      end\n"
	    s += "    join_any\n"
        s += "    disable fork;\n\n"
        s += "    #10;\n"
        s += "  endtask: drive_item\n\n"
        s += "endclass: #{@name}_driver\n"
        
    end

end

# UVM generator - monitor class
# This class is used to generate a monitor
class UVM_gen_mon < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_monitor extends uvm_monitor;\n\n"
        s += "  virtual #{@name}_if vif;\n\n"
		s += "  bit checks_enable = 1; // Control checking in monitor and interface\n"
        s += "  bit coverage_enable = 1; // Control coverage in monitor and interface\n"
		s += "  uvm_analysis_port #(#{@name}_item) item_collected_port;\n"
        s += "  event cov_transaction; // Events needed to trigger covergroups\n"
        s += "  protected #{@name}_item trans_collected;\n\n"
        s += "  // UVM automation macros for general components\n"
        s += "  `uvm_component_utils_begin(#{@name}_monitor)\n"
		s += "    `uvm_field_int(checks_enable, UVM_ALL_ON)\n"
        s += "    `uvm_field_int(coverage_enable, UVM_ALL_ON)\n"
        s += "  `uvm_component_utils_end\n\n"
        s += "  // Coverage\n"
		s += "  covergroup cov_trans @cov_transaction;\n"
        s += "  option.per_instance = 1;\n"
        s += "    // Coverage bins definition\n"
        s += "  endgroup: cov_trans\n\n"
        s += "  // Constructor\n"
        s += "  function new (string name = \"#{@name}_monitor\", uvm_component parent);\n"
        s += "    super.new(name, parent);\n"
		s += "      cov_trans = new();\n"
        s += "      cov_trans.set_inst_name({get_full_name(), \".cov_trans\"});\n"
        s += "      trans_collected = new();\n"
        s += "      item_collected_port = new(\"item_collected_port\", this);\n"
        s += "  endfunction: new\n\n"
        s += "  function void build_phase(uvm_phase phase);\n"
        s += "    string inst_name;\n"
        s += "    super.build_phase(phase);\n"
        s += "    if (!uvm_config_db#(virtual #{@name}_if)::get(this,\"\",\"vif\",vif))\n"
        s += "      `uvm_fatal(\"NOVIF\", {\"virtual interface must be set for: \",\n"
        s += "      get_full_name(),\".vif\"});\n"
        s += "  endfunction: build_phase\n\n"
        s += "  virtual task run_phase(uvm_phase phase);\n"
		s += "    collect_transactions(); // collector task\n"
        s += "  endtask: run_phase\n\n"
        s += "  virtual protected task collect_transactions();\n"
        s += "    //forever begin\n"
		s += "      //@(posedge vif.clock);\n"
        s += "      // Collect the data from the bus into trans_collected\n"
        s += "      if (checks_enable)\n"
        s += "        perform_transfer_checks();\n"
        s += "      if (coverage_enable)\n"
        s += "        perform_transfer_coverage();\n"
        s += "      item_collected_port.write(trans_collected);\n"
        s += "    //end\n"
        s += "  endtask: collect_transactions\n\n"
		s += "  virtual protected function void perform_transfer_coverage();\n"
        s += "    -> cov_transaction;\n"
        s += "  endfunction: perform_transfer_coverage\n\n"
        s += "  virtual protected function void perform_transfer_checks();\n"
        s += "    // Perform data checks on trans_collected.\n"
        s += "  endfunction: perform_transfer_checks\n\n"
        s += "endclass: #{@name}_monitor\n"
        
    end

end


# UVM generator - sequencer class
# This class is used to generate a sequencer
# But you could also skip this and use the default uvm_sequencer in agent class
class UVM_gen_seqr < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_sequencer extends uvm_sequencer #(#{@name}_item);\n\n"
        s += "  `uvm_component_utils(#{@name}_sequencer)\n\n"
        s += "  // Constructor\n"
        s += "  function new (string name, uvm_component parent);\n"
        s += "    super.new(name, parent);\n"
        s += "  endfunction: new\n\n"
        s += "endclass: #{@name}_sequencer\n"
    end

end

# UVM generator - agent class
# This class is used to generate a agent
class UVM_gen_agent < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_agent extends uvm_agent;\n\n"
		s += "  uvm_active_passive_enum is_active;\n\n"
        s += "  // UVM automation macros\n"
        s += "  `uvm_component_utils_begin(#{@name}_agent)\n"
		s += "    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)\n"
        s += "  `uvm_component_utils_end\n\n"
        s += "  // Constructor\n"
        s += "  function new (string name, uvm_component parent);\n"
        s += "    super.new(name, parent);\n"
        s += "  endfunction: new\n\n"
        s += "  uvm_sequencer #(#{@name}_item) sequencer;\n"
        s += "  #{@name}_driver driver;\n"
        s += "  #{@name}_monitor monitor;\n\n"
        s += "  // Use build_phase to create agents's subcomponents\n"
        s += "  virtual function void build_phase(uvm_phase phase);\n"
        s += "    super.build_phase(phase);\n"
        s += "    monitor = #{@name}_monitor::type_id::create(\"monitor\",this);\n"
        s += "    if (is_active == UVM_ACTIVE) begin\n"
        s += "      // Build the sequencer and driver\n"
        s += "      sequencer =\n"
        s += "      uvm_sequencer#(#{@name}_item)::type_id::create(\"sequencer\",this);\n"
        s += "      driver = #{@name}_driver::type_id::create(\"driver\",this);\n"
        s += "    end\n\n"
        s += "  endfunction: build_phase\n\n"
        s += "  virtual function void connect_phase(uvm_phase phase);\n"
        s += "    if(is_active == UVM_ACTIVE) begin\n"
        s += "      driver.seq_item_port.connect(sequencer.seq_item_export);\n"
        s += "    end\n"
        s += "  endfunction: connect_phase\n\n"
        s += "endclass: #{@name}_agent\n"
    end
    
end

# UVM generator - scoreboard class
# This class is used to generate a scoreboard
class UVM_gen_sb < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_scoreboard extends uvm_scoreboard;\n\n"
        s += "  uvm_analysis_imp#(#{@name}_item, #{@name}_scoreboard) item_collected_export;\n\n"
        s += "  protected bit disable_scoreboard = 0;\n"
        s += "  int sb_error = 0;\n\n"
        s += "  // Provide implementations of virtual methods such as get_type_name and create\n"
        s += "  `uvm_component_utils_begin(#{@name}_scoreboard)\n"
        s += "    `uvm_field_int(disable_scoreboard, UVM_ALL_ON)\n"
        s += "  `uvm_component_utils_end\n\n"
        s += "  // Constructor\n"
        s += "  function new (string name, uvm_component parent);\n"
        s += "    super.new(name, parent);\n"
        s += "  endfunction: new\n\n"
        s += "  // build_phase\n"
        s += "  function void build_phase(uvm_phase phase);\n"
        s += "    item_collected_export = new(\"item_collected_export\", this);\n"
        s += "  endfunction\n\n"
        s += "  // Provide implementation of write()\n"
        s += "  virtual function void write(#{@name}_item trans);\n"
        s += "    if(!disable_scoreboard) begin\n"
        s += "    end\n"
        s += "  endfunction: write\n\n"
        s += "endclass\n"
    end
end

# UVM generator - env class
# This class is used to generate env
class UVM_gen_env < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_env extends uvm_env;\n\n"
        s += "  // Virtual interface variable\n"
        s += "  protected virtual interface #{@name}_if vif;\n\n"
        s += "  // Control properties\n"
		s += "  protected int num_masters = 0;\n\n"
        s += "  // Components of the env\n"
        s += "  #{@name}_agent masters[];\n"
		s += "  #{@name}_scoreboard scoreboard0;\n\n"
        s += "  `uvm_component_utils_begin(#{@name}_env)\n"
        s += "    `uvm_field_int(num_masters, UVM_ALL_ON)\n"
        s += "  `uvm_component_utils_end\n\n"
        s += "  virtual function void build_phase(uvm_phase phase);\n"
        s += "    string inst_name;\n"
        s += "    super.build_phase(phase);\n\n"
        s += "    if(!uvm_config_db#(virtual #{@name}_if)::get(this, \"\", \"vif\", vif))\n"
        s += "      `uvm_fatal(\"NOVIF\",{\"virtual interface must be set for: \",get_full_name(),\".vif\"});\n\n"
        s += "    if(num_masters ==0)\n"
        s += "      `uvm_fatal(\"NONUM\",{\"'num_masters' must be set for: \", get_full_name()});\n\n"
		s += "    //uvm_config_db#(uvm_active_passive_enum)::set(this,\n"
		s += "    uvm_config_db#(int)::set(this,\n"
		s += "      \"masters*\", \"is_active\", UVM_ACTIVE);\n\n"
        s += "    masters = new[num_masters];\n"
        s += "    for(int i = 0; i < num_masters; i++) begin\n"
        s += "      $sformat(inst_name, \"masters[%0d]\", i);\n"
        s += "      masters[i] = #{@name}_agent::type_id::create(inst_name, this);\n"
        s += "    end\n\n"
		s += "    scoreboard0 = #{@name}_scoreboard::type_id::create(\"scoreboard0\", this);\n\n"
        s += "    // Build slaves and other components\n\n"
        s += "  endfunction\n\n"
        s += "  virtual function void connect_phase(uvm_phase phase);\n"
        s += "    // Connect monitor to scoreboard\n"
        s += "    masters[0].monitor.item_collected_port.connect(\n"
        s += "      scoreboard0.item_collected_export);\n"
        s += "  endfunction: connect_phase\n\n"
        s += "  // Constructor\n"
        s += "  function new(string name, uvm_component parent);\n"
        s += "    super.new(name, parent);\n"
        s += "  endfunction: new\n\n"
        s += "endclass\n"
    end
    
end

# UVM generator - test class
# This class is used to generate test
class UVM_gen_test < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_base_test extends uvm_test;\n\n"
		s += "  `uvm_component_utils(#{@name}_base_test)\n\n"
        s += "  #{@name}_env #{@name}_env0;\n\n"
        s += "  // The test’s constructor\n"
        s += "  function new (string name = \"#{@name}_base_test\",\n"
        s += "    uvm_component parent = null);\n"
        s += "    super.new(name, parent);\n"
        s += "  endfunction\n\n"
        s += "  // Update this component's properties and create the #{@name}_env component\n"
        s += "  virtual function void build_phase(uvm_phase phase); // create the top-level environment.\n\n"
		s += "    //For derived class, super.build_phase() through the base class,\n"
		s += "    // will create the top-level environment and all its subcomponents\n"
		s += "    //Therefore, any configuration that will affect the building\n"
		s += "    // of these components must be set before calling super.build_phase()\n"
        s += "    uvm_config_db#(int)::set(this,\"#{@name}_env0\", \"num_masters\", 1);\n"
        s += "    super.build_phase(phase);\n"
        s += "    #{@name}_env0 =\n"
        s += "      #{@name}_env::type_id::create(\"#{@name}_env0\", this);\n"
        s += "    //Since the sequences don’t get started until a later phase,\n"
        s += "    // they could be called after super.build_phase()\n"
        s += "    uvm_config_db#(uvm_object_wrapper)::\n"
        s += "      set(this, \"#{@name}_env0.masters[0].sequencer.run_phase\",\n"
        s += "      \"default_sequence\", #{@name}_base_seq::type_id::get());\n"
        s += "  endfunction\n\n"
        s += "  function void end_of_elaboration_phase(uvm_phase phase);\n"
        s += "    uvm_top.print_topology();\n"
        s += "  endfunction: end_of_elaboration_phase\n\n"
		s += "  virtual task run_phase(uvm_phase phase);\n"
        s += "    //set a drain-time for the environment if desired \n"
        s += "    phase.phase_done.set_drain_time(this, 5000);\n"
        s += "  endtask\n\n"
        s += "endclass\n"

    end
    
end

# UVM generator - sequence class
# This class is used to generate sequence
class UVM_gen_seq < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "class #{@name}_base_seq extends uvm_sequence #(#{@name}_item);\n\n"
		s += "  rand int count;\n"
        s += "  constraint c1 { count > 0; count < 10; }\n\n"
        s += "  // Register with the factory\n"
        s += "  `uvm_object_utils_begin(#{@name}_base_seq)\n"
		s += "    `uvm_field_int(count, UVM_ALL_ON)\n"
        s += "  `uvm_object_utils_end\n\n"
        s += "  // The sequence’s constructor\n"
        s += "  function new (string name = \"#{@name}_base_seq\");\n"
        s += "    super.new(name);\n"
        s += "  endfunction\n\n"
		s += "  virtual task body();\n"
		s += "    `uvm_info(get_type_name(), $psprintf(\"has %0d item(s)\", count), UVM_LOW)\n"
        s += "    repeat (count)\n"
        s += "      `uvm_do(req)\n"
        s += "  endtask\n\n"
        s += "  virtual task pre_body();\n"
        s += "    uvm_test_done.raise_objection(this);\n"
        s += "  endtask\n\n"
        s += "  virtual task post_body();\n"
        s += "    uvm_test_done.drop_objection(this);\n"
        s += "  endtask\n\n"
        s += "endclass\n"

    end
    
end


# UVM generator - tb top class
# This class is used to generate tb top module
class UVM_gen_tb_top < UVM_gen_file

	attr_reader :p_list, :dut_file, :dut_mod

    def initialize(name, file, port_list, dut_file, dut_mod)
        super(name, file)
		@p_list = port_list
		@dut_file = dut_file
		@dut_mod = dut_mod
    end
    
    def to_s
        s = "`include \"#{@name}_pkg.sv\"\n"
        s += "`include \"#{@name}_if.sv\"\n\n"
        s += "`include \"#{@dut_file}\"\n\n"
        s += "module #{@name}_tb_top;\n\n"
        s += "  import uvm_pkg::*;\n"
        s += "  import #{@name}_pkg::*;\n\n"
        s += "  #{@name}_if vif(); //SystemVerilog Interface\n\n"
        s += "  #{@dut_mod} dut(\n"

        @p_list.each do |p|
			s += "    vif.#{p.name}"
			# Add comma if not the last port
			s += "," if p != @p_list.last
		    s += "\n"
        end

        s += "  );\n\n"
        s += "  initial begin\n"
		s += "    //automatic uvm_coreservice_t cs_ = uvm_coreservice_t::get();\n"
        s += "    //uvm_config_db#(virtual #{@name}_if)::set(cs_.get_root(), \"*\", \"vif\", vif);\n"
		s += "    uvm_config_db#(virtual #{@name}_if)::set(null, \"*.#{@name}_env0*\", \"vif\", vif);\n"
        s += "    run_test();\n"
        s += "  end\n\n"
        s += "  initial begin\n"
        s += "    //vif.sig_reset <= 1'b1;\n"
        s += "    //vif.sig_clock <= 1'b1;\n"
        s += "    //#50 vif.sig_reset = 1'b0;\n"
        s += "  end\n\n"
        s += "  //Generate Clock\n"
        s += "  //always\n"
        s += "  //  #5 vif.sig_clock = ~vif.sig_clock;\n\n"
        s += "  //dump fsdb\n"
        s += "  `ifdef FSDB\n"
        s += "  initial begin\n"
        s += " 	  $fsdbDumpfile(\"wave.fsdb\");\n"
        s += "    $fsdbDumpvars(0, #{@name}_tb_top);\n"
        s += "    $fsdbDumpflush;\n"
        s += "  end\n"
        s += "  `endif\n\n"
        s += "endmodule\n"
    end
    
end


# UVM generator - pkg class
# This class is used to generate pkg
class UVM_gen_pkg < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = "package #{@name}_pkg;\n\n"
        s += "  import uvm_pkg::*;\n"
        s += "  `include \"uvm_macros.svh\"\n\n"
        s += "  `include \"#{@name}_item.sv\"\n"
        s += "  `include \"#{@name}_drv.sv\"\n"
        s += "  `include \"#{@name}_mon.sv\"\n"
        s += "  `include \"#{@name}_agent.sv\"\n"
        s += "  `include \"#{@name}_scoreboard.sv\"\n"
        s += "  `include \"#{@name}_env.sv\"\n"
        s += "  `include \"#{@name}_seq_lib.sv\"\n"
        s += "  `include \"#{@name}_test_lib.sv\"\n"
        s += "endpackage: #{@name}_pkg\n\n"
    end
    
end

# UVM generator - rakefile class
# This class is used to generate rakefile
class UVM_gen_rakefile < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s

		s =  "uvm_home = \"/home/nxf06757/data/lib/uvm-1.2\"\n\n"
		s += "home_dir = Dir.pwd\n"
        s += "out_dir = home_dir+\"/out\"\n"
        s += "src_dir = out_dir+\"/src\"\n"
        s += "sim_dir = out_dir+\"/sim\"\n"
		s += "comp_dir = out_dir+\"/comp\"\n"
        s += "ip_dir = out_dir+\"/ip\"\n\n"

		s += "task :default => [:run]\n\n"

        s += "desc \"get IP code (if any)\"\n"
        s += "task :ip do\n"
		s += "\tcmd = \"git submodule update --init --recursive\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "end\n\n"

        s += "desc \"publish files\"\n"
        s += "task :publish => [:ip] do\n"
		s += "\tmkdir_p src_dir\n"
		s += "\tcmd = \"ln -s \#{home_dir}/rtl \#{src_dir}\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "\tcmd = \"ln -s \#{home_dir}/verif \#{src_dir}\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "\tmkdir_p ip_dir\n"
		s += "\tcmd = \"ln -s \#{home_dir}/ip \#{ip_dir}\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "end\n\n"

		s += "desc \"compile\"\n"
        s += "task :compile => [:publish] do\n"
		s += "\tmkdir_p comp_dir\n"
		s += "\tcmd = \"cd \#{comp_dir}; irun +incdir+../src/verif/uvc/#{@name} +incdir+../src/rtl -uvm -access +rw -64bit -sv -svseed random -sem2009 +fsdb+autoflush -loadpli1 /cadappl_sde/ictools/verdi/K-2015.09/share/PLI/IUS/LINUX64/libIUS.so -licqueue ../src/verif/tb/#{@name}_tb_top.sv -top #{@name}_tb_top +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=#{@name}_base_test\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "end\n\n"
		
        s += "desc \"run base case\"\n"
        s += "task :run => [:compile] do\n"
		s += "\tmkdir_p sim_dir\n"
		s += "\tcmd = \"cd \#{sim_dir}; irun -R -nclibdirname ../INCA_libs +incdir+../src/verif/uvc/#{@name} +incdir+../src/rtl -uvm -access +rw -64bit -sv -svseed random -sem2009 +fsdb+autoflush -loadpli1 /cadappl_sde/ictools/verdi/K-2015.09/share/PLI/IUS/LINUX64/libIUS.so -licqueue ../src/verif/tb/#{@name}_tb_top.sv -top #{@name}_tb_top +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=#{@name}_base_test\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "end\n\n"

        s += "desc \"run base case with waveform\"\n"
		s += "task :run_fsdb => [:compile] do\n"
		s += "\tcmd = \"cd \#{sim_dir}; irun -R -nclibdirname ../INCA_libs +incdir+../src/verif/uvc/#{@name} +incdir+../src/rtl -uvm -access +rw -64bit -sv -svseed random -sem2009 +fsdb+autoflush -loadpli1 /cadappl_sde/ictools/verdi/K-2015.09/share/PLI/IUS/LINUX64/libIUS.so -licqueue ../src/verif/tb/#{@name}_tb_top.sv -top #{@name}_tb_top +UVM_VERBOSITY=UVM_HIGH +UVM_TESTNAME=#{@name}_base_test +define+FSDB\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "end\n\n"

        s += "desc \"open verdi\"\n"
		s += "task :verdi => [:run_fsdb] do\n"
		s += "\tcmd = \"cd \#{sim_dir}; verdi -sv +incdir+\#{uvm_home}/src \#{uvm_home}/src/uvm.sv ../src/verif/tb/#{@name}_tb_top.sv &\"\n"
		s += "\tputs \"Running CMD> \#{cmd}\"\n"
		s += "\tsystem(cmd)\n"
		s += "end\n\n"
    end
    
end

# Only run the following code when this file is the main file being run
# instead of having been required or loaded by another file
if __FILE__ == $0 

# This hash will hold all of the options parsed from the 
# command-line by OptionParser
    options = {}

    optparse = OptionParser.new do |opts|
        # Set a banner displayed at the top of the help screen
        opts.banner = "Usage: ./proj_gen.rb -n PROJ_NAME -f MODULE_FILE [-t TOP_MODULE] -o OUTPUT_DIR"
    
        # Define the env name
        options[:env_name] = nil
        opts.on('-n', '--name PROJ_NAME', 'Specify the project name') do |name|
            options[:env_name] = name
        end
 
        # Define the module file
        options[:mod_file] = nil
        opts.on('-f', '--file MODULE_FILE', 'Specify the module file') do |file|
            options[:mod_file] = file
        end
    
        # Define the top module (optional)
        options[:top_mod] = nil
        opts.on('-t', '--top TOP_MODULE', 'Specify the top module (optional)') do |top|
            options[:top_mod] = top
        end 
    
        # Define the output directory
        options[:output_dir] = nil
        opts.on('-o', '--output OUTPUT_DIR', 'Specify the output directory') do |dir|
            options[:output_dir] = dir
        end
    
        # This displays the help screen
        opts.on('-h', '--help', 'Display this help screen') do
            puts opts
            exit
        end 
 
    end
    
    # Parse the command-line. Remember there are two forms of the parse method.
    # The 'parse' method simply parses ARGV, while the 'parse!' method parses ARGV and 
    # removes any options found there, as well as any parameters for the options
    optparse.parse!

    # For optparse debug only
    #fakeArgs = ['-f', 'xyz.v']
    #optparse.parse!(fakeArgs)
    
    
    # Check the validity of the options
    # Check the env name
    if options[:env_name] == nil
        puts "ERROR: please specify the environment name with \'-n\'"
        exit
    end
    
    # Check the module file
    if options[:mod_file] == nil
        puts "ERROR: please specify the module file with \'-f\'"
        exit
    end
    unless File::exists?(options[:mod_file])
        puts "ERROR: \'#{options[:mod_file]}\' is invalid. Please specify the valid module file"
        exit
    end
    
    # Check the output directory
    if options[:output_dir] == nil
        puts "ERROR: please specify the output directory with \'-o\'"
        exit
    end
    
    
    # Check the top module
    top_mod = nil
    
    mod_file = File::open(options[:mod_file])
    mod_file.each do |line|
    
        # Locate the top module
        if options[:top_mod] == nil #top module is not specified
            if line =~ /^\s*module\s*(\w*)/ #find the first module definition
                top_mod = $1
            end
        else #top module is specified
            if line =~ /^\s*module\s*(#{options[:top_mod]})/
                top_mod = $1
            end
        end
        
    end
    
    mod_file.close
    
    if top_mod == nil
        puts "ERROR: cannot find the top module \'#{options[:top_mod]}\'"
        exit
    else
        puts "The top module is: #{top_mod}"
    end
    
    
    # Assign options hash to variables
    env_name = options[:env_name]
    mod_file = options[:mod_file]
	out_dir  = options[:output_dir].chomp.strip
    out_dir.chop! if out_dir[-1] == '/'
    
    # Check the ports
    port_list = []
    port_flag = false
    
    mod_file = File::open(mod_file)
    mod_file.each do |line|
        
        if port_flag == false
            if line =~ /^\s*module\s*(#{top_mod})/ #start of module
                port_flag = true
            end
        # Get the ports starting with input/output/inout
        elsif line =~ /(input|output|inout)\s*(\[.*\])*\s*(.*)\s*;/
            port = UVM_gen_port.new($3, $1, $2)
            port_list << port
        
        elsif line =~ /^\s*endmodule/ #end of module
            port_flag = false
            break    
        end
        
    end
    
    mod_file.close   
    
	puts "making dir: #{out_dir}"

	# Copy RTL file
	Dir.mkdir out_dir+"/rtl" if !File::directory?(out_dir+"/rtl")
	FileUtils.copy options[:mod_file], out_dir+"/rtl"
	puts "Copying RTL file to: #{out_dir}/rtl"
	
	# Gen UVC files
	Dir.mkdir out_dir+"/verif" if !File::directory?(out_dir+"/verif")
	Dir.mkdir out_dir+"/verif/uvc" if !File::directory?(out_dir+"/verif/uvc")
	Dir.mkdir out_dir+"/verif/uvc/"+env_name if !File::directory?(out_dir+"/verif/uvc/"+env_name)
    # Gen the interface
    intf = UVM_gen_if.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_if.sv", port_list)
    intf.to_f
    
    # Gen the data item
    item = UVM_gen_item.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_item.sv")
	item.to_f
    
    # Gen the driver
    driver = UVM_gen_drv.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_drv.sv")
	driver.to_f

	# Gen the monitor
    monitor = UVM_gen_mon.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_mon.sv")
	monitor.to_f
    
    # Gen the sequencer
    #sequencer = UVM_gen_seqr.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_sequencer.sv")
	#sequencer.to_f
    
    # Gen the agent
    agent = UVM_gen_agent.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_agent.sv")
	agent.to_f
    
	# Gen the scoreboard
    scoreboard = UVM_gen_sb.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_scoreboard.sv")
	scoreboard.to_f

    # Gen the env
    env = UVM_gen_env.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_env.sv")
	env.to_f
    
    # Gen the test lib
    test = UVM_gen_test.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_test_lib.sv")
	test.to_f

    # Gen the seq lib
    seq = UVM_gen_seq.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_seq_lib.sv")
	seq.to_f

    # Gen the pkg
    pkg = UVM_gen_pkg.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_pkg.sv")
	pkg.to_f


	# Gen tb files
	Dir.mkdir out_dir+"/verif/tb" if !File::directory?(out_dir+"/verif/tb")

    # Gen the tb top
	dut_file = options[:mod_file].split('/')[-1]
    tb_top = UVM_gen_tb_top.new(env_name, out_dir+"/verif/tb/"+env_name+"_tb_top.sv", port_list, dut_file, top_mod)
	tb_top.to_f

	# IP dir
	Dir.mkdir out_dir+"/ip" if !File::directory?(out_dir+"/ip")

    # Gen the rakefile
    rakefile = UVM_gen_rakefile.new(env_name, out_dir+"/rakefile")
	rakefile.to_f

end
