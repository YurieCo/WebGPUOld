var db = connect('localhost:27017/wbDB');
db.attempts.find({
}).forEach(function(entry) {
    entry.attempts.forEach(function(attempt) {
        if (attempt.ProgramText != undefined)
            printjson(attempt.created_on)
    })
})

