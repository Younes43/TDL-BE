/* Imports. */

%{

open Type
open Ast.AstSyntax
%}


%token <int> ENTIER
%token <string> ID
%token <string> TID
%token RETURN
%token PV
%token AO
%token AF
%token PF
%token PO
%token EQUAL
%token CONST
%token PRINT
%token IF
%token ELSE
%token WHILE
%token BOOL
%token INT
%token RAT
%token CALL 
%token CO
%token CF
%token SLASH
%token NUM
%token DENOM
%token TRUE
%token FALSE
%token PLUS
%token MULT
%token INF
%token AMV
%token NULL 
%token NEW
%token ENUMERATION
%token COMMA
%token SWITCH
%token CASE
%token DEFAULT
%token DBPT
%token BREAK
%token EOF

(* Type de l'attribut synthétisé des non-terminaux *)
%type <programme> prog
%type <instruction list> bloc
%type <fonction> fonc
%type <instruction list> is
%type <instruction> i
%type <typ> typ
%type <(typ*string) list> dp
%type <expression> e 
%type <expression list> cp
%type <affectable> a

(* Type et définition de l'axiome *)
%start <Ast.AstSyntax.programme> main

%%

main : lenu = enums lfi = prog EOF     {let (Programme (_,lf1,li))=lfi in (Programme (lenu,lf1,li))}

enums : en1 = enum en2 = enums {en1::en2}
      |                          {[]}

enum : ENUMERATION n = TID AO x = ids AF PV   {Enumeration(n,x)}

ids : n=TID {[n]}
    | n=TID COMMA x=ids {n::x}

prog :
| lf = fonc  lfi = prog   {let (Programme (lenu,lf1,li))=lfi in (Programme (lenu,lf::lf1,li))}
| ID li = bloc            {Programme ([],[],li)}

fonc : t=typ n=ID PO p=dp PF AO li=is RETURN exp=e PV AF {Fonction(t,n,p,li,exp)}

bloc : AO li = is AF      {li}

is :
|                         {[]}
| i1=i li=is              {i1::li}

i :
| t=typ n=ID EQUAL e1=e PV          {Declaration (t,n,e1)}
| n=a EQUAL e1=e PV                 {Affectation (n,e1)}
| CONST n=ID EQUAL e=ENTIER PV      {Constante (n,e)}
| PRINT e1=e PV                     {Affichage (e1)}
| IF exp=e li1=bloc ELSE li2=bloc   {Conditionnelle (exp,li1,li2)}
| WHILE exp=e li=bloc               {TantQue (exp,li)}
| SWITCH PO exp=e PF AO lc1=lc AF   {Switch (exp,lc1)}

lc :
| {[]}
| c1=c lc1=lc {c1::lc1}

c:
| CASE n=TID DBPT ls=is i=b {(Tident n,ls,i)}
| CASE e=ENTIER DBPT ls=is i=b {(Entier e,ls,i)}
| CASE TRUE DBPT ls=is i=b {(True,ls,i)}
| CASE FALSE DBPT ls=is i=b {(False,ls,i)}
| DEFAULT DBPT ls=is i=b {(Default,ls,i)} 

b :
| {Notbreak}
| BREAK PV {Break}


dp :
|                         {[]}
| t=typ n=ID lp=dp        {(t,n)::lp}

typ :
| BOOL    {Bool}
| INT     {Int}
| RAT     {Rat}
| t=typ MULT {Pointeur(t)}
| t=TID {Enum(t)}

e : 
| CALL n=ID PO lp=cp PF   {AppelFonction (n,lp)}
| CO e1=e SLASH e2=e CF   {Rationnel(e1,e2)}
| NUM e1=e                {Numerateur e1}
| DENOM e1=e              {Denominateur e1}
| TRUE                    {True}
| FALSE                   {False}
| e=ENTIER                {Entier e}
| PO e1=e PLUS e2=e PF    {Binaire (Plus,e1,e2)}
| PO e1=e MULT e2=e PF    {Binaire (Mult,e1,e2)}
| PO e1=e EQUAL e2=e PF   {Binaire (Equ,e1,e2)}
| PO e1=e INF e2=e PF     {Binaire (Inf,e1,e2)}
| PO exp=e PF             {exp}
| n=a                     {Affectable(n)}
| NULL                    {Null}
| PO NEW t=typ PF         {New (t)}
| AMV n=ID                {Adresse (n)}
| n=TID                   {Tident n}

cp :
|               {[]}
| e1=e le=cp    {e1::le}

a:
| PO MULT n=a PF     {Valeur (n)}
| n=ID               {Ident n}

