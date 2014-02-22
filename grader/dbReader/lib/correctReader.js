var db = connect('localhost:27017/wbDB');
db.attempts.find({
    "mp_id": "3",
    "user": {$type: 2},
    "attempts": {$type: 3},
    "attempts.ProgramText": {$type: 2}
}, {
    "attempts.SolutionData": 0
}).forEach(function(entry) {
    var printed = false;
    entry.attempts.forEach(function(attempt) {
        if (printed == false && attempt.Correctness == true) {
            printjson(entry.user);
            printed = true;
        }
    })
})

