# Project Generator

[TOC]

## Introduction

The main purpose of this program is to automatically generate a basic project source code framework with a runnable and extendable UVM verification environment, based on a top module verilog RTL file, which could greatly save the effort and time for the initial setup work of a new project. 

## How to Use

To get help on this program:

> ./proj_gen.rb -h

Usage: ./proj_gen.rb -n PROJ_NAME -f MODULE_FILE [-t TOP_MODULE] -o OUTPUT_DIR
* -n, --name PROJ_NAME        Specify the project name
* -f, --file MODULE_FILE         Specify the module file
* -t, --top TOP_MODULE         Specify the top module (optional)
* -o, --output OUTPUT_DIR    Specify the output directory
* -h, --help                                  Display this help screen

Note: [-t TOP_MODULE] is optional, default is the 1st module in MODULE_FILE

### Examples

Specify project name "sample", RTL file "sample.v", top module "sample", and generate to dir "./sample":
> ./proj_gen.rb -n sample -f sample.v -t sample-o ./sample

Could omit top module if "sample" is the 1st module defined in RTL file "sample.v":
> ./proj_gen.rb -n sample -f sample.v -o ./sample



------

## Exploring the Sample Project

In this section we explore the generated sample project.

### Tasks Available

To get the available task list, just change to sample project directory and type:

> rake --tasks

Normally the task list looks like:

```
rake compile         # compile
rake ip              # get IP code (if any)
rake publish         # publish files
rake run[case]       # run case
rake run_fsdb[case]  # run case with waveform
rake verdi           # open verdi
```

Pay attention to task

> rake ip

IPs are developed as separate projects and organized as nested submodules in this sample project.

**Benefit:** a centralized IP is much easier to maintain than the the same IP scattered in different projects with different versions.

### Dependency

Note that the tasks above have dependency relationship as:

```
ip <= publish <= compile <= run/run_fsdb
```

It means higher dependency tasks (right ones) rely on lower dependency tasks (left ones), and will automatically execute dependent tasks if necessary.

For example, if you execute

> rake run

from scratch, it will automatically run tasks 'ip', 'publish', and 'compile' before that.

**Benefit:** program takes care of all the underlying dependency issues so that user only needs to focus on target task.

### Flow and File Structure

Before running any tasks, the original clean project file structure is:

```
▾ ip/
▾ rtl/
    sample.v
▾ verif/
  ▾ tb/
      sample_tb_top.sv
  ▾ uvc/
    ▾ sample/
        sample_agent.sv
        sample_drv.sv
        sample_env.sv
        sample_if.sv
        sample_item.sv
        sample_mon.sv
        sample_pkg.sv
        sample_scoreboard.sv
        sample_seq_lib.sv
        sample_test_lib.sv
  rakefile
```

#### Publish

All the code is published to 'out/src' directory before use (compile/run). So the project file structure after 

> rake publish

is:

```
▸ ip/
▾ out/
  ▾ src/
    ▾ ip/
    ▸ rtl/
    ▸ verif/
▸ rtl/
▸ verif/
  rakefile
```

**Benefit:** better flexibility and neater source code control.

#### Compile

A simulation snapshot will be created in 'out/sim/comp' directory for simulation of multiple cases,  after 

> rake compile

```
▸ ip/
▾ out/
  ▾ sim/
    ▾ comp/
      ▾ INCA_libs/
        ▸ irun.lnx8664.14.20.nc/
        ▸ irun.nc/
        ▸ worklib/
        irun_comp_sample.log
  ▸ src/
▸ rtl/
▸ verif/
  rakefile
```

#### Simulate

Execute 

> rake run[CASE_NAME]

or 
> rake run_fsdb[CASE_NAME]

for case simulation w.o/w. waveform. The sim log and waveform are stored in directory 'out/sim/CASE_NAME':

```
▸ ip/
▾ out/
  ▾ sim/
    ▸ comp/
    ▾ sample_base_test/
        irun.log
        novas_dump.log
        wave.fsdb
  ▸ src/
▸ rtl/
▸ verif/
  rakefile
```

**Benefit:** multiple cases can run simultaneously based on the same snapshot to improve the simulation efficiency.

#### Debug

To open a verdi session for debug, just type:

> rake verdi





