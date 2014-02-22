var db = connect('localhost:27017/wbDB');
db.attempts.find({
    "mp_id": "2",
    "user": {$type: 2},
    "attempts": {$type: 3},
    "attempts.ProgramText": {$type: 2}
}, {
    "attempts.SolutionData.InputFiles": 0,
    "attempts.SolutionData.InputData": 0,
    "attempts.SolutionData.UserOutputData": 0,
    "attempts.SolutionData.ExpectedOutputData": 0,
}).forEach(function(entry) {
    attempt_count = 0;
    entry.attempts.forEach(function(attempt) {
        if (attempt.submitted_program ||
            attempt.saved_program ||
            attempt.SolutionData == undefined) {
            return ;
        }
        attempt_count++;
    });
    printjson(attempt_count);
})

