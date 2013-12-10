include /home/can/share/c-boot/config.mk
#from $(TOPDIR)/config.mk:
#obj :=
#CPU := arm920t
#SOBJS :=
#AR := arm-linux-ar
#ARFLAGS := crv
 


LIB	= $(obj)lib$(CPU).a

START	= start.o
COBJS	= cpu.o interrupts.o

SRCS	:= $(START:.o=.S) $(SOBJS:.o=.S) $(COBJS:.o=.c)
#SRCS	:= start.S cpu.c interrupts.c
OBJS	:= $(addprefix $(obj),$(COBJS) $(SOBJS))
#OBJS	:= cpu.o interrupts.o
START	:= $(addprefix $(obj),$(START))
#START	:= start.o

#all:	$(obj).depend $(START) $(LIB)
all:	$(obj) $(START) $(LIB)
#all:	start.o libarm920t.a

$(LIB):	$(OBJS)
#libarm920t.a: cpu.o interrupts.o

	$(AR) $(ARFLAGS) $@ $(OBJS)
#	arm-linux-ar crv libarm920t.a cpu.o interrupts.o

clean:
	rm *.o *.a
#########################################################################

# defines $(obj).depend target
#include $(SRCTREE)/rules.mk

#sinclude $(obj).depend

########################################################################
