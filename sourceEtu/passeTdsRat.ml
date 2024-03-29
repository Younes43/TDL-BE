
(* Module de la passe de gestion des identifiants *)
module PasseTdsRat : Passe.Passe with type t1 = Ast.AstSyntax.programme and type t2 = Ast.AstTds.programme =
struct

  open Tds
  open Exceptions
  open Ast
  open AstTds
  (*open PrinterAstSyntax*)


  type t1 = Ast.AstSyntax.programme
  type t2 = Ast.AstTds.programme

(* analyse_tds_affectable : AstSyntax.affectable -> tds -> boolean -> AstTds.affectable *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre a : l'affectable à analyser *)
(* Paramètre modif : indique si l’affectable est modifié*)
(* Vérifie la bonne utilisation des affectables et tranforme l'affectable
en une affectable de type AstTds.instruction *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_affectable tds (a:AstSyntax.affectable) modif =
  match a with 
  | AstSyntax.Ident n ->
    begin
      match chercherGlobalement tds n with 
      | None -> raise (IdentifiantNonDeclare n)
      | Some info ->
        begin
          match info_ast_to_info info with 
          | InfoFun _ -> raise (MauvaiseUtilisationIdentifiant n)
          | InfoVar _ -> Ident info
          | InfoConst _ -> if modif then raise (MauvaiseUtilisationIdentifiant n) else Ident info
        end
    end
  | AstSyntax.Valeur v -> Valeur (analyse_tds_affectable tds v true)


(* analyse_tds_expression : AstSyntax.expression -> AstTds.expression *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre e : l'expression à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'expression
en une expression de type AstTds.expression *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_expression tds e = 
  match e with
  | AstSyntax.AppelFonction (id, le) ->
    begin
      match chercherGlobalement tds id with 
      | None -> raise (IdentifiantNonDeclare id)
      | Some info ->
        begin
          match info_ast_to_info info with 
          | InfoFun _ -> 
            let ne = List.map (fun e -> analyse_tds_expression tds e) le in AppelFonction(info, ne)
          | _ -> raise (MauvaiseUtilisationIdentifiant id)
        end
    end
  | AstSyntax.Rationnel (e1, e2) -> 
    let ne1 = (analyse_tds_expression tds e1) in
    let ne2 = (analyse_tds_expression tds e2) in
    Rationnel(ne1, ne2)
  | AstSyntax.Numerateur e ->
    let ne = (analyse_tds_expression tds e) in
    Numerateur ne
  | AstSyntax.Denominateur e ->
    let ne = (analyse_tds_expression tds e) in
    Denominateur ne
  | AstSyntax.True -> True
  | AstSyntax.False -> False
  | AstSyntax.Entier v -> Entier v
  | AstSyntax.Binaire (op, e1, e2) -> 
    let ne1 = (analyse_tds_expression tds e1) in
    let ne2 = (analyse_tds_expression tds e2) in
    Binaire(op, ne1, ne2)
  | AstSyntax.Affectable a -> Affectable (analyse_tds_affectable tds a false)
  | AstSyntax.Null  -> Null
  | AstSyntax.New t -> New t
  | AstSyntax.Adresse n ->
    begin
      match chercherGlobalement tds n with
      | None -> raise (IdentifiantNonDeclare n)
      | Some info ->
        begin
          match info_ast_to_info info with 
          | InfoFun _ -> raise (MauvaiseUtilisationIdentifiant n)
          | InfoVar _ -> Adresse info
          | InfoConst _ -> raise (MauvaiseUtilisationIdentifiant n)
        end
    end
  | AstSyntax.Tident tid -> 
    begin 
      match chercherGlobalement tds tid with 
      | None -> raise (IdentifiantNonDeclare tid)
      | Some info ->
        begin
          match info_ast_to_info info with
            | InfoVar _ -> Tident info
            | _ -> raise (MauvaiseUtilisationIdentifiant tid)
        end
    end
  | AstSyntax.Default -> Default
    

(* analyse_tds_instruction : AstSyntax.instruction -> tds -> AstTds.instruction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre i : l'instruction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme l'instruction
en une instruction de type AstTds.instruction *)
(* Erreur si mauvaise utilisation des identifiants *)
let rec analyse_tds_instruction tds i =
  match i with
  | AstSyntax.Declaration (t, n, e) ->
      begin
        match chercherLocalement tds n with
        | None ->
            (* L'identifiant n'est pas trouvé dans la tds locale, 
            il n'a donc pas été déclaré dans le bloc courant *)
            (* Vérification de la bonne utilisation des identifiants dans l'expression *)
            (* et obtention de l'expression transformée *) 
            let ne = analyse_tds_expression tds e in
            (* Création de l'information associée à l'identfiant *)
            let info = InfoVar (n,Undefined, 0, "") in
            (* Création du pointeur sur l'information *)
            let ia = info_to_info_ast info in
            (* Ajout de l'information (pointeur) dans la tds *)
            ajouter tds n ia;
            (* Renvoie de la nouvelle déclaration où le nom a été remplacé par l'information 
            et l'expression remplacée par l'expression issue de l'analyse *)
            Declaration (t, ne, ia) 
        | Some _ ->
            (* L'identifiant est trouvé dans la tds locale, 
            il a donc déjà été déclaré dans le bloc courant *) 
            raise (DoubleDeclaration n)
      end
  | AstSyntax.Affectation (a,e) ->
    (* Dans affectation donc affectable en ecriture *)
    Affectation ((analyse_tds_affectable tds a true), (analyse_tds_expression tds e) )
  | AstSyntax.Constante (n,v) -> 
      begin
        match chercherLocalement tds n with
        | None -> 
        (* L'identifiant n'est pas trouvé dans la tds locale, 
        il n'a donc pas été déclaré dans le bloc courant *)
        (* Ajout dans la tds de la constante *)
        ajouter tds n (info_to_info_ast (InfoConst (n,v))); 
        (* Suppression du noeud de déclaration des constantes devenu inutile *)
        Empty
        | Some _ ->
          (* L'identifiant est trouvé dans la tds locale, 
          il a donc déjà été déclaré dans le bloc courant *) 
          raise (DoubleDeclaration n)
      end
  | AstSyntax.Affichage e -> 
      (* Vérification de la bonne utilisation des identifiants dans l'expression *)
      (* et obtention de l'expression transformée *)
      let ne = analyse_tds_expression tds e in
      (* Renvoie du nouvel affichage où l'expression remplacée par l'expression issue de l'analyse *)
      Affichage (ne)
  | AstSyntax.Conditionnelle (c,t,e) -> 
      (* Analyse de la condition *)
      let nc = analyse_tds_expression tds c in
      (* Analyse du bloc then *)
      let tast = analyse_tds_bloc tds t in
      (* Analyse du bloc else *)
      let east = analyse_tds_bloc tds e in
      (* Renvoie la nouvelle structure de la conditionnelle *)
      Conditionnelle (nc, tast, east)
  | AstSyntax.TantQue (c,b) -> 
      (* Analyse de la condition *)
      let nc = analyse_tds_expression tds c in
      (* Analyse du bloc *)
      let bast = analyse_tds_bloc tds b in
      (* Renvoie la nouvelle structure de la boucle *)
      TantQue (nc, bast)
  | AstSyntax.Break -> Break
  | AstSyntax.Notbreak -> Empty
  | AstSyntax.Switch(e,lc) -> 
    let aux tds (e, b, i) = 
      let ne = analyse_tds_expression tds e in 
      let nb = analyse_tds_bloc tds b in 
      let ni = analyse_tds_instruction tds i in 
      ne,nb,ni 
    in
    let ne = analyse_tds_expression tds e in
    let nlc = List.map (aux tds) lc in
    Switch(ne,nlc)

      
(* analyse_tds_bloc : AstSyntax.bloc -> AstTds.bloc *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre li : liste d'instructions à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le bloc
en un bloc de type AstTds.bloc *)
(* Erreur si mauvaise utilisation des identifiants *)
and analyse_tds_bloc tds li =
  (* Entrée dans un nouveau bloc, donc création d'une nouvelle tds locale 
  pointant sur la table du bloc parent *)
  let tdsbloc = creerTDSFille tds in
  (* Analyse des instructions du bloc avec la tds du nouveau bloc 
  Cette tds est modifiée par effet de bord *)
   let nli = List.map (analyse_tds_instruction tdsbloc) li in
   (* afficher_locale tdsbloc ; *) (* décommenter pour afficher la table locale *)
   nli


(* analyse_tds_fonction : AstSyntax.fonction -> tds -> AstTds.fonction *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre : la fonction à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme la fonction
en une fonction de type AstTds.fonction *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyse_tds_fonction maintds (AstSyntax.Fonction(t,n,lp,li,e))  =
  (* analyser un parametre *)
  let aux tds (t, n) = 
    match chercherLocalement tds n with 
    | Some _ -> raise (DoubleDeclaration n)
    | None -> 
      let info = info_to_info_ast (InfoVar(n, t, 0, "")) in ajouter tds n info;
      (t, info)
  in
  match chercherGlobalement maintds n with 
  | Some info -> 
    begin
      match info_ast_to_info info with 
      | InfoFun _ ->
        let lpt = fst (List.split lp) in
        (* chercher la signature de la fonction *)
        begin
          match info_ast_to_info info with 
          | InfoFun (n, t, ltp) -> if not (List.mem lpt ltp) then 
            (* la signature n'existe pas deja  *)
            let tdslocal = creerTDSFille maintds in
            ajouter maintds n info;
            ajouter tdslocal n info;
            let nlp = List.map (aux tdslocal) lp in
            let nli = List.map (analyse_tds_instruction tdslocal) li in
            let ne = analyse_tds_expression tdslocal e in
            ajouter_signature lpt info;
            Fonction (t, info, nlp, nli, ne)
            (* la signature existe déja  *)
            else raise (DoubleDeclaration n)
          | _ -> failwith "internal error"
        end
      | _ -> failwith "internal error"
    end
  | None ->
    let tdslocal = creerTDSFille maintds in
    let info = info_to_info_ast (InfoFun(n, t, [fst (List.split lp)])) 
    in ajouter maintds n info;
    ajouter tdslocal n info;
    let nlp = List.map (aux tdslocal) lp in
    let nli = List.map (analyse_tds_instruction tdslocal) li in
    let ne = analyse_tds_expression tdslocal e in
    Fonction (t, info, nlp, nli, ne)
  

(* analyse_tds_enumeration : AstSyntax.enumeration -> tds -> AstTds.enumeration *)
(* Paramètre tds : la table des symboles courante *)
(* Paramètre : enumeration à analyser *)
(* Vérifie la bonne utilisation des enumeration et tranforme l'enumeration
en une enumeration de type AstTds.enumeration *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyse_tds_enumeration maintds (AstSyntax.Enumeration(n, ln)) = 
  (* fonction auxiliere : tds -> string -> info_ast*)
  (* Paramètre tds : la table des symboles courante *)
  (* Paramètre x : le nom de la valeur de type enumeration a analyser *)
  (* Vérifie la bonne utilisation d'une valeur de type enumeration et la tranforme
  en une info_ast *)
  (* Erreur si mauvaise utilisation des identifiants *)  
  let aux tds x =
    match chercherGlobalement tds x with 
      | Some _ -> raise (DoubleDeclaration x)
      | None  ->
        let info_x = info_to_info_ast (InfoVar(x, Enum n, 0, "")) in ajouter tds x info_x;
        info_x
  in 
  match chercherGlobalement maintds n with 
  | Some _ -> raise (DoubleDeclaration n)
  | None ->
    let info = info_to_info_ast (InfoVar(n, Enum n, 0, "")) in ajouter maintds n info;
    let info_l = List.map (aux maintds) ln in
    Enumeration(info, info_l)


(* analyser : AstSyntax.ast -> AstTds.ast *)
(* Paramètre : le programme à analyser *)
(* Vérifie la bonne utilisation des identifiants et tranforme le programme
en un programme de type AstTds.ast *)
(* Erreur si mauvaise utilisation des identifiants *)
let analyser (AstSyntax.Programme (enumerations, fonctions, prog)) =
  let tds = creerTDSMere () in
  let ne = List.map (analyse_tds_enumeration tds) enumerations in
  let nf = List.map (analyse_tds_fonction tds) fonctions in
  let nb = analyse_tds_bloc tds prog in
  Programme (ne, nf, nb)
end
