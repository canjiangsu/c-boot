#TOPDIR = /home/can/share/c-boot
#ARCH = arm
#SRCTREE = $(TOPDIR)
#obj =

include $(TOPDIR)/config.mk

LIB	= $(obj)lib$(ARCH).a

COBJS-y += interrupts.o

SRCS	:= $(COBJS-y:.o=.c)
OBJS	:= $(addprefix $(obj),$(COBJS-y))

$(LIB): $(obj) .depend $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

############################################
include $(SRCTREE)/rules.mk

sinclude $(obj).depend
###########################################

testfor:
	for f in $(SRCS); do \
		g=`basename $$f | sed -e 's/\(.*\)\.\w/1.o/'`;\
		echo $$g; \
	done

