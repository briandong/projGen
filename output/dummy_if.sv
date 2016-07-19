interface dummy_if;

  // Control flags
  bit has_checks = 1;
  bit has_coverage = 1;

  // Actual signals
  logic  P1, P2; //input
  logic [7:0] P3; //output
  logic  P4; //inout

endinterface: dummy_if
