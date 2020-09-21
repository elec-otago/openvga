#########################################################
# User settings start here
#########################################################

RTL_PATH=../rtl
LIB_PATH=${RTL_PATH}/lib
SIM_PATH=.
MEM_PATH=${RTL_PATH}/mem
WBC_PATH=${LIB_PATH}
CPU_PATH=${RTL_PATH}/cpu
TTA_PATH=${CPU_PATH}/tta16
RISC_PATH=${CPU_PATH}/risc16
CACHE_PATH=${RTL_PATH}/cache
PCI_PATH=${RTL_PATH}/pci
VID_PATH=${RTL_PATH}/video
XPATH=${SIM_PATH}/xilinx

LIB_FILES=${LIB_PATH}/fifo/async/afifo16.v ${LIB_PATH}/fifo/async/afifo2k.v ${LIB_PATH}/counter/bin2gray.v ${WBC_PATH}/wb_mux4to1.v ${LIB_PATH}/mux/mux4to1.v ${LIB_PATH}/mfsr/mfsr7.v ${LIB_PATH}/mfsr/mfsr8.v ${LIB_PATH}/mfsr/mfsr9.v ${LIB_PATH}/mfsr/mfsr10.v ${LIB_PATH}/mfsr/mfsr11.v ${WBC_PATH}/wb_leds.v ${LIB_PATH}/counter/fib/fib20.v ${LIB_PATH}/clock/clkdiv.v

CACHE_FILES=${CACHE_PATH}/wb_simple_cache.v ${CACHE_PATH}/wb_cache_flush.v ${CACHE_PATH}/fetch_wb.v ${CACHE_PATH}/tag_ram.v ${CACHE_PATH}/cache_bram.v

RISC_FILES=${RISC_PATH}/risc16_tile.v ${RISC_PATH}/risc16.v ${RISC_PATH}/fetch.v ${RISC_PATH}/risc_rf.v ${RISC_PATH}/risc_mem_wb.v ${RISC_PATH}/decode.v ${RISC_PATH}/execute.v ${RISC_PATH}/branch.v ${RISC_PATH}/memory.v ${RISC_PATH}/risc_alu.v ${CACHE_FILES} ${CPU_PATH}/fastbits.v  ${WBC_PATH}/wb_dma.v ${WBC_PATH}/pre_read.v ${WBC_PATH}/wb_sync.v

TTA_FILES=${TTA_PATH}/tta16_tile.v ${TTA_PATH}/tta16.v ${CACHE_FILES} ${CPU_PATH}/fastbits.v  ${WBC_PATH}/wb_dma.v ${WBC_PATH}/pre_read.v ${WBC_PATH}/wb_sync.v ${TTA_PATH}/tta_stream8to8.v ${TTA_PATH}/tta_stream4to4.v ${TTA_PATH}/tta_stream4to8.v
#  ${CPU_PATH}/tta/tta_stream8to32.v

MEM_FILES=${MEM_PATH}/wb_sdram_ctrl.v ${MEM_PATH}/ddr_datapath.v ${MEM_PATH}/rfc.v

WBC_FILES=${WBC_PATH}/wb_sprom.v ${PCI_PATH}/wb_pci_top.v ${PCI_PATH}/cfgspace.v ${PCI_PATH}/wb_pci_mem.v

VID_FILES=${VID_PATH}/wb_video_top.v ${VID_PATH}/wb_vga_ctrl.v ${VID_PATH}/wb_crtc.v ${VID_PATH}/crtc.v ${VID_PATH}/prefetch.v  ${VID_PATH}/vga16.v  ${VID_PATH}/wb_redraw.v

COMMON_FILES=${RTL_PATH}/freega_top.v ${RTL_PATH}/freega_io.v ${LIB_FILES} ${TTA_FILES} ${WBC_FILES} ${VID_FILES} ${MEM_FILES}
IFILES=${COMMON_FILES} freega_tb.v ${SIM_PATH}/pci/pci_stresstest.v ${SIM_PATH}/pci/pci_testblock.v ${SIM_PATH}/pci/pci_gencmds.v  ${LIB_PATH}/fifo/sync/sfifo2k.v ${SIM_PATH}/mem/mt48lc4m16a2.v ${XPATH}/IBUF.v ${XPATH}/OBUF.v ${XPATH}/BUFG.v ${XPATH}/BUFGMUX.v ${XPATH}/DCM.v ${XPATH}/RAMB16_S36_S36.v ${XPATH}/OFDDRTRSE.v ${XPATH}/IFDDRRSE.v ${XPATH}/MUXCY.v ${XPATH}/RAMB16_S18_S18.v ${XPATH}/RAMB16_S18_S36.v ${XPATH}/RAMB16_S9_S9.v ${XPATH}/FDRSE.v ${XPATH}/RAM16X1S.v

# (optional) Name of top module. Defaults to name of first file with suffix removed
ICARUS_TOP_MODULE=freega_tb


#########################################################
# Advanced user settings
#########################################################

ICARUS_OPTIONS=

#########################################################
# User settings end here
#########################################################

all: icarus

clean:
	rm -rf icarus.out tb.vcd
	@md5sum Makefile > make.md5

clean_test:
ifneq '$(shell cat make.md5)' '$(shell md5sum Makefile)'
	@echo 'Makefile changed: making clean'
	make clean
else
endif

test:
	echo ${TEST}

#########################################################

icarus: clean_test ${XFILES}
	iverilog -Wall -D__icarus -o icarus.out -s ${ICARUS_TOP_MODULE} ${ICARUS_OPTIONS} ${IFILES}
