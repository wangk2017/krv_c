# krv_c
A configurable microprocessor based on RISCV

Introduction

krv-c is a configurable RISCV-based 32-bit micro-controller subsystem. It consists of a RISCV processor Core and can be configured to have tightly coupled memories for instruction and data acceleration, machine timer and platform level interrupt controller (KPLIC) for timer and external interrupts respectively and power gating for saving energy.  



Features

•RISC-V 32b integer ISA standard

•Can be configured to have full RV32M supported

•Can be configured to include Instruction/data TCM for acceleration

•precise exception and external interrupt support

•Can be configured to have Machine Timer support

•Can be configured to have integrated platform-level interrupt controller 

•lite AHB interconnection

•APB peripherals of UART/TIMER/GPIO

•low power design with clock-gating, operands gating and can be configured to include power gating

