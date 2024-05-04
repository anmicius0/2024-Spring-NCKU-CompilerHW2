/* Definition section */
%{
    #include "compiler_common.h"
    #include "compiler_util.h"
    #include "main.h"

    int yydebug = 1;
%}

/* Variable or self-defined structure */
%union {
    ObjectType var_type;

    bool b_var;
    int i_var;
    float f_var;
    char *s_var;

    Object object_val;
}

/* Token without return */
%token COUT
%token SHR SHL BAN BOR BNT BXO ADD SUB MUL DIV REM NOT GTR LES GEQ LEQ EQL NEQ LAN LOR
%token VAL_ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN BAN_ASSIGN BOR_ASSIGN BXO_ASSIGN SHR_ASSIGN SHL_ASSIGN INC_ASSIGN DEC_ASSIGN
%token IF ELSE FOR WHILE RETURN BREAK CONTINUE

/* Token with return, which need to sepcify type */
%token <var_type> VARIABLE_T
%token <s_var> IDENT
%token <i_var> INT_LIT
%token <s_var> STR_LIT
%token <b_var> BOOL_LIT
%token <f_var> FLOAT_LIT

/* Nonterminal with return, which need to sepcify type */
%type <object_val> Expression
%type <object_val> CoutParm
%type <object_val> CoutParmList
%type <object_val> Stmt // Return type added
%type <object_val> StmtList // Return type added

/* Operator Precedence and Associativity */
%left ADD SUB
%left MUL DIV REM
%right VAL_ASSIGN ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN BAN_ASSIGN BOR_ASSIGN BXO_ASSIGN SHR_ASSIGN SHL_ASSIGN
%left GTR LES GEQ LEQ EQL NEQ
%left LAN
%left LOR
%right NOT BNT  /* Unary operators */
%right SHL /* Added precedence for SHL */

/* Yacc will start at this nonterminal */
%start Program

%%
/* Grammar section */

Program
    : { pushScope(); } GlobalStmtList { dumpScope(); }
    | /* Empty file */
;

GlobalStmtList
    : GlobalStmtList GlobalStmt
    | GlobalStmt
;

GlobalStmt
    : DefineVariableStmt
    | FunctionDefStmt
;

DefineVariableStmt
    : VARIABLE_T IDENT VAL_ASSIGN Expression ';'
;

/* Function */
FunctionDefStmt
    : VARIABLE_T IDENT '(' FunctionParameterStmtList ')' { createFunction($<var_type>1, $<s_var>2); }
      '{' StmtList '}' { dumpScope(); } // Added StmtList for function body
;

FunctionParameterStmtList
    : FunctionParameterStmtList ',' FunctionParameterStmt
    | FunctionParameterStmt
    | /* Empty function parameter */
;

FunctionParameterStmt
    : VARIABLE_T IDENT { pushFunParm($<var_type>1, $<s_var>2, VAR_FLAG_DEFAULT); }
;

/* Scope (now connected to the grammar) */
StmtList
    : StmtList Stmt
    | Stmt
;

Stmt
    : Value { printf("Value encountered\n"); }
    | RETURN Value ';' { printf("RETURN\n"); }
    | COUT CoutParmList ';' { stdoutPrint(); } // Corrected syntax
//    | IF '(' Expression ')' Stmt { printf("IF\n"); } // Example of an IF statement
//    | IF '(' Expression ')' Stmt ELSE Stmt { printf("IF-ELSE\n"); } // IF-ELSE statement
    | FOR '(' Expression ';' Expression ';' Expression ')' Stmt { printf("FOR\n"); } // Example of a FOR statement
    | WHILE '(' Expression ')' Stmt { printf("WHILE\n"); } // Example of a WHILE statement
    | BREAK ';' { printf("BREAK\n"); } // BREAK statement
    | CONTINUE ';' { printf("CONTINUE\n"); } // CONTINUE statement
    // ... add other statement types as needed
;

Value
    : Expression { $<object_val>$ = $<object_val>1; }
    | ';' { $<object_val>$ = (Object){0}; } // Handle empty statement
;
CoutParmList
    : CoutParm
    | CoutParmList SHL CoutParm { pushFunInParm(&$<object_val>3); $<object_val>$ = $<object_val>1; }  // Use $1 to propagate the return value
;

CoutParm
    : Expression { pushFunInParm(&$<object_val>1); $<object_val>$ = $<object_val>1; } // Base case for the list
;

Expression
    : IDENT {
        $<object_val>$.type = OBJECT_TYPE_STR; // Assuming IDENT is a string
        $<object_val>$.value = (uint64_t)$<s_var>1; // Convert the string to a uint64_t
        printf("IDENT (name=%s, address=%llu)\n", $<s_var>1, $<object_val>$.value);
    }
    | INT_LIT {
        $<object_val>$.type = OBJECT_TYPE_INT;
        $<object_val>$.value = $<i_var>1;
        printf("INT_LIT %d\n", $<i_var>1);
    }
    | STR_LIT {
        $<object_val>$.type = OBJECT_TYPE_STR;
        $<object_val>$.value = (uint64_t)$<s_var>1;
        printf("STR_LIT \"%s\"\n", $<s_var>1);
    }
    | FLOAT_LIT {
        $<object_val>$.type = OBJECT_TYPE_FLOAT;
        $<object_val>$.value = $<f_var>1;
        printf("FLOAT_LIT %f\n", $<f_var>1);
    }
//    | Expression ADD Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value + $<object_val>3.value;
//        printf("ADD\n");
//    }
//    | Expression SUB Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value - $<object_val>3.value;
//        printf("SUB\n");
//    }
//    | Expression MUL Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value * $<object_val>3.value;
//        printf("MUL\n");
//    }
//    | Expression DIV Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value / $<object_val>3.value;
//        printf("DIV\n");
//    }
//    | Expression REM Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value % $<object_val>3.value;
//        printf("REM\n");
//    }
//    | Expression SHR Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value >> $<object_val>3.value;
//        printf("SHR\n");
//    }
//    | Expression SHL Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value << $<object_val>3.value;
//        printf("SHL\n");
//    }
//    | Expression BAN Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value & $<object_val>3.value;
//        printf("BAN\n");
//    }
//    | Expression BOR Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value | $<object_val>3.value;
//        printf("BOR\n");
//    }
//    | Expression BNT Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = ~$<object_val>2.value;
//        printf("BNT\n");
//    }
//    | Expression BXO Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = $<object_val>1.value ^ $<object_val>3.value;
//        printf("BXO\n");
//    }
//    | NOT Expression {
//        $<object_val>$.type = OBJECT_TYPE_INT;
//        $<object_val>$.value = !$<object_val>2.value;
//        printf("NOT\n");
//    }
//    | Expression GTR Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.value > $<object_val>3.value;
//        printf("GTR\n");
//    }
//    | Expression LES Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.value < $<object_val>3.value;
//        printf("LES\n");
//    }
//    | Expression GEQ Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.value >= $<object_val>3.value;
//        printf("GEQ\n");
//    }
//    | Expression LEQ Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.value <= $<object_val>3.value;
//        printf("LEQ\n");
//    }
//    | Expression EQL Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.value == $<object_val>3.value;
//        printf("EQL\n");
//    }
//    | Expression NEQ Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.value != $<object_val>3.value;
//        printf("NEQ\n");
//    }
//    | Expression LAN Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.b_var && $<object_val>3.b_var;
//        printf("LAN\n");
//    }
//    | Expression LOR Expression {
//        $<object_val>$.type = OBJECT_TYPE_BOOL;
//        $<object_val>$.b_var = $<object_val>1.b_var || $<object_val>3.b_var;
//        printf("LOR\n");
//    }
//    | Expression VAL_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, VAL_ASSIGN, $<object_val>3);
//        printf("EQL_ASSIGN\n");
//    }
//    | Expression ADD_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, ADD_ASSIGN, $<object_val>3);
//        printf("ADD_ASSIGN\n");
//    }
//    | Expression SUB_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, SUB_ASSIGN, $<object_val>3);
//        printf("SUB_ASSIGN\n");
//    }
//    | Expression MUL_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, MUL_ASSIGN, $<object_val>3);
//        printf("MUL_ASSIGN\n");
//    }
//    | Expression DIV_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, DIV_ASSIGN, $<object_val>3);
//        printf("DIV_ASSIGN\n");
//    }
//    | Expression REM_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, REM_ASSIGN, $<object_val>3);
//        printf("REM_ASSIGN\n");
//    }
//    | Expression SHR_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, SHR_ASSIGN, $<object_val>3);
//        printf("SHR_ASSIGN\n");
//    }
//    | Expression SHL_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, SHL_ASSIGN, $<object_val>3);
//        printf("SHL_ASSIGN\n");
//    }
//    | Expression BAN_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, BAN_ASSIGN, $<object_val>3);
//        printf("BAN_ASSIGN\n");
//    }
//    | Expression BOR_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, BOR_ASSIGN, $<object_val>3);
//        printf("BOR_ASSIGN\n");
//    }
//    | Expression BXO_ASSIGN Expression {
//        $<object_val>$ = evalExpression($<object_val>1, BXO_ASSIGN, $<object_val>3);
//        printf("BXO_ASSIGN\n");
//    }
//    | Expression INC_ASSIGN {
//        $<object_val>$ = evalExpression($<object_val>1, INC_ASSIGN, (Object){0});
//        printf("INC_ASSIGN\n");
//    }
//    | Expression DEC_ASSIGN {
//        $<object_val>$ = evalExpression($<object_val>1, DEC_ASSIGN, (Object){0});
//        printf("DEC_ASSIGN\n");
//    }
//    | '(' Expression ')' { $$ = $<object_val>2; }
;

%%
/* C code section */
