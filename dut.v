module dut_dummy( 
  input wire ubus_req_master_0,
  output reg ubus_gnt_master_0,
  input wire ubus_req_master_1,
  output reg ubus_gnt_master_1,
  input wire ubus_clock,
  input wire ubus_reset,
  input wire [15:0] ubus_addr,
  input wire [1:0] ubus_size,
  output reg ubus_read,
  output reg ubus_write,
  output reg  ubus_start,
  input wire ubus_bip,
  inout wire [7:0] ubus_data,
  input wire ubus_wait,
  input wire ubus_error);

endmodule