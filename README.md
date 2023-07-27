# QuestionBank
Creates a Latex File that can be used to generate a question bank for educational purposes. 

HOW TO USE:

0) Make sure you have dune setup for OCaml since this is done in dune after all.
1) First you can download the entire repository in your local device. For Windows users, make sure to open it in Linux. (Either virtual machine or in VS-Code via Ubuntu)
2) Although the Sqlite3 module will already be in the dune package, in case of any error, make sure you have it installed already. The end result should be as provided in the code,

`./bin/dune`
```(executable
 (public_name practice)
 (name main)
 (libraries  sqlite3))
```

 as  " `(libraries  sqlite3))`"
 
3) You can delete the `.tex` files and `question_bank.db` and start fresh. Keeping it won't do any harm either, it contains the examples I used while building, for test purposes.
4) First off we start by going into the current directory as in  `cd "DIRECTORY_NAME"`
5) Then we follow this procedure

<h3><strong>dune build</strong></h3> (For building the dune application) <br></br>


<h2><strong>ADDING QUESTIONS-ANSWERS WITH TOPIC NAME IN DATABASE:</strong></h2>

`dune exec ./bin/main.exe -- -t "TOPIC_NAME" -q "COMMA SEPARATED QUES IDS" -a "ANSWERS FOR RESP. QUES"` <br></br>
Sample usage: (For creating questions 1,2 for the topic OS): <br></br> 
`dune exec ./bin/main.exe -- -t OS -q 1,2 -a 1,2` <br></br>

<h2><strong>CREATING A LATEX FILE THAT CAN INCLUDE/EXCLUDE ANSWERS</strong></h2>

`dune exec ./bin/main.exe -- -gen "LATEX_FILE.tex" -t "TOPIC_NAME" -q "COMMA SEPARATED QUES IDS" -include` <br></br>
-include includes answers in Latex File. IF we DO NOT WANT ANSWERS, in out question bank, we can simply remove include tag <br></br>
`dune exec ./bin/main.exe -- -gen "LATEX_FILE.tex" -t "TOPIC_NAME" -q "COMMA SEPARATED QUES IDS"` <br></br>

Sample usage: (For creating a latex file named "OS3.tex" including questions (and answers) for the Topic Name OS):
Note that, the topic name must actually contain the respective questions in the question bank.<br></br>

`dune exec ./bin/main.exe -- -gen OS3.tex -t OS -q 1,2 -include` <br></br>
`dune exec ./bin/main.exe -- -gen OS3.tex -t OS -q 1,2` <br></br>

That marks the end of usage for this program. Hopefully this helped.




