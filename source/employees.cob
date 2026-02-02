       IDENTIFICATION DIVISION.
       PROGRAM-ID. employees.
      * load employee data from CSV file into an indexed file
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

         SELECT emp-in-file
           ASSIGN TO "employees.csv"
           ORGANIZATION IS LINE SEQUENTIAL
           FILE STATUS IS ws-fs-in.

         SELECT emp-out-file
           ASSIGN TO "employees.idx"
           ORGANIZATION IS INDEXED
           ACCESS MODE IS DYNAMIC
           RECORD KEY IS emp-id
           FILE STATUS IS ws-fs-out.

       DATA DIVISION.
       FILE SECTION.
       FD emp-in-file
          RECORD CONTAINS 512 CHARACTERS
          LABEL RECORDS ARE STANDARD.
       01 in-line PIC X(512).

       FD  emp-out-file.
       COPY "EMPLOYEES.CPY".

       WORKING-STORAGE SECTION.

       01 ws-fs-in  PIC XX.
       01 ws-fs-out PIC XX.

       01 ws-text-fields.
          05 ws-emp-id-txt     PIC X(20).
          05 ws-first-txt      PIC X(40).
          05 ws-last-txt       PIC X(40).
          05 ws-genderid-txt   PIC X(5).
          05 ws-dob-txt        PIC X(20).
          05 WS-AGE-TXT        PIC X(5).
          05 ws-deptid-txt     PIC X(5).
          05 ws-entry-txt      PIC X(20).
          05 ws-los-txt        PIC X(20).
          05 ws-roleid-txt     PIC X(5).
          05 ws-dummy-txt      PIC X(5).

       01 ws-dob-yyyy-txt   PIC X(4).
       01 ws-dob-mm-txt     PIC X(2).
       01 ws-dob-dd-txt     PIC X(2).

       01 ws-entry-yyyy-txt PIC X(4).
       01 ws-entry-mm-txt   PIC X(2).
       01 ws-entry-dd-txt   PIC X(2).

       PROCEDURE DIVISION.

       MAIN-LOGIC.

           OPEN INPUT emp-in-file
                OUTPUT emp-out-file.

           IF ws-fs-in NOT = "00"
               DISPLAY "OPEN INPUT FAILED, FS=" ws-fs-in
               STOP RUN
           END-IF.

           IF ws-fs-out NOT = "00"
               DISPLAY "OPEN OUTPUT FAILED, FS=" ws-fs-out
               STOP RUN
           END-IF.

           PERFORM LOAD-LOOP UNTIL ws-fs-in = "10".

           CLOSE emp-in-file
                 emp-out-file.

           DISPLAY "LOAD COMPLETE.".

           STOP RUN.

       LOAD-LOOP.

           READ emp-in-file
               AT END MOVE "10" TO ws-fs-in
               NOT AT END
                   PERFORM PROCESS-LINE
           END-READ.

       PROCESS-LINE.

           DISPLAY in-line.

           UNSTRING in-line DELIMITED BY ","
             INTO ws-emp-id-txt
                  ws-first-txt
                  ws-last-txt
                  ws-genderid-txt
                  ws-dob-txt
                  WS-AGE-TXT
                  ws-deptid-txt
                  ws-entry-txt
                  ws-los-txt
                  ws-roleid-txt
                  ws-dummy-txt
           END-UNSTRING.

           INSPECT ws-text-fields
               REPLACING ALL X"0D" BY SPACE
                         ALL X"0A" BY SPACE
                         ALL X"09" BY SPACE
                         ALL '"'   BY SPACE.

           UNSTRING ws-dob-txt DELIMITED BY "/"
             INTO ws-dob-dd-txt ws-dob-mm-txt ws-dob-yyyy-txt
           END-UNSTRING.

           UNSTRING ws-entry-txt DELIMITED BY "/"
             INTO ws-entry-dd-txt ws-entry-mm-txt ws-entry-yyyy-txt
           END-UNSTRING.

           MOVE ws-first-txt TO emp-first-name.

           MOVE ws-last-txt TO emp-last-name.

           MOVE FUNCTION NUMVAL-C(ws-emp-id-txt)       TO emp-id.
           MOVE FUNCTION NUMVAL-C(ws-genderid-txt)     TO emp-gender-id.

           MOVE FUNCTION NUMVAL-C(ws-dob-yyyy-txt)     TO emp-dob-yyyy.
           MOVE FUNCTION NUMVAL-C(ws-dob-mm-txt)       TO emp-dob-mm.
           MOVE FUNCTION NUMVAL-C(ws-dob-dd-txt)       TO emp-dob-dd.

           MOVE FUNCTION NUMVAL-C(ws-deptid-txt)       TO emp-dept-id.
           MOVE FUNCTION NUMVAL-C(ws-roleid-txt)       TO emp-role-id.

           MOVE FUNCTION NUMVAL-C(ws-entry-yyyy-txt)   TO emp-entry-yyyy.
           MOVE FUNCTION NUMVAL-C(ws-entry-mm-txt)     TO emp-entry-mm.
           MOVE FUNCTION NUMVAL-C(ws-entry-dd-txt)     TO emp-entry-dd.

           WRITE EMP-REC
             INVALID KEY
               DISPLAY "DUPLICATE KEY FOR emp-id=" emp-id.
