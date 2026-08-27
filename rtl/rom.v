module rom
#(
  parameter ADDRWIDTH = 14,
  parameter DATAWIDTH = 8
)
(
  input                       clock,
  input  [ADDRWIDTH-1:0]      address,
  output reg [DATAWIDTH-1:0]  q,
  input                       rden,

  // download interface
  input                       ioctl_download,
  input  [24:0]               ioctl_addr,
  input  [7:0]                ioctl_dout,
  input                       ioctl_wr
);

reg [DATAWIDTH-1:0] mem [0:(1<<ADDRWIDTH)-1];

always @(posedge clock) begin
  if (ioctl_wr && ioctl_download)
    mem[ioctl_addr[ADDRWIDTH-1:0]] <= ioctl_dout;
end

always @(posedge clock) begin
  if (rden)
    q <= mem[address];
  else
    q <= {DATAWIDTH{1'b1}};
end

endmodule
