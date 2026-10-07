# bison genera el .c y gcc lo compila; -w porque el esqueleto del profesor usa C K&R
all: trad back

trad: src/trad.y
	bison -o trad.c src/trad.y
	gcc -w -o trad trad.c

back: src/back.y
	bison -o back.c src/back.y
	gcc -w -o back back.c

# pasa todas las pruebas por el frontend
test: trad
	@for f in pruebas/*.c; do echo "== $$f"; ./trad < $$f; done

clean:
	rm -f trad back trad.c back.c

.PHONY: all test clean