#!/usr/bin/env ruby

require 'optparse'

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
            s += "  logic #{p.width} #{p.name}; //#{p.type}\n"
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
        s += "      uvm_fatal(\"NOVIF\", {\"virtual interface must be set for: \",\n"
        s += "      get_full_name(),\".vif\"});\n"
        s += "  endfunction: build_phase\n\n"
        s += "  virtual task run_phase(uvm_phase phase);\n"
        s += "    forever begin\n"
        s += "      // Get the next data item from sequencer (may block)\n"
        s += "      seq_item_port.get_next_item(item);\n"
        s += "      // Execute the item\n"
        s += "      drive_item(item);\n"
        s += "      seq_item_port.item_done(); // Consume the request\n"
        s += "     end\n"
        s += "  endtask: run\n\n"
        s += "  virtual task drive_item (input #{@name}_item item);\n"
        s += "    // Add your logic here.\n"
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
        s += "      uvm_fatal(\"NOVIF\", {\"virtual interface must be set for: \",\n"
        s += "      get_full_name(),\".vif\"});\n"
        s += "  endfunction: build_phase\n\n"
        s += "  virtual task run_phase(uvm_phase phase);\n"
		s += "    collect_transactions(); // collector task\n"
        s += "  endtask: run\n\n"
        s += "  virtual protected task collect_transactions();\n"
        s += "    forever begin\n"
		s += "      @(posedge vif.clock);\n"
        s += "      // Collect the data from the bus into trans_collected\n"
        s += "      if (checks_enable)\n"
        s += "        perform_transfer_checks();\n"
        s += "      if (coverage_enable)\n"
        s += "        perform_transfer_coverage();\n"
        s += "      item_collected_port.write(trans_collected);\n"
        s += "    end\n"
        s += "  endtask: collect_transactions\n\n"
		s += "  virtual protected function void perform_transfer_coverage();\n"
        s += "    -> cov_transaction;\n"
        s += "  endfunction : perform_transfer_coverage\n\n"
        s += "  virtual protected function void perform_transfer_checks();\n"
        s += "    // Perform data checks on trans_collected.\n"
        s += "  endfunction : perform_transfer_checks\n\n"
        s += "endclass: #{@name}_monitor\n"
        
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
        opts.banner = "Usage: ./uvm_gen.rb -n ENV_NAME -f MODULE_FILE [-t TOP_MODULE] -o OUTPUT_DIR"
    
        # Define the env name
        options[:env_name] = nil
        opts.on('-n', '--name ENV_NAME', 'Specify the environment name') do |name|
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
    out_dir  = options[:output_dir]
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
    
    
    # Gen the interface
    intf = UVM_gen_if.new(env_name, 
        out_dir+"/"+env_name+"_if.sv", port_list)
    puts "Generating file: #{out_dir}/#{env_name}_if.sv"
    #puts intf.to_s
    intf.to_f
    
    # Gen the data item
    item = UVM_gen_item.new(env_name, out_dir+"/"+env_name+"_item.sv")
    puts "Generating file: #{out_dir}/#{env_name}_item.sv"
    #puts item.to_s
	item.to_f
    
    # Gen the driver
    driver = UVM_gen_drv.new(env_name, out_dir+"/"+env_name+"_driver.sv")
    puts "Generating file: #{out_dir}/#{env_name}_driver.sv"
    #puts driver.to_s
	driver.to_f

	# Gen the monitor
    monitor = UVM_gen_mon.new(env_name, out_dir+"/"+env_name+"_monitor.sv")
    puts "Generating file: #{out_dir}/#{env_name}_monitor.sv"
    #puts monitor.to_s
	monitor.to_f
end
