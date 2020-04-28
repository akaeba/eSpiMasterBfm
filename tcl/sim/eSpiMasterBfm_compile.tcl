##************************************************************************
## @author:  	Andreas Kaeberlein
## @copyright:	Copyright 2020
## @credits: 	AKAE
##
## @license:  	BSDv3
## @maintainer:	Andreas Kaeberlein
## @email:		andreas.kaeberlein@web.de
##
## @file:       eSpiMasterBfm_compile.tcl
## @note:       VHDL'93
## @date:   	2020-04-24
##
## @brief:      compiles dut/tb
##************************************************************************



# path setting
#
set path_tb "../tb/eSpiMasterBfm"
set path_src "../hdl"
#


# Compile TB
#
vcom -93 -novopt $path_tb/eSpiMasterBfm.vhd;		# BFM used for TB
vcom -93 -novopt $path_tb/eSpiMasterBfm_tb.vhd;		# tests BFM
#