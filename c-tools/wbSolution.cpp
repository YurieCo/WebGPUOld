
#include    <wb.h>

#ifdef WB_USE_JSON

json_t * _solution_correctQ = NULL;

static void _onUnsameImageFunction(string str) {
    const char * c_str = str.c_str();
    _solution_correctQ = json_string(c_str);
}

static wbBool wbSolution_correctQ(char * expectedOutputFile, wbSolution_t sol) {
    wbBool res;

    if (expectedOutputFile == NULL) {
        _solution_correctQ = json_string("Failed to determined the expected output file.");
        return wbFalse;
    } else if (!wbFile_existsQ(expectedOutputFile)) {
        string str = wbString("The file ", expectedOutputFile, " does not exist.");
        _solution_correctQ = json_string(str.c_str());
        return wbFalse;
    } else if (wbString_sameQ(wbSolution_getType(sol), "image")) {
        wbImage_t solutionImage = NULL;
        wbImage_t expectedImage = wbImport(expectedOutputFile);
        if (expectedImage == NULL) {
            _solution_correctQ = json_string("Failed to open expected output file.");
            res = wbFalse;
        } else if (wbImage_getWidth(expectedImage) != wbSolution_getWidth(sol)) {
            _solution_correctQ = json_string("The image width of the expected image does not match that of the solution.");
            res = wbFalse;
        } else if (wbImage_getHeight(expectedImage) != wbSolution_getHeight(sol)) {
            _solution_correctQ = json_string("The image height of the expected image does not match that of the solution.");
            res = wbFalse;
        } else {

            solutionImage = (wbImage_t) wbSolution_getData(sol);
            wbAssert(solutionImage != NULL);

            res = wbImage_sameQ(solutionImage, expectedImage, _onUnsameImageFunction);
        }
        if (expectedImage != NULL) {
            wbImage_delete(expectedImage);
        }
        return res;
    } else if (wbString_sameQ(wbSolution_getType(sol), "vector") ||
               wbString_sameQ(wbSolution_getType(sol), "matrix")) {
        wbReal_t * expectedData;
        int expectedRows, expectedColumns;

        expectedData = (wbReal_t *) wbImport(expectedOutputFile, &expectedRows, &expectedColumns);

        if (expectedData == NULL) {
            _solution_correctQ = json_string("Failed to open expected output file.");
            res = wbFalse;
        } else if (expectedRows != wbSolution_getRows(sol)) {
            wbLog(TRACE, "Number of rows in the solution is ", wbSolution_getRows(sol),
                         ". Expected number of rows is ", expectedRows, ".");
            _solution_correctQ = json_string("The number of rows in the solution did not match that of the expected results.");
            res = wbFalse;
        } else if (expectedColumns != wbSolution_getColumns(sol)) {
            wbLog(TRACE, "Number of columns in the solution is ", wbSolution_getColumns(sol),
                         ". Expected number of columns is ", expectedColumns, ".");
            _solution_correctQ = json_string("The number of columns in the solution did not match that of the expected results.");
            res = wbFalse;
        } else {
            int ii, jj, idx;
            wbReal_t * solutionData;

            solutionData = (wbReal_t *) wbSolution_getData(sol);

            for (ii = 0; ii < expectedRows; ii++) {
                for (jj = 0; jj < expectedColumns; jj++) {
                    idx = ii * expectedColumns + jj;
                    if (wbUnequalQ(expectedData[idx], solutionData[idx])) {
                        string str;
                        if (expectedColumns == 1) {

                            str = wbString("The solution did not match the expected results at row ", ii,
                                            ". Expecting ", expectedData[idx], " but got ",
                                            solutionData[idx], ".");

                        } else {
                            str = wbString("The solution did not match the expected results at column ", jj,
                                            " and row ", ii, ". Expecting ", expectedData[idx], " but got ",
                                            solutionData[idx], ".");

                        }
                        _solution_correctQ = json_string(str.c_str());
                        res = wbFalse;
                        goto matrixCleanup;
                    }
                }
            }

            res = wbTrue;
        }
matrixCleanup:
        if (expectedData != NULL) {
            wbFree(expectedData);
        }
        return res;
    } else {
        wbAssert(wbFalse);
        return wbFalse;
    }
}

wbBool wbSolution(char * expectedOutputFile,
                  char * outputFile, char * type0,
                  void * data, int rows, int columns) {
    char * type;
    wbBool res;
    wbSolution_t sol;

    if (expectedOutputFile == NULL ||
        //outputFile == NULL ||
        data == NULL ||
        type0 == NULL) {
        wbLog(ERROR, "Failed to grade solution");
        return wbFalse;
    }

    type = wbString_toLower(type0);

    if (_solution_correctQ != NULL) {
        json_delete(_solution_correctQ);
        _solution_correctQ = NULL;
    }

    wbSolution_setOutputFile(sol, outputFile);
    wbSolution_setType(sol, type);
    wbSolution_setData(sol, data);
    wbSolution_setRows(sol, rows);
    wbSolution_setColumns(sol, columns);

    res = wbSolution_correctQ(expectedOutputFile, sol);

/*
    if (wbString_sameQ(type, "image")) {
        wbImage_t img = wbImage_new(rows, columns);
        memcpy(wbImage_getData(img), data, rows*columns*wbImage_channels*sizeof(wbReal_t));
        wbExport(outputFile, img);
        wbImage_delete(img);
    } else if (wbString_sameQ(type, "vector") ||
               wbString_sameQ(type, "matrix")) {
        wbExport(outputFile, (wbReal_t *) data, rows, columns);
    }
*/

    wbFree(type);

    return res;
}

wbBool wbSolution(wbArg_t arg, void * data, int rows, int columns) {
    int ii;
    char * type;
    wbBool res;
    json_t * msg;
    char * expectedOutputFile;
    char * outputFile;
    json_t * inputFileArray;

    expectedOutputFile = wbArg_getExpectedOutputFile(arg);
    outputFile = wbArg_getOutputFile(arg);
    type = wbArg_getType(arg);

    wbAssert(type != NULL);
    wbAssert(expectedOutputFile != NULL);
    wbAssert(outputFile != NULL);

    res = wbSolution(expectedOutputFile, outputFile, type, data, rows, columns);

#if 1
    if (res) {
        _solution_correctQ = json_object();

        msg = json_string("Solution is correct.");

        json_object_set(_solution_correctQ, "CorrectQ", json_true());
        json_object_set(_solution_correctQ, "Message", msg);
    } else {
        msg = _solution_correctQ;
        _solution_correctQ = json_object();
        json_object_set(_solution_correctQ, "CorrectQ", json_false());
        json_object_set(_solution_correctQ, "Message", msg);
    }
#else
    if (res) {
        _solution_correctQ = json_true();
    } else {
        _solution_correctQ = json_false();
    }
#endif

    inputFileArray = json_array();

    for (ii = 0; ii < wbArg_getInputCount(arg); ii++) {
        char * file = wbArg_getInputFile(arg, ii);
        if (file != NULL) {
            json_array_append(inputFileArray, json_string(file));
        }
    }

    /*
    json_object_set(_solution_correctQ, "InputFiles", inputFileArray);
    json_object_set(_solution_correctQ, "ExpectedOutput", json_string(expectedOutputFile));
    json_object_set(_solution_correctQ, "OutputFile", json_string(outputFile));
    */

    return res;
}

wbBool wbSolution(wbArg_t arg, void * data, int rows) {
    return wbSolution(arg, data, rows, 1);
}

wbBool wbSolution(wbArg_t arg, wbImage_t img) {
    return wbSolution(arg, img, wbImage_getHeight(img), wbImage_getWidth(img));
}

#endif /* WB_USE_JSON */
