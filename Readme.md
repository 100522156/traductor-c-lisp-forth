# Traductor C → Lisp → Forth

Procesador de lenguaje en dos fases hecho con Bison para la asignatura
Procesadores del Lenguaje (UC3M, 2025-26). Nota: 8.

- **Frontend (`src/trad.y`)**: traduce un subconjunto de C (variables globales y locales,
  funciones con parámetros y return, while, for, if/else, switch, arrays, printf/puts) a Common Lisp.
- **Backend (`src/back.y`)**: traduce el Lisp resultante a Forth (notación postfija).

La memoria completa está en [`docs/memoria.pdf`](docs/memoria.pdf).

## Requisitos
`bison`, `gcc` y, para ejecutar lo generado, `sbcl` (Lisp) y `gforth` (Forth).

## Uso
```bash
make            # compila trad y back
make test       # pasa las pruebas de pruebas/ por el frontend

./trad < pruebas/prueba3_estructuras_basicas_if_while.c > p3.lisp
sbcl --script p3.lisp
./back < p3.lisp > p3.fs && gforth p3.fs -e bye
```

## Autores
Miguel Merino Sánchez · Pablo García Aparicio

El esqueleto del analizador léxico (`yylex`) lo proporcionó el profesorado de la asignatura.