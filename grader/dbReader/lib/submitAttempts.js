var db = connect('localhost:27017/wbDB');
[1,2,3,4,5,6,10,20,30,40,50].forEach(function(mp) {
    var count = 0;
    db.attempts.find({
        "mp_id": "" + mp
    }).forEach(function(entry) {
        entry.attempts.forEach(function(attempt) {
            if (attempt.ProgramText != undefined) {
                count++;
            }
        });
    })
    printjson({"mp_id": mp, "count": count});
})
