
.SUFFIXES: .css .styl .md .html

all: style.css index.html

%.css: %.less
	lessc $< > $@

%.html: %.md header.html footer.html
	cat header.html  > $@
	markdown $<     >> $@
	cat footer.html >> $@

clean:
	rm -f style.css index.html
