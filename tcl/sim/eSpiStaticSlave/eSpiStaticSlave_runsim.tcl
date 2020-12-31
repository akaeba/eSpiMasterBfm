##************************************************************************
## @author:     Andreas Kaeberlein
## @copyright:  Copyright 2020
## @credits:    AKAE
##
## @license:    BSDv3
## @maintainer: Andreas Kaeberlein
## @email:      andreas.kaeberlein@web.de
##
## @file:       eSpiStaticSlave_runsim.tcl
## @note:       VHDL'93
## @date:       2020-08-07
##
## @brief:      starts simulation
##                1) open Modelsim project in simulation directory '/sim'
##                2) Tools -> TCL -> Execute Macro
##                3) choose this script '/tcl/sim/*/*.tcl
##************************************************************************



# start simulation, disable optimization
vsim -novopt -t 1ps work.eSpiStaticSlave_tb
#vsim -novopt -gDO_ALL_TEST=true -t 1ps work.eSpiStaticSlave_tb

# load Waveform
do "../tcl/sim/eSpiStaticSlave/eSpiStaticSlave_waveform.do"

# sim until finish
run 2 us
