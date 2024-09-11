SHELL := /usr/bin/env bash

# This is the meta makefile included in all slides it is a modified variant of a standard makefile which i've used for several years.
# therefore it may contain some dead code and cleanups

SLIDES_TEX             := $(shell ls source_*.tex)
# [bad but psst] mass-aware present-check https://unix.stackexchange.com/questions/79301/test-if-there-are-files-matching-a-pattern-in-order-to-execute-a-script#79304
DEPENDENCIES           := ${SLIDES_TEX} data/preamble.tex $(shell compgen -G "*.java" > /dev/null && ls *.java) $(shell compgen -G "*.bib" > /dev/null && ls *.bib)
# for each 'source_*' we create n pdf versions which will be prepared here
SLIDES_BASE            := $(basename $(SLIDES_TEX:source_%=%))
SLIDES_VARIANTS_NOANIM := $(addprefix noanim_, ${SLIDES_BASE})
SLIDES_VARIANTS_ALL    := ${SLIDES_VARIANTS_NOANIM} ${SLIDES_BASE} # $(addsuffix -dark,${SLIDES_VARIANTS_NOANIM})
SLIDESPDF              := $(addsuffix .pdf,${SLIDES_VARIANTS_ALL})
CLEANTARGETS           := log aux out ind bbl blg lof lot toc idx acn acr alg glg glo gls fls fdb_latexmk auxlock md5 SATZE ZSM UB TOP listing upa ilg TOPIC DEFS vrb snm nav atfi run.xml bcf

# used internally for rule reuse
__FILENAME    := ""
__FILECONTENT := ""

.PHONY = all compile clean produce docker

all: compile clean

compile: ${SLIDESPDF}
	@echo Built the pdfs: ${SLIDESPDF}

# for each pdf we set the filename similarly
%.pdf: __FILENAME = $(addsuffix .tex, $(basename $@))

# noanim_noannot_%.pdf: __FILECONTENT = \\PassOptionsToClass{handout}{beamer}\\PassOptionsToPackage{disable}{beamer-latex-pdfpc-notes}\\input{source_$*.tex}
# noanim_noannot_%.pdf: ${DEPENDENCIES}
# 	$(produce)

# this are mere wrapper rules to be used with the common producer below
# with $* we get the stem (whatever the '%' did expand to)
noanim_%.pdf: __FILECONTENT = \\PassOptionsToClass{handout}{beamer}\\input{source_$*.tex}
noanim_%.pdf: ${DEPENDENCIES}
	$(produce)

# specified below so it does not trigger the others
%.pdf: __FILECONTENT = \\input{source_$*.tex}
%.pdf: ${DEPENDENCIES}
	$(produce)

# byusing define we can use target-specific variables :D
# we only make use of temporary files to do not clutter
define produce
	echo "${__FILECONTENT}" > "${__FILENAME}"
	latexmk "${__FILENAME}"
	rm "${__FILENAME}"
endef

clean:
	for fd in $(CLEANTARGETS); do rm -f *.$$fd; done

docker:
	docker build --pull --tag 'presentation-builder' --file 'Dockerfile' .

ifeq (${VERBOSE},0)
MAKEFLAGS += --silent
# Better than defining '.SILENT'
endif