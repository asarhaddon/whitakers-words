# Makefile for Whitaker's words

GPRBUILD                                := gprbuild
GPRBUILD_OPTIONS                        := -j4

# Build flags are commonly found in the environment, but if they are
# set on our Make command line, forward them to GNAT projects.
export ADAFLAGS                         ?=
export LDFLAGS                          ?=

# For the library, a static archive is built by default but a
# non-empty shared object version selects a relocatable library
export latin_utils_soversion            :=

# Directory where dictionnary files are created and searched for.
# This variable is expected to be overridden at build time, with some
# architecture-specific value like $(prefix)/share/whitakers-words).
# At run time, another directory can be selected via the
# WHITAKERS_WORDS_DATADIR environment variable.
datadir                                 := .
# During (re)builds, the tools must read and test the fresh data and
# ignore any previous version already installed in $(datadir).
export WHITAKERS_WORDS_DATADIR := .

# If a relocatable library has been selected, tell the dynamic loader
# where to find it during tests or generation of the dictionaries.
ifneq (,$(latin_utils_soversion))
  export LD_LIBRARY_PATH := $(if $(LD_LIBRARY_PATH),$(LD_LIBRARY_PATH):)lib/latin_utils-dynamic
endif

generated_sources := src/latin_utils/latin_utils-config.adb

# It is convenient to let gprbuild deal with Ada dependencies, and
# only then let a submake decide which data must be refreshed
# according to the now up-to-date timestamps of the generators.
.PHONY: all
all: commands
	$(MAKE) -f Makefile.data.mk

# This target is more efficient than separate gprbuild runs because
# the dependency graph is only constructed once.
# It is run either because by an explicit 'commands' target, or
# because a generated file requires it.
.PHONY: commands
commands: $(generated_sources)
	$(GPRBUILD) -p $(GPRBUILD_OPTIONS) commands.gpr

.PHONY: clean
clean:
	$(MAKE) -f Makefile.data.mk $@
	rm -fr bin lib obj
	rm -f $(generated_sources)

$(generated_sources): %: %.in Makefile
	sed 's|@datadir@|$(datadir)|' $< > $@

.PHONY: test
test: all
	cd test && ./run-tests.sh
