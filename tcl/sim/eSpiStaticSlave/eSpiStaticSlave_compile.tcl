##************************************************************************
## @author:     Andreas Kaeberlein
## @copyright:  Copyright 2020
## @credits:    AKAE
##
## @license:    BSDv3
## @maintainer: Andreas Kaeberlein
## @email:      andreas.kaeberlein@web.de
##
## @file:       eSpiStaticSlave_compile.tcl
## @note:       VHDL'93
## @date:       2020-08-04
##
## @brief:      compiles dut/tb
##************************************************************************



# path setting
#
set path_tb "../tb"
set path_src "../bfm"
#


# Compile TB
#
vcom -93 -novopt $path_src/eSpiStaticSlave.vhd;     # DUT
vcom -93 -novopt $path_tb/eSpiStaticSlave_tb.vhd;   # TB
#
