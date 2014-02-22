var db = connect('localhost:27017/wbDB');
[1,2,3,4,5,6,10,20,30,40,50].forEach(function(mp) {
    var count = 0;
    var length = 0;
    db.attempts.find({
        "mp_id": "" + mp
    }).forEach(function(entry) {
        entry.attempts.forEach(function(attempt) {
            var program = undefined;
            if (attempt.submitted_program) {
                program = attempt.submitted_program;
            } else if (attempt.saved_program){
                program = attempt.saved_program;
            } else {
                program = attempt.ProgramText;
            }
            if (program) {
                var lines = program.split("\n");
                length += lines.length;
                count++;
            }
        });
    })
    printjson({"mp_id": mp, "count": count, "length": length, "avgLength": length/count});
})
