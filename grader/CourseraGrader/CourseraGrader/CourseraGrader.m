
(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)

BeginPackage["CourseraGrader`", {"CUDALink`", "CCompilerDriver`", "CUDALink`NVCCCompiler`", "JSONTools`"}]

$SubmissionDB;
$UserDB;

$Scores;
$Comments;
$DatasetFailures;

$ScoresFile;
$CommentsFile;
$DatasetFailuresFile;

$WorkingDir;
$DatasetDir;

grade;
datasets;

readEntry;


(*
Begin["`Private`"]
*)


(*********************************************************)

$ThisFile = $InputFileName
$ThisDirectory = DirectoryName[$ThisFile]

(*********************************************************)
(*********************************************************)


$UserDB = FileNameJoin[{$ThisDirectory, "SystemResources", "users.csv"}]
$SubmissionDB = FileNameJoin[{$ThisDirectory, "db.json"}]
$SubmissionDB = FileNameJoin[{$ThisDirectory, "mp50_programs"}]

(*********************************************************)
(*********************************************************)

$Scores = {}
$DatasetFailures = {}
$Comments = {}

$GradeDir = FileNameJoin[{"/home/abduld/mp50", "grades"}]
$ScoresFile = FileNameJoin[{$ThisDirectory, "scores.csv"}]
$CommentsFile = FileNameJoin[{$ThisDirectory, "comments.csv"}]
$DatasetFailuresFile = FileNameJoin[{$ThisDirectory, "failures.csv"}]
$WorkingDir = FileNameJoin[{"/tmp", "working"}]
$DatasetDir = FileNameJoin[{$ThisDirectory, "dataset"}]
$SupportDir = FileNameJoin[{$ThisDirectory, "support"}]
$SubmissionDirectory = FileNameJoin[{$ThisDirectory, "submission"}]

(*********************************************************)
(*********************************************************)


datasetBaseDir[1 | 10] =
    FileNameJoin[{$ThisDirectory, "..", "..", "..", "server-coffee", "mp", "1", "data"}];

datasetBaseDir[2 | 20] =
    FileNameJoin[{$ThisDirectory, "..", "..", "..", "server-coffee", "mp", "2", "data"}];

datasetBaseDir[3 | 30] =
    FileNameJoin[{$ThisDirectory, "..", "..", "..", "server-coffee", "mp", "3", "data"}];

datasetBaseDir[4 | 40] =
    FileNameJoin[{$ThisDirectory, "..", "..", "..", "server-coffee", "mp", "4", "data"}];

datasetBaseDir[5 | 50] =
    FileNameJoin[{$ThisDirectory, "..", "..", "..", "server-coffee", "mp", "5", "data"}];

datasetBaseDir[6] =
    FileNameJoin[{$ThisDirectory, "..", "..", "..", "server-coffee", "mp", "6", "data"}];

ClearAll[datasets]
datasets[n_] := datasets[n] = FileNameJoin[{datasetBaseDir[n], ToString@#}]& /@ Range[0, 9]

ClearAll[datasetInputs]
datasetInputs[4 | 40, dir_] :=
	{
		FileNameJoin[{dir, "input0.raw"}]
	}

datasetInputs[5 | 50, dir_] :=
	{
		FileNameJoin[{dir, "input.raw"}]
	}

datasetInputs[6, dir_] :=
	{
		FileNameJoin[{dir, "input0.ppm"}],
		FileNameJoin[{dir, "input1.csv"}]
	}

datasetInputs[1 | 10 | 2 | 20 | 3 | 30, dir_] :=
	{
		FileNameJoin[{dir, "input0.raw"}],
		FileNameJoin[{dir, "input1.raw"}]
	}

ClearAll[datasetOutput]
datasetOutput[6, dir_] :=
	FileNameJoin[{dir, "output.ppm"}]

datasetOutput[1 | 10 | 2 | 20 | 3 | 30 | 4 | 40 | 5 | 50, dir_] :=
	FileNameJoin[{dir, "output.raw"}]

ClearAll[formatDatasetInputs]
formatDatasetInputs[n_, dir_] :=
	StringJoin[
		"-i ",
		Riffle[datasetInputs[n, dir], ","]
	]

ClearAll[formatDataset]
formatDataset[n_, m_] := formatDataset[n, m] =
    Module[{base = datasets[n][[m+1]], inputs, output},
        inputs = datasetInputs[n, base];
        output = datasetOutput[n, base];
        StringJoin[
            " -i ",
            Riffle[inputs, ","],
            " -e ",
            output,
            " -t ",
            "vector"
        ]
    ]

(*********************************************************)
(*********************************************************)
(*
If[DirectoryQ[$GradeDir],
    RenameDirectory[$GradeDir, $GradeDir <> ToString[RandomInteger[100]]]

];
*)

Quiet@CreateDirectory[$GradeDir];

If[DirectoryQ[$WorkingDir],
    (* RenameDirectory[$WorkingDir, $WorkingDir <> ToString[RandomInteger[100]]] *)
    DeleteDirectory[$WorkingDir, DeleteContents -> True]

];

CreateDirectory[$WorkingDir];

(*********************************************************)
(*********************************************************)

updateTable[] :=
    (
        Export[$ScoresFile, $Scores /. Rule -> List, "CSV"];
        Export[$CommentsFile, $Comments /. Rule -> List, "CSV"];
        Export[$DatasetFailuresFile, $DatasetFailures /. Rule -> List, "CSV"];
    )


(*********************************************************)
(*********************************************************)

strm := strm = OpenRead[$ProgramEntries]

readLine[] :=
	Module[{line = Read[strm, String]},
		If[StringQ[line],
			line,
			$Failed
		]
	]

nextEntry[] :=
	Module[{line, entry = ""},
		line = readLine[];
		While[StringQ[line] && line != "}",
			 entry = entry <> line;
			 line = readLine[]
		];
		If[StringQ[line],
			entry = ImportString[entry <> "}", "JSON"],
			entry = $Failed
		];
		entry
	]

(*********************************************************)
(*********************************************************)

programReplacements = {
	"cudaMalloc" -> "wbCUDAMalloc",
	"cudaFree" -> "wbCUDAFree",
	"cudaMemcpy" -> "wbCUDAMemCpy",
    "\[OpenCurlyDoubleQuote]" -> "\"",
    "\[CloseCurlyDoubleQuote]" -> "\""
}

(*********************************************************)
(*********************************************************)


ClearAll[compile]
compile[user_, dir_] :=
	Module[{mainPath, workingDir, cmp, programErr},
		mainPath = FileNames["main.cu", dir, Infinity];
        If[mainPath === {},
            Return[$Failed]
        ];
        mainPath = First[mainPath];
		workingDir = FileNameJoin[{$WorkingDir, user}];
		mainPath = CopyFile[mainPath, FileNameJoin[{workingDir, "main.cu"}]];
		cmp = CreateExecutable[{mainPath},
							   "main",
							   "TargetDirectory" -> workingDir,
                               "IncludeDirectories" -> $SupportDir,
							   "Compiler" -> NVCCCompiler,
                               "Libraries" -> "rt",
                               "CompilerInstallation" -> "/usr/local/cuda",
                                "ShellOutputFunction" -> ((programErr = #)&)
		];
		{cmp, programErr}
	]
	
(*********************************************************)
(*********************************************************)

userData := userData = Import[$UserDB, "CSV"]

users := users = Dispatch[MapThread[Rule, Transpose[Reverse /@ userData]]]

getUser[user_] := user /. users

(*********************************************************)
(*********************************************************)

dbStream := dbStream = OpenRead[$SubmissionDB]

readLine[] := line = Read[dbStream, String];

readEntry[] :=
    Module[{line, str},
        line = readLine[];
        If[line === EndOfFile,
            Return[$Failed]
        ];
        str = line;
        While[line =!= "}",
            line = readLine[];
            str = str <> line;
        ];
        If[StringQ[str],
            str = StringReplace[str, "ISODate(" ~~ x___ ~~ ")" -> x];
            ImportString[str, "JSON"],
            $Failed
        ]
    ]

mp1Score = {
    "Compilation" -> 0.3,
    "Correctness" -> 0.5,
    "MemoryLeaks" -> 0.1,
    "Performance" -> 0.1
};

mp2Score = {
    "Compilation" -> 0.15,
    "Correctness" -> 0.6,
    "MemoryLeaks" -> 0.1,
    "Performance" -> 0.05
};

checkCompilationWarnings[] :=
    Module[{},
        True
    ]

checkCorrectness[] :=
    Module[{},
        True
    ]
checkCUDAMemoryLeaks[] :=
    Module[{},
        True
    ]

ClearAll[gradeProgram]
gradeProgram[user_, exe_ /; !FileExistsQ[exe]] :=
    "Run" -> "CompileFailed"

gradeProgram[user_, exe_ /; FileExistsQ[exe]] :=
	Module[{results, res, cons, txt, tmp, mpId},
        mpId = 50;
        results = Table[
            xPrint["dataset ", ii];
            xPrint[exe <> formatDataset[mpId, ii]];
            cons = TimeConstrained[
                {time, txt} = AbsoluteTiming[
                    Import["!" <> exe <> formatDataset[mpId, ii] <> " 2>&1", "Text"]
                ],
                15
            ];
            If[cons === $Aborted,
                xPrint[exe <> formatDataset[mpId, ii] <> " 2&>1"];
                res = {
                    "CUDAMemory" -> 0,
                    "Solution" -> {
                        "CorrectQ" -> False,
                        "Message" -> "15 second time constraint reached when running program."
                    }
                },
                txt = StringReplace[txt, ___ ~~ "==$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$" ~~ x___ :> x];
                txt = StringTrim[txt, "Aborted (core dumped)"];
                tmp = If[StringTrim[txt] === "",
                    $Failed,
                    Quiet@ImportString[txt, "JSON"]
                ];
                If[!ListQ[tmp],
                    xPrint[" Failed ", txt];
                    xPrint[" Failed 2 ", tmp];
                    xPrint[exe <> formatDataset[mpId, ii] <> " 2&>1"];
                    res = {
                        "CUDAMemory" -> 0,
                        "Solution" -> {
                            "CorrectQ" -> False,
                            "Message" -> "Failed to run program. Got " <> txt
                        }
                    },
                    res = tmp;
                    res = Append[res, "Time" -> time]
                ];
                Append[res, "Dataset" -> ii]
            ],
            {ii, 0, 9}
        ];
        "Run" -> results
	]

replaceWbCheck[str_] :=
    StringReplace[
        str,
        {
            "#define wbCheck" -> "#define wbCheck",
            "wbCheck" -> "wbStmt"
        }
    ]

replaceCUDAAllocs[str0_] :=
    Module[{str = str0},
        str = StringReplace[
            str,
            {
                "cudaFree(" -> "wbCUDAFree( (void *)",
                "cudaMalloc(" -> "wbCUDAMalloc( (void **)"
            }
        ];
        str = StringReplace[str, "( (void **)(void **)" -> "((void **)"];
        str = StringReplace[str, "( (void **) (void **)" -> "((void **)"];
        str = StringReplace[str, "( (void **)(void**)" -> "((void **)"];
        str = StringReplace[str, "( (void **) (void**)" -> "((void **)"];
        str = StringReplace[str, "free(" ~~ Shortest[mem___] ~~ ");" :> ("wbFree("<> mem <> ");")];
        str = StringReplace[str, "malloc(" ~~ Shortest[sz___] ~~ ");" :> ("wbMalloc(" <> sz <> ");")];
        str
    ]

ClearAll[grade]
grade[entry_List] :=
	Module[{
            user, mpId, attempts,
            programAttempts, lastSubmission,
            lastSubmissionTime, lastSubmissionProgram,
            courseraUser, exe, out
        },
		user = ("user" /. entry) /. "user" -> Null;
        If[user == Null,
            Return[]
        ];
		mpId = 50;
        If[!StringQ[user] || !IntegerQ[mpId] || mpId < 0,
            Return[]
        ];
        courseraUser = user /. users;
		attempt = replaceCUDAAllocs["program" /. entry];
		attempt = replaceWbCheck[attempt];
        {exe, out} = compileProgram[user, attempt];
        Export[
            FileNameJoin[{$GradeDir, user}],
            {
                "user" -> user,
                "mp" -> mpId,
                "program" -> ("program" /. entry),
                "compile_message" -> out,
                gradeProgram[user, exe]
            },
            "JSON"
        ]
	]

compileProgram[user_, attempt_] :=
    Module[{workDir, file, buildFile, buildOut},
        workDir = FileNameJoin[{$WorkingDir, user}];
        CreateDirectory[workDir];
        buildFile = copyBuildFile[workDir];
        Print["Compiling ", workDir];
        file = Export[FileNameJoin[{workDir, "program.cu"}], attempt, "Text"];
        SetDirectory[workDir];
        buildOut = Import["!./build.sh", "Text"];
        ResetDirectory[];
        {FileNameJoin[{workDir, "program"}], buildOut}
    ]

copyBuildFile[workDir_] :=
    Module[{buildFile},
        buildFile = FileNameJoin[{$ThisDirectory, "build.sh"}];
        CopyFile[buildFile, FileNameJoin[{workDir, "build.sh"}]]
    ]



(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)


(* End[] *)

EndPackage[]


(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)
(*********************************************************)


