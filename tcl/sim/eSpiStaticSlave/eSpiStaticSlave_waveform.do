onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group Misc /espistaticslave_tb/XRESET
add wave -noupdate -expand -group Misc /espistaticslave_tb/p_stimuli/good
add wave -noupdate -expand -group Misc /espistaticslave_tb/SLGOOD
add wave -noupdate -expand -group ESPI /espistaticslave_tb/XCS
add wave -noupdate -expand -group ESPI /espistaticslave_tb/SCK
add wave -noupdate -expand -group ESPI /espistaticslave_tb/MOSI
add wave -noupdate -expand -group ESPI /espistaticslave_tb/MISO
add wave -noupdate -expand -group ESPI /espistaticslave_tb/XALERT
add wave -noupdate -expand -group Message /espistaticslave_tb/REQMSG
add wave -noupdate -expand -group Message /espistaticslave_tb/CMPMSG
add wave -noupdate -expand -group Message /espistaticslave_tb/LDMSG
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/stage
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/requestMsg
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/reqMsgStartIdx
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/reqMsgStopIdx
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/reqBitsPend
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/cpltSegStartIdx
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/cpltSegStopIdx
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/rspBitsSend
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/reqBitsCap
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/reqMsgCap
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/totalSeg
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/currentSeg
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/SFR
add wave -noupdate -expand -group eSpiSlave /espistaticslave_tb/DUT/p_espiSlave/str1
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {418694 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 382
configure wave -valuecolwidth 105
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1005010 ps}
