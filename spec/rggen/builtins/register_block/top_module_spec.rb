require_relative '../spec_helper'

describe "register_block/top_module" do
  include_context 'configuration common'
  include_context 'register_map common'
  include_context 'rtl common'

  before(:all) do
    enable :global, [:data_width, :address_width]
    enable :register_block, [:name, :byte_size]
    enable :register_block, [:top_module, :clock_reset, :host_if, :bus_splitter, :irq_controller]
    enable :register_block, :host_if, :apb
    enable :register, [:name, :offset_address, :array, :type]
    enable :register, :type, [:external, :indirect]
    enable :bit_field, [:name, :bit_assignment, :type, :initial_value, :reference]
    enable :bit_field, :type, [:rw, :ro, :w0c, :w1c]

    configuration = create_configuration(address_width: 16)
    register_map  = create_register_map(
      configuration,
      "block_0" => [
        [nil, nil         , "block_0"                                                                                                                               ],
        [nil, nil         , 256                                                                                                                                     ],
        [                                                                                                                                                           ],
        [                                                                                                                                                           ],
        [nil, "register_0", "0x00"     , nil     , nil                                                     , "bit_field_0_0", "[16]"   , "rw" , 0  , nil            ],
        [nil, nil         , nil        , nil     , nil                                                     , "bit_field_0_1", "[0]"    , "ro" , 0  , nil            ],
        [nil, "register_1", "0x04"     , nil     , nil                                                     , "bit_field_1_0", "[31:16]", "ro" , 0  , nil            ],
        [nil, nil         , nil        , nil     , nil                                                     , "bit_field_1_1", "[15:0]" , "rw" , 0  , nil            ],
        [nil, "register_2", "0x08-0x0F", "[2]"   , nil                                                     , "bit_field_2_0", "[31:16]", "ro" , 0  , nil            ],
        [nil, nil         , nil        , nil     , nil                                                     , "bit_field_2_1", "[15:0]" , "rw" , 0  , nil            ],
        [nil, "register_3", "0x10"     , "[2,4]", "indirect: bit_field_0_0:1, bit_field_1_0, bit_field_1_1", "bit_field_3_0", "[31:16]", "ro" , 0  , nil            ],
        [nil, nil         , nil        , nil    , nil                                                      , "bit_field_3_1", "[15:0]" , "rw" , 0  , nil            ],
        [nil, "register_4", "0x14"     , nil    , nil                                                      , "bit_field_4_0", "[8]"    , "w0c", 0  , "bit_field_0_0"],
        [nil, nil         , nil        , nil    , nil                                                      , "bit_field_4_1", "[0]"    , "w1c", 0  , "bit_field_0_0"],
        [nil, "register_5", "0x20-0x2F", nil    , :external                                                , nil            , nil      , nil  , nil, nil            ]
      ]
    )

    @rtl  = build_rtl_factory.create(configuration, register_map).register_blocks[0]
  end

  after(:all) do
    clear_enabled_items
  end

  let(:rtl) do
    @rtl
  end

  describe "#write_file" do
    let(:expected_code) do
      <<'CODE'
module block_0 (
  input clk,
  input rst_n,
  rggen_apb_if.slave apb_if,
  output o_irq,
  output o_bit_field_0_0,
  input i_bit_field_0_1,
  input [15:0] i_bit_field_1_0,
  output [15:0] o_bit_field_1_1,
  input [15:0] i_bit_field_2_0[2],
  output [15:0] o_bit_field_2_1[2],
  input [15:0] i_bit_field_3_0[2][4],
  output [15:0] o_bit_field_3_1[2][4],
  input i_bit_field_4_0_set,
  input i_bit_field_4_1_set,
  rggen_bus_if.master register_5_bus_if
);
  rggen_bus_if #(8, 32) bus_if();
  rggen_register_if #(8, 32) register_if[14]();
  logic [1:0] ier;
  logic [1:0] isr;
  logic [32:0] register_3_indirect_index[2][4];
  rggen_host_if_apb #(
    .LOCAL_ADDRESS_WIDTH  (8)
  ) u_host_if (
    .apb_if (apb_if),
    .bus_if (bus_if)
  );
  rggen_bus_splitter #(
    .DATA_WIDTH       (32),
    .TOTAL_REGISTERS  (14)
  ) u_bus_splitter (
    .clk          (clk),
    .rst_n        (rst_n),
    .bus_if       (bus_if),
    .register_if  (register_if)
  );
  assign ier = {register_if[0].value[16], register_if[0].value[16]};
  assign isr = {register_if[12].value[8], register_if[12].value[0]};
  rggen_irq_controller #(
    .TOTAL_INTERRUPTS (2)
  ) u_irq_controller (
    .clk    (clk),
    .rst_n  (rst_n),
    .i_ier  (ier),
    .i_isr  (isr),
    .o_irq  (o_irq)
  );
  rggen_default_register #(
    .ADDRESS_WIDTH  (8),
    .START_ADDRESS  (8'h00),
    .END_ADDRESS    (8'h03),
    .DATA_WIDTH     (32),
    .VALID_BITS     (32'h00010001),
    .READABLE_BITS  (32'h00010001)
  ) u_register_0 (
    .register_if  (register_if[0]),
    .o_select     ()
  );
  rggen_bit_field_rw #(
    .MSB            (16),
    .LSB            (16),
    .INITIAL_VALUE  (1'h0)
  ) u_bit_field_0_0 (
    .clk          (clk),
    .rst_n        (rst_n),
    .register_if  (register_if[0]),
    .o_value      (o_bit_field_0_0)
  );
  rggen_bit_field_ro #(
    .MSB  (0),
    .LSB  (0)
  ) u_bit_field_0_1 (
    .register_if  (register_if[0]),
    .i_value      (i_bit_field_0_1)
  );
  rggen_default_register #(
    .ADDRESS_WIDTH  (8),
    .START_ADDRESS  (8'h04),
    .END_ADDRESS    (8'h07),
    .DATA_WIDTH     (32),
    .VALID_BITS     (32'hffffffff),
    .READABLE_BITS  (32'hffffffff)
  ) u_register_1 (
    .register_if  (register_if[1]),
    .o_select     ()
  );
  rggen_bit_field_ro #(
    .MSB  (31),
    .LSB  (16)
  ) u_bit_field_1_0 (
    .register_if  (register_if[1]),
    .i_value      (i_bit_field_1_0)
  );
  rggen_bit_field_rw #(
    .MSB            (15),
    .LSB            (0),
    .INITIAL_VALUE  (16'h0000)
  ) u_bit_field_1_1 (
    .clk          (clk),
    .rst_n        (rst_n),
    .register_if  (register_if[1]),
    .o_value      (o_bit_field_1_1)
  );
  generate if (1) begin : g_register_2
    genvar g_i;
    for (g_i = 0;g_i < 2;g_i++) begin : g
      rggen_default_register #(
        .ADDRESS_WIDTH  (8),
        .START_ADDRESS  (8'h08 + 8'h04 * g_i),
        .END_ADDRESS    (8'h0b + 8'h04 * g_i),
        .DATA_WIDTH     (32),
        .VALID_BITS     (32'hffffffff),
        .READABLE_BITS  (32'hffffffff)
      ) u_register_2 (
        .register_if  (register_if[2+g_i]),
        .o_select     ()
      );
      rggen_bit_field_ro #(
        .MSB  (31),
        .LSB  (16)
      ) u_bit_field_2_0 (
        .register_if  (register_if[2+g_i]),
        .i_value      (i_bit_field_2_0[g_i])
      );
      rggen_bit_field_rw #(
        .MSB            (15),
        .LSB            (0),
        .INITIAL_VALUE  (16'h0000)
      ) u_bit_field_2_1 (
        .clk          (clk),
        .rst_n        (rst_n),
        .register_if  (register_if[2+g_i]),
        .o_value      (o_bit_field_2_1[g_i])
      );
    end
  end endgenerate
  generate if (1) begin : g_register_3
    genvar g_i, g_j;
    for (g_i = 0;g_i < 2;g_i++) begin : g
      for (g_j = 0;g_j < 4;g_j++) begin : g
        assign register_3_indirect_index[g_i][g_j] = {register_if[0].value[16], register_if[1].value[31:16], register_if[1].value[15:0]};
        rggen_indirect_register #(
          .ADDRESS_WIDTH  (8),
          .START_ADDRESS  (8'h10),
          .END_ADDRESS    (8'h13),
          .INDEX_WIDTH    (33),
          .INDEX_VALUE    ({1'h1, g_i[15:0], g_j[15:0]}),
          .DATA_WIDTH     (32),
          .VALID_BITS     (32'hffffffff),
          .READABLE_BITS  (32'hffffffff)
        ) u_register_3 (
          .register_if  (register_if[4+4*g_i+g_j]),
          .i_index      (register_3_indirect_index[g_i][g_j])
        );
        rggen_bit_field_ro #(
          .MSB  (31),
          .LSB  (16)
        ) u_bit_field_3_0 (
          .register_if  (register_if[4+4*g_i+g_j]),
          .i_value      (i_bit_field_3_0[g_i][g_j])
        );
        rggen_bit_field_rw #(
          .MSB            (15),
          .LSB            (0),
          .INITIAL_VALUE  (16'h0000)
        ) u_bit_field_3_1 (
          .clk          (clk),
          .rst_n        (rst_n),
          .register_if  (register_if[4+4*g_i+g_j]),
          .o_value      (o_bit_field_3_1[g_i][g_j])
        );
      end
    end
  end endgenerate
  rggen_default_register #(
    .ADDRESS_WIDTH  (8),
    .START_ADDRESS  (8'h14),
    .END_ADDRESS    (8'h17),
    .DATA_WIDTH     (32),
    .VALID_BITS     (32'h00000101),
    .READABLE_BITS  (32'h00000101)
  ) u_register_4 (
    .register_if  (register_if[12]),
    .o_select     ()
  );
  rggen_bit_field_w01s_w01c #(
    .MODE             (rggen_rtl_pkg::RGGEN_CLEAR_MODE),
    .SET_CLEAR_VALUE  (0),
    .MSB              (8),
    .LSB              (8),
    .INITIAL_VALUE    (1'h0)
  ) u_bit_field_4_0 (
    .clk            (clk),
    .rst_n          (rst_n),
    .i_set_or_clear (i_bit_field_4_0_set),
    .register_if    (register_if[12]),
    .o_value        ()
  );
  rggen_bit_field_w01s_w01c #(
    .MODE             (rggen_rtl_pkg::RGGEN_CLEAR_MODE),
    .SET_CLEAR_VALUE  (1),
    .MSB              (0),
    .LSB              (0),
    .INITIAL_VALUE    (1'h0)
  ) u_bit_field_4_1 (
    .clk            (clk),
    .rst_n          (rst_n),
    .i_set_or_clear (i_bit_field_4_1_set),
    .register_if    (register_if[12]),
    .o_value        ()
  );
  rggen_external_register #(
    .ADDRESS_WIDTH  (8),
    .START_ADDRESS  (8'h20),
    .END_ADDRESS    (8'h2f),
    .DATA_WIDTH     (32)
  ) u_register_5 (
    .clk                  (clk),
    .rst_n                (rst_n),
    .register_control_if  (register_if[13]),
    .register_data_if     (register_if[13]),
    .bus_if               (register_5_bus_if)
  );
endmodule
CODE
    end

    it "レジスタモジュールのRTLを書き出す" do
      expect { rtl.write_file('.') }.to write_binary_file("./block_0.sv", expected_code)
    end
  end
end
