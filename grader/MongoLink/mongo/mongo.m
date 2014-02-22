(* Mathematica Package *)

(* Author: Zach Bjornson *)

BeginPackage["mongo`", {"JLink`"}]

OpenConnection::usage=
"OpenConnection[] opens a connection to localhost:27017.
OpenConnection[host, port] opens a connection to the specified host and port.
In either case, the database server must already be running; this function will not start the server.";

GetDatabase::usage=
"GetDatabase[connection, database] returns the specified database object.";

CollectionNames::usage=
"CollectionNames[database] returns a list of collection names in the specified database.";

GetCollection::usage=
"GetCollection[database, collection] gets or creates the specified collection.";

FindDocuments::usage=
"FindDocuments[collection] returns all documents from a collection.
FindDocuments[collection, query] selects all documents from a collection that satisfy the criteria of the query.
FindDocuments[collection, query, projection] returns only those field specified by projection.";

InsertDocument::usage=
"InsertDocument[collection, document] inserts a list of rules (a document) into a collection.";

DropCollection::usage=
"DropCollection[collection] drops a collection.";

DropDatabase::usage=
"DropDatabase[connection, database] drops a database by name.";

mongo::tostr = "Warning: calling toString on `1`, which is not specifically handled."; 

Begin["`Private`"]
(* Implementation of the package *)

$rulepattern = {(_Rule | _RuleDelayed) ..};

OpenConnection[] := OpenConnection["localhost", 27017]

OpenConnection[host_String, port_Integer] :=
	JavaNew["com.mongodb.MongoClient",host,port];

GetDatabase[connection_Symbol, database_String] := 
	connection@getDB[database];

DropDatabase[connection_Symbol, database_String] :=
	connection@dropDatabase[database];

CollectionNames[database_Symbol] :=  Module[{collections}, 
	collections = database@getCollectionNames[];
	collections@toArray[]
]

GetCollection[database_Symbol, collection_String] :=
	database@getCollection[collection];

DropCollection[collection_Symbol] := collection@drop[];

InsertDocument[collection_Symbol, document : $rulepattern] := Module[{docobj, result},
	docobj = serialize[document];
	result = collection@insert[{docobj}];
	result@getN[]
]

serialize[x : $rulepattern] := serialize[Null, x]

serialize[_, x : $rulepattern] := 
  Module[{newdbobj = JavaNew["com.mongodb.BasicDBObject"]}, 
   Map[serialize[newdbobj, #] &, x]; newdbobj]

serialize[dbobj_, Rule[k_String, v_]] := 
   dbobj@append[MakeJavaObject[k], serialize[dbobj, v]]

serialize[dbobj_, x_] := MakeJavaObject[x] (*:(_Integer|_Real|_String|_List|True|False)*)

serialize[dbobj_, x_?JavaObjectQ] := x

FindDocuments[collection_Symbol] := Module[{cursor},
	cursor = collection@find[];
	processResults[cursor]
]

FindDocuments[collection_Symbol, query : $rulepattern] := Module[{serializedQuery, cursor},
	serializedQuery = serialize[query];
	cursor = collection@find[serializedQuery];
	processResults[cursor]
]

FindDocuments[collection_Symbol, query : $rulepattern, projection_List] := Module[{serializedQuery, serializedProjection},
	serializedQuery = serialize[query];
	serializedProjection = serialize[#->1 &/@ projection];
	cursor = collection@find[serializedQuery, serializedProjection];
	processResults[cursor]
]

processResults[cursor_] := Module[{results},
	results = Reap[
		While[cursor@hasNext[],
			Sow[deserialize[cursor@next[]]];
		]
	][[2]];
	cursor@close[];
	If[Length[results], results = results[[1]]];
	Return[results]
]

deserialize[x_?JavaObjectQ] := Module[{it, pairs, result},
   it = x@entrySet[]@iterator[];
   result = Reap[
     While[it@hasNext[],
      pairs = it@next[];
      Sow[pairs@getKey[] -> deserialize[pairs@getValue[]]]
      ]
     ][[2]];
   If[Length[result], result = result[[1]]];
   Return[result]
   ] /; InstanceOf[x, "com.mongodb.BasicDBObject"]

deserialize[x_?JavaObjectQ] := Return[x@toString[]] /; InstanceOf[x, "org.bson.types.ObjectId"]

deserialize[x_?JavaObjectQ] := Return[x@toArray[]] /; InstanceOf[x, "com.mongodb.BasicDBList"]

(*Fallback*)
deserialize[x_?JavaObjectQ] := (
	Message[mongo::tostr, ClassName[x]];
	Return[x@toString[]])

(*Native type*)
deserialize[x_] := x

End[]

EndPackage[]

