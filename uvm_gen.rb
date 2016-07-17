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
        s += "  ovm_object_utils_begin(#{@name}_item)\n"
        s += "    ovm_field_int(addr, UVM_ALL_ON)\n"
        s += "    ovm_field_int(data, UVM_ALL_ON)\n"
        s += "    ovm_field_int(delay, UVM_ALL_ON)\n"
        s += "  ovm_object_utils_end\n\n" 
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
        s = 'class simple_driver extends uvm_driver #(simple_item);
simple_item s_item;
virtual dut_if vif;
// UVM automation macros for general components
ovm_component_utils(simple_driver) 
// Constructor
function new (string name = "simple_driver", uvm_component parent);
super.new(name, parent);
endfunction : new
function void build_phase(uvm_phase phase);
string inst_name;
super.build_phase(phase);
if(!uvm_config_db#(virtual dut_if)::get(this,
"","vif",vif))
ovm_fatal("NOVIF",
{"virtual interface must be set for: ",
get_full_name(),".vif"});
endfunction : build_phase
task run_phase(uvm_phase phase);
forever begin
// Get the next data item from sequencer (may block).
seq_item_port.get_next_item(s_item);
// Execute the item.
drive_item(s_item);
seq_item_port.item_done(); // Consume the request.
end
endtask : run
task drive_item (input simple_item item);
... // Add your logic here.
endtask : drive_item
endclass : simple_driver'
        
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
    out_dir.chop! if out_dir[-1] = '/'
    
    
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
    intf.to_f
    
    # Gen the data item
    item = UVM_gen_item.new(env_name, out_dir+"/"+env_name+"_item.sv")
    puts "Generating file: #{out_dir}/#{env_name}_item.sv"
    puts item.to_s
    

end
