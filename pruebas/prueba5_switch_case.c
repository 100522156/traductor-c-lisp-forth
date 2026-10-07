main () {
    int estado = 404;
    
    switch (estado) {
        case 200:
            puts("OK");
            break;
        case 404:
            puts("No encontrado");
            break;
        case 500:
            puts("Error de servidor");
            break;
        default:
            puts("Desconocido");
            break;
    }
}
//@ (main)
