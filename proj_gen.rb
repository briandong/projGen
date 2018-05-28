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
        File::open(@file, "w") do |f|
          f.puts to_s
		end
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
        s = <<-HEREDOC_IF
interface #{@name}_if;

  // Control flags
  bit has_checks = 1;
  bit has_coverage = 1;

  // Actual signals
		HEREDOC_IF
        
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
        s = <<-HEREDOC_ITEM
class #{@name}_item extends uvm_sequence_item;

  rand int unsigned addr;
  rand int unsigned data;
  rand int unsigned delay;

  constraint c1 {addr < 16'h2000;}
  constraint c2 {data < 16'h1000;}

  //UVM automation macros for general objects
  `uvm_object_utils_begin(#{@name}_item)
    `uvm_field_int(addr, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(delay, UVM_ALL_ON)
  `uvm_object_utils_end

  // Constructor
  function new (string name = "#{@name}_item");
    super.new(name);
  endfunction: new

endclass: #{@name}_item
        HEREDOC_ITEM
    end

end

# UVM generator - driver class
# This class is used to generate a driver
class UVM_gen_drv < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_DRV
class #{@name}_driver extends uvm_driver #(#{@name}_item);

  #{@name}_item item;
  virtual #{@name}_if vif;

  // UVM automation macros for general components
  `uvm_component_utils(#{@name}_driver)

  // Constructor
  function new (string name = "#{@name}_driver", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    string inst_name;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual #{@name}_if)::get(this,"","vif",vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ",
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
  endtask: run_phase

  virtual task drive_item (input #{@name}_item item);
    // Add your logic here.
    `uvm_info(get_type_name(), "driving item", UVM_LOW)

    fork
      begin
      end
      begin
      end
    join_any
    disable fork;

    #10;
  endtask: drive_item

endclass: #{@name}_driver
        HEREDOC_DRV
    end

end

# UVM generator - monitor class
# This class is used to generate a monitor
class UVM_gen_mon < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_MON
class #{@name}_monitor extends uvm_monitor;

  virtual #{@name}_if vif;

  bit checks_enable = 1; // Control checking in monitor and interface
  bit coverage_enable = 1; // Control coverage in monitor and interface
  uvm_analysis_port #(#{@name}_item) item_collected_port;
  event cov_transaction; // Events needed to trigger covergroups
  protected #{@name}_item trans_collected;

  // UVM automation macros for general components
  `uvm_component_utils_begin(#{@name}_monitor)
    `uvm_field_int(checks_enable, UVM_ALL_ON)
    `uvm_field_int(coverage_enable, UVM_ALL_ON)
  `uvm_component_utils_end

  // Coverage
  covergroup cov_trans @cov_transaction;
  option.per_instance = 1;
    // Coverage bins definition
  endgroup: cov_trans

  // Constructor
  function new (string name = "#{@name}_monitor", uvm_component parent);
    super.new(name, parent);
      cov_trans = new();
      cov_trans.set_inst_name({get_full_name(), ".cov_trans"});
      trans_collected = new();
      item_collected_port = new("item_collected_port", this);
  endfunction: new

  function void build_phase(uvm_phase phase);
    string inst_name;
    super.build_phase(phase);
    if (!uvm_config_db#(virtual #{@name}_if)::get(this,"","vif",vif))
      `uvm_fatal("NOVIF", {"virtual interface must be set for: ",
      get_full_name(),".vif"});
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    collect_transactions(); // collector task
  endtask: run_phase

  virtual protected task collect_transactions();
    //forever begin
      //@(posedge vif.clock);
      // Collect the data from the bus into trans_collected
      if (checks_enable)
        perform_transfer_checks();
      if (coverage_enable)
        perform_transfer_coverage();
      item_collected_port.write(trans_collected);
    //end
  endtask: collect_transactions

  virtual protected function void perform_transfer_coverage();
    -> cov_transaction;
  endfunction: perform_transfer_coverage

  virtual protected function void perform_transfer_checks();
    // Perform data checks on trans_collected.
  endfunction: perform_transfer_checks

endclass: #{@name}_monitor
        HEREDOC_MON
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
        s = <<-HEREDOC_SEQR
class #{@name}_sequencer extends uvm_sequencer #(#{@name}_item);

  `uvm_component_utils(#{@name}_sequencer)

  // Constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

endclass: #{@name}_sequencer
		HEREDOC_SEQR
    end

end

# UVM generator - agent class
# This class is used to generate a agent
class UVM_gen_agent < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_AGENT
class #{@name}_agent extends uvm_agent;

  uvm_active_passive_enum is_active;

  // UVM automation macros
  `uvm_component_utils_begin(#{@name}_agent)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_component_utils_end

  // Constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  uvm_sequencer #(#{@name}_item) sequencer;
  #{@name}_driver driver;
  #{@name}_monitor monitor;
  
  // Use build_phase to create agents's subcomponents
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor = #{@name}_monitor::type_id::create("monitor",this);
    if (is_active == UVM_ACTIVE) begin
      // Build the sequencer and driver
      sequencer =
      uvm_sequencer#(#{@name}_item)::type_id::create("sequencer",this);
      driver = #{@name}_driver::type_id::create("driver",this);
    end
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    if(is_active == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction: connect_phase

endclass: #{@name}_agent
        HEREDOC_AGENT
    end
    
end

# UVM generator - scoreboard class
# This class is used to generate a scoreboard
class UVM_gen_sb < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_SB
class #{@name}_scoreboard extends uvm_scoreboard;

  uvm_analysis_imp#(#{@name}_item, #{@name}_scoreboard) item_collected_export;

  protected bit disable_scoreboard = 0;
  int sb_error = 0;

  // Provide implementations of virtual methods such as get_type_name and create
  `uvm_component_utils_begin(#{@name}_scoreboard)
    `uvm_field_int(disable_scoreboard, UVM_ALL_ON)
  `uvm_component_utils_end

  // Constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  // build_phase
  function void build_phase(uvm_phase phase);
    item_collected_export = new("item_collected_export", this);
  endfunction

  // Provide implementation of write()
  virtual function void write(#{@name}_item trans);
    if(!disable_scoreboard) begin
    end
  endfunction: write

endclass
        HEREDOC_SB
    end
end

# UVM generator - env class
# This class is used to generate env
class UVM_gen_env < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_ENV
class #{@name}_env extends uvm_env;

  // Virtual interface variable
  protected virtual interface #{@name}_if vif;

  // Control properties
  protected int num_masters = 0;

  // Components of the env
  #{@name}_agent masters[];
  #{@name}_scoreboard scoreboard0;

  `uvm_component_utils_begin(#{@name}_env)
    `uvm_field_int(num_masters, UVM_ALL_ON)
  `uvm_component_utils_end

  virtual function void build_phase(uvm_phase phase);
    string inst_name;
    super.build_phase(phase);

    if(!uvm_config_db#(virtual #{@name}_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});

    if(num_masters ==0)
      `uvm_fatal("NONUM",{"'num_masters' must be set for: ", get_full_name()});

    //uvm_config_db#(uvm_active_passive_enum)::set(this,
    uvm_config_db#(int)::set(this,
      "masters*", "is_active", UVM_ACTIVE);

    masters = new[num_masters];
    for(int i = 0; i < num_masters; i++) begin
      $sformat(inst_name, "masters[%0d]", i);
      masters[i] = #{@name}_agent::type_id::create(inst_name, this);
    end

    scoreboard0 = #{@name}_scoreboard::type_id::create("scoreboard0", this);

    // Build slaves and other components

  endfunction

  virtual function void connect_phase(uvm_phase phase);
    // Connect monitor to scoreboard
    masters[0].monitor.item_collected_port.connect(
      scoreboard0.item_collected_export);
  endfunction: connect_phase

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

endclass
        HEREDOC_ENV
    end
    
end

# UVM generator - test class
# This class is used to generate test
class UVM_gen_test < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_TEST
class #{@name}_base_test extends uvm_test;

  `uvm_component_utils(#{@name}_base_test)

  #{@name}_env #{@name}_env0;

  // The test’s constructor
  function new (string name = "#{@name}_base_test",
    uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Update this component's properties and create the #{@name}_env component
  virtual function void build_phase(uvm_phase phase); // create the top-level environment.

    //For derived class, super.build_phase() through the base class,
    // will create the top-level environment and all its subcomponents
    //Therefore, any configuration that will affect the building
    // of these components must be set before calling super.build_phase()
    uvm_config_db#(int)::set(this,"#{@name}_env0", "num_masters", <%= num_of_masters %>);
    super.build_phase(phase);
    #{@name}_env0 =
      #{@name}_env::type_id::create("#{@name}_env0", this);
    //Since the sequences don’t get started until a later phase,
    // they could be called after super.build_phase()
    uvm_config_db#(uvm_object_wrapper)::
      set(this, "#{@name}_env0.masters[0].sequencer.run_phase",
      "default_sequence", #{@name}_base_seq::type_id::get());
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase

  virtual task run_phase(uvm_phase phase);
    //set a drain-time for the environment if desired 
    phase.phase_done.set_drain_time(this, 5000);
  endtask

endclass
        HEREDOC_TEST
    end
    
end

# UVM generator - sequence class
# This class is used to generate sequence
class UVM_gen_seq < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_SEQ
class #{@name}_base_seq extends uvm_sequence #(#{@name}_item);

  rand int count;
  constraint c1 { count > 0; count < 10; }

  // Register with the factory
  `uvm_object_utils_begin(#{@name}_base_seq)
    `uvm_field_int(count, UVM_ALL_ON)
  `uvm_object_utils_end

  // The sequence’s constructor
  function new (string name = "#{@name}_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info(get_type_name(), $psprintf("has %0d item(s)", count), UVM_LOW)
    repeat (count)
      `uvm_do(req)
  endtask

  virtual task pre_body();
    uvm_test_done.raise_objection(this);
  endtask

  virtual task post_body();
    uvm_test_done.drop_objection(this);
  endtask

endclass
        HEREDOC_SEQ
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
        s = <<-HEREDOC_TOP
`include "#{@name}_pkg.sv"
`include "#{@name}_if.sv"

`include "#{@dut_file}"

module #{@name}_tb_top;

  import uvm_pkg::*;
  import #{@name}_pkg::*;

  #{@name}_if vif(); //SystemVerilog Interface

  #{@dut_mod} dut(
		HEREDOC_TOP

        @p_list.each do |p|
			s += "    vif.#{p.name}"
			# Add comma if not the last port
			s += "," if p != @p_list.last
		    s += "\n"
        end

        s += <<-HEREDOC_TOP
  );

  initial begin
    //automatic uvm_coreservice_t cs_ = uvm_coreservice_t::get();
    //uvm_config_db#(virtual #{@name}_if)::set(cs_.get_root(), "*", "vif", vif);
    uvm_config_db#(virtual #{@name}_if)::set(null, "*.#{@name}_env0*", "vif", vif);
    run_test();
  end

  initial begin
    //vif.sig_reset <= 1'b1;
    //vif.sig_clock <= 1'b1;
    //#50 vif.sig_reset = 1'b0;
  end

  //Generate Clock
  //always
  //  #5 vif.sig_clock = ~vif.sig_clock;

  //dump fsdb
  `ifdef FSDB
  initial begin
 	  $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, #{@name}_tb_top);
    $fsdbDumpflush;
  end
  `endif

endmodule
		HEREDOC_TOP
    end
    
end


# UVM generator - pkg class
# This class is used to generate pkg
class UVM_gen_pkg < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_PKG
package #{@name}_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "#{@name}_item.sv"
  `include "#{@name}_drv.sv"
  `include "#{@name}_mon.sv"
  `include "#{@name}_agent.sv"
  `include "#{@name}_scoreboard.sv"
  `include "#{@name}_env.sv"
  `include "#{@name}_seq_lib.sv"
  `include "#{@name}_test_lib.sv"
endpackage: #{@name}_pkg
		HEREDOC_PKG
    end
    
end

# UVM generator - suite class
# This class is used to generate suite file
class UVM_gen_suite < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_SUITE
suite :base

  test :#{@name}_base_test
    desc    "The base test for all other tests"
    owner   :smith
	config  :full
    sanity  true
    regress true
    debug   false
  endtest

endsuite
 	HEREDOC_SUITE
    end
end

# UVM generator - config class
# This class is used to generate config file
class UVM_gen_config < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
        s = <<-HEREDOC_CONFIG
dummy = false
num_of_masters = 1
 	HEREDOC_CONFIG
    end
end

# UVM generator - rakefile class
# This class is used to generate rakefile
class UVM_gen_rakefile < UVM_gen_file

    def initialize(name, file)
        super(name, file)
    end
    
    def to_s
		s = <<-HEREDOC_RAKE
home_dir   = Dir.pwd
out_dir    = home_dir+"/out"

incdir_list  = " +incdir+$UVM_HOME/src $UVM_HOME/src/uvm.sv $UVM_HOME/src/dpi/uvm_dpi.cc"

cmd_prefix = "bsub -I "

# irun version
#compile_cmd = "irun -elaborate \#{incdir_list} \#{ver_dir}/tb/#{@name}_tb_top.sv -top #{@name}_tb_top -64bit -access +rw -uvm -v93 +define+FSDB -l irun_comp_#{@name}.log"
#sim_cmd = "irun -R -nclibdirname \#{comp_dir}/INCA_libs \#{incdir_list} -uvm -access +rw -64bit -sv -svseed random -sem2009 +fsdb+autoflush -loadpli1 /cadappl_sde/ictools/verdi/K-2015.09/share/PLI/IUS/LINUX64/libIUS.so -licqueue \#{src_dir}/verif/tb/#{@name}_tb_top.sv -top #{@name}_tb_top +UVM_VERBOSITY=UVM_HIGH"

# Methods
def run_cmd(type, dir, command)
  mkdir_p dir if !File::directory?(dir)
  cmd = "cd \#{dir} && \#{command}"
  if sh(cmd)
    puts "**Successfully completed CMD \#{type.to_s.upcase}**"
  else
    puts "**Error running CMD \#{type.to_s.upcase}> \#{cmd}**"
  end
end

def run_pub(dir, set_file)
  puts "Publishing \#{dir} with \#{set_file}..."

  settings = []
  File::open(set_file).each do |l|
	settings << l.strip.gsub(/\\s/,'') #remove white spaces
  end

  Dir["\#{dir}/**/*.erb"].each do |f|
    f_target = File.dirname(f)+"/"+File.basename(f, File.extname(f))
	cmd = "erb \#{settings.join " "} \#{f} > \#{f_target} && rm \#{f}"
    puts "Parsing \#{f} => \#{f_target}"
    sh(cmd)
  end
end

# Testcases
# class Testcase definition
class Testcase
  attr_accessor :name, :suite, :desc, :owner, :config, :sanity, :regress, :debug

  def initialize(name)
    @name = name
  end
end

@test_list = []

@suite_name = nil
@test_name = nil
@desc, @owner, @config = nil, nil, nil
@sanity, @regress, @debug = false, false, false

def gen_test_list
  @test_list = []
  suite_list = FileList["meta/suites/*.rb"]
  suite_list.each do |suite_f|
    path = File.dirname(suite_f) + "/" + 
	  File.basename(suite_f, File.extname(suite_f))
    require_relative path
  end
end

def suite(name)
  @suite_name = name
end

def test(name)
  @test_name = name
  @desc, @owner = nil, nil
  @sanity, @regress, @debug = false, false, false
end

def desc(content)
  @desc = content
end

def owner(name)
  @owner = name
end

def config(cfg)
  @config = cfg
end

def sanity(status = false)
  @sanity = status
end

def regress(status = false)
  @regress = status
end

def debug(status = false)
  @debug = status
end

def endtest
  #initialize
  t = Testcase.new(@test_name)
  #set default if not available
  t.suite = @suite_name || "UNKNOWN"
  t.desc = @desc || "UNKNOWN"
  t.owner = @owner || "UNKNOWN"
  t.config = @config || "UNKNOWN"
  t.sanity = @sanity || false
  t.regress = @regress || false
  t.debug = @debug || false

  @test_list << t

  @test_name = nil
  @desc, @owner = nil, nil
  @sanity, @regress, @debug = false, false, false
end

def endsuite
  @suite_name = nil
end


# Tasks
task :default => [:run]

desc "get IP code (if any)"
task :ip do
  cmd = "git submodule update --init --recursive"
  run_cmd(:ip, home_dir, cmd)
end

desc "publish files"
task :publish, [:config] => [:ip] do |t, args|
  args.with_defaults(:config => :full)
  ocfg_dir = out_dir+"/\#{args[:config].to_s}"
  osrc_dir = ocfg_dir+"/src"
  #cmd = "ln -s \#{home_dir}/design \#{osrc_dir} &&"
  #cmd += "ln -s \#{home_dir}/verif \#{osrc_dir} &&"
  #cmd += "ln -s \#{home_dir}/ip \#{osrc_dir}"
  cmd  = "cp -r \#{home_dir}/design \#{osrc_dir} &&"
  cmd += "cp -r \#{home_dir}/verif \#{osrc_dir} "
  run_cmd(:publish, osrc_dir, cmd)
  run_pub("\#{osrc_dir}/design", "meta/config/\#{args[:config].to_s}.cfg")
  run_pub("\#{osrc_dir}/verif", "meta/config/\#{args[:config].to_s}.cfg")
end

desc "compile"
task :compile, [:config, :dbg] => [:publish] do |t, args|
  args.with_defaults(:config => :full)
  args.with_defaults(:dbg => false)
  ocfg_dir  = out_dir+"/\#{args[:config].to_s}"
  osrc_dir  = ocfg_dir+"/src"
  odes_dir  = osrc_dir+"/design"
  ortl_dir  = odes_dir+"/rtl"
  over_dir  = osrc_dir+"/verif"
  osim_dir  = ocfg_dir+"/sim"
  ocomp_dir = osim_dir+"/comp"
  incdir_list += " +incdir+\#{ortl_dir} +incdir+\#{over_dir}/tb +incdir+\#{over_dir}/uvc/#{@name}"
  compile_cmd = cmd_prefix + "vcs \#{incdir_list} \#{over_dir}/tb/#{@name}_tb_top.sv -sverilog -full64 -debug_access+all -lca -l compile.log"
  compile_cmd += " +define+FSDB" if args[:dbg]
  run_cmd(:compile, ocomp_dir, compile_cmd)
end

desc "simulation"
task :sim, [:case, :config, :dbg] => [:compile] do |t, args|
  args.with_defaults(:case => :#{@name}_base_test)
  args.with_defaults(:config => :full)
  args.with_defaults(:dbg => false)
  ocfg_dir  = out_dir+"/\#{args[:config].to_s}"
  osrc_dir  = ocfg_dir+"/src"
  osim_dir  = ocfg_dir+"/sim"
  ocomp_dir = osim_dir+"/comp"
  ocase_dir = osim_dir+"/\#{args[:case].to_s}"
  sim_cmd = cmd_prefix + "\#{ocomp_dir}/simv +ntb_random_seed_automatic +UVM_VERBOSITY=UVM_HIGH -l sim.log"
  sim_cmd += " +UVM_TESTNAME=\#{args[:case].to_s}"
  sim_cmd += " +UVM_CONFIG_DB_TRACE" if args[:dbg]
  run_cmd(:run, ocase_dir, sim_cmd)
end

desc "run case"
task :run, [:dbg] do |t, args|
  args.with_defaults(:dbg => false)
  case_list = args.extras
  gen_test_list
  @test_list.each do |t|
	Rake::Task[:sim].invoke(t.name, t.config, args[:dbg]) if case_list.include? t.name
  end
end

desc "run sanity"
task :sanity do
  gen_test_list
  @test_list.each do |t|
	Rake::Task[:sim].invoke(t.name, t.config) if (t.sanity && !t.debug)
  end
end

desc "run regression"
task :regress do
  gen_test_list
  @test_list.each do |t|
	Rake::Task[:sim].invoke(t.name, t.config) if (t.regress && !t.debug)
  end
end

desc "open verdi"
task :verdi, [:config] do
  ocfg_dir  = out_dir+"/\#{args[:config].to_s}"
  osrc_dir  = ocfg_dir+"/src"
  over_dir  = osrc_dir+"/verif"
  incdir_list += " +incdir+\#{ortl_dir} +incdir+\#{over_dir}/tb +incdir+\#{over_dir}/uvc/#{@name}"
  verdi_cmd = cmd_prefix + "verdi -sv -uvm \#{incdir_list} \#{ver_dir}/tb/#{@name}_tb_top.sv &"
  run_cmd(:verdi, sim_dir, verdi_cmd)
end

desc "clean output"
task :clean do
  clean_cmd = "rm -rf out"
  run_cmd(:clean, home_dir, clean_cmd)
end
		HEREDOC_RAKE
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
        opts.banner = "Usage:   ./proj_gen.rb -n PROJ_NAME -f MODULE_FILE [-t TOP_MODULE] -o OUTPUT_DIR\n"
		opts.banner += "Example: ./proj_gen.rb -n sample -f sample.v.erb -o ./sampleProj"
    
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
	Dir.mkdir out_dir if !File::directory?(out_dir)

    # Gen meta files
	FileUtils.mkdir_p out_dir+"/meta/suites" if !File::directory?(out_dir+"/meta/suites")
	FileUtils.mkdir_p out_dir+"/meta/config" if !File::directory?(out_dir+"/meta/config")

	# Copy RTL file
	FileUtils.mkdir_p out_dir+"/design/rtl" if !File::directory?(out_dir+"/design/rtl")
	FileUtils.copy options[:mod_file], out_dir+"/design/rtl"
	puts "Copying RTL file to: #{out_dir}/design/rtl"
	
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
	test = UVM_gen_test.new(env_name, out_dir+"/verif/uvc/"+env_name+"/"+env_name+"_test_lib.sv.erb")
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
	dut_file = File.basename options[:mod_file]
	dut_file = File.basename(dut_file, File.extname(dut_file)) if File.extname(dut_file) == ".erb"
    tb_top = UVM_gen_tb_top.new(env_name, out_dir+"/verif/tb/"+env_name+"_tb_top.sv", port_list, dut_file, top_mod)
	tb_top.to_f

	# IP dir
	Dir.mkdir out_dir+"/ip" if !File::directory?(out_dir+"/ip")

    # Gen the suite file
    suite = UVM_gen_suite.new(env_name, out_dir+"/meta/suites/base.rb")
    suite.to_f

    # Gen the config file
    config = UVM_gen_config.new(env_name, out_dir+"/meta/config/full.cfg")
    config.to_f

    # Gen the rakefile
    rakefile = UVM_gen_rakefile.new(env_name, out_dir+"/rakefile")
	rakefile.to_f

end
