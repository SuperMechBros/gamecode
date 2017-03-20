CPP := cc -xc -E
QCC ?= gmqcc

PROGS_OUT ?= $(CURDIR)/..
WORKDIR ?= ../.tmp

QCCFLAGS_WATERMARK ?= $(shell git describe --tags --dirty='~')
VER = $(subst *,\*,$(QCCFLAGS_WATERMARK))
NDEBUG ?= 1
XONOTIC ?= 1
BUILD_MOD ?=

# We eventually need to get rid of these
QCCFLAGS_WTFS ?= \
	-Wno-field-redeclared

QCCDEFS ?= \
	-DXONOTIC=$(XONOTIC) \
	-DWATERMARK="$(QCCFLAGS_WATERMARK)" \
	-DNDEBUG=$(NDEBUG) \
	$(if $(BUILD_MOD), -DBUILD_MOD="$(BUILD_MOD)" -I$(BUILD_MOD), ) \
	$(QCCDEFS_EXTRA)

# -Ooverlap-locals is required
QCCFLAGS ?= \
	-std=gmqcc \
	-Ooverlap-locals \
	-O3 \
	-Werror -Wall \
	$(QCCFLAGS_WTFS) \
	-flno -futf8 -fno-bail-on-werror \
	-frelaxed-switch -freturn-assignments \
	$(QCCFLAGS_EXTRA)



.PHONY: all
all: qc

$(WORKDIR):
	@mkdir -p $@

.PHONY: clean
clean: | $(WORKDIR)
	$(RM) $(PROGS_OUT)/csprogs.dat
	$(RM) $(PROGS_OUT)/menu.dat
	$(RM) $(PROGS_OUT)/progs.dat
	$(RM) $(WORKDIR)/*.d
	$(RM) $(WORKDIR)/*.qc
	$(RM) $(WORKDIR)/*.txt

.PHONY: qc
qc: $(PROGS_OUT)/csprogs.dat $(PROGS_OUT)/menu.dat $(PROGS_OUT)/progs.dat




QCCVERSION := $(shell cd lib && $(QCC) --version)
QCCVERSIONFILE := $(WORKDIR)/qccversion.$(shell echo ${QCCVERSION} | git hash-object --stdin)
$(QCCVERSIONFILE): | $(WORKDIR)
	@ $(RM) $(WORKDIR)/qccversion.*
	@ echo $(QCCVERSION) > $@

export WORKDIR
export CPP
export QCC
export QCCDEFS
export QCCFLAGS

$(PROGS_OUT)/csprogs.dat: client/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/client\'
	@ ./tools/qcc.sh client $@ $<
-include $(WORKDIR)/client.d

$(PROGS_OUT)/progs.dat: server/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/server\'
	@ ./tools/qcc.sh server $@ $<
-include $(WORKDIR)/server.d

$(PROGS_OUT)/menu.dat: menu/progs.inc $(QCCVERSIONFILE) | $(WORKDIR)
	@ echo make[1]: Entering directory \`$(CURDIR)/menu\'
	@ ./tools/qcc.sh menu $@ $<
-include $(WORKDIR)/menu.d
