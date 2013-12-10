#CROSS_COMPILE := arm-linux-
obj :=
src :=
#CPU := arm920t
#SOBJS := 

# clean the slate ...
PLATFORM_RELFLAGS =
PLATFORM_CPPFLAGS =
PLATFORM_LDFLAGS =

LD = $(CROSS_COMPILE)ld
CC = $(CROSS_COMPILE)gcc
AR = $(CROSS_COMPILE)ar
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
##############################################

# Load generatedd board configuration
sinclude $(OBJTREE)/include/autoconf.mk

ifdef ARCH
sinclude $(TOPDIR)/$(ARCH)_config.mk   # include architecture dependend rules
endif
ifdef CPU
sinclude $(TOPDIR)/cpu/$(CPU)/config.mk # include CPU specific rules
endif
ifdef SOC
sinclude $(TOPDIR)/cpu/$(CPU)/$(SOC)/config.mk #include SoC specific rules
endif
ifdef VENDOR
BOARDDIR = $(VENDOR)/$(BOARD)
else
BOARDDIR = $(BOARD)
endif
ifdef BOARD
sinclude $(TOPDIR)/board/$(BOARDDIR)/config.mk #include board specific rules
endif

##############################################

ARFLAGS = crv
DBGFLAGS = -gdwarf-2
OPTFLAGS = -O0
##############################################
sinclude $(TOPDIR)/cpu/$(CPU)/config.mk

CPPFLAGS := $(DBGFLAGS) $(OPTFLAGS) -D__KERNEL__
ifneq ($(TEXT_BASE),)
CPPFLAGS += -DTEXT_BASE=$(TEXT_BASE)
endif

CPPFLAGS += -I$(TOPDIR)/include

CFLAGS := $(CPPFLAGS) -Wall -Wstrict-prototypes
AFLAGS := -D__ASSEMBLY__ $(CPPFLAGS)

LDSCRIPT := $(TOPDIR)/board/$(BOARDDIR)/c-boot.lds

LDFLAGS += -Bstatic -T $(LDSCRIPT) $(PLATFORM_LDFLAGS)
ifneq ($(TEXT_BASE),)
LDFLAGS += -Ttext $(TEXT_BASE)
endif

############################################################
%.s:	%.S
	$(CPP) $(AFLAGS) -o $@ $<
%.o:	%.S
	$(CC) $(AFLAGS) -c -o $@ $<
%.o:	%.c
	$(CC) $(CFLAGS) -c -o $@ $<



