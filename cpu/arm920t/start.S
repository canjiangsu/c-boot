/*
 *********************************************
 *
 * Jump vector table as in table 3,1 in[1]
 *
 *********************************************
 */
#include <config.h>

.globl _start
_start:	b       start_code
	ldr	pc, _undefined_instruction
	ldr	pc, _software_interrupt
	ldr	pc, _prefetch_abort
	ldr	pc, _data_abort
	ldr	pc, _not_used
	ldr	pc, _irq
	ldr	pc, _fiq

_undefined_instruction:	.word undefined_instruction
_software_interrupt:	.word software_interrupt
_prefetch_abort:	.word prefetch_abort
_data_abort:		.word data_abort
_not_used:		.word not_used
_irq:			.word irq
_fiq:			.word fiq

	.balignl 16,0xdeadbeef

_TEXT_BASE:
	.word	TEXT_BASE

.globl _armboot_start
_armboot_start:
	.word _start
/*
 * These are defined in the board-specific linker script.
 */

.globl  _bss_start
_bss_start:
    .word __bss_start

.globl  _bss_end
_bss_end:
    .word _end

start_code:
	/*
	 * set the cpu to SVC32 mode
	 */
	mrs	r0,cpsr
	bic	r0,r0,#0x1f
	orr	r0,r0,#0xd3
	msr	cpsr,r0

#define pWTCON	0x53000000
#define INTMSK	0x4A000008
#define INTSUBMSK 0x4A00001C
	
	ldr	r0, =pWTCON
	mov	r1, #0x0
	str	r1, [r0]

	/*
	 * mask all IRQs by setting all bits in the INTMR - default
	 */
	mov	r1, #0xffffffff
	ldr	r0, =INTMSK
	str	r1, [r0]
	
	ldr	r1, =0x7fff
	ldr	r0, =INTSUBMSK
	str	r1, [r0]

//============================
// CLOCK & POWER MANAGEMENT
//============================
#define LOCKTIME	0x4C000000	//PLL lock time counter
#define MPLLCON		0x4C000004	//MPLL Control
#define UPLLCON		0x4C000008	//UPLL Control
#define CLKCON		0x4c00000c	//Clock generator control
#define CLKSLOW		0x4c000010	//Slow clock control
#define CLKDIVN		0x4c000014	//Clock divider control

#define MDIV_405 0x7f << 12
#define PSDIV_405 0x21

#define U_MDIV_96 0x38<<12  //Fin=12.0MHz Fout=96MHz
#define U_PDIV_96 0x21
	//To reduce PLL lock time, adjust the LOCKTIME register.
	ldr	r0,=LOCKTIME
	ldr	r1,=0x0fff0fff
	str	r1,[r0]

	//FCLK:HCLK:PCLK = 1:4:8
	ldr r0, =CLKDIVN
	mov r1, #5
	str r1, [r0]
	
	mrc p15, 0, r1, c1, c0, 0 /*read ctrl register*/
	orr r1, r1, #0xc0000000 /*Asynchronous*/
	mcr p15, 0, r1, c1, c0, 0 /*write ctrl register */

	/*Configure UPLL*/
	ldr r0,=UPLLCON
	ldr r1,=(U_MDIV_96+U_PDIV_96)
	str r1,[r0]
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	
	/*Configure MPLL*/
	ldr r0,=MPLLCON
	ldr r1,=(MDIV_405+PSDIV_405) //Fin=12MHz
	str r1,[r0]

	bl cpu_init_crit

	adr r0, _start
	ldr r1, _TEXT_BASE
	cmp r0,r1
	beq stack_setup
/******************************************************/
#define NAND_CTL_BASE	0x4E000000
/* Offset */
#define oNFCONF	0x00
#define oNFCONT	0x04
#define oNFCMD	0x08
#define oNFSTAT	0x20
#define LENGTH_UBOOT 0x40000
	@ reset NAND
	
	mov r1, #NAND_CTL_BASE
	ldr r2, =((7<<12)|(7<<8)|(7<<4)|(0<<0))
	str r2, [r1, #oNFCONF]
	ldr r2, [r1, #oNFCONF]

	ldr r2, =((1<<4)|(0<<1)|(1<<0))	@ ACtive low CE Control
	str r2, [r1, #oNFCONT]
	ldr r2, [r1, #oNFCONT]
	
	ldr r2, =(0x6) @ RnB Clear
	str r2, [r1, #oNFSTAT]
	ldr r2, [r1, #oNFSTAT]
	
	mov r2, #0xff	@ RESET command
	strb	r2, [r1, #oNFCMD]
	
	mov r3, #0 @ wait
nand1:
	add r3, r3, #0x1
	cmp r3, #0xa
	blt nand1
nand2:
	ldr r2, [r1, #oNFSTAT]	@ wait ready
	tst r2, #0x4
	beq nand2
	
	ldr r2, [r1, #oNFCONT]
	orr r2, r2, #0x2	@ Flash Memory Chip Disable
	str r2, [r1, #oNFCONT]
	
	@ get read to call C function (for nand_read())
	ldr sp, DW_STACK_START	@ setup stack pointer
	mov fp, #0 @ no previous frame, so fp=0

	@ copy U-Boot to RAM
	ldr r0, =TEXT_BASE
	mov r1, #0x0
	mov r2, #LENGTH_UBOOT
	
	bl nand_read_ll
	tst r0, #0x0
	beq ok_nand_read
bad_nand_read:
loop2:
	b loop2	@infinite loop
ok_nand_read:
	@ verify
	mov r0, #0
	ldr r1, =TEXT_BASE
	mov r2, #0x400	@ 4 byte * 1024 =4K-bytes
go_next:
	ldr r3, [r0], #4
	ldr r4, [r1], #4
	teq r3, r4
	bne notmatch
	subs r2, r2, #4
	beq	stack_setup
	bne	go_next
notmatch:
loop3:
	b loop3	@infinite loop
		


/******************************************************/
	/* Set up the stack */
stack_setup:
	ldr r0, _TEXT_BASE	/* upper 128 KiB: relocated c-boot */
	sub r0, r0, #CFG_MALLOC_LEN /* malloc area
	sub r0, r0, #CFG_GBL_DATA_SIZE	/* bdinfo */
#ifdef CONFIG_USE_IRQ
	sub r0, r0, #(CONFIG_STACKSIZE_IRQ+CONFIG_STACKSIZE_FIQ)
#endif
	sub sp, r0, #12	/* leave 3 words for abort-stack */

clear_bss:
	ldr r0, _bss_start
	ldr r1, _bss_end
	mov r2, #0x00000000

clbss_l:
	str r2,[r0]
	add r0, r0, #4
	cmp r0, r1
	bne clbss_l
@	ldr pc, _start_armboot

@_start_armboot: .word start_armboot
	
#define STACK_BASE  TEXT_BASE
#define STACK_SIZE  0x10000
    .align  2
DW_STACK_START: .word   STACK_BASE+STACK_SIZE-4

cpu_init_crit:
	/*
	 * flush v4 I/D caches
	 */
	mov r0,#0
	mcr p15, 0, r0, c7, c7, 0  /* flush v3/v4 cache */
	mcr p15, 0, r0, c8, c7, 0  /* flush v4 TLB */

	/*
	 * disable MMU stuff and caches
	 */
	mrc p15, 0, r0, c1, c0, 0
	bic r0, r0, #0x00002300	@ clear bits 13, 9:8 (--V- --RS)
	bic r0, r0, #0x00000087 @ clear bits 7, 2:0 (B--- -CAM)
	orr r0, r0, #0x00000002 @ set bit 2 (A) Align
	orr r0, r0, #0x00001000 @ set bit 12 (I) I-Cache
	mcr p15, 0, r0, c1, c0, 0

	/*
	 * before relocating, we have to setup RAM timing
	 * because memory timing is board-dependend, you will
	 * find a lowlevel_init.S in your board directory.
	 */
	mov ip, lr
	bl lowlevel_init
	mov lr, ip
	mov pc, lr
	

/*
 ***************************************
 *
 * Interrupt handling
 *
 ***************************************
 *
 */

@
@ IRQ stack frame.
@
#define S_FRAME_SIZE	72

#define S_OLD_R0	68
#define S_PSR		64
#define S_PC		60
#define S_LR		56
#define S_SP		52

#define S_IP		48
#define S_FP		44
#define S_R10		40
#define S_R9		36
#define S_R8		32
#define S_R7		28
#define S_R6		24
#define S_R5		20
#define S_R4		16
#define S_R3		12
#define S_R2		8
#define S_R1		4
#define S_R0		0

#define	MODE_SVC	0x13
#define I_BIT		0x80

/*
 * use bad_save_user_regs for abort/prefetch/undef/swi ...
 * use irq_save_user_regs / irq_restore_user_regs for IRQ/FIQ handling
 */

	.macro	bad_save_user_regs
	sub	sp, sp, #S_FRAME_SIZE
	stmia	sp, {r0 - r12}
	ldr	r2, _armboot_start
	sub	r2, r2, #(CONFIG_STACKSIZE+CFG_MALLOC_LEN)
	sub	r2, r2, #(CFG_GBL_DATA_SIZE+8)	@ set base 2 words into abort stack
	ldmia	r2, {r2 - r3}			@ get pc, cpsr
	add	r0, sp, #S_FRAME_SIZE		@ restore sp_SVC
	
	add	r5, sp, #S_SP
	mov	r1, lr
	stmia	r5, {r0 - r3}			@ save sp_SVC, lr_SVC, pc, cpsr
	.endm
	
	.macro	irq_save_user_regs
	sub	sp, sp, #S_FRAME_SIZE
	stmia	sp, {r0 - r12}			@ Calling r0-r12
	add	r7, sp, #S_PC
	stmdb	r7, {sp, lr}^			@ Calling SP, LR
	str	lr, [r7, #0]			@ Save calling PC
	mrs	r6, spsr
	str	r6, [r7, #4]			@ Save CPSR
	str	r0, [r7, #8]			@ Save OLD_R0
	mov	r0, sp
	.endm

	.macro	irq_restore_user_regs
	ldmia	sp, {r0 - lr}^			@ Calling r0 - lr
	mov	r0, r0
	ldr	lr, [sp, #S_PC]			@ Get PC
	add	sp, sp, #S_FRAME_SIZE
	subs	pc, lr, #4			@ return & move spsr_svc into cpsr
	.endm

	.macro get_bad_stack
	ldr	r13, _armboot_start		@ setup our mode stack
	sub	r13, r13, #(CONFIG_STACKSIZE+CFG_MALLOC_LEN)
	sub	r13, r13, #(CFG_GBL_DATA_SIZE+8) @ reserved a couple spots in abort stack
	str	lr, [r13]			@ save caller lr /spsr
	mrs	lr, spsr
	str	lr, [r13, #4]

	mov	r13, #MODE_SVC			@ prepare SVC-mode
	@ msr	spsr_c, r13
	msr	spsr, r13
	mov	lr, pc
	movs	pc, lr
	.endm

	.macro	get_irq_stack			@ setup	IRQ stack
	ldr	sp, IRQ_STACK_START
	.endm

	.macro	get_fiq_stack
	ldr	sp, FIQ_STACK_START
	.endm

	
/*
 * exception handlers
 */
	.align 5
undefined_instruction:
	get_bad_stack
	bad_save_user_regs
	bl do_undefined_instruction

	.align 5
software_interrupt:
	get_bad_stack
	bad_save_user_regs
	bl do_software_interrupt

	.align 5
prefetch_abort:
	get_bad_stack
	bad_save_user_regs
	bl do_prefetch_abort

	.align 5
data_abort:
	get_bad_stack
	bad_save_user_regs
	bl do_data_abort

	.align 5
not_used:
	get_bad_stack
	bad_save_user_regs
	bl do_not_used

#ifdef CONFIG_USE_IRQ

	.align 5
fiq:
	get_irq_stack
	irq_save_user_regs
	bl	do_irq
	irq_restore_user_regs
	bl fiq

	.align 5
irq:
	get_fiq_stack
	irq_save_user_regs
	bl	do_irq
	irq_restore_user_regs
#else
	
	.align	5
irq:	
	get_bad_stack
	bad_save_user_regs
	bl	do_irq

	.align	5
fiq:	
	get_bad_stack
	bad_save_user_regs
	bl	do_fiq

#endif

