#!/usr/bin/env ruby

require "test/unit"
require "./uvm_gen"

# Derive the test class from 'Test::Unit::TestCase'
class UVM_gen_port_test < Test::Unit::TestCase

    # test method starts with 'test_'
    def test_to_s
        p = UVM_gen_port.new("abc", "[7:0]", "input")
        assert_equal(p.to_s, "input [7:0] abc")
    end
    
end