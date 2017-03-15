# Project Generator

[TOC]

## Introduction

The main purpose of this program is to build a runnable and expandable UVM verification environment framework automatically with user-friendly guides based on a verilog top module file, which could greatly save the effort and time for the implementation and debug of detailed verification work. 

## Help & Usage

> ./proj_gen.rb -h


Usage: ./proj_gen.rb -n ENV_NAME -f MODULE_FILE [-t TOP_MODULE] -o OUTPUT_DIR
* -n, --name ENV_NAME              Specify the environment name
* -f, --file MODULE_FILE           Specify the module file
* -t, --top TOP_MODULE             Specify the top module (optional)
* -o, --output OUTPUT_DIR          Specify the output directory
* -h, --help                       Display this help screen

*Note: [-t TOP_MODULE] is optional, default is the 1st module in MODULE_FILE*


## Examples


> ./proj_gen.rb -n uart -f uart.v -t uart -o ./uart
