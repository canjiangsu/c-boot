
void enable_interrupts (void)
{
	return;
}

int disable_interrupts (void)
{
	return 0;
}

void bad_mode (void)
{
	return;
}

void show_regs (void)
{
	return;
}

void do_undefined_instruction (void)
{
	return;
}

void do_software_interrupt (void)
{
	return;
}

void do_prefetch_abort (void)
{
	return;
}

void do_data_abort (void)
{
	return;
}

void do_not_used (void)
{
	return;
}

void do_fiq (void)
{
	return;
}
#ifndef CONFIG_USE_IRQ
void do_irq (void)
{
	return;
}
#endif
