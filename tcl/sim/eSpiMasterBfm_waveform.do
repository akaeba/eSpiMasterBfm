onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Main
add wave -noupdate /espimasterbfm_tb/p_stimuli/good
add wave -noupdate /espimasterbfm_tb/espiCmdFail
add wave -noupdate -divider eSPI
add wave -noupdate /espimasterbfm_tb/CSn
add wave -noupdate /espimasterbfm_tb/SCK
add wave -noupdate /espimasterbfm_tb/DIO
add wave -noupdate -divider Help
add wave -noupdate -radix hexadecimal /espimasterbfm_tb/p_stimuli/eSpiMsg
add wave -noupdate -radix hexadecimal /espimasterbfm_tb/p_stimuli/slv8
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {19598789 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 243
configure wave -valuecolwidth 114
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
WaveRestoreZoom {0 ps} {137463728 ps}
