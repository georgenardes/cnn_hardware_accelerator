## Generated SDC file "fpga_design.sdc"

## Copyright (C) 2017  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 17.1.0 Build 590 10/25/2017 SJ Lite Edition"

## DATE    "Tue Nov 02 13:41:26 2021"

##
## DEVICE  "5CSEMA5F31C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLK} -period 20.000 -waveform { 0.000 10.000 } [get_ports {i_CLK}]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

# set_clock_uncertainty -rise_from [get_clocks {CLK}] -rise_to [get_clocks {CLK}] -setup 0.170  
# set_clock_uncertainty -rise_from [get_clocks {CLK}] -rise_to [get_clocks {CLK}] -hold 0.060  
# set_clock_uncertainty -rise_from [get_clocks {CLK}] -fall_to [get_clocks {CLK}] -setup 0.170  
# set_clock_uncertainty -rise_from [get_clocks {CLK}] -fall_to [get_clocks {CLK}] -hold 0.060  
# set_clock_uncertainty -fall_from [get_clocks {CLK}] -rise_to [get_clocks {CLK}] -setup 0.170  
# set_clock_uncertainty -fall_from [get_clocks {CLK}] -rise_to [get_clocks {CLK}] -hold 0.060  
# set_clock_uncertainty -fall_from [get_clocks {CLK}] -fall_to [get_clocks {CLK}] -setup 0.170  
# set_clock_uncertainty -fall_from [get_clocks {CLK}] -fall_to [get_clocks {CLK}] -hold 0.060  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************

# set_false_path -from [get_ports {i_CLR i_GO i_IN_DATA[0][0] i_IN_DATA[0][1] i_IN_DATA[0][2] i_IN_DATA[0][3] i_IN_DATA[0][4] i_IN_DATA[0][5] i_IN_DATA[0][6] i_IN_DATA[0][7] i_IN_DATA[1][0] i_IN_DATA[1][1] i_IN_DATA[1][2] i_IN_DATA[1][3] i_IN_DATA[1][4] i_IN_DATA[1][5] i_IN_DATA[1][6] i_IN_DATA[1][7] i_IN_DATA[2][0] i_IN_DATA[2][1] i_IN_DATA[2][2] i_IN_DATA[2][3] i_IN_DATA[2][4] i_IN_DATA[2][5] i_IN_DATA[2][6] i_IN_DATA[2][7] i_IN_SEL_LINE[0] i_IN_SEL_LINE[1] i_IN_WRITE_ADDR[0] i_IN_WRITE_ADDR[1] i_IN_WRITE_ADDR[2] i_IN_WRITE_ADDR[3] i_IN_WRITE_ADDR[4] i_IN_WRITE_ADDR[5] i_IN_WRITE_ADDR[6] i_IN_WRITE_ADDR[7] i_IN_WRITE_ADDR[8] i_IN_WRITE_ADDR[9] i_IN_WRITE_ENA i_LOAD i_OUT_READ_ADDR[0] i_OUT_READ_ADDR[1] i_OUT_READ_ADDR[2] i_OUT_READ_ADDR[3] i_OUT_READ_ADDR[4] i_OUT_READ_ADDR[5] i_OUT_READ_ADDR[6] i_OUT_READ_ADDR[7] i_OUT_READ_ADDR[8] i_OUT_READ_ADDR[9] i_OUT_READ_ENA}] -to [get_ports {o_LOADED o_OUT_DATA[0][0] o_OUT_DATA[0][1] o_OUT_DATA[0][2] o_OUT_DATA[0][3] o_OUT_DATA[0][4] o_OUT_DATA[0][5] o_OUT_DATA[0][6] o_OUT_DATA[0][7] o_OUT_DATA[1][0] o_OUT_DATA[1][1] o_OUT_DATA[1][2] o_OUT_DATA[1][3] o_OUT_DATA[1][4] o_OUT_DATA[1][5] o_OUT_DATA[1][6] o_OUT_DATA[1][7] o_OUT_DATA[2][0] o_OUT_DATA[2][1] o_OUT_DATA[2][2] o_OUT_DATA[2][3] o_OUT_DATA[2][4] o_OUT_DATA[2][5] o_OUT_DATA[2][6] o_OUT_DATA[2][7] o_OUT_DATA[3][0] o_OUT_DATA[3][1] o_OUT_DATA[3][2] o_OUT_DATA[3][3] o_OUT_DATA[3][4] o_OUT_DATA[3][5] o_OUT_DATA[3][6] o_OUT_DATA[3][7] o_OUT_DATA[4][0] o_OUT_DATA[4][1] o_OUT_DATA[4][2] o_OUT_DATA[4][3] o_OUT_DATA[4][4] o_OUT_DATA[4][5] o_OUT_DATA[4][6] o_OUT_DATA[4][7] o_OUT_DATA[5][0] o_OUT_DATA[5][1] o_OUT_DATA[5][2] o_OUT_DATA[5][3] o_OUT_DATA[5][4] o_OUT_DATA[5][5] o_OUT_DATA[5][6] o_OUT_DATA[5][7] o_READY}]
set_false_path -from [get_ports {i_CLR i_GO i_ADDR[*]  i_SEL[*] }] 

set_false_path  -to [get_ports {o_DATA[*] o_READY}]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

