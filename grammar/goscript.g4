grammar goscript;

// basic type name
UINT32: 'uint32';
UINT64: 'uint64';
INT32: 'int32';
INT64: 'int64';
FLOAT32: 'float32';
FLOAT64: 'float64';
STRING: 'string';
BYTES: 'bytes';
BOOL: 'bool';
UINT8: 'uint8';
CHAN: 'chan';
ANY: 'any';

FOR: 'for';
BREAK: 'break';
CONTINUE: 'continue';

IF: 'if';
ELSE: 'else';

SWITCH: 'switch';
CASE: 'case';

RETURN: 'return';

VAR: 'var';
LOCAL: 'local';
CONST: 'const';

FUNCTION: 'func';

BOOLLITERAL
   : 'true'
   | 'false'
   ;

NULL
   : 'nil'
   ;

POW: '**';
MUL: '*';
DIV: '/';
MOD: '%';
ADD: '+';
SUB: '-';
UNARYADD: '++';
UNARYSUB: '--';

EQ: '==';
INEQ: '!=';
GT: '>';
GE: '>=';
LE: '<=';
LT: '<';
REGEX: '=~';

AND: '&&';
OR: '||';
NOT: '!';

CHANOP: '<-';
CHANOPNONBLOCK: '<<-';

ASSIGN: '=';
ADDEQUAL: '+=';
SUBEQUAL: '-=';
MULEQUAL: '*=';
DIVEQUAL: '/=';

INT
   : [0-9]+;

FLOAT
   : ([0-9]+)'.'[0-9]+;

STRINGLITERAL
   : '\'' ( ~('\''|'\\') | ('\\' .) )* '\'';

NAME: [a-zA-Z_]+[a-zA-Z0-9_]*;

DOT: '.';
TAILARRAY : '...';

WHITESPACE: [ \r\n\t]+ -> skip;
COMMENT :  '//' ~( '\r' | '\n' )* ( '\r' | '\n' ) -> skip;

// 1
program
    : (functiondef|typedef|execution)+;

functiondef
    : FUNCTION NAME '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' returntypename?  closure # FunctionDef
    | FUNCTION NAME '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' '('returntypename (',' returntypename) *')' closure # FunctionDef
    | FUNCTION NAME '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' outparam?  closure # FunctionDef
    | FUNCTION NAME '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' '('outparam (',' outparam) *')' closure # FunctionDef
    ;

lambda
    : FUNCTION  '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' returntypename?  closure # LambdaDef
    | FUNCTION  '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' '('returntypename (',' returntypename) *')' closure # LambdaDef
    | FUNCTION  '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' outparam?  closure # LambdaDef
    | FUNCTION  '(' (inparam (',' inparam)* (TAILARRAY)?)?  ')' '('outparam (',' outparam) *')' closure # LambdaDef
    ;

closure
    : block;

inparam
    : param;

outparam
    : param;

intypename
    : typename;

returntypename
    : typename;

param
    : NAME typename;

typename
    : (NAME|basicTypeName) # SimpleTypeName
    | functionTypeName # FunctionType
    | '[' basicTypeName ']' typename # MapTypeName
    | '[]' typename # SliceTypeName
    | CHAN '<' typename '>' # ChanTypeName
    ;

functionTypeName
    : FUNCTION  '(' (intypename (',' intypename)* (TAILARRAY)?)?  ')' returntypename?
    | FUNCTION  '(' (intypename (',' intypename)* (TAILARRAY)?)?  ')' '('returntypename (',' returntypename) *')'
    ;

typedef
    : 'typedef' NAME '['  basicTypeName ']' typenameindef # TypeDefMap
    | 'typedef' NAME '[]' typenameindef # TypeDefSlice
    | 'typedef' NAME '{' (messagefield (messagefield)*)? '}' # TypeDefMessage
    | 'typedef' NAME '{' (NAME ':' INT)* '}' # TypeDefEnum
    | 'typedef' NAME functionTypeNameindef # TypeDefFunction
    ;

messagefield
    : NAME typenameindef # FieldDef
    | 'oneof' NAME '{' oneoffield (oneoffield)* '}' # OneofDef
    ;

oneoffield
    : NAME typenameindef;

typenameindef
    : (NAME|basicTypeName) # SimpleTypeNameInDef
    | functionTypeNameindef # FunctionTypeInDef
    | '[' basicTypeName ']' typenameindef # MapTypeNameInDef
    | '[]' typenameindef # SliceTypeNameInDef
    | CHAN '<' typenameindef '>' # ChanTypeNameInDef
    ;

functionTypeNameindef
    : FUNCTION  '(' (intypenameindef (',' intypenameindef)* (TAILARRAY)?)?  ')' returntypenameindef?
    | FUNCTION  '(' (intypenameindef (',' intypenameindef)* (TAILARRAY)?)?  ')' '('returntypenameindef (',' returntypenameindef) *')'
    ;

intypenameindef
    : typenameindef;

returntypenameindef
    : typenameindef;

execution
    : control # Ctrl
    | line ';' # LineProgram
    ;

control
    : IF '(' expr ')' block (ELSE (block|control))? # If
    | SWITCH '(' expr ')' '{' (CASE constant ':' block)+ '}' # Switch
    | FOR '(' NAME 'in' collection ')' block # ForInSlice
    | FOR '(' NAME ',' NAME 'in' collection ')' block  # ForInMap
    | FOR '(' line ';' expr ';' restoreStack ')' block  # For
    | BREAK ';' # Break
    | CONTINUE ';' # Continue
    | RETURN ';'# ReturnVoid
    | RETURN expr (',' expr)*';' # ReturnVal
    ;

collection
    : expr;

block
    : '{' (execution)* '}';

line
    : restoreStack # RestoreStackSp
    | vardef # VarDef
    | constdef # ConstDef
    ;

restoreStack
    : keepStack;

keepStack
    : expr # ExprEntry
    | expr (',' expr)+ op=ASSIGN expr # FunctionAssign
    ;

variable
    : NAME # VariableName
    | '@' # VariableName
    ;

asserted: typename;

filter: expr;

indexs
    : expr ':' expr ':' expr # IndexType1
    | expr ':' expr # IndexType2
    | expr ':' # IndexType3
    | expr # IndexType4
    | ':' expr # IndexType5
    ;

expr
    : '(' expr ')' # Pass
    | constant # Pass
    | variable # Pass
    | lambda # Pass
    | builtin # Pass
    | expr DOT NAME # Select
    | expr DOT '(' asserted ')' # TypeAssert
    | expr '[?(' filter ')]' # SliceFilter
    | expr '[' expr ']' # Index
    | expr '[' indexs (',' indexs)* ']' # SliceMultiIndex
    | expr '[' '[' expr (',' expr)* ']' ']' # MapMultiIndex
    | expr '(' (expr (',' expr)*)? ')' # DirectCall
    | op=(UNARYADD|UNARYSUB|NOT|SUB) expr # LeftUnary
    | expr op=(UNARYADD|UNARYSUB) # RightUnary
    | <assoc=right> expr op=POW  expr # Binary
    | expr op=(MUL | DIV | MOD) expr # Binary
    | expr op=(ADD | SUB) expr # Binary
    | expr op=(EQ | INEQ | GT | GE | LT | LE | REGEX) expr # Binary
    | expr op=AND expr # Binary
    | expr op=OR expr # Binary
    | expr (CHANOP|CHANOPNONBLOCK) expr # Send
    | (CHANOP|CHANOPNONBLOCK) expr # Recv
    | <assoc=right> expr op=(ASSIGN|ADDEQUAL|SUBEQUAL|MULEQUAL|DIVEQUAL) expr # Binary
    | <assoc=right> expr op=ASSIGN initializationListBegin # AssignInitializationlist
    | constructor # Construct
    ;

basicTypeName
    : (UINT32|UINT64|INT32|INT64|FLOAT32|FLOAT64|STRING|BYTES|BOOL|UINT8|ANY);

builtin
    : 'pushBack' '(' expr',' expr ')'
    | 'pushFront' '(' expr',' expr ')'
    | 'delete' '(' expr',' expr ')'
    | 'enumString' '(' expr ')'
    | 'len' '(' expr ')'
    | 'typeof' '(' expr ')'
    | UINT32 '(' expr ')'
    | UINT64 '(' expr ')'
    | INT32 '(' expr ')'
    | INT64 '(' expr ')'
    | FLOAT32 '(' expr ')'
    | FLOAT64 '(' expr ')'
    | STRING '(' expr ')'
    | BYTES '(' expr ')'
    | BOOL '(' expr ')'
    | UINT8 '(' expr ')'
    | ANY '(' expr ')'
    ;

initializationListBegin
    : initializationList;

initializationList
    : '[' (initializationList (',' initializationList)*)? ']' # InitSlice
    | '{'  NAME '('initializationList')' (',' NAME '(' initializationList ')' )* '}' # InitMessage
    | '{'  initializationList ':' initializationList (',' initializationList ':' initializationList )* '}' # InitMap
    | expr # InitConstant
    ;

constant
    : INT # ConstantInt
    | FLOAT # ConstantFloat
    | BOOLLITERAL # ConstantBool
    | NULL # ConstantNil
    | STRINGLITERAL # ConstantString
    ;

constructor
    : 'new' typename '(' ')'
    | 'new' typename '('expr (',' expr)*')'
    ;

vardef
    : VAR NAME typename
    | VAR NAME typename '=' expr
    | VAR NAME typename '=' initializationListBegin
    | LOCAL NAME typename
    | LOCAL NAME typename '=' expr
    | LOCAL NAME typename '=' initializationListBegin
    ;

constdef
    : CONST NAME basicTypeName '=' constant
    ;