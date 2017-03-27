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

## Exploring the Sample Project

In this section we explore the generated sample project.

### File Structure







