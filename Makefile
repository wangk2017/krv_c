zephyr_dir := ~/open-sources/zephyr
riscv_test_dir := ~/riscv-tests
software_dir := ./software

default: all


zephyr/%.hex: $(zephyr_dir)/samples/%/build/zephyr/zephyr.elf firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,37d" hex_file/$@

sw/%.hex: $(software_dir)/%/build/software.elf firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,1024d" hex_file/$@
	sed -i "434,1024d" hex_file/$@

pg/%.hex: tests/extra_tests/pg_ctrl/pg_ctrl-m-% firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,1024d" hex_file/$@

dbg/%.hex: tests/extra_tests/dbg/debug-m-% firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,1024d" hex_file/$@

int/%.hex: tests/extra_tests/int/kplic-m-% firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,1024d" hex_file/$@

csr/%.hex: tests/extra_tests/csr/rv32m-m-% firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,1024d" hex_file/$@


riscv/%.hex: $(riscv_test_dir)/isa/rv32ui-p-% firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,1024d" hex_file/$@

rv32m/%.hex: $(riscv_test_dir)/isa/rv32um-p-% firmware/makehex.py
	python firmware/makehex.py $< > hex_file/$@
	sed -i "1,1024d" hex_file/$@

all_rv32m_hex: rv32m/div.hex rv32m/divu.hex rv32m/mul.hex rv32m/mulh.hex rv32m/mulhsu.hex rv32m/mulhu.hex rv32m/rem.hex rv32m/remu.hex
all_riscv_hex: riscv/add.hex riscv/bne.hex riscv/or.hex riscv/sltu.hex riscv/addi.hex riscv/fence_i.hex riscv/ori.hex riscv/sra.hex riscv/and.hex riscv/jal.hex riscv/sb.hex riscv/srai.hex riscv/andi.hex riscv/jalr.hex riscv/sh.hex riscv/srl.hex riscv/auipc.hex  riscv/lb.hex riscv/simple.hex  riscv/srli.hex riscv/beq.hex riscv/lbu.hex riscv/sll.hex riscv/sub.hex riscv/bge.hex riscv/lh.hex riscv/slli.hex riscv/sw.hex riscv/bgeu.hex riscv/lhu.hex riscv/slt.hex riscv/xor.hex riscv/blt.hex riscv/lui.hex riscv/slti.hex riscv/xori.hex riscv/bltu.hex riscv/lw.hex riscv/sltiu.hex
all_pg_hex: pg/simple.hex
all_dbg_hex: dbg/ebreak.hex dbg/breakpoint.hex
all_int_hex: int/simple.hex
all_csr_hex: csr/csrrc.hex csr/csrrs.hex csr/csrrw.hex csr/csrrci.hex csr/csrrsi.hex csr/csrrwi.hex
all_zephyr_hex: zephyr/hello_world.hex zephyr/philosophers.hex zephyr/synchronization.hex

comp:
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v

veri:
	verilator -Wall +incdir+./tb +incdir+./tb/sim_inc --cc ./tb/rom.v ./verification/krv_c_tb.v ./src/rtl/*/*.v  ./src/Actel_DirectCore/*.v --exe ./verification/sim_main.cpp
	make -j -C obj_dir -f Vkrv_c_tb.mk Vkrv_c_tb

csr.%.sim: hex_file/csr/%.hex 
	cp $< hex_file/run.hex
	./tb/sim_define.sh RISCV
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

all_csr_tests: csr.csrrc.sim csr.csrrs.sim csr.csrrw.sim csr.csrrci.sim csr.csrrsi.sim csr.csrrwi.sim

pg.%.sim: hex_file/pg/%.hex 
	cp $< hex_file/run.hex
	./tb/sim_define.sh PG_TEST
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

all_pg_tests: pg.simple.sim

int.%.sim: hex_file/int/%.hex 
	cp $< hex_file/run.hex
	./tb/sim_define.sh RISCV
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

all_int_tests: int.simple.sim

sw_helloworld.sim: hex_file/sw/helloworld.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh SW_HW
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt
	

zephyr.sim: hex_file/zephyr/hello_world.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh ZEPHYR
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt
	
zephyr_sync.sim: hex_file/zephyr/synchronization.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh ZEPHYR_SYNC
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt
	
zephyr_phil.sim: hex_file/zephyr/philosophers.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh ZEPHYR_PHIL
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt
	
rv32m.%.sim: hex_file/rv32m/%.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh RISCV
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

all_rv32m_test: rv32m.mul.sim rv32m.mulh.sim rv32m.mulhu.sim rv32m.mulhsu.sim rv32m.div.sim rv32m.rem.sim rv32m.divu.sim rv32m.remu.sim 

riscv.%.sim: hex_file/riscv/%.hex 
	cp $< hex_file/run.hex
	./tb/sim_define.sh RISCV
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

all_riscv_tests: riscv.add.sim riscv.bne.sim riscv.or.sim riscv.sltu.sim riscv.addi.sim riscv.fence_i.sim riscv.ori.sim riscv.sra.sim riscv.and.sim riscv.jal.sim riscv.sb.sim riscv.srai.sim riscv.andi.sim riscv.jalr.sim riscv.sh.sim riscv.srl.sim riscv.auipc.sim  riscv.lb.sim riscv.simple.sim  riscv.srli.sim riscv.beq.sim riscv.lbu.sim riscv.sll.sim riscv.sub.sim riscv.bge.sim riscv.lh.sim riscv.slli.sim riscv.sw.sim riscv.bgeu.sim riscv.lhu.sim riscv.slt.sim riscv.xor.sim riscv.blt.sim riscv.lui.sim riscv.slti.sim riscv.xori.sim riscv.bltu.sim riscv.lw.sim riscv.sltiu.sim

dbg_ref.sim: hex_file/dbg/breakpoint.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh DBG_REF
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

breakpoint.sim: hex_file/dbg/breakpoint.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh BREAKPOINT
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

ebreak.sim: hex_file/dbg/ebreak.hex
	cp $< hex_file/run.hex
	./tb/sim_define.sh EBREAK
	iverilog -g2009 -I ./tb -I ./tb/case_ctrl_dbg -I ./src/rtl/inc -o ./out/krv ./tb/krv_c_tb.v ./tb/rom.v ./src/rtl/*/*.v
	vvp -l out/$@ -v -n ./out/krv -lxt2
	cp out/krv.vcd out/krv.lxt

check_fail:
	grep "Fail" out/*.sim

check_time_out:
	grep "Time Out" out/*.sim

wave: 
	gtkwave ./out/krv.lxt &
	
clean:
	rm -vrf ./out/*.sim
	rm -vrf ./out/krv*
	rm -vrf ./out/uart*
	rm -vrf ./tb/tb_defines.vh
	rm -vrf ./out/*.txt
	rm -vrf ./hex_file/run.hex

.PHONY: all
