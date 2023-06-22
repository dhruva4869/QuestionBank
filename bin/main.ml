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
      id INTEGER PRIMARY KEY,
      text TEXT NOT NULL
    );
  " in
  let create_answers_table = "
    CREATE TABLE IF NOT EXISTS answers (
      question_id INTEGER NOT NULL,
      text TEXT NOT NULL,
      FOREIGN KEY(question_id) REFERENCES questions(id)
    );
  " in
  ignore (Sqlite3.exec db create_questions_table);
  ignore (Sqlite3.exec db create_answers_table)

let add_question (bank : question_bank) (question_id : int) (q_text : string) : unit =
  let insert_question = "
    INSERT INTO questions (id, text) VALUES (?, ?)
  " in
  let stmt = Sqlite3.prepare bank.db insert_question in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int question_id)));
  ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT q_text));
  ignore (Sqlite3.step stmt);
  ignore (Sqlite3.finalize stmt)

let add_answer (bank : question_bank) (q_id : int) (a_text : string) : unit =
  let insert_answer = "
    INSERT INTO answers (question_id, text) VALUES (?, ?)
  " in
  let stmt = Sqlite3.prepare bank.db insert_answer in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int q_id)));
  ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.TEXT a_text));
  ignore (Sqlite3.step stmt);
  ignore (Sqlite3.finalize stmt)

let get_answers (bank : question_bank) (q_id : int) : (answer * answer) list =
  let select_answers = "
    SELECT q.text, a.text
    FROM questions q
    JOIN answers a ON q.id = a.question_id
    WHERE q.id = ?
  " in
  let stmt = Sqlite3.prepare bank.db select_answers in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.INT (Int64.of_int q_id)));
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

let generate_latex_file (bank : question_bank) (qid : int) (filename : string) : unit =
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
  let latex_content =
    "\n\n\\section{Question Q" ^ string_of_int qid ^ "}\n\n" ^
    question_text ^ "\n\n" ^
    "Answer: " ^ answers_text ^ "\n"
  in
  let oc = open_out_gen [Open_creat; Open_text; Open_append] 0o666 filename in
  output_string oc latex_content;
  close_out oc

let rec main (bank : question_bank) : unit =
  print_endline "What would you like to do?";
  print_endline "1. Add question";
  print_endline "2. Add answer";
  print_endline "3. View answers";
  print_endline "4. Generate LaTeX file";
  print_endline "5. Exit";
  print_string "Enter your choice: ";
  match read_int () with
  | 1 ->
    print_string "Enter question ID: ";
    let question_id = read_int () in
    print_string "Enter question: ";
    let question_text = read_line () in
    add_question bank question_id question_text;
    print_endline ("Question added with ID: " ^ string_of_int question_id);
    print_newline ();
    main bank
  | 2 ->
    print_string "Enter question ID: ";
    let question_id = read_int () in
    print_string "Enter answer: ";
    let answer_text = read_line () in
    add_answer bank question_id answer_text;
    print_endline "Answer added.";
    print_newline ();
    main bank
  | 3 ->
    print_string "Enter question ID: ";
    let question_id = read_int () in
    let question_answers = get_answers bank question_id in
    if List.length question_answers > 0 then (
      let _, answer = List.hd question_answers in
      print_endline ("Question: " ^ answer.text);
      print_endline "Answers:";
      List.iter (fun (_, a) -> print_endline a.text) question_answers
    ) else (
      print_endline "No answers found for the question."
    );
    print_newline ();
    main bank
  | 4 ->
    print_string "Enter question ID: ";
    let question_id = read_int () in
    print_string "Enter filename for LaTeX file: ";
    let filename = read_line () in
    generate_latex_file bank question_id filename;
    print_endline ("LaTeX file generated: " ^ filename);
    print_newline ();
    main bank
  | 5 ->
    ignore (Sqlite3.db_close bank.db);
    print_endline "Goodbye!"
  | _ ->
    print_endline "Invalid choice.";
    main bank

let () =
  let question_bank = init_question_bank () in
  create_tables question_bank.db;
  main question_bank