open Type

(* Interface des arbres abstraits *)
module type Ast =
sig
   type expression
   type affectable
   type instruction
   type fonction
   type enumeration
   type programme
end

(* Interface d'affichage des arbres abstraits *)
module type PrinterAst =
sig
  module A:Ast

(* string_of_expression :  expression -> string *)
(* transforme une expression en chaîne de caractère *)
val string_of_expression : A.expression -> string

(* string_of_instruction :  instruction -> string *)
(* transforme une instruction en chaîne de caractère *)
val string_of_instruction : A.instruction -> string

(* string_of_fonction :  fonction -> string *)
(* transforme une fonction en chaîne de caractère *)
val string_of_fonction : A.fonction -> string

(* string_of_ast :  ast -> string *)
(* transforme un ast en chaîne de caractère *)
val string_of_programme : A.programme -> string

(* print_ast :  ast -> unit *)
(* affiche un ast *)
val print_programme : A.programme -> unit

end


(* *************************************** *)
(* AST après la phase d'analyse syntaxique *)
(* *************************************** *)
module AstSyntax =
struct

(* Opérateurs binaires de Rat *)
type binaire = Plus | Mult | Equ | Inf

type affectable =
  (* Accès à un identifiant représenté par son nom *)
  | Ident of string
  (* Accès à la valeur d'un pointeur *)
  | Valeur of affectable

(* Enumeration représenté par le nom de l'énumeration et la liste des valeurs *)
type enumeration = Enumeration of string * string list

(* Expressions de Rat *)
type expression =
  (* Appel de fonction représenté par le nom de la fonction et la liste des paramètres réels *)
  | AppelFonction of string * expression list 
  (* Rationnel représenté par le numérateur et le dénominateur *)
  | Rationnel of expression * expression 
  (* Accès au numérateur d'un rationnel *)
  | Numerateur of expression
  (* Accès au dénominateur d'un rationnel *)
  | Denominateur of expression
  (* Booléen vrai *)
  | True
  (* Booléen faux *)
  | False
  (* Entier *)
  | Entier of int
  (* Opération binaire représentée par l'opérateur, l'opérande gauche et l'opérande droite *)
  | Binaire of binaire * expression * expression
  (* Affectable  *)
  | Affectable of affectable
  (* Null *)
  | Null
  (* new de type *)
  | New of typ
  (* Accès à l'adress d'une variable *)
  | Adresse  of string
  (* Accès à la valeur d'un type enumeration *)
  | Tident of string
  (* expression default utilisé en switch case *)
  | Default 

(* Instructions de Rat *)
type bloc = instruction list
and instruction =
  (* Déclaration de variable représentée par son type, son nom et l'expression d'initialisation *)
  | Declaration of typ * string * expression
  (* Affectation d'une variable représentée par son nom et la nouvelle valeur affectée *)
  | Affectation of affectable * expression
  (* Déclaration d'une constante représentée par son nom et sa valeur (entier) *)
  | Constante of string * int
  (* Affichage d'une expression *)
  | Affichage of expression
  (* Conditionnelle représentée par la condition, le bloc then et le bloc else *)
  | Conditionnelle of expression * bloc * bloc
  (*Boucle TantQue représentée par la conditin d'arrêt de la boucle et le bloc d'instructions *)
  | TantQue of expression * bloc
  (* instruction break utilisé en switch case a la fin du code bloc pour un cas *)
  | Break
  (* abscence de l'instruction break utilisé en switch case a la fin du code bloc pour un cas *)
  | Notbreak
  (* switch/case représentée par l'expression qu'on test et une list des triple expression : (case expression) bloc : bloc du code, instruction : Break | Notbreak*)
  | Switch of expression * ((expression * bloc * instruction) list)

(* Structure des fonctions de Rat *)
(* type de retour - nom - liste des paramètres (association type et nom) - corps de la fonction - expression de retour *)
type fonction = Fonction of typ * string * (typ * string) list * instruction list * expression

(* Structure d'un programme Rat *)
(* liste de fonction - programme principal *)
type programme = Programme of enumeration list * fonction list * bloc
end


(*Module d'affiche des AST issus de la phase d'analyse syntaxique *)
module PrinterAstSyntax : PrinterAst with module A = AstSyntax =
struct

  module A = AstSyntax
  open A

  (* Conversion des opérateurs binaires *)
  let string_of_binaire b =
    match b with
    | Plus -> "+ "
    | Mult -> "* "
    | Equ -> "= "
    | Inf -> "< "

  (* Conversion des affectables *)
  let rec string_of_affectable a =
    match a with 
    | Valeur a -> "valeur de " ^ string_of_affectable a
    | Ident n -> n ^ ""

  (* Conversion des enumerations *)
  let string_of_enumeration en = 
    let Enumeration(n, lv) = en in 
    "enumeration " ^ n ^ " : \n" ^
    List.fold_right (fun h t -> h ^ " " ^ t) lv ""

  (* Conversion des expressions *)
  let rec string_of_expression e =
    match e with
    | AppelFonction (n,le) -> "call "^n^"("^((List.fold_right (fun i tq -> (string_of_expression i)^tq) le ""))^") "
    | Rationnel (e1,e2) -> "["^(string_of_expression e1)^"/"^(string_of_expression e2)^"] "
    | Numerateur e1 -> "num "^(string_of_expression e1)^" "
    | Denominateur e1 ->  "denom "^(string_of_expression e1)^" "
    | True -> "true "
    | False -> "false "
    | Entier i -> (string_of_int i)^" "
    | Binaire (b,e1,e2) -> (string_of_expression e1)^(string_of_binaire b)^(string_of_expression e2)^" "
    | Null -> "Null "
    | New t -> "new " ^ (string_of_type t) ^ " "
    | Affectable a -> (string_of_affectable a) ^ " "
    | Adresse n -> "adress " ^ n ^ " "
    | Tident n -> n ^ " "
    | Default -> "default "

  (* Conversion des instructions *)
  let rec string_of_instruction i =
    match i with
    | Declaration (t, n, e) -> "Declaration  : "^(string_of_type t)^" "^n^" = "^(string_of_expression e)^"\n"
    | Affectation (a,e) ->  "Affectation  : "^(string_of_affectable a)^" = "^(string_of_expression e)^"\n"
    | Constante (n,i) ->  "Constante  : "^n^" = "^(string_of_int i)^"\n"
    | Affichage e ->  "Affichage  : "^(string_of_expression e)^"\n"
    | Conditionnelle (c,t,e) ->  "Conditionnelle  : IF "^(string_of_expression c)^"\n"^
                                  "THEN \n"^((List.fold_right (fun i tq -> (string_of_instruction i)^tq) t ""))^
                                  "ELSE \n"^((List.fold_right (fun i tq -> (string_of_instruction i)^tq) e ""))^"\n"
    | TantQue (c,b) -> "TantQue  : TQ "^(string_of_expression c)^"\n"^
                                  "FAIRE \n"^((List.fold_right (fun i tq -> (string_of_instruction i)^tq) b ""))^"\n"
    | Break -> "break \n"
    | Notbreak -> "\n"
    | Switch(e, _) -> "Switch  : switch " ^ (string_of_expression e) ^ "\n" 

  (* Conversion des fonctions *)
  let string_of_fonction (Fonction(t,n,lp,li,e)) = (string_of_type t)^" "^n^" ("^((List.fold_right (fun (t,n) tq -> (string_of_type t)^" "^n^" "^tq) lp ""))^") = \n"^
                                        ((List.fold_right (fun i tq -> (string_of_instruction i)^tq) li ""))^
                                        "Return "^(string_of_expression e)^"\n"

  (* Conversion d'un programme Rat *)
  let string_of_programme (Programme (enumerations, fonctions, instruction)) =
    (List.fold_right (fun f tq -> (string_of_enumeration f)^tq) enumerations "")^
    (List.fold_right (fun f tq -> (string_of_fonction f)^tq) fonctions "")^
    (List.fold_right (fun i tq -> (string_of_instruction i)^tq) instruction "")

  (* Affichage d'un programme Rat *)
  let print_programme programme =
    print_string "AST : \n";
    print_string (string_of_programme programme);
    flush_all ()

end

(* ********************************************* *)
(* AST après la phase d'analyse des identifiants *)
(* ********************************************* *)
module AstTds =
struct

  type affectable =
  | Ident of Tds.info_ast (* le nom de l'identifiant est remplacé par ses informations *)
  | Valeur of affectable

  type enumeration = Enumeration of Tds.info_ast * Tds.info_ast list

  (* Expressions existantes dans notre langage *)
  (* ~ expression de l'AST syntaxique où les noms des identifiants ont été 
  remplacés par les informations associées aux identificateurs *)
  type expression =
    | AppelFonction of Tds.info_ast * expression list
    | Rationnel of expression * expression
    | Numerateur of expression
    | Denominateur of expression
    | True
    | False
    | Entier of int
    | Binaire of AstSyntax.binaire * expression * expression
    | Null
    | New of typ
    | Affectable of affectable
    | Adresse of Tds.info_ast (* le nom de l'identifiant est remplacé par ses informations *)
    | Tident of Tds.info_ast
    | Default 

  (* instructions existantes dans notre langage *)
  (* ~ instruction de l'AST syntaxique où les noms des identifiants ont été 
  remplacés par les informations associées aux identificateurs 
  + suppression de nœuds (const) *)
  type bloc = instruction list
  and instruction =
    | Declaration of typ * expression * Tds.info_ast (* le nom de l'identifiant est remplacé par ses informations *)
    | Affectation of  affectable * expression (* le nom de l'identifiant est remplacé par ses informations *)
    | Affichage of expression
    | Conditionnelle of expression * bloc * bloc
    | TantQue of expression * bloc
    | Empty (* les nœuds ayant disparus: Const *)
    | Break
    | Switch of expression * ((expression * bloc * instruction) list)


  (* Structure des fonctions dans notre langage *)
  (* type de retour - nom - liste des paramètres (association type et information sur les paramètres) - corps de la fonction - expression de retour - information sur la fonction*)
  (* le nom de la fonction est gardé car il sera nécessaire au moment de la génération de code*)
  type fonction = Fonction of typ * Tds.info_ast * (typ * Tds.info_ast ) list * instruction list * expression 

  (* Structure d'un programme dans notre langage *)
  type programme = Programme of enumeration list * fonction list * bloc

end
    

(* ******************************* *)
(* AST après la phase de typage *)
(* ******************************* *)
module AstType =
struct

type affectable =
  | Ident of Tds.info_ast (* le nom de l'identifiant est remplacé par ses informations *)
  | Valeur of affectable

type enumeration = Enumeration of Tds.info_ast * Tds.info_ast list

(* Opérateurs binaires existants dans Rat - résolution de la surcharge *)
type binaire = PlusInt | PlusRat | MultInt | MultRat | EquInt | EquBool | EquEnum | Inf

(* Expressions existantes dans Rat *)
(* = expression de AstTds *)
type expression =
  | AppelFonction of Tds.info_ast * expression list * typ list
  | Rationnel of expression * expression
  | Numerateur of expression
  | Denominateur of expression
  | True
  | False
  | Entier of int
  | Binaire of binaire * expression * expression
  | Null
  | New of typ
  | Affectable of affectable
  | Adresse of Tds.info_ast 
  | Tident of Tds.info_ast
  | Default 


(* instructions existantes Rat *)
(* = instruction de AstTds + informations associées aux identificateurs, mises à jour *)
(* + résolution de la surcharge de l'affichage *)
type bloc = instruction list
 and instruction =
  | Declaration of expression * Tds.info_ast
  | Affectation of affectable * expression 
  | AffichageInt of expression
  | AffichageRat of expression
  | AffichageBool of expression
  | Conditionnelle of expression * bloc * bloc
  | TantQue of expression * bloc
  | Empty (* les noeuds ayant disparus: Const *)
  | Break
  | Switch of expression * ((expression * bloc * instruction) list)


(* nom, liste des paramètres, corps, expression de retour, informations associées à l'identificateur *)
type fonction = Fonction of Tds.info_ast * Tds.info_ast list * instruction list * expression 

(* Structure d'un programme dans notre langage *)
type programme = Programme of enumeration list * fonction list * bloc

let taille_variables_declarees i = 
  match i with
  | Declaration (_,info) -> 
    begin
    match Tds.info_ast_to_info info with
    | InfoVar (_,t,_,_) -> getTaille t
    | _ -> failwith "internal error"
    end
  | _ -> 0 ;;

end

(* ******************************* *)
(* AST après la phase de placement *)
(* ******************************* *)
module AstPlacement =
struct
type affectable = AstType.affectable


(* Expressions existantes dans notre langage *)
(* = expression de AstType  *)
type expression = AstType.expression

(* instructions existantes dans notre langage *)
(* = instructions de AstType  *)
type bloc = instruction list
 and instruction = AstType.instruction

(* nom, corps, expression de retour, informations associées à l'identificateur *)
(* Plus besoin de la liste des paramètres mais on la garde pour les tests du placements mémoire *)
type fonction = Fonction of Tds.info_ast * Tds.info_ast list * instruction list * expression

(* Structure d'un programme dans notre langage *)
type programme = Programme of AstType.enumeration list * fonction list * bloc

end
