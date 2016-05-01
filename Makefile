DATA2MEM = /cygdrive/e/Xilinx/14.7/ISE_DS/ISE/bin/nt64/data2mem.exe

all:
	make -C tools
	make -C firmware
	make -C config
	avr-size --common firmware/image.elf
	$(DATA2MEM) -bm fpga/progmem_bd.bmm -bt fpga/HdmilightTop.bit -bd firmware/image.mem -o b hdmilight-preconfig.bit
	tools/bitmerge.py --pad=0x10000 hdmilight-preconfig.bit config/merged.bin hdmilight.bit

clean:
	make -C tools clean
	make -C firmware clean
	make -C config clean
	rm -f hdmilight-preconfig.bit
	rm -f hdmilight.bit
