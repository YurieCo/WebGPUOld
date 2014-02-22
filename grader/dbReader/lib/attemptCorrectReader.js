var db = connect('localhost:27017/wbDB');
db.attempts.find({
    "mp_id": "4"
}).forEach(function(entry) {
    var last_attempt = undefined;
    //var final_date = (new Date(2012, 12, 27, 4, 0, 0, 0)).getTime()
    var program = "";
    var final_date = (new Date(2013, 1, 8, 4, 0, 0, 0)).getTime()
    var correctQ = {0: false, 1: false, 2: false, 3: false, 4: false, 5: false};
    entry.attempts.forEach(function(attempt) {
        if (attempt.created_on != undefined) {
            var date = ISODate(attempt.created_on).getTime();
            if (date > final_date) {
                return ;
            }
            if (attempt.SolutionData) {
                var dataset = attempt.SolutionData.DatasetId;
                if (correctQ[dataset] == false) {
                    correctQ[dataset] = attempt.SolutionData.CorrectQ;
                    if (correctQ[0] == true &&
                        correctQ[1] == true &&
                        correctQ[2] == true &&
                        correctQ[3] == true &&
                        correctQ[4] == true &&
                        correctQ[5] == true
                       ) {
                            program = attempt.ProgramText;
                       }
                }
            }
        }
    });
    if (program == "") {
        entry.attempts.forEach(function(attempt) {
            if (attempt.created_on != undefined) {
                var date = ISODate(attempt.created_on).getTime();
                if (date > final_date) {
                    return ;
                }
                if (last_attempt == undefined || last_attempt.created_on < date) {
                    last_attempt = attempt;
                    last_attempt.created_on = date;
                }
            }
        });
        if (last_attempt == undefined) {
            var program;
            var attempt = entry.attempts[entry.attempts.length - 1];
            if (attempt.submitted_program) {
                program = attempt.submitted_program;
            } else {
                program = attempt.saved_program;
            }
        } else {
            program = last_attempt.ProgramText;
        }
    }
    printjson({
        "user": entry.user,
        "program": program,
        "correctQ": correctQ
    });
})

