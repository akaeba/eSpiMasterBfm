##************************************************************************
## @author:     Andreas Kaeberlein
## @copyright:  Copyright 2020
## @credits:    AKAE
##
## @license:    BSDv3
## @maintainer: Andreas Kaeberlein
## @email:      andreas.kaeberlein@web.de
##
## @file:       eSpiMasterBfm_compile.tcl
## @note:       VHDL'93
## @date:       2020-04-24
##
## @brief:      compiles dut/tb
##                1) open Modelsim project in simulation directory '/sim'
##                2) Tools -> TCL -> Execute Macro
##                3) choose this script '/tcl/sim/*/*.tcl
##************************************************************************



# path setting
#
set path_tb "../tb"
set path_src "../bfm"
#


# BFM
#
vcom -93 -novopt $path_src/eSpiMasterBfm.vhd;   # BFM used for TB
vcom -93 -novopt $path_src/eSpiStaticSlave.vhd; # needed for TB
#


# TB
#
vcom -93 -novopt $path_tb/eSpiMasterBfm_tb.vhd;     # tests BFM
#
