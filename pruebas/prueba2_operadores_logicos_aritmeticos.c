int val1 = 20, val2 = 3, resultado;

main () {
    resultado = (val1 != val2) && (val1 % val2 == 2);
    printf("%d", resultado);
    resultado = !resultado || (val1 <= 15);
    printf("%d", resultado);
}
//@ (main)
