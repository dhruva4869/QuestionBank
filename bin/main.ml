type answer = {
  text : string;
}

type question_bank = {
  db : Sqlite3.db;
}

let init_question_bank () : question_bank =
  {
    db = Sqlite3.db_open "question_bank.db";
  }

let create_tables (db : Sqlite3.db) : unit =
  let create_questions_table = "
    CREATE TABLE IF NOT EXISTS questions (
      id TEXT PRIMARY KEY,
      text TEXT NOT NULL
    );
  " in
  let create_answers_table = "
    CREATE TABLE IF NOT EXISTS answers (
      question_id TEXT NOT NULL,
      text TEXT NOT NULL,
      FOREIGN KEY(question_id) REFERENCES questions(id)
    );
  " in
  ignore (Sqlite3.exec db create_questions_table);
  ignore (Sqlite3.exec db create_answers_table)

let add_question (bank : question_bank) (question_id : string) (q_text : string) : unit =
  let insert_question = "
    INSERT INTO questions (id, text) VALUES (?, ?)
  " in
  let stmt = Sqlite3.prepare bank.db insert_question in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT question_id));
  ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT q_text));
  ignore (Sqlite3.step stmt);
  ignore (Sqlite3.finalize stmt)

let add_answer (bank : question_bank) (q_id : string) (a_text : string) : unit =
  let insert_answer = "
    INSERT INTO answers (question_id, text) VALUES (?, ?)
  " in
  let stmt = Sqlite3.prepare bank.db insert_answer in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT q_id));
  ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT a_text));
  ignore (Sqlite3.step stmt);
  ignore (Sqlite3.finalize stmt)

let get_answers (bank : question_bank) (q_id : string) : (answer * answer) list =
  let select_answers = "
    SELECT q.text, a.text
    FROM questions q
    JOIN answers a ON q.id = a.question_id
    WHERE q.id = ?
  " in
  let stmt = Sqlite3.prepare bank.db select_answers in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT q_id));
  let rec fetch_answers acc =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
      let question_text = Sqlite3.column_text stmt 0 in
      let answer_text = Sqlite3.column_text stmt 1 in
      let question = { text = question_text } in
      let answer = { text = answer_text } in
      fetch_answers ((question, answer) :: acc)
    | _ ->
      ignore (Sqlite3.finalize stmt);
      List.rev acc
  in
  fetch_answers []

let generate_latex_file (bank : question_bank) (topic : string) (qids : string list) (filename : string) (include_answers : bool) : unit =
  let rec process_questions questions =
    match questions with
    | [] -> ()
    | qid :: rest ->
      let answers = get_answers bank qid in
      let question_text =
        match answers with
        | (question, _) :: _ -> question.text
        | [] -> "No question available"
      in
      let answers_text =
        match answers with
        | (_, answer) :: _ -> answer.text
        | [] -> "No answer available"
      in
      let answer_section =
        if include_answers then
          "Answer: " ^ answers_text ^ "\n"
        else
          ""
      in
      let latex_content =
        "\n\n\\section{Question " ^ topic ^ qid ^ "}\n\n" ^
        question_text ^ "\n\n" ^
        answer_section
      in
      let oc = open_out_gen [Open_creat; Open_text; Open_append] 0o666 filename in
      output_string oc latex_content;
      close_out oc;
      process_questions rest
  in
  process_questions qids


let topic_name = ref ""
let question_ids_to_add = ref []
let answer_ids_to_add = ref []  
let generate_latex = ref false
let filename = ref ""
let include_answers = ref false

let options = [
  ("-t", Arg.String (fun t -> topic_name := t), "Topic name");
  ("-q", Arg.String (fun qids -> question_ids_to_add := String.split_on_char ',' qids), "Question ID(s) (comma-separated)");
  ("-a", Arg.String (fun aids -> answer_ids_to_add := String.split_on_char ',' aids), "Answer ID(s) (comma-separated)");
  ("-gen", Arg.Tuple([
             Arg.String (fun f -> filename := f);
             Arg.Unit (fun () -> generate_latex := true);
           ]), "Generate LaTeX file");
  ("-include", Arg.Unit (fun () -> include_answers := true), "Include answers in the LaTeX file");
]

let usage_msg = "Usage: my_program -gen <filename> -t <topic> -q <qid> -a <qid> [-include]"


let main (bank : question_bank) : unit =
  Arg.parse options (fun _ -> ()) usage_msg;

  if !generate_latex then (
    if !topic_name = "" || List.length !question_ids_to_add = 0 then (
      print_endline "Please provide a valid topic name and at least one question ID.";
      exit 1;
    );

    let include_answers_str = if !include_answers then "yes" else "no" in
      let prefixed_qids = List.map (fun qid -> !topic_name ^ qid) !question_ids_to_add in
      print_endline ("Generating LaTeX file: " ^ !filename);
      print_endline ("Topic: " ^ !topic_name);
      print_endline ("Question IDs: " ^ String.concat "," prefixed_qids);
      print_endline ("Include Answers: " ^ include_answers_str);
      generate_latex_file bank !topic_name prefixed_qids !filename !include_answers;
      print_endline "LaTeX file generated.";
      exit 0;

  );

  let rec add_questions_answers qids aids =
    match qids, aids with
    | [], [] -> ()
    | qid :: qrest, aid :: arest ->
      let topic_and_qid = !topic_name ^ qid in  
      print_string ("Enter question for ID " ^ topic_and_qid ^ ": ");
      let question_text = read_line () in
      add_question bank topic_and_qid question_text;  
      print_endline ("Question added with ID: " ^ topic_and_qid);
      print_newline ();

      let topic_and_aid = !topic_name ^ aid in  
      print_string ("Enter answer for question ID " ^ topic_and_aid ^ ": ");
      let answer_text = read_line () in
      add_answer bank topic_and_aid answer_text; 
      print_endline "Answer added.";
      print_newline ();

      add_questions_answers qrest arest
    | _, _ ->
      print_endline "Invalid input. Number of question IDs should match the number of answer IDs.";
      exit 1
  in
  add_questions_answers !question_ids_to_add !answer_ids_to_add;
;;

let () =
  let question_bank = init_question_bank () in
  create_tables question_bank.db;
  main question_bank;
  ignore (Sqlite3.db_close question_bank.db);
  print_endline "Goodbye!"
