`define KRV_HAS_PLIC
`define KRV_HAS_MTIMER
`define KRV_HAS_ITCM
`define KRV_HAS_DTCM
`define KRV_HAS_PG
`define KRV_SUPPORT_RV32M

`define BOOT_ADDR 32'h0000_0000
//TCM defines
`define ITCM_START_ADDR `BOOT_ADDR
`define ITCM_SIZE	32'h0000_4000
`define DTCM_START_ADDR 32'h0004_0000
`define DTCM_SIZE	32'h0000_4000