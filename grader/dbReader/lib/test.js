var db = connect('localhost:27017/wbDB');
var ii = 0;
db.attempts.find(
    {
        "mp_id": "1",
        "user": {$type: 2},
        "attempts": {$type: 3}
    }
).forEach(function(entry) {
    last_attempt = undefined;
    attempt_count = 0;
    entry.attempts.forEach(function(attempt) {
        if (attempt.submitted_program ||
            attempt.saved_program ||
            attempt.SolutionData == undefined ||
            attempt.SolutionData.CorrectQ == false) {
            return ;
        }
        date = Date(attempt.created_on);
        if (last_attempt == undefined || last_attempt.date > date) {
            last_attempt = attempt;
            last_attempt.created_on = date;
        }
        attempt_count++;
    });
    /*
    if (last_attempt == undefined) {
        last_attempt = {
            "ProgramText": ""
        }
    }
    */
    /*
    if (entry.attempts.length == 1) {
        print("-en------------------");
        printjson(entry);
        print("-done------------------");
    }
    */
    if (last_attempt != undefined) {
        entry = {
            "user": entry.user,
            "mp_id": parseInt(entry.mp_id),
            "success": last_attempt.SolutionData.CorrectQ,
            "program": last_attempt.ProgramText,
            "attempt_count": attempt_count,
            "created_on": last_attempt.created_on
        };
        print(tojson(entry, false, false));
    }
});
