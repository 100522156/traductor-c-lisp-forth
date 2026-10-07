int area_rectangulo (int base, int altura) {
    int superficie;
    superficie = base * altura;
    return superficie;
}

main () {
    int b = 8;
    int h = 3;
    printf("%s %d", "Area:", area_rectangulo(b, h));
}
//@ (main)
