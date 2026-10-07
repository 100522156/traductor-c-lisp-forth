int n = 5, suma = 0;

main () {
    while (n > 0) {
        if (n % 2 == 0) {
            puts("Es par");
            suma = suma + n;
        } else {
            puts("Es impar");
        }
        n = n - 1;
    }
}
//@ (main)
