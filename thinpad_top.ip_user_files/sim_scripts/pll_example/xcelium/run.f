-makelib xcelium_lib/xil_defaultlib -sv \
  "C:/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "C:/Xilinx/Vivado/2018.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../thinpad_top.srcs/sources_1/ip/pll_example/pll_example_clk_wiz.v" \
  "../../../../thinpad_top.srcs/sources_1/ip/pll_example/pll_example.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

