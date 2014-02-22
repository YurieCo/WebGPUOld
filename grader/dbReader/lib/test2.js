var db = connect('localhost:27017/wbDB');
db.attempts.find({
    "mp_id": "1",
    "user": {$type: 2},
    "attempts": {$type: 3},
    "attempts.ProgramText": {$type: 2}
}, {
    "attempts.SolutionData": 0
}).forEach(function(entry) {
    entry._id = entry.user;
    entry.created_at = 0;
    entry.updated_on = 0;
    printjson(entry);
})

