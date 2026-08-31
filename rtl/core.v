
module core (
    input         clk_sys,
    input         reset,
    input  [7:0]  p1,
    input  [7:0]  p2,
    input  [7:0]  p3,
    input  [7:0]  dsw,
    input  [7:0]  dsw2,
    input         ioctl_download,
    input  [15:0] ioctl_index,
    input  [24:0] ioctl_addr,
    input  [7:0]  ioctl_dout,
    input         ioctl_wr,
    output [2:0]  red,
    output [2:0]  green,
    output [1:0]  blue,
    output        vb,
    output        hb,
    output        vs,
    output        hs,
    output        ce_pix,
    output [15:0] sound,
    input         vflip
);

    wire core_download = ioctl_download && (ioctl_index == 16'd0);
    wire ioctl_rom0  = core_download && ioctl_addr < 25'h08000;
    wire ioctl_rom1  = core_download && ioctl_addr >= 25'h08000 && ioctl_addr < 25'h0C000;
    wire ioctl_rom2  = core_download && ioctl_addr >= 25'h0C000 && ioctl_addr < 25'h10000;
    wire ioctl_rom3  = core_download && ioctl_addr >= 25'h10000 && ioctl_addr < 25'h18000;
    wire ioctl_rom4  = core_download && ioctl_addr >= 25'h18000 && ioctl_addr < 25'h1C000;
    wire ioctl_rom5  = core_download && ioctl_addr >= 25'h1C000 && ioctl_addr < 25'h1E000;
    wire ioctl_rom6  = core_download && ioctl_addr >= 25'h1E000 && ioctl_addr < 25'h20000;
    wire ioctl_rom7  = core_download && ioctl_addr >= 25'h20000 && ioctl_addr < 25'h28000;
    wire ioctl_rom8  = core_download && ioctl_addr >= 25'h28000 && ioctl_addr < 25'h30000;
    wire ioctl_rom9  = core_download && ioctl_addr >= 25'h30000 && ioctl_addr < 25'h38000;
    wire ioctl_romA  = core_download && ioctl_addr >= 25'h38000 && ioctl_addr < 25'h3C000;
    wire ioctl_romB  = core_download && ioctl_addr >= 25'h3C000 && ioctl_addr < 25'h40000;
    wire ioctl_romC  = core_download && ioctl_addr >= 25'h40000 && ioctl_addr < 25'h44000;
    wire ioctl_romD  = core_download && ioctl_addr >= 25'h44000 && ioctl_addr < 25'h48000;
    wire ioctl_romE  = core_download && ioctl_addr >= 25'h48000 && ioctl_addr < 25'h4C000;
    wire ioctl_romF  = core_download && ioctl_addr >= 25'h4C000 && ioctl_addr < 25'h4C100;
    wire ioctl_romG  = core_download && ioctl_addr >= 25'h4C100 && ioctl_addr < 25'h4C200;


    wire [7:0]  mainrom_lo_q;
    wire [14:0] mainrom_lo_addr;
    wire [7:0]  mainrom_hi_q;
    wire [13:0] mainrom_hi_addr;
    wire [7:0]  vrom_q;
    wire [13:0] vrom_addr;
    wire [7:0]  sndrom_lo_q;
    wire [14:0] sndrom_lo_addr;
    wire [7:0]  sndrom_hi_q;
    wire [13:0] sndrom_hi_addr;
    wire [7:0]  srom_q;
    wire [12:0] srom_addr;
    wire [7:0]  charrom_q;
    wire [12:0] charrom_addr;
    wire [7:0]  spr0_q;
    wire [14:0] spr0_addr;
    wire [7:0]  spr1_q;
    wire [14:0] spr1_addr;
    wire [7:0]  spr2_q;
    wire [14:0] spr2_addr;
    wire [7:0]  spr2p0_q;
    wire [13:0] spr2p0_addr;
    wire [7:0]  spr2p1_q;
    wire [13:0] spr2p1_addr;
    wire [7:0]  spr2p2_q;
    wire [13:0] spr2p2_addr;
    wire [7:0]  bg0_q;
    wire [13:0] bg0_addr;
    wire [7:0]  bg1_q;
    wire [13:0] bg1_addr;
    wire [7:0]  promRG_q;
    wire [7:0]  promRG_addr;
    wire [7:0]  promB_q;
    wire [7:0]  promB_addr;

    assign mainrom_lo_addr = main_addr[14:0];
    assign mainrom_hi_addr = main_addr[13:0];
    assign vrom_addr       = vid_addr[13:0];
    assign sndrom_lo_addr  = snd_addr[14:0];
    assign sndrom_hi_addr  = snd_addr[13:0];
    assign srom_addr       = spr_addr[12:0];

    wire ce_cpu;
    wire ce_4m_vid;
    wire ce_4m_snd;

    // 5 MHz pixel clock from 48 MHz: 5 pulses per 48 cycles (pattern 10,10,10,9,9)
    reg [5:0] pix_clk_cnt = 0;
    reg       ce_pix_clk = 0;
    always @(posedge clk_sys) begin
        ce_pix_clk <= 1'b0;
        if (pix_clk_cnt == 6'd47)
            pix_clk_cnt <= 0;
        else
            pix_clk_cnt <= pix_clk_cnt + 6'd1;
        case (pix_clk_cnt)
            6'd0, 6'd10, 6'd19, 6'd29, 6'd38: ce_pix_clk <= 1'b1;
            default: ;
        endcase
    end

    clk_en #(.DIV(7))  u_ce_cpu    (.ref_clk(clk_sys), .cen(ce_cpu));
    clk_en #(.DIV(11)) u_ce_4m_vid (.ref_clk(clk_sys), .cen(ce_4m_vid));
    clk_en #(.DIV(11)) u_ce_4m_snd (.ref_clk(clk_sys), .cen(ce_4m_snd));

    // ROMs

    // MCPU
    rom #(.ADDRWIDTH(15)) u_mainrom_lo (
        .clock          ( clk_sys          ),
        .address        ( mainrom_lo_addr  ),
        .q              ( mainrom_lo_q     ),
        .rden           ( 1'b1             ),
        .ioctl_download ( ioctl_rom0       ),
        .ioctl_addr     ( ioctl_addr[14:0] ),
        .ioctl_dout     ( ioctl_dout       ),
        .ioctl_wr       ( ioctl_wr         )
    );

    // MCPU
    rom #(.ADDRWIDTH(14)) u_mainrom_hi (
        .clock          ( clk_sys          ),
        .address        ( mainrom_hi_addr  ),
        .q              ( mainrom_hi_q     ),
        .rden           ( 1'b1             ),
        .ioctl_download ( ioctl_rom1       ),
        .ioctl_addr     ( ioctl_addr[13:0] ),
        .ioctl_dout     ( ioctl_dout       ),
        .ioctl_wr       ( ioctl_wr         )
    );

    // VCPU
    rom #(.ADDRWIDTH(14)) u_vrom (
        .clock          ( clk_sys          ),
        .address        ( vrom_addr        ),
        .q              ( vrom_q           ),
        .rden           ( 1'b1             ),
        .ioctl_download ( ioctl_rom2       ),
        .ioctl_addr     ( ioctl_addr[13:0] ),
        .ioctl_dout     ( ioctl_dout       ),
        .ioctl_wr       ( ioctl_wr         )
    );

    // SND CPU
    rom #(.ADDRWIDTH(15)) u_sndrom_lo (
        .clock          ( clk_sys           ),
        .address        ( sndrom_lo_addr    ),
        .q              ( sndrom_lo_q       ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_rom3        ),
        .ioctl_addr     ( ioctl_addr[14:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SND CPU
    rom #(.ADDRWIDTH(14)) u_sndrom_hi (
        .clock          ( clk_sys           ),
        .address        ( sndrom_hi_addr    ),
        .q              ( sndrom_hi_q       ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_rom4        ),
        .ioctl_addr     ( ioctl_addr[13:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SPR CPU
    rom #(.ADDRWIDTH(13)) u_srom (
        .clock          ( clk_sys          ),
        .address        ( srom_addr        ),
        .q              ( srom_q           ),
        .rden           ( 1'b1             ),
        .ioctl_download ( ioctl_rom5       ),
        .ioctl_addr     ( ioctl_addr[12:0] ),
        .ioctl_dout     ( ioctl_dout       ),
        .ioctl_wr       ( ioctl_wr         )
    );

    // CHAR ROM
    rom #(.ADDRWIDTH(13)) u_charrom (
        .clock          ( clk_sys           ),
        .address        ( charrom_addr      ),
        .q              ( charrom_q         ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_rom6        ),
        .ioctl_addr     ( ioctl_addr[12:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SPRITE ROM
    rom #(.ADDRWIDTH(15)) u_spr0 (
        .clock          ( clk_sys           ),
        .address        ( spr0_addr         ),
        .q              ( spr0_q            ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_rom7        ),
        .ioctl_addr     ( ioctl_addr[14:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SPRITE ROM
    rom #(.ADDRWIDTH(15)) u_spr1 (
        .clock          ( clk_sys           ),
        .address        ( spr1_addr         ),
        .q              ( spr1_q            ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_rom8        ),
        .ioctl_addr     ( ioctl_addr[14:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SPRITE ROM
    rom #(.ADDRWIDTH(15)) u_spr2 (
        .clock          ( clk_sys           ),
        .address        ( spr2_addr         ),
        .q              ( spr2_q            ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_rom9        ),
        .ioctl_addr     ( ioctl_addr[14:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SPRITE ROM
    rom #(.ADDRWIDTH(14)) u_spr2p0 (
        .clock          ( clk_sys           ),
        .address        ( spr2p0_addr       ),
        .q              ( spr2p0_q          ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_romA        ),
        .ioctl_addr     ( ioctl_addr[13:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SPRITE ROM
    rom #(.ADDRWIDTH(14)) u_spr2p1 (
        .clock          ( clk_sys           ),
        .address        ( spr2p1_addr       ),
        .q              ( spr2p1_q          ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_romB        ),
        .ioctl_addr     ( ioctl_addr[13:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // SPRITE ROM
    rom #(.ADDRWIDTH(14)) u_spr2p2 (
        .clock          ( clk_sys           ),
        .address        ( spr2p2_addr       ),
        .q              ( spr2p2_q          ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_romC        ),
        .ioctl_addr     ( ioctl_addr[13:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // BG TILES
    rom #(.ADDRWIDTH(14)) u_bg0 (
        .clock          ( clk_sys           ),
        .address        ( bg0_addr          ),
        .q              ( bg0_q             ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_romD        ),
        .ioctl_addr     ( ioctl_addr[13:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // BG TILES
    rom #(.ADDRWIDTH(14)) u_bg1 (
        .clock          ( clk_sys           ),
        .address        ( bg1_addr          ),
        .q              ( bg1_q             ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_romE        ),
        .ioctl_addr     ( ioctl_addr[13:0]  ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // PROM
    rom #(.ADDRWIDTH(8)) u_promRG (
        .clock          ( clk_sys           ),
        .address        ( promRG_addr       ),
        .q              ( promRG_q          ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_romF        ),
        .ioctl_addr     ( ioctl_addr[7:0]   ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // PROM
    rom #(.ADDRWIDTH(8)) u_promB (
        .clock          ( clk_sys           ),
        .address        ( promB_addr        ),
        .q              ( promB_q           ),
        .rden           ( 1'b1              ),
        .ioctl_download ( ioctl_romG        ),
        .ioctl_addr     ( ioctl_addr[7:0]   ),
        .ioctl_dout     ( ioctl_dout        ),
        .ioctl_wr       ( ioctl_wr          )
    );

    // MAIN CPU

    wire [7:0]  main_data_in;
    wire [7:0]  main_data_out;
    wire [15:0] main_addr;
    wire        main_mreq_n;
    wire        main_iorq_n;
    wire        main_rd_n;
    wire        main_wr_n;
    wire        main_m1_n;

    // 7A: E1=*MREQ, A,B,C=A13,A14,A15
    wire main_rom_lo_cs = ~main_mreq_n && ~main_addr[15];
    wire main_rom_hi_cs = ~main_mreq_n &&  main_addr[15] && ~main_addr[14];

    // 7C: E1=*MREQ, E2=A15, C=A14, B=A13, A=A12
    wire main_y4_cs = ~main_mreq_n && main_addr[15] && main_addr[14] && ~main_addr[13] && ~main_addr[12];
    wire main_y5_cs = ~main_mreq_n && main_addr[15] && main_addr[14] && ~main_addr[13] &&  main_addr[12];
    wire main_y6_cs = ~main_mreq_n && main_addr[15] && main_addr[14] && main_addr[13] && ~main_addr[12];

    // A11 sub-select
    wire main_ram_cs       = main_y4_cs && ~main_addr[11];
    wire main_spr_dpram_cs = main_y4_cs &&  main_addr[11];
    wire main_vid_dpram_cs = main_y5_cs && ~main_addr[11];
    wire main_ctrl_cs      = main_y5_cs &&  main_addr[11];

    // I/O — RPORT selector: $E000=DSW1, $E001=DSW2, $E002=P1, $E003=P2, $E004=SYSTEM
    wire main_io_cs = main_y6_cs && ~main_addr[11];
    wire main_dsw1_cs = main_io_cs && main_addr[3:0] == 4'h0;
    wire main_dsw2_cs = main_io_cs && main_addr[3:0] == 4'h1;
    wire main_p1_cs   = main_io_cs && main_addr[3:0] == 4'h2;
    wire main_p2_cs   = main_io_cs && main_addr[3:0] == 4'h3;
    wire main_sys_cs  = main_io_cs && main_addr[3:0] == 4'h4;

    // Scroll Y
    wire main_scroll_cs = main_y6_cs && main_addr[11];

    wire main_irq_ack_vid = ~main_wr_n && main_ctrl_cs && main_addr[1:0] == 2'd2;
    wire main_irq_ack_spr = ~main_wr_n && main_ctrl_cs && main_addr[1:0] == 2'd1;
    wire main_snd_cmd_w   = ~main_wr_n && main_ctrl_cs && main_addr[1:0] == 2'd3;

    reg vid_irq_latch = 0;
    always @(posedge clk_sys) begin
        if (reset)
            vid_irq_latch <= 0;
        else if (main_irq_ack_vid)
            vid_irq_latch <= 1;
        else if (~vid_m1_n && vid_addr == 16'h0038)
            vid_irq_latch <= 0;
    end
    wire vid_irq_n = ~vid_irq_latch;

    reg spr_irq_latch = 0;
    always @(posedge clk_sys) begin
        if (reset)
            spr_irq_latch <= 0;
        else if (main_irq_ack_spr)
            spr_irq_latch <= 1;
        else if (~spr_m1_n && spr_addr == 16'h0038)
            spr_irq_latch <= 0;
    end
    wire spr_irq_n = ~spr_irq_latch;

    reg snd_irq_latch = 0;
    always @(posedge clk_sys) begin
        if (reset)
            snd_irq_latch <= 0;
        else if (~main_wr_n && main_snd_cmd_w)
            snd_irq_latch <= 1;
        else if (~snd_m1_n && snd_addr == 16'h0038)
            snd_irq_latch <= 0;
    end
    wire snd_irq_n = ~snd_irq_latch;

    // VIDEO CPU

    wire [7:0]  vid_data_in;
    wire [7:0]  vid_data_out;
    wire [15:0] vid_addr;
    wire        vid_mreq_n;
    wire        vid_rd_n;
    wire        vid_wr_n;

    wire vid_rom_cs = ~vid_mreq_n && ~vid_addr[15] && ~vid_addr[14];
    wire vid_ram_cs = ~vid_mreq_n && vid_addr[15] && ~vid_addr[14] && ~vid_addr[13] && ~vid_addr[12];
    wire vid_vram_cs = ~vid_mreq_n && vid_addr[15] && ~vid_addr[14] && vid_addr[13] && ~vid_addr[12];
    wire vid_shared_cs = ~vid_mreq_n && vid_addr[15] && vid_addr[14] && ~vid_addr[13] && ~vid_addr[12];

    wire vid_fg_cs = vid_vram_cs && ~vid_addr[11];
    wire vid_bg_cs = vid_vram_cs &&  vid_addr[11];

    wire vid_fgvram_cs  = vid_fg_cs && ~vid_addr[10];
    wire vid_fgcvram_cs = vid_fg_cs &&  vid_addr[10];
    wire vid_bgvram_cs  = vid_bg_cs && ~vid_addr[10];
    wire vid_bgcvram_cs = vid_bg_cs &&  vid_addr[10];

    // SND CPU

    wire [7:0]  snd_data_in;
    wire [7:0]  snd_data_out;
    wire [15:0] snd_addr;
    wire        snd_mreq_n;
    wire        snd_iorq_n;
    wire        snd_rd_n;
    wire        snd_wr_n;

    wire snd_rom_lo_cs = ~snd_mreq_n && ~snd_addr[15];
    wire snd_rom_hi_cs = ~snd_mreq_n &&  snd_addr[15] && ~snd_addr[14];
    wire snd_ram_cs    = ~snd_mreq_n &&  snd_addr[15] && snd_addr[14] && ~snd_addr[13] && ~snd_addr[12];

    wire snd_io_rd = ~snd_iorq_n && ~snd_rd_n;
    wire snd_dac_wr_cs = ~snd_iorq_n && ~snd_wr_n && snd_addr[7:0] == 8'h00;
    wire snd_ay_data_cs = ~snd_iorq_n && ~snd_wr_n && snd_addr[7:0] == 8'h02;
    wire snd_ay_addr_cs = ~snd_iorq_n && ~snd_wr_n && snd_addr[7:0] == 8'h03;
    wire snd_ay_read_cs = snd_io_rd && snd_addr[7:0] == 8'h02;

    // SPRITE CPU

    wire [7:0]  spr_data_in;
    wire [7:0]  spr_data_out;
    wire [15:0] spr_addr;
    wire        spr_mreq_n;
    wire        spr_rd_n;
    wire        spr_wr_n;

    wire spr_rom_cs = ~spr_mreq_n && ~spr_addr[15] && ~spr_addr[14] && ~spr_addr[13];
    wire spr_ram_cs = ~spr_mreq_n && spr_addr[15] && ~spr_addr[14] && ~spr_addr[13] && ~spr_addr[12];
    wire spr_spriteram_cs = ~spr_mreq_n && spr_addr[15] && ~spr_addr[14] && spr_addr[13] && ~spr_addr[12];
    wire spr_shared_cs = ~spr_mreq_n && spr_addr[15] && spr_addr[14] && ~spr_addr[13] && ~spr_addr[12] && spr_addr[11];

    wire        main_halt_n;
    wire        spr_halt_n;
    wire        vid_m1_n;
    wire        spr_m1_n;
    wire        snd_m1_n;

    tv80s #(.Mode(0), .T2Write(1), .IOWait(1)) u_main_cpu (
        .reset_n  ( ~reset        ),
        .clk      ( clk_sys       ),
        .cen      ( ce_cpu        ),
        .wait_n   ( 1'b1          ),
        .int_n    ( 1'b1          ),
        .nmi_n    ( cpu_nmi_n     ),
        .busrq_n  ( 1'b1          ),
        .m1_n     ( main_m1_n     ),
        .mreq_n   ( main_mreq_n   ),
        .iorq_n   ( main_iorq_n   ),
        .rd_n     ( main_rd_n     ),
        .wr_n     ( main_wr_n     ),
        .halt_n   ( main_halt_n   ),
        .A        ( main_addr     ),
        .di       ( main_data_in  ),
        .dout     ( main_data_out )
    );

    tv80s #(.Mode(0), .T2Write(1), .IOWait(1)) u_vid_cpu (
        .reset_n  ( ~reset        ),
        .clk      ( clk_sys       ),
        .cen      ( ce_4m_vid     ),
        .wait_n   ( 1'b1          ),
        .int_n    ( vid_irq_n     ),
        .nmi_n    ( cpu_nmi_n     ),
        .busrq_n  ( 1'b1          ),
        .m1_n     ( vid_m1_n      ),
        .mreq_n   ( vid_mreq_n    ),
        .iorq_n   (               ),
        .rd_n     ( vid_rd_n      ),
        .wr_n     ( vid_wr_n      ),
        .halt_n   (               ),
        .A        ( vid_addr      ),
        .di       ( vid_data_in   ),
        .dout     ( vid_data_out  )
    );

    tv80s #(.Mode(0), .T2Write(1), .IOWait(1)) u_snd_cpu (
        .reset_n  ( ~reset        ),
        .clk      ( clk_sys       ),
        .cen      ( ce_4m_snd     ),
        .wait_n   ( 1'b1          ),
        .int_n    ( snd_irq_n     ),
        .nmi_n    ( snd_nmi_n     ),
        .busrq_n  ( 1'b1          ),
        .m1_n     ( snd_m1_n      ),
        .mreq_n   ( snd_mreq_n    ),
        .iorq_n   ( snd_iorq_n    ),
        .rd_n     ( snd_rd_n      ),
        .wr_n     ( snd_wr_n      ),
        .halt_n   (               ),
        .A        ( snd_addr      ),
        .di       ( snd_data_in   ),
        .dout     ( snd_data_out  )
    );

    tv80s #(.Mode(0), .T2Write(1), .IOWait(1)) u_spr_cpu (
        .reset_n  ( ~reset        ),
        .clk      ( clk_sys       ),
        .cen      ( ce_cpu        ),
        .wait_n   ( 1'b1          ),
        .int_n    ( spr_irq_n     ),
        .nmi_n    ( cpu_nmi_n     ),
        .busrq_n  ( 1'b1          ),
        .m1_n     ( spr_m1_n      ),
        .mreq_n   ( spr_mreq_n    ),
        .iorq_n   (               ),
        .rd_n     ( spr_rd_n      ),
        .wr_n     ( spr_wr_n      ),
        .halt_n   ( spr_halt_n    ),
        .A        ( spr_addr      ),
        .di       ( spr_data_in   ),
        .dout     ( spr_data_out  )
    );

    reg [5:0] main_ctrl_reg;
    always @(posedge clk_sys) begin
        if (reset)
            main_ctrl_reg <= 6'd0;
        else if (~main_wr_n && main_ctrl_cs && main_addr[1:0] == 2'd0)
            main_ctrl_reg <= main_data_out[5:0];
    end

    wire main_nmi_en = main_ctrl_reg[5];

    // main data bus mux
    assign main_data_in =
        main_rom_lo_cs     ? mainrom_lo_q   :
        main_rom_hi_cs     ? mainrom_hi_q   :
        main_ram_cs        ? main_ram_q     :
        main_spr_dpram_cs  ? main_spr_q_a   :
        main_vid_dpram_cs  ? main_vid_q_a   :
        main_dsw1_cs       ? dsw            :
        main_dsw2_cs       ? dsw2           :
        main_p1_cs         ? p1             :
        main_p2_cs         ? p2             :
        main_sys_cs        ? p3             :
                              8'hFF;

    // vid data bus mux
    assign vid_data_in =
        vid_rom_cs      ? vrom_q         :
        vid_ram_cs      ? vid_ram_q      :
        vid_fgvram_cs   ? fg_vram_q      :
        vid_fgcvram_cs  ? fg_cvram_q     :
        vid_bgvram_cs   ? bg_vram_q      :
        vid_bgcvram_cs  ? bg_cvram_q     :
        vid_shared_cs   ? main_vid_q_b   :
                          8'hFF;

    reg [7:0] sound_cmd_latch;
    reg       sound_cmd_pending;
    always @(posedge clk_sys) begin
        if (reset) begin
            sound_cmd_latch   <= 8'd0;
            sound_cmd_pending <= 1'b0;
        end else if (~main_wr_n && main_snd_cmd_w) begin
            sound_cmd_latch   <= main_data_out;
            sound_cmd_pending <= 1'b1;
        end else if (snd_io_rd && snd_addr[7:0] == 8'h02) begin
            sound_cmd_pending <= 1'b0;
        end
    end

    reg [7:0] snd_dac_reg;
    always @(posedge clk_sys) begin
        if (reset)
            snd_dac_reg <= 8'd0;
        else if (snd_dac_wr_cs)
            snd_dac_reg <= snd_data_out;
    end

    // SND

    wire [7:0] ay_data_r;
    wire       ay_bdir = ~snd_wr_n && (snd_ay_data_cs || snd_ay_addr_cs);
    wire       ay_bc   = snd_ay_read_cs || (~snd_wr_n && snd_ay_addr_cs);

    reg [3:0] ay_addr_latch;
    always @(posedge clk_sys) begin
        if (reset)
            ay_addr_latch <= 4'd0;
        else if (ay_bdir && ay_bc)
            ay_addr_latch <= snd_data_out[3:0];
    end

    wire       ay_cs_n = ~( (ay_bdir && ~ay_bc) || (~ay_bdir && ay_bc) );
    wire       ay_wr_n = ~(ay_bdir && ~ay_bc);

    wire [9:0] ay_sound;
    wire [7:0] ay_a, ay_b, ay_c;
    wire       ay_sample;

    jt49 u_ym2149 (
        .rst_n   ( ~reset        ),
        .clk     ( clk_sys       ),
        .clk_en  ( ce_4m_snd     ),
        .addr    ( ay_addr_latch ),
        .cs_n    ( ay_cs_n       ),
        .wr_n    ( ay_wr_n       ),
        .din     ( snd_data_out  ),
        .dout    ( ay_data_r     ),
        .sel     ( 1'b1          ),
        .sound   ( ay_sound      ),
        .A       ( ay_a          ),
        .B       ( ay_b          ),
        .C       ( ay_c          ),
        .sample  ( ay_sample     ),
        .IOA_in  ( sound_cmd_latch ),
        .IOA_out (               ),
        .IOA_oe  (               ),
        .IOB_in  ( 8'hFF         ),
        .IOB_out (               ),
        .IOB_oe  (               )
    );

    // sound data data bus mux
    assign snd_data_in =
        snd_rom_lo_cs  ? sndrom_lo_q     :
        snd_rom_hi_cs  ? sndrom_hi_q     :
        snd_ram_cs     ? snd_ram_q       :
        (snd_io_rd && snd_addr[7:0] == 8'h02) ? ay_data_r  : 8'hFF;

    // snd mix
    wire [13:0] ay_mix = { ay_sound, 4'd0 };
    wire [13:0] dac_14 = { snd_dac_reg, 6'd0 };
    wire [14:0] sound_sum = { 1'b0, ay_mix } + { 1'b0, dac_14 };
    assign sound = sound_sum[14] ? 16'hFFFF : { 2'b00, sound_sum[13:0] };

    // sprite data bus mux
    assign spr_data_in =
        spr_rom_cs          ? srom_q          :
        spr_ram_cs          ? spr_ram_q       :
        spr_spriteram_cs    ? spr_spriteram_q :
        spr_shared_cs       ? main_spr_q_b    :
                              8'hFF;

    // RAM

    wire [7:0] main_ram_q;
    wire [9:0] main_ram_addr = main_addr[9:0];

    dpram #(.ADDRWIDTH(10)) u_main_ram (
        .clock     ( clk_sys          ),
        .address_a ( main_ram_addr    ),
        .data_a    ( main_data_out    ),
        .q_a       ( main_ram_q       ),
        .rden_a    ( 1'b1             ),
        .wren_a    ( ~main_wr_n && main_ram_cs ),
        .address_b ( 10'd0            ),
        .data_b    ( 8'd0             ),
        .q_b       (                  ),
        .rden_b    ( 1'b0             ),
        .wren_b    ( 1'b0             ),
    );


    wire [7:0]  main_spr_q_a;
    wire [7:0]  main_spr_q_b;
    wire [10:0] main_spr_addr_a = main_addr[10:0];
    wire [10:0] main_spr_addr_b = spr_addr[10:0];

    dpram #(.ADDRWIDTH(11)) u_main_spr_dpram (
        .clock     ( clk_sys              ),
        .address_a ( main_spr_addr_a      ),
        .data_a    ( main_data_out        ),
        .q_a       ( main_spr_q_a         ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( ~main_wr_n && main_spr_dpram_cs ),
        .address_b ( main_spr_addr_b      ),
        .data_b    ( spr_data_out         ),
        .q_b       ( main_spr_q_b         ),
        .rden_b    ( 1'b1                 ),
        .wren_b    ( ~spr_wr_n && spr_shared_cs )
    );

    wire [7:0]  main_vid_q_a;
    wire [7:0]  main_vid_q_b;
    wire [10:0] main_vid_addr_a = main_addr[10:0];
    wire [10:0] main_vid_addr_b = vid_addr[10:0];

    dpram #(.ADDRWIDTH(11)) u_main_vid_dpram (
        .clock     ( clk_sys              ),
        .address_a ( main_vid_addr_a      ),
        .data_a    ( main_data_out        ),
        .q_a       ( main_vid_q_a         ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( ~main_wr_n && main_vid_dpram_cs ),
        .address_b ( main_vid_addr_b      ),
        .data_b    ( vid_data_out         ),
        .q_b       ( main_vid_q_b         ),
        .rden_b    ( 1'b1                 ),
        .wren_b    ( ~vid_wr_n && vid_shared_cs )
    );


    wire [7:0] vid_ram_q;

    dpram #(.ADDRWIDTH(11)) u_vid_ram (
        .clock     ( clk_sys          ),
        .address_a ( vid_addr[10:0]   ),
        .data_a    ( vid_data_out     ),
        .q_a       ( vid_ram_q        ),
        .rden_a    ( 1'b1             ),
        .wren_a    ( ~vid_wr_n && vid_ram_cs ),
        .address_b ( 11'd0            ),
        .data_b    ( 8'd0             ),
        .q_b       (                  ),
        .rden_b    ( 1'b0             ),
        .wren_b    ( 1'b0             )
    );

    wire [7:0] snd_ram_q;

    dpram #(.ADDRWIDTH(10)) u_snd_ram (
        .clock     ( clk_sys          ),
        .address_a ( snd_addr[9:0]    ),
        .data_a    ( snd_data_out     ),
        .q_a       ( snd_ram_q        ),
        .rden_a    ( 1'b1             ),
        .wren_a    ( ~snd_wr_n && snd_ram_cs ),
        .address_b ( 10'd0            ),
        .data_b    ( 8'd0             ),
        .q_b       (                  ),
        .rden_b    ( 1'b0             ),
        .wren_b    ( 1'b0             )
    );

    wire [7:0] bg_tile_code_q;
    wire [7:0] bg_tile_attr_q;
    wire [7:0] bg_vram_addr;

    wire [7:0] fg_vram_q;

    reg        fg_vram_wr_en;
    reg [7:0]  fg_vram_wr_data;

    always @(posedge clk_sys) begin
        if (~vid_wr_n && vid_fgvram_cs) begin
            fg_vram_wr_en   <= 1'b1;
            fg_vram_wr_data <= vid_data_out;
        end else begin
            fg_vram_wr_en   <= 1'b0;
        end
    end

    wire [7:0] fg_vram_q_b;
    wire [9:0] fg_tile_idx;
    wire [9:0] fg_vram_rd_addr = fg_tile_idx;

    dpram #(.ADDRWIDTH(10)) u_fg_vram (
        .clock     ( clk_sys              ),
        .address_a ( vid_addr[9:0]        ),
        .data_a    ( fg_vram_wr_data      ),
        .q_a       ( fg_vram_q            ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( fg_vram_wr_en        ),
        .address_b ( fg_vram_rd_addr      ),
        .data_b    ( 8'd0                 ),
        .q_b       ( fg_vram_q_b          ),
        .rden_b    ( 1'b1                 ),
        .wren_b    ( 1'b0                 )
    );

    wire [7:0] fg_cvram_q;
    wire [7:0] fg_cvram_q_b;

    reg        fg_cvram_wr_en;
    reg [7:0]  fg_cvram_wr_data;

    always @(posedge clk_sys) begin
        if (~vid_wr_n && vid_fgcvram_cs) begin
            fg_cvram_wr_en   <= 1'b1;
            fg_cvram_wr_data <= vid_data_out;
        end else begin
            fg_cvram_wr_en   <= 1'b0;
        end
    end

    dpram #(.ADDRWIDTH(10)) u_fg_cvram (
        .clock     ( clk_sys              ),
        .address_a ( vid_addr[9:0]        ),
        .data_a    ( fg_cvram_wr_data     ),
        .q_a       ( fg_cvram_q           ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( fg_cvram_wr_en       ),
        .address_b ( fg_vram_rd_addr      ),
        .data_b    ( 8'd0                 ),
        .q_b       ( fg_cvram_q_b         ),
        .rden_b    ( 1'b1                 ),
        .wren_b    ( 1'b0                 )
    );

    wire [7:0] bg_vram_q;

    reg        bg_vram_wr_en;
    reg [7:0]  bg_vram_wr_data;

    always @(posedge clk_sys) begin
        if (~vid_wr_n && vid_bgvram_cs) begin
            bg_vram_wr_en   <= 1'b1;
            bg_vram_wr_data <= vid_data_out;
        end else begin
            bg_vram_wr_en   <= 1'b0;
        end
    end

    dpram #(.ADDRWIDTH(8)) u_bg_vram (
        .clock     ( clk_sys              ),
        .address_a ( vid_addr[7:0]        ),
        .data_a    ( bg_vram_wr_data      ),
        .q_a       ( bg_vram_q            ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( bg_vram_wr_en        ),
        .address_b ( bg_vram_addr         ),
        .data_b    ( 8'd0                 ),
        .q_b       ( bg_tile_code_q       ),
        .rden_b    ( 1'b1                 ),
        .wren_b    ( 1'b0                 )
    );

    wire [7:0] bg_cvram_q;

    reg        bg_cvram_wr_en;
    reg [7:0]  bg_cvram_wr_data;

    always @(posedge clk_sys) begin
        if (~vid_wr_n && vid_bgcvram_cs) begin
            bg_cvram_wr_en   <= 1'b1;
            bg_cvram_wr_data <= vid_data_out;
        end else begin
            bg_cvram_wr_en   <= 1'b0;
        end
    end

    dpram #(.ADDRWIDTH(8)) u_bg_cvram (
        .clock     ( clk_sys              ),
        .address_a ( vid_addr[7:0]        ),
        .data_a    ( bg_cvram_wr_data     ),
        .q_a       ( bg_cvram_q           ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( bg_cvram_wr_en       ),
        .address_b ( bg_vram_addr         ),
        .data_b    ( 8'd0                 ),
        .q_b       ( bg_tile_attr_q       ),
        .rden_b    ( 1'b1                 ),
        .wren_b    ( 1'b0                 )
    );

    wire [7:0] spr_spriteram_q;
    wire [7:0] spr_spriteram_qb;
    wire [9:0] spr_b_addr;
    wire       spr_b_rden;

    dpram #(.ADDRWIDTH(10)) u_spr_spriteram (
        .clock     ( clk_sys              ),
        .address_a ( spr_addr[9:0]        ),
        .data_a    ( spr_data_out         ),
        .q_a       ( spr_spriteram_q      ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( ~spr_wr_n && spr_spriteram_cs ),
        .address_b ( spr_b_addr           ),
        .data_b    ( 8'd0                 ),
        .q_b       ( spr_spriteram_qb     ),
        .rden_b    ( spr_b_rden           ),
        .wren_b    ( 1'b0                 )
    );

    wire [7:0] spr_ram_q;

    dpram #(.ADDRWIDTH(11)) u_spr_ram (
        .clock     ( clk_sys              ),
        .address_a ( spr_addr[10:0]       ),
        .data_a    ( spr_data_out         ),
        .q_a       ( spr_ram_q            ),
        .rden_a    ( 1'b1                 ),
        .wren_a    ( ~spr_wr_n && spr_ram_cs ),
        .address_b ( 11'd0                ),
        .data_b    ( 8'd0                 ),
        .q_b       (                      ),
        .rden_b    ( 1'b0                 ),
        .wren_b    ( 1'b0                 )
    );


    // H/V gen

    reg [8:0]  hcnt;
    reg [8:0]  vcnt;
    reg        vblank_i;

    always @(posedge clk_sys) begin
        if (reset) begin
            hcnt      <= 9'd0;
            vcnt      <= 9'd0;
            vblank_i  <= 1'b1;
        end else if (ce_pix_clk) begin
            if (hcnt == 9'd319) begin
                hcnt <= 9'd0;
                if (vcnt == 9'd261) begin
                    vcnt     <= 9'd0;
                    vblank_i <= 1'b0;
                end else begin
                    vcnt <= vcnt + 9'd1;
                    if (vcnt == 9'd223)
                        vblank_i <= 1'b1;
                end
            end else
                hcnt <= hcnt + 9'd1;
        end
    end

    assign ce_pix = ce_pix_clk;

    // reg cpu_nmi_n;
    // always @(posedge clk_sys) begin
    //     if (reset)
    //         cpu_nmi_n <= 1'b1;
    //     else if (main_nmi_en)
    //         cpu_nmi_n <= ~vblank_i;
    //     else
    //         cpu_nmi_n <= 1'b1;
    // end
    wire cpu_nmi_n = ~(vb | ~main_nmi_en);

    reg [12:0] snd_nmi_cnt = 0;
    reg        snd_nmi_clk = 0;
    always @(posedge clk_sys) begin
        if (reset) begin
            snd_nmi_cnt <= 0;
            snd_nmi_clk <= 0;
        end else if (snd_nmi_cnt == 13'd3999) begin
            snd_nmi_cnt <= 0;
            snd_nmi_clk <= ~snd_nmi_clk;
        end else
            snd_nmi_cnt <= snd_nmi_cnt + 1;
    end
    wire snd_nmi_n = ~snd_nmi_clk;

    reg [7:0] scroll_y;
    always @(posedge clk_sys) begin
        if (reset)
            scroll_y <= 8'd0;
        else if (~main_wr_n && main_scroll_cs)
            scroll_y <= main_data_out;
    end

    assign vb  = (vcnt < 9'd16 || vcnt >= 9'd240);
    assign hb  = (hcnt >= 9'd272);
    assign vs  = (vcnt == 9'd250 || vcnt == 9'd252);
    assign hs  = (hcnt >= 9'd290 && hcnt <= 9'd310);

    // RENDERING

    wire [7:0] bg_hpos = hcnt[7:0] - 8'd16;
    wire [7:0] bg_vpos = vcnt[7:0] - scroll_y;
    wire [3:0] bg_tile_col = bg_hpos[7:4];
    wire [3:0] bg_tile_row = bg_vpos[7:4];
    wire [3:0] bg_pixel_x  = bg_hpos[3:0];
    wire [3:0] bg_pixel_y  = bg_vpos[3:0];
    assign bg_vram_addr = { bg_tile_col, ~bg_tile_row };

    reg [7:0] bg_tile_code_s1;
    reg [7:0] bg_tile_attr_s1;
    reg [3:0] bg_pixel_x_s1;
    reg [3:0] bg_pixel_y_s1;

    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            bg_tile_code_s1 <= (bg_tile_col == 4'd0) ? 8'd0 : bg_tile_code_q;
            bg_tile_attr_s1 <= bg_tile_attr_q;
            bg_pixel_x_s1   <= bg_pixel_x;
            bg_pixel_y_s1   <= bg_pixel_y;
        end
    end

    function [13:0] xoffset_byte_lut;
        input [3:0] col;
        case (col[3:2])
            2'b00: xoffset_byte_lut = 14'd16;
            2'b01: xoffset_byte_lut = 14'd8192;
            2'b10: xoffset_byte_lut = 14'd0;
            2'b11: xoffset_byte_lut = 14'd8208;
        endcase
    endfunction

    wire [13:0] rom_byte_addr = { bg_tile_code_s1, 5'd0 } + { 10'd0, ~bg_pixel_y_s1 } + xoffset_byte_lut(bg_pixel_x_s1);

    assign bg0_addr = rom_byte_addr;
    assign bg1_addr = rom_byte_addr;

    reg [2:0] bg_pixel_s2;
    reg [7:0] bg_tile_attr_s2;

    wire [1:0] bg_col_r = bg_pixel_x_s1[1:0];
    wire [2:0] bg_pbit = { 1'b0, bg_col_r };

    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            bg_pixel_s2 <= { bg1_q[bg_pbit], bg0_q[bg_pbit + 3'd4],  bg0_q[bg_pbit] };
            bg_tile_attr_s2 <= bg_tile_attr_s1;
        end
    end

    reg [2:0]  bg_pixel_s3;
    reg [7:0]  bg_tile_attr_s3;
    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            bg_pixel_s3     <= bg_pixel_s2;
            bg_tile_attr_s3 <= bg_tile_attr_s2;
        end
    end

    wire [2:0] bg_color_idx = bg_tile_attr_s3[6:4];
    wire [4:0] bg_palette   = { main_ctrl_reg[4:3], bg_color_idx };

    wire [3:0] bg_r = promRG_q[7:4];
    wire [3:0] bg_g = promRG_q[3:0];
    wire [3:0] bg_b = promB_q[3:0];

    wire bg_visible = (hcnt >= 9'd16 && hcnt < 9'd272) && (vcnt >= 9'd16 && vcnt < 9'd240);

    reg bg_visible_s1, bg_visible_s2, bg_visible_s3;
    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            bg_visible_s1 <= bg_visible;
            bg_visible_s2 <= bg_visible_s1;
            bg_visible_s3 <= bg_visible_s2;
        end
    end

    // line buffers

    reg [3:0]  spr_scan_state;
    reg [7:0]  spr_scan_idx;
    reg [7:0]  spr_scan_y_r, spr_scan_attr_r;
    reg [7:0]  spr_scan_x_r;

    reg [2:0]  spr_buf_color_A [0:63], spr_buf_color_B [0:63];
    reg [7:0]  spr_buf_x_A     [0:63], spr_buf_x_B     [0:63];
    reg [47:0] spr_buf_pdata_A [0:63], spr_buf_pdata_B [0:63];

    reg [5:0]  spr_line_count_wr;
    reg [5:0]  spr_line_count_rd;


    wire spr_buf_rd = vcnt[0];
    reg last_vcnt0;
    wire vcnt0_changed = vcnt[0] != last_vcnt0;

    wire spr_scan_active = 1'b1;

    reg [9:0]  scan_code_r;
    reg [3:0]  scan_py_r;
    reg        scan_bank_r;
    reg [7:0]  scan_lo_p0, scan_lo_p1, scan_lo_p2;

    assign spr_b_rden = spr_scan_active && (spr_scan_state != 4'd0) && (spr_scan_state < 4'd7);
    assign spr_b_addr = (spr_scan_state == 4'd1) ? {spr_scan_idx, 2'b00} :
                        (spr_scan_state == 4'd3) ? {spr_scan_idx, 2'b01} :
                        (spr_scan_state == 4'd4) ? {spr_scan_idx, 2'b10} :
                        (spr_scan_state == 4'd5) ? {spr_scan_idx, 2'b11} :
                        10'd0;

    always @(posedge clk_sys) begin
        if (reset) begin
            spr_scan_state <= 4'd0;
            spr_line_count_wr <= 6'd0;
            spr_line_count_rd <= 6'd0;
            scan_lo_p0 <= 8'd0;
            scan_lo_p1 <= 8'd0;
            scan_lo_p2 <= 8'd0;
            scan_code_r <= 10'd0;
            scan_py_r <= 4'd0;
            scan_bank_r <= 1'b0;
            last_vcnt0 <= 1'b0;
        end
        else if (spr_scan_active) begin
            last_vcnt0 <= vcnt[0];
            if (vcnt0_changed)
                spr_line_count_rd <= spr_line_count_wr;
            case (spr_scan_state)
                4'd0: begin
                    spr_scan_idx <= 8'd0;
                    if (vcnt0_changed) begin
                        spr_line_count_wr <= 6'd0;
                        spr_scan_state <= 4'd1;
                    end
                end
                4'd1: begin
                    spr_scan_state <= 4'd2;
                end
                4'd2: begin
                    if ((vcnt[7:0] - spr_spriteram_qb) < 5'd16) begin
                        spr_scan_y_r <= spr_spriteram_qb;
                        spr_scan_state <= 4'd3;
                    end
                    else begin
                        spr_scan_idx <= spr_scan_idx + 8'd1;
                        spr_scan_state <= (spr_scan_idx == 8'd255) ? 4'd0 : 4'd1;
                    end
                end
                4'd3: begin
                    spr_scan_state <= 4'd4;
                end
                4'd4: begin
                    spr_scan_attr_r <= spr_spriteram_qb;
                    spr_scan_state <= 4'd5;
                end
                4'd5: begin
                    spr_scan_x_r <= spr_spriteram_qb;
                    spr_scan_state <= 4'd6;
                end
                4'd6: begin
                    if (spr_line_count_wr < 6'd63) begin
                        scan_code_r <= {spr_scan_attr_r[1:0], spr_spriteram_qb};
                        scan_bank_r <= spr_scan_attr_r[2];
                        if (spr_scan_attr_r[7])
                            scan_py_r <= vcnt[3:0] - spr_scan_y_r[3:0];
                        else
                            scan_py_r <= 4'd15 - (vcnt[3:0] - spr_scan_y_r[3:0]);

                        if (~spr_buf_rd) begin
                            spr_buf_color_B[spr_line_count_wr] <= spr_scan_attr_r[6:4];
                            spr_buf_x_B[spr_line_count_wr]     <= spr_scan_x_r;
                        end
                        else begin
                            spr_buf_color_A[spr_line_count_wr] <= spr_scan_attr_r[6:4];
                            spr_buf_x_A[spr_line_count_wr]     <= spr_scan_x_r;
                        end
                        spr_line_count_wr <= spr_line_count_wr + 6'd1;
                        spr_scan_state <= 4'd7;
                    end
                    else begin
                        spr_scan_idx <= spr_scan_idx + 8'd1;
                        spr_scan_state <= (spr_scan_idx == 8'd255) ? 4'd0 : 4'd1;
                    end
                end
                4'd7: begin
                    spr_scan_state <= 4'd8;
                end
                4'd8: begin
                    scan_lo_p0 <= scan_bank_r ? spr2p0_q : spr0_q;
                    scan_lo_p1 <= scan_bank_r ? spr2p1_q : spr1_q;
                    scan_lo_p2 <= scan_bank_r ? spr2p2_q : spr2_q;
                    spr_scan_state <= 4'd9;
                end
                4'd9: begin
                    if (~spr_buf_rd) begin
                        spr_buf_pdata_B[spr_line_count_wr - 6'd1] <= {
                            scan_bank_r ? spr2p2_q : spr2_q, scan_lo_p2,
                            scan_bank_r ? spr2p1_q : spr1_q, scan_lo_p1,
                            scan_bank_r ? spr2p0_q : spr0_q, scan_lo_p0
                        };
                    end
                    else begin
                        spr_buf_pdata_A[spr_line_count_wr - 6'd1] <= {
                            scan_bank_r ? spr2p2_q : spr2_q, scan_lo_p2,
                            scan_bank_r ? spr2p1_q : spr1_q, scan_lo_p1,
                            scan_bank_r ? spr2p0_q : spr0_q, scan_lo_p0
                        };
                    end
                    spr_scan_idx <= spr_scan_idx + 8'd1;
                    spr_scan_state <= (spr_scan_idx == 8'd255) ? 4'd0 : 4'd1;
                end
                default: spr_scan_state <= 4'd0;
            endcase
        end
    end

    reg [2:0]  spr_match_color;
    reg [2:0]  spr_match_pixel;
    reg        spr_match_valid;
    integer    spr_i;

    reg [7:0]  pe_x;
    reg [47:0] pe_pdata;
    reg [3:0]  pe_px;
    reg [2:0]  pe_pixel;

    always @(*) begin
        spr_match_valid = 1'b0;
        spr_match_color = 3'd0;
        spr_match_pixel = 3'd0;
        pe_x = 8'd0;
        pe_pdata = 48'd0;
        pe_px = 4'd0;
        pe_pixel = 3'd0;
        if (bg_visible && spr_line_count_rd != 6'd0) begin
            for (spr_i = 63; spr_i >= 0; spr_i = spr_i - 1) begin
                if (!spr_match_valid && spr_i < spr_line_count_rd) begin
                    pe_x = spr_buf_rd ? spr_buf_x_B[spr_i] : spr_buf_x_A[spr_i];
                    if (hcnt >= {1'b0, pe_x} + 9'd16 && hcnt < {1'b0, pe_x} + 9'd32) begin
                        pe_pdata = spr_buf_rd ? spr_buf_pdata_B[spr_i] : spr_buf_pdata_A[spr_i];
                        pe_px = hcnt[3:0] - pe_x[3:0];
                        pe_pixel = pe_px[3] ?
                            {pe_pdata[8 + pe_px[2:0]], pe_pdata[24 + pe_px[2:0]], pe_pdata[40 + pe_px[2:0]]} :
                            {pe_pdata[pe_px[2:0]], pe_pdata[16 + pe_px[2:0]], pe_pdata[32 + pe_px[2:0]]};
                        if (pe_pixel != 3'd0) begin  // transparent
                            spr_match_valid = 1'b1;
                            spr_match_color = spr_buf_rd ? spr_buf_color_B[spr_i] : spr_buf_color_A[spr_i];
                            spr_match_pixel = pe_pixel;
                        end
                    end
                end
            end
        end
    end

    wire [14:0] scan_rom_addr_lo = {scan_code_r, 5'd0} + {10'd0, scan_py_r};
    wire [14:0] scan_rom_addr_hi = scan_rom_addr_lo + 15'd16;
    wire        scan_rom_active = (spr_scan_state == 4'd7) || (spr_scan_state == 4'd8);
    wire [14:0] spr_rom_addr = scan_rom_active ?
        (spr_scan_state == 4'd8 ? scan_rom_addr_hi : scan_rom_addr_lo) :
        15'd0;

    wire spr_bank = scan_rom_active ? scan_bank_r : 1'b0;

    assign spr0_addr   = spr_bank ? 15'd0 : spr_rom_addr;
    assign spr1_addr   = spr_bank ? 15'd0 : spr_rom_addr;
    assign spr2_addr   = spr_bank ? 15'd0 : spr_rom_addr;
    assign spr2p0_addr = spr_bank ? spr_rom_addr[13:0] : 14'd0;
    assign spr2p1_addr = spr_bank ? spr_rom_addr[13:0] : 14'd0;
    assign spr2p2_addr = spr_bank ? spr_rom_addr[13:0] : 14'd0;

    reg [2:0]  spr_pix_s1;
    reg [2:0]  spr_col_s1;
    reg        spr_val_s1;
    reg [2:0]  spr_pix_s2;
    reg [2:0]  spr_col_s2;
    reg        spr_val_s2;

    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            spr_pix_s1  <= spr_match_pixel;
            spr_col_s1  <= spr_match_color;
            spr_val_s1  <= spr_match_valid;
            spr_pix_s2  <= spr_pix_s1;
            spr_col_s2  <= spr_col_s1;
            spr_val_s2  <= spr_val_s1;
        end
    end

    wire [7:0] fg_hpos = hcnt[7:0] - 8'd16;
    wire [7:0] fg_vpos = vcnt[7:0];
    wire [4:0] fg_tile_col = fg_hpos[7:3];
    wire [4:0] fg_tile_row = fg_vpos[7:3];
    wire [2:0] fg_pixel_x  = fg_hpos[2:0];
    wire [2:0] fg_pixel_y  = fg_vpos[2:0];
    assign fg_tile_idx = {fg_tile_col, ~fg_tile_row};

    reg [8:0] fg_code_s1;
    reg [7:0] fg_attr_s1;
    reg [2:0] fg_pixel_x_s1;
    reg [2:0] fg_pixel_y_s1;

    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            fg_code_s1    <= {fg_cvram_q_b[0], fg_vram_q_b};
            fg_attr_s1    <= fg_cvram_q_b;
            fg_pixel_x_s1 <= fg_pixel_x;
            fg_pixel_y_s1 <= fg_pixel_y;
        end
    end

    wire [2:0] fg_row = ~fg_pixel_y_s1;
    wire       fg_plane = fg_pixel_x_s1[2];

    assign charrom_addr = {fg_plane, fg_code_s1, fg_row};

    reg [2:0] fg_color_s2;
    reg       fg_valid_s2;

    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            fg_color_s2 <= fg_attr_s1[5:3];
            fg_valid_s2 <= bg_visible_s1 && (charrom_q[{1'b0, fg_pixel_x_s1[1:0]}] != 1'b0);
        end
    end

    // sch 9/13 - FG has a dedicated DAC
    reg [3:0] fg_r_s2, fg_g_s2, fg_b_s2;
    always @(*) begin
        case (fg_color_s2)
            3'd0: begin fg_r_s2 = 4'h0; fg_g_s2 = 4'h0; fg_b_s2 = 4'h0; end
            3'd1: begin fg_r_s2 = 4'h0; fg_g_s2 = 4'h0; fg_b_s2 = 4'hF; end
            3'd2: begin fg_r_s2 = 4'h0; fg_g_s2 = 4'hF; fg_b_s2 = 4'h0; end
            3'd3: begin fg_r_s2 = 4'h0; fg_g_s2 = 4'hF; fg_b_s2 = 4'hF; end
            3'd4: begin fg_r_s2 = 4'hF; fg_g_s2 = 4'h0; fg_b_s2 = 4'h0; end
            3'd5: begin fg_r_s2 = 4'hF; fg_g_s2 = 4'h0; fg_b_s2 = 4'hF; end
            3'd6: begin fg_r_s2 = 4'hF; fg_g_s2 = 4'hF; fg_b_s2 = 4'h0; end
            3'd7: begin fg_r_s2 = 4'hF; fg_g_s2 = 4'hF; fg_b_s2 = 4'hF; end
        endcase
    end

    reg        fg_valid_s3;
    reg [3:0]  fg_r_s3, fg_g_s3;
    reg [1:0]  fg_b_s3;
    always @(posedge clk_sys) begin
        if (ce_pix_clk) begin
            fg_valid_s3 <= fg_valid_s2;
            fg_r_s3     <= fg_r_s2;
            fg_g_s3     <= fg_g_s2;
            fg_b_s3     <= fg_b_s2;
        end
    end

    wire [4:0] spr_palette = {main_ctrl_reg[4:3], spr_col_s2};
    wire [7:0] spr_prom_addr = {spr_palette, spr_pix_s2};

    assign promRG_addr = spr_val_s2 ? spr_prom_addr : { bg_palette[4:0], bg_pixel_s3 };
    assign promB_addr  = spr_val_s2 ? spr_prom_addr : { bg_palette[4:0], bg_pixel_s3 };

    wire [3:0] final_r = promRG_q[7:4];
    wire [3:0] final_g = promRG_q[3:0];
    wire [3:0] final_b = promB_q[3:0];

    assign red   = bg_visible_s3 && fg_valid_s3 ? fg_r_s3[3:1] :
                   bg_visible_s3 ? (spr_val_s2 ? final_r[3:1] : bg_r[3:1]) : 3'd0;
    assign green = bg_visible_s3 && fg_valid_s3 ? fg_g_s3[3:1] :
                   bg_visible_s3 ? (spr_val_s2 ? final_g[3:1] : bg_g[3:1]) : 3'd0;
    assign blue  = bg_visible_s3 && fg_valid_s3 ? fg_b_s3 :
                   bg_visible_s3 ? (spr_val_s2 ? final_b[3:2] : bg_b[3:2]) : 2'd0;

endmodule
