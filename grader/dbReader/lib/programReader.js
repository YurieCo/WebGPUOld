var db = connect('localhost:27017/wbDB');
db.attempts.find({
    "mp_id": "1",
    "user": {$type: 2},
    "attempts": {$type: 3},
    "attempts.ProgramText": {$type: 2}
}, {
    "attempts.SolutionData": 0
}).forEach(function(entry) {
    var printed = false;
    entry.attempts.forEach(function(attempt) {
        if (attempt.ProgramText != undefined && printed == false) {
            printjson(entry.user);
            printed = true;
        }
    })
})

