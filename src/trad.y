/*
     409, Pablo Garcia Aparicio, Miguel Merino Sanchez
     100522190@alumnos.uc3m.es, 100522156@alumnos.uc3m.es
*/
%{                          // SECCION 1 Declaraciones de C-Yacc

#include <stdio.h>
#include <ctype.h>            // declaraciones para tolower
#include <string.h>           // declaraciones para cadenas
#include <stdlib.h>           // declaraciones para exit ()

#define FF fflush(stdout);    // para forzar la impresion inmediata

int yylex () ;
int yyerror () ;
char *mi_malloc (int) ;
char *gen_code (char *) ;
char *int_to_string (int) ;
char *char_to_string (char) ;

char temp [2048] ;

// Abstract Syntax Tree (AST) Node Structure

typedef struct ASTnode t_node ;

struct ASTnode {
    char *op ;
    int type ;      // leaf, unary or binary nodes
    t_node *left ;
    t_node *right ;
} ;

// Definitions for explicit attributes

typedef struct s_attr {
    int value ;    // - Numeric value of a NUMBER 
    char *code ;   // - to pass IDENTIFIER names, and other translations 
    t_node *node ; // - for possible future use of AST
} t_attr ;

#define YYSTYPE t_attr

char *tabla_local[256]; // guardamos aqui las variables locales para no liarnos con las globales
int n_local = 0;

char nombre_funcion_actual[256] = "";

void insertar_local(char *nombre) {
    tabla_local[n_local++] = gen_code(nombre);
}

int es_local(char *nombre) {
    int i;
    for (i = 0; i < n_local; i++)
        if (strcmp(tabla_local[i], nombre) == 0) return 1;
    return 0;
}

%}

// Definitions for explicit attributes

%token NUMBER        
%token IDENTIF       // Identificador=variable
%token INTEGER       // identifica el tipo entero
%token STRING
%token MAIN          // identifica el comienzo del proc. main
%token WHILE         // identifica el bucle main
%token FOR
%token INC
%token DEC
%token PRINTF
%token PUTS
%token AND
%token OR
%token NOT_EQ
%token EQ
%token LEQ
%token GEQ
%token IF
%token ELSE
%token SWITCH
%token CASE
%token DEFAULT
%token BREAK
%token RETURN

%right '='                    // es la ultima operacion que se debe realizar
%left AND OR
%left '!'
%left NOT_EQ EQ
%left '<' '>' LEQ GEQ
%left '+' '-'                 // menor orden de precedencia
%left '*' '/' '%'             // orden de precedencia intermedio
%left UNARY_SIGN              // mayor orden de precedencia

%%                            // Seccion 3 Gramatica - Semantico

axioma: declaraciones_y_funciones funcion_main ;

declaraciones_y_funciones:
        /* vacio */
    |   declaraciones_y_funciones declaracion
    |   declaraciones_y_funciones funcion_usuario
    ;

declaracion:
        INTEGER lista_ids ';'
        { printf("%s", $2.code); }
    ;

lista_ids:
                IDENTIF {
                    sprintf (temp, "(setq %s 0)\n", $1.code);
                    $$.code = gen_code (temp);
                }
            |   IDENTIF '=' NUMBER {
                    sprintf (temp, "(setq %s %d)\n", $1.code, $3.value);
                    $$.code = gen_code (temp);
                }
            |   lista_ids ',' IDENTIF {
                    sprintf (temp, "%s(setq %s 0)\n", $1.code, $3.code);
                    $$.code = gen_code (temp);
                }
            |   lista_ids ',' IDENTIF '=' NUMBER {
                    sprintf (temp, "%s(setq %s %d)\n", $1.code, $3.code, $5.value);
                    $$.code = gen_code (temp);
                }
            |   IDENTIF '[' NUMBER ']' { // lo creamos con make-array como pide el pdf
                    sprintf (temp, "(setq %s (make-array %d))\n", $1.code, $3.value);
                    $$.code = gen_code (temp);
                }
            |   lista_ids ',' IDENTIF '[' NUMBER ']' {
                    sprintf (temp, "%s(setq %s (make-array %d))\n", $1.code, $3.code, $5.value);
                    $$.code = gen_code (temp);
                }
            ;

lista_ids_local:
                IDENTIF { // metemos el nombre de la funcion delante para que no choque con globales
                    insertar_local($1.code);
                    sprintf (temp, "(setq %s_%s 0)\n", nombre_funcion_actual, $1.code);
                    $$.code = gen_code (temp);
                }
            |   IDENTIF '=' NUMBER {
                    insertar_local($1.code);
                    sprintf (temp, "(setq %s_%s %d)\n", nombre_funcion_actual, $1.code, $3.value);
                    $$.code = gen_code (temp);
                }
            |   lista_ids_local ',' IDENTIF {
                    insertar_local($3.code);
                    sprintf (temp, "%s(setq %s_%s 0)\n", $1.code, nombre_funcion_actual, $3.code);
                    $$.code = gen_code (temp);
                }
            |   lista_ids_local ',' IDENTIF '=' NUMBER {
                    insertar_local($3.code);
                    sprintf (temp, "%s(setq %s_%s %d)\n", $1.code, nombre_funcion_actual, $3.code, $5.value);
                    $$.code = gen_code (temp);
                }
            |   IDENTIF '[' NUMBER ']' {
                    insertar_local($1.code);
                    sprintf (temp, "(setq %s_%s (make-array %d))\n", nombre_funcion_actual, $1.code, $3.value);
                    $$.code = gen_code (temp);
                }
            |   lista_ids_local ',' IDENTIF '[' NUMBER ']' {
                    insertar_local($3.code);
                    sprintf (temp, "%s(setq %s_%s (make-array %d))\n", $1.code, nombre_funcion_actual, $3.code, $5.value);
                    $$.code = gen_code (temp);
                }
            ;

lista_params:
        INTEGER IDENTIF
        {
            insertar_local($2.code);
            sprintf(temp, "%s", $2.code);
            $$.code = gen_code(temp);
        }
    |   lista_params ',' INTEGER IDENTIF
        {
            insertar_local($4.code);
            sprintf(temp, "%s %s", $1.code, $4.code);
            $$.code = gen_code(temp);
        }
    ;

lista_args:
        expresion
        {
            sprintf(temp, "%s", $1.code);
            $$.code = gen_code(temp);
        }
    |   lista_args ',' expresion
        {
            sprintf(temp, "%s %s", $1.code, $3.code);
            $$.code = gen_code(temp);
        }
    ;

funcion_usuario:
        IDENTIF '(' ')' '{' { n_local = 0; // vaciamos la tabla de locales al empezar una funcion nueva
        strcpy(nombre_funcion_actual, $1.code); } lista_sentencias '}'
        {
            sprintf(temp, "(defun %s ()\n%s)\n", $1.code, $6.code);
            printf("%s", temp);
        }
    |   IDENTIF '(' lista_params ')' '{' { n_local = 0; strcpy(nombre_funcion_actual, $1.code);
        } lista_sentencias '}'
        {
            sprintf(temp, "(defun %s (%s)\n%s)\n", $1.code, $3.code, $7.code);
            printf("%s", temp);
        }
    |   INTEGER IDENTIF '(' ')' '{' { n_local = 0;
        strcpy(nombre_funcion_actual, $2.code); } lista_sentencias '}'
        {
            sprintf(temp, "(defun %s ()\n%s)\n", $2.code, $7.code);
            printf("%s", temp);
        }
    |   INTEGER IDENTIF '(' lista_params ')' '{' { n_local = 0; strcpy(nombre_funcion_actual, $2.code);
        } lista_sentencias '}'
        {
            sprintf(temp, "(defun %s (%s)\n%s)\n", $2.code, $4.code, $8.code);
            printf("%s", temp);
        }
    ;

funcion_main:
        MAIN '(' ')' '{' { n_local = 0; strcpy(nombre_funcion_actual, "main"); } lista_sentencias '}'
        {
            sprintf(temp, "(defun main ()\n%s)\n", $6.code);
            $$.code = gen_code(temp);
            printf("%s", $$.code);
        }
;

inc_dec:
        INC '(' IDENTIF ')'
        {
            if (es_local($3.code))
                sprintf(temp, "(setf %s_%s (+ %s_%s 1))\n", nombre_funcion_actual, $3.code, nombre_funcion_actual, $3.code);
            else
                sprintf(temp, "(setf %s (+ %s 1))\n", $3.code, $3.code);
            $$.code = gen_code(temp);
        }
    |   DEC '(' IDENTIF ')'
        {
            if (es_local($3.code))
                sprintf(temp, "(setf %s_%s (- %s_%s 1))\n", nombre_funcion_actual, $3.code, nombre_funcion_actual, $3.code);
            else
                sprintf(temp, "(setf %s (- %s 1))\n", $3.code, $3.code);
            $$.code = gen_code(temp);
        }
    ;

lista_casos:
        CASE NUMBER ':' lista_sentencias BREAK ';'
        {
            sprintf(temp, "(%d %s)", $2.value, $4.code);
            $$.code = gen_code(temp);
        }
    |   lista_casos CASE NUMBER ':' lista_sentencias BREAK ';'
        {
            sprintf(temp, "%s(%d %s)", $1.code, $3.value, $5.code);
            $$.code = gen_code(temp);
        }
    |   lista_casos DEFAULT ':' lista_sentencias BREAK ';'
        {
            sprintf(temp, "%s(otherwise %s)", $1.code, $4.code);
            $$.code = gen_code(temp);
        }
    ;

lista_sentencias:
        sentencia ';'
        {
            sprintf(temp, "%s\n", $1.code);
            $$.code = gen_code(temp);
        }
    |   INTEGER lista_ids_local ';'
        {
            sprintf(temp, "%s", $2.code);
            $$.code = gen_code(temp);
        }
    |   WHILE '(' expresion ')' '{' lista_sentencias '}'
        {
            sprintf(temp, "(loop while %s do\n%s)\n", $3.code, $6.code);
            $$.code = gen_code(temp);
        }
    |   FOR '(' IDENTIF '=' expresion ';' expresion ';' inc_dec ')' '{' lista_sentencias '}'
        {
            if (es_local($3.code)) // inicializamos antes del bucle y el incremento va al final del bloque
                sprintf(temp, "(setf %s_%s %s)\n(loop while %s do\n%s%s)\n", nombre_funcion_actual, $3.code, $5.code, $7.code, $12.code, $9.code);
            else
                sprintf(temp, "(setf %s %s)\n(loop while %s do\n%s%s)\n", $3.code, $5.code, $7.code, $12.code, $9.code);
            $$.code = gen_code(temp);
        }
    |   IF '(' expresion ')' '{' lista_sentencias '}'
        {
            // metemos un progn porque el if de lisp necesita agrupar sentencias si hay varias
            sprintf(temp, "(if %s\n(progn\n%s))\n", $3.code, $6.code);
            $$.code = gen_code(temp);
        }
    |   IF '(' expresion ')' '{' lista_sentencias '}' ELSE '{' lista_sentencias '}'
        {
            sprintf(temp, "(if %s\n(progn\n%s)\n(progn\n%s))\n", $3.code, $6.code, $10.code);
            $$.code = gen_code(temp);
        }
    |   SWITCH '(' IDENTIF ')' '{' lista_casos '}'
        {
            char var_name[512];
            if (es_local($3.code)) // pillamos el nombre con prefijo si es local para que el case funcione bien
                sprintf(var_name, "%s_%s", nombre_funcion_actual, $3.code);
            else
                sprintf(var_name, "%s", $3.code);
            sprintf(temp, "(case %s\n%s)\n", var_name, $6.code);
            $$.code = gen_code(temp);
        }
    |   lista_sentencias sentencia ';'
        {
            sprintf(temp, "%s%s\n", $1.code, $2.code);
            $$.code = gen_code(temp);
        }
    |   lista_sentencias INTEGER lista_ids_local ';'
        {
            sprintf(temp, "%s%s", $1.code, $3.code);
            $$.code = gen_code(temp);
        }
    |   lista_sentencias WHILE '(' expresion ')' '{' lista_sentencias '}'
        {
            sprintf(temp, "%s(loop while %s do\n%s)\n", $1.code, $4.code, $7.code);
            $$.code = gen_code(temp);
        }
    |   lista_sentencias FOR '(' IDENTIF '=' expresion ';' expresion ';' inc_dec ')' '{' lista_sentencias '}'
        {
            if (es_local($4.code))
                sprintf(temp, "%s(setf %s_%s %s)\n(loop while %s do\n%s%s)\n", $1.code, nombre_funcion_actual, $4.code, $6.code, $8.code, $13.code, $10.code);
            else
                sprintf(temp, "%s(setf %s %s)\n(loop while %s do\n%s%s)\n", $1.code, $4.code, $6.code, $8.code, $13.code, $10.code);
            $$.code = gen_code(temp);
        }
    |   lista_sentencias IF '(' expresion ')' '{' lista_sentencias '}'
        {
            sprintf(temp, "%s(if %s\n(progn\n%s))\n", $1.code, $4.code, $7.code);
            $$.code = gen_code(temp);
        }
    |   lista_sentencias IF '(' expresion ')' '{' lista_sentencias '}' ELSE '{' lista_sentencias '}'
        {
            sprintf(temp, "%s(if %s\n(progn\n%s)\n(progn\n%s))\n", $1.code, $4.code, $7.code, $11.code);
            $$.code = gen_code(temp);
        }
    |   lista_sentencias SWITCH '(' IDENTIF ')' '{' lista_casos '}'
        {
            char var_name[512];
            if (es_local($4.code))
                sprintf(var_name, "%s_%s", nombre_funcion_actual, $4.code);
            else
                sprintf(var_name, "%s", $4.code);
            sprintf(temp, "%s(case %s\n%s)\n", $1.code, var_name, $7.code);
            $$.code = gen_code(temp);
        }
;

sentencia:
              IDENTIF '=' expresion      {
                                           if (es_local($1.code))
                                               sprintf (temp, "(setf %s_%s %s)", nombre_funcion_actual, $1.code, $3.code) ;
                                           else
                                               sprintf (temp, "(setf %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | '@' expresion              { sprintf (temp, "(print %s)", $2.code) ;  
                                           $$.code = gen_code (temp) ; }
            | inc_dec
                {
                    $$.code = $1.code;
                }
            | RETURN expresion
                {
                    sprintf(temp, "(return-from %s %s)", nombre_funcion_actual, $2.code);
                    $$.code = gen_code(temp);
                }
            | IDENTIF '(' ')'
                {
                    sprintf(temp, "(%s)", $1.code);
                    $$.code = gen_code(temp);
                }
            | IDENTIF '(' lista_args ')'
                {
                    sprintf(temp, "(%s %s)", $1.code, $3.code);
                    $$.code = gen_code(temp);
                }
            | PRINTF '(' STRING ')'
            {
                $$.code = gen_code(""); // ignoramos la cadena de formato como pide el enunciado
            }
            | PRINTF '(' STRING ',' lista_exprs ')'
            {
                sprintf(temp, "%s", $5.code);
                $$.code = gen_code(temp);
            }
            | PUTS '(' STRING ')'
            {
                sprintf(temp, "(print \"%s\")", $3.code);
                $$.code = gen_code(temp);
            }
            | IDENTIF '[' expresion ']' '=' expresion
                {
                    if (es_local($1.code))
                        sprintf(temp, "(setf (aref %s_%s %s) %s)", nombre_funcion_actual, $1.code, $3.code, $6.code);
                    else
                        sprintf(temp, "(setf (aref %s %s) %s)", $1.code, $3.code, $6.code);
                    $$.code = gen_code(temp);
                }
            ;

lista_exprs:
        expresion
        {
            sprintf(temp, "(princ %s)", $1.code);
            $$.code = gen_code(temp);
        }
    |   STRING
        {
            sprintf(temp, "(princ \"%s\")", $1.code);
            $$.code = gen_code(temp);
        }
    |   lista_exprs ',' expresion
        {
            sprintf(temp, "%s(princ %s)", $1.code, $3.code);
            $$.code = gen_code(temp);
        }
    |   lista_exprs ',' STRING
        {
            sprintf(temp, "%s(princ \"%s\")", $1.code, $3.code);
            $$.code = gen_code(temp);
        }
;

expresion:
              termino                  { $$ = $1 ; }
            | expresion '+' expresion  { sprintf (temp, "(+ %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion '-' expresion  { sprintf (temp, "(- %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion '*' expresion  { sprintf (temp, "(* %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion '/' expresion  { sprintf (temp, "(/ %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion '%' expresion  { sprintf (temp, "(mod %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion AND expresion  { sprintf (temp, "(and %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion OR expresion   { sprintf (temp, "(or %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | '!' expresion            { sprintf (temp, "(not %s)", $2.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion NOT_EQ expresion { sprintf (temp, "(/= %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion EQ expresion   { sprintf (temp, "(= %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion '<' expresion  { sprintf (temp, "(< %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion '>' expresion  { sprintf (temp, "(> %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion LEQ expresion  { sprintf (temp, "(<= %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            | expresion GEQ expresion  { sprintf (temp, "(>= %s %s)", $1.code, $3.code) ;
                                           $$.code = gen_code (temp) ; }
            ;

termino:
              operando                           { $$ = $1 ; }                         
            | '+' operando %prec UNARY_SIGN      { $$ = $2 ; }
            | '-' operando %prec UNARY_SIGN      { sprintf (temp, "(- %s)", $2.code) ;
                                                     $$.code = gen_code (temp) ; }    
            ;

operando:
              IDENTIF                  {
                                           if (es_local($1.code))
                                               sprintf (temp, "%s_%s", nombre_funcion_actual, $1.code) ;
                                           else
                                               sprintf (temp, "%s", $1.code) ;
                                           $$.code = gen_code (temp) ; }
            | NUMBER                   { sprintf (temp, "%d", $1.value) ;
                                           $$.code = gen_code (temp) ; }
            | '(' expresion ')'        { $$ = $2 ; }
            | IDENTIF '(' ')'
                {
                    sprintf(temp, "(%s)", $1.code);
                    $$.code = gen_code(temp);
                }
            | IDENTIF '(' lista_args ')'
                {
                    sprintf(temp, "(%s %s)", $1.code, $3.code);
                    $$.code = gen_code(temp);
                }
            | IDENTIF '[' expresion ']'
                {
                    if (es_local($1.code)) // usamos aref para acceder a los elementos del array
                        sprintf(temp, "(aref %s_%s %s)", nombre_funcion_actual, $1.code, $3.code);
                    else
                        sprintf(temp, "(aref %s %s)", $1.code, $3.code);
                    $$.code = gen_code(temp);
                }
            ;

%%                            // SECCION 4   Codigo en C

int n_line = 1 ;

int yyerror (mensaje)
char *mensaje ;
{
    fprintf (stderr, "%s en la linea %d\n", mensaje, n_line) ;
    printf ( "\n") ;    // bye
}

char *int_to_string (int n)
{
    char ltemp [2048] ;

    sprintf (ltemp, "%d", n) ;

    return gen_code (ltemp) ;
}

char *char_to_string (char c)
{
    char ltemp [2048] ;

    sprintf (ltemp, "%c", c) ;

    return gen_code (ltemp) ;
}

char *my_malloc (int nbytes)       // reserva n bytes de memoria dinamica
{
    char *p ;
    static long int nb = 0;        // sirven para contabilizar la memoria
    static int nv = 0 ;            // solicitada en total

    p = malloc (nbytes) ;
    if (p == NULL) {
        fprintf (stderr, "No queda memoria para %d bytes mas\n", nbytes) ;
        fprintf (stderr, "Reservados %ld bytes en %d llamadas\n", nb, nv) ;
        exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;

    return p ;
}


/***************************************************************************/
/********************** Seccion de Palabras Reservadas *********************/
/***************************************************************************/

typedef struct s_keyword { // para las palabras reservadas de C
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = { // define las palabras reservadas y los
    "main",        MAIN,           // y los token asociados
    "int",         INTEGER,
    "printf",      PRINTF,
    "puts",        PUTS,
    "while",       WHILE,
    "for",         FOR,
    "inc",         INC,
    "dec",         DEC,
    "if",          IF,
    "else",        ELSE,
    "switch",      SWITCH,
    "case",        CASE,
    "default",     DEFAULT,
    "break",       BREAK,
    "return",      RETURN,
    "&&",          AND,
    "||",          OR,
    "!=",          NOT_EQ,
    "==",          EQ,
    "<=",          LEQ,
    ">=",          GEQ,
    NULL,          0               // para marcar el fin de la tabla
} ;

t_keyword *search_keyword (char *symbol_name)
{                                  // Busca n_s en la tabla de pal. res.
                                   // y devuelve puntero a registro (simbolo)
    int i ;
    t_keyword *sim ;

    i = 0 ;
    sim = keywords ;
    while (sim [i].name != NULL) {
        if (strcmp (sim [i].name, symbol_name) == 0) {
                                     // strcmp(a, b) devuelve == 0 si a==b
            return &(sim [i]) ;
        }
        i++ ;
    }

    return NULL ;
}


/***************************************************************************/
/******************* Seccion del Analizador Lexicografico ******************/
/***************************************************************************/

char *gen_code (char *name)     // copia el argumento a un
{                                      // string en memoria dinamica
    char *p ;
    int l ;

    l = strlen (name)+1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;

    return p ;
}


int yylex ()
{
// NO MODIFICAR ESTA FUNCION SIN PERMISO
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char ops_expandibles [] = "!<=|>%&/+-*" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do {
        c = getchar () ;

        if (c == '#') { // Ignora las lineas que empiezan por #  (#define, #include)
            do {        //  OJO que puede funcionar mal si una linea contiene #
                c = getchar () ;
            } while (c != '\n') ;
        }

        if (c == '/') { // Si la linea contiene un / puede ser inicio de comentario
            cc = getchar () ;
            if (cc != '/') {   // Si el siguiente char es /  es un comentario, pero...
                ungetc (cc, stdin) ;
            } else {
                c = getchar () ;    // ...
                if (c == '@') { // Si es la secuencia //@  ==> transcribimos la linea
                    do {        // Se trata de codigo inline (Codigo embebido en C)
                        c = getchar () ;
                        putchar (c) ;
                    } while (c != '\n') ;
                } else {        // ==> comentario, ignorar la linea
                    while (c != '\n') {
                        c = getchar () ;
                    }
                }
            }
        } else if (c == '\\') c = getchar () ;

        if (c == '\n')
            n_line++ ;

    } while (c == ' ' || c == '\n' || c == 10 || c == 13 || c == '\t') ;

    if (c == '\"') {
        i = 0 ;
        do {
            c = getchar () ;
            temp_str [i++] = c ;
        } while (c != '\"' && i < 255) ;
        if (i == 256) {
            printf ("AVISO: string con mas de 255 caracteres en linea %d\n", n_line) ;
        }           // habria que leer hasta el siguiente " , pero, y si falta?
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') && i < 255) {
            temp_str [i++] = tolower (c) ;
            c = getchar () ;
        }
        temp_str [i] = '\0' ;
        ungetc (c, stdin) ;

        yylval.code = gen_code (temp_str) ;
        symbol = search_keyword (yylval.code) ;
        if (symbol == NULL) {    // no es palabra reservada -> identificador antes vrariabre
            return (IDENTIF) ;
        } else {
            return (symbol->token) ;
        }
    }

    if (strchr (ops_expandibles, c) != NULL) { // busca c en ops_expandibles
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        } else {
            yylval.code = gen_code (temp_str) ; // aunque no se use
            return (symbol->token) ;
        }
    }

    if (c == EOF || c == 255 || c == 26) {
        return (0) ;
    }

    return c ;
}


int main ()
{
    yyparse () ;
}
