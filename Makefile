# SPDX-License-Identifier: CC-BY-4.0
#
# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
SOURCEDIR     = source
BUILDDIR      = build
LATEXDIFF     = latexdiff

all: latexpdf html

help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
	@echo "  latexdiff   to make LaTeX files including changebars against previous release"

.PHONY: all help latexdiff Makefile

latexdiff: latex
	@echo "Generating LaTeX changebars..."
	$(LATEXDIFF) --type=UNDERLINE --config VERBATIMENV=sphinxVerbatim \
		$(BUILDDIR)/latex-previous/sbom-specification.tex \
		$(BUILDDIR)/latex/sbom-specification.tex \
		> $(BUILDDIR)/latex/sbom-specification-changebars.tex
	@echo "Running LaTeX files through pdflatex..."
	$(MAKE) -C $(BUILDDIR)/latex all-pdf
	@echo
	@echo "latexdiff finished; the PDF files are in $(BUILDDIR)/latex."

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
