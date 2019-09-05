# krv_c
A configurable microprocessor based on RISCV


Introduction


krv-c is a configurable RISCV-based 32-bit micro-controller subsystem. Based on krv_m0 (https://github.com/wangk2017/krv_m0), krv-c has featuers as below:


Features


•RV32IM standard ISA support

•Instruction/data TCM for acceleration

•Integrated Platform-Level Interrupt Controller(PLIC)

•Support Debug functionalities of breakpoint/single-step

•Lite AHB interconnection with APB peripherals of UART

•Low Power Design with clock-gating and power-gating

•support SoC configurable for features above



Configre


Configure file is located here: 

src/rtl/inc/user_config.vh


Tool Setup


krv_c uses the free iverilog for functional verification and gtkwave for debug. Below is how these tools are installed for ubuntu

$:sudo apt-get install iverilog

$:sudo apt-get install gtkwave


Simulation Run


(1) RV32I Compliance verification

krv_m0 uses the riscv-tests rv32ui/rv32um for compliance check

https://github.com/riscv/riscv-tests

For RV32I check:

make all_riscv_tests

For RV32M check (if RV32M support is included)

make all_rv32m_test

The TB will check the value of gp(GPRS3), if it is 0x1 after entering write_tohost, it will display Pass, or it will display Fail.

(2) Boot OS Zephyr applications (Hello world/philosopher/synchronization)

krv_m0 test uses the board m2gl025_miv for some tiny setting changes for clock frequency, baud rate and ROM start address.

run hello world application

make zephyr.sim

run philosopher application

make zephyr_phil.sim

run synchronization application

make zephyr_sync.sim


Software Development


krv-c could support zephyr OS, and application could be developped in zephyr OS env.

For bare-metal software programs, a software dir with a simple example of helloworld is included here:

software/helloworld

You could develop your own software under this DIR.
