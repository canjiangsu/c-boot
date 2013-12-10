VERSION = 1
PATCHLEVEL = 0
SUBLEVEL = 4
EXTRAVERSION = 
C_BOOT_VERSION = $(VERSION).$(PATCHLEVEL).$(SUBLEVEL)$(EXTRAVERSION)

OBJTREE		:= $(if $(BUILD_DIR),$(BUILD_DIR),$(CURDIR))
SRCTREE		:= $(CURDIR)
TOPDIR		:= $(SRCTREE)
LNDIR		:= $(OBJTREE)
export	TOPDIR SRCTREE OBJTREE

MKCONFIG	:= $(SRCTREE)/mkconfig
export MKCONFIG

ifneq ($(OBJTREE),$(SRCTREE))
obj := $(OBJTREE)/
src := $(SRCTREE)/
else
obj :=
src :=
endif
export obj src

ifeq ($(obj)include/config.mk,$(wildcard $(obj)include/config.mk))
# load ARCH, BOARD, and CPU configuration
include $(obj)include/config.mk
export ARCH CPU BOARD VENDOR SOC

ifndef CROSS_COMPILE
ifeq ($(ARCH),arm)
CROSS_COMPILE = arm-linux-
endif
endif

export CROSS_COMPILE

# load other configuration
include $(TOPDIR)/config.mk

OBJS = cpu/$(CPU)/start.o

OBJS := $(addprefix $(obj),$(OBJS))

#LIBS = lib_generic/libgeneric.a
LIBS += cpu/$(CPU)/lib$(CPU).a
LIBS += lib_$(ARCH)/lib$(ARCH).a

LIBS := $(addprefix $(obj),$(LIBS))

LIBBOARD = board/$(BOARDDIR)/lib$(BOARD).a
LIBBOARD := $(addprefix $(obj),$(LIBBOARD))

__OBJS := $(subst $(obj),,$(OBJS))
__LIBS := $(subst $(obj),,$(LIBS)) $(subst $(obj),,$(LIBBOARD))

#######################################################
ALL += $(obj)c-boot.bin $(obj)c-boot.dis

all:		$(ALL)

c-boot.bin:	c-boot
	$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

c-boot.dis: c-boot
	$(OBJDUMP) -d $< > $@

c-boot:  $(OBJS) $(LIBBOARD) $(LIBS) 
	cd $(LNDIR) && $(LD) $(LDFLAGS) $(__OBJS) \
		--start-group $(__LIBS) --end-group \
	-Map c-boot.map -o c-boot

$(OBJS):
	$(MAKE) -C cpu/$(CPU) $(notdir $@)
$(LIBS):
	$(MAKE) -C $(dir $(subst $(obj),,$@))
$(LIBBOARD):
	$(MAKE) -C $(dir $(subst $(obj),,$@))

endif

unconfig:
	@rm -f $(obj)include/config.h $(obj)include/config.mk \
		$(obj)board/*/config.tmp $(obj)board/*/*/config.tmp \
		$(obj)include/autoconf.mk $(obj)include/autoconf.mk.dep 

fl2440_config:	unconfig
	@$(MKCONFIG) $(@:_config=) arm arm920t fl2440 NULL s3c24x0

clean:
	@find $(OBJTREE) -type f \
		\( -name 'core' -o -name '*.bak' -o -name '*~' \
		-o -name '*.o' -o -name '*.a' \) -print \
		| xargs rm -f

clobber:	clean
	@find $(OBJTREE) -type f \( -name .depend \
		-o -name '*.srec' -o -name '*.bin' -o -name c-boot.img \) \
		-print0 \
		| xargs -0 rm -f
	@rm -f $(OBJS) $(obj)*.bak $(obj)ctags $(obj)etags $(obj)TAGS \
		$(obj)cscope.* $(obj)*.*~
	@rm -f $(obj)c-boot $(obj)c-boot.map $(obj)c-boot.hex $(ALL)
	@rm -f $(obj)include/asm/proc $(obj)include/asm/arch $(obj)include/asm
	@[ ! -d $(obj)nand_spl ] || find $(obj)nand_spl -lname "*" -print | xargs rm -f
	@[ ! -d $(obj)onenand_ipl ] || find $(obj)onenand_ipl -lname "*" -print | xargs rm -f
	@[ ! -d $(obj)api_examples ] || find $(obj)api_examples -lname "*" -print | xargs rm -f

mrproper \
distclean:	clobber unconfig

##########test#######################
testboard:
	echo $(BOARD)
testwildcard:
	echo $(wildcard $(obj)inlcude/config.mk)
testlibs:
	make -C $(dir cpu/arm920t/libarm920t.a)

test:	haha
	echo $(CURDIR) $< $@

haha: 
	echo "I am here!"

doub \
line:
	echo "doub line"

testpanduan:
	@[ ! -d $(obj)nand_spl ] || echo "$(obj)nand_spl exist"
