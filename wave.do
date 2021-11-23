onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cnn_top_tb/u_DUT/i_CLK
add wave -noupdate /cnn_top_tb/u_DUT/i_CLR
add wave -noupdate /cnn_top_tb/u_DUT/i_GO
add wave -noupdate -radix unsigned /cnn_top_tb/u_DUT/i_ADDR
add wave -noupdate -radix unsigned /cnn_top_tb/u_DUT/i_SEL
add wave -noupdate -radix unsigned /cnn_top_tb/u_DUT/o_DATA
add wave -noupdate /cnn_top_tb/u_DUT/o_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF1_DATA_IN
add wave -noupdate /cnn_top_tb/u_DUT/w_IMG_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_IMG_READ_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF1_WRITE_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF1_WRITE_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF1_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF1_SEL_LINE
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF1_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV1_GO
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV1_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV1_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF2_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF2_READ_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF2_WRITE_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF2_WRITE_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF2_SEL_LINE
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF2_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL1_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL1_DATA_IN
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL1_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF3_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF3_READ_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF3_WRITE_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF3_WRITE_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF3_SEL_LINE
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF3_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV2_DATA_IN
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV2_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV2_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF4_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF4_READ_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF4_WRITE_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF4_WRITE_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF4_SEL_LINE
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF4_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL2_DATA_IN
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL2_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL2_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF5_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF5_READ_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF5_WRITE_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF5_WRITE_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF5_SEL_LINE
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF5_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV3_DATA_IN
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV3_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV3_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF6_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF6_READ_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF6_WRITE_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF6_WRITE_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF6_SEL_LINE
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF6_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL3_DATA_IN
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL3_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_POOL3_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF7_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF7_READ_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF7_WRITE_ADDR
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF7_WRITE_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF7_SEL_LINE
add wave -noupdate /cnn_top_tb/u_DUT/w_REBUFF7_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV4_DATA_IN
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV4_DATA_OUT
add wave -noupdate /cnn_top_tb/u_DUT/w_CONV4_READY
add wave -noupdate /cnn_top_tb/u_DUT/w_FC_READ_ENA
add wave -noupdate /cnn_top_tb/u_DUT/w_FC_READ_ADDR
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {459748000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {459717640 ps} {459806931 ps}
