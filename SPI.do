vlib work
vlog SPI_MAIN.v
vsim -voptargs=+acc work.SPI_Wrapper_tb
add wave *
run -all