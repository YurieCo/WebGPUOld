var db = connect('localhost:27017/wbDB');
db.attempts.find({
    "mp_id": "1",
    "user": {$type: 2},
    "attempts": {$type: 3},
    "attempts.ProgramText": {$type: 2},
    "attempts.SolutionData.DatasetId": 0
}, {
    "attempts.SolutionData.InputFiles": 0,
    "attempts.SolutionData.InputData": 0,
    "attempts.SolutionData.OutputData": 0,
    "attempts.SolutionData.UserOutputData": 0,
    "attempts.SolutionData.ExpectedOutputData": 0,
}).forEach(function(entry) {
    entry.attempts.forEach(function(attempt) {
        if (attempt.ProgramText != undefined &&
            attempt.Correctness === true &&
            attempt.ProgramTimer != undefined)
            printjson(attempt.ProgramTimer.ElapsedTime)
    })
})

