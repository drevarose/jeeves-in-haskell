# Makefile.

jeeves-constraints.pdf: jeeves-constraints.lhs format.tex jeeves.bib
	cp jeeves-constraints.lhs jeeves-constraints-tmp.tex
	pdflatex jeeves-constraints-tmp
	bibtex jeeves-constraints-tmp
	pdflatex jeeves-constraints-tmp
	makeindex jeeves-constraints-tmp
	pdflatex jeeves-constraints-tmp
	pdflatex jeeves-constraints-tmp
	rm jeeves-constraints-tmp.tex
	mv jeeves-constraints-tmp.pdf jeeves-constraints.pdf

clean:
	rm *-tmp.*
