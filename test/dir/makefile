
all: index.html

index.html: index.txt
	sed -e 's/FOO/Hello, world!/' $< > $@

clean:
	rm -f index.html
