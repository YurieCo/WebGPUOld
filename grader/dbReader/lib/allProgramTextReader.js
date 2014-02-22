var db = connect('localhost:27017/wbDB');
db.attempts.find({
    "mp_id": "1",
    "user": {$type: 2},
    "attempts": {$type: 3},
    "attempts.ProgramText": {$type: 2}
}, {
    "attempts.SolutionData.InputFiles": 0,
    "attempts.SolutionData.InputData": 0,
    "attempts.SolutionData.UserOutputData": 0,
    "attempts.SolutionData.ExpectedOutputData": 0,
}).forEach(function(entry) {
    var printed = false;
    last_attempt = undefined;
    attempt_count = 0;
    entry.attempts.forEach(function(attempt) {
        if (attempt.submitted_program ||
            attempt.saved_program ||
            attempt.SolutionData == undefined ||
            /* attempt.SolutionData.CorrectQ == */ false) {
            return ;
        }
        printjson(attempt.ProgramText);
    });
})

