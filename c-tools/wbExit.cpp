
#include    <wb.h>

void wb_atExit(void) {
#if defined(WB_USE_JSON) && defined(wbLogger_printOnExit)
    char * res;
    json_t * obj;
#if 0
    json_t * timerJSON = wbTimer_toJSON();
    json_t * logJSON = wbLogger_toJSON();
#endif

    cudaDeviceSynchronize();

    obj = json_object();
    //json_object_set(obj, "Timer", timerJSON);
    //json_object_set(obj, "Logger", logJSON);
    json_object_set(obj, "CUDAMemory", json_integer(_cudaMallocSize));

    if (_solution_correctQ != NULL) {
        json_object_set(obj, "Solution", _solution_correctQ);
    } else {
        json_t * obj = json_object();
        json_object_set(_solution_correctQ, "CorrectQ", json_false());
        json_object_set(obj, "Solution", obj);
    }

    res = json_dumps(obj, JSON_INDENT(1));

    fprintf(stdout, "==$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$\n");
    fprintf(stdout, "%s", res);

    json_delete(obj);

    wbFree(res);
#elif defined(wbLogger_printOnExit)
	string timerXML = wbTimer_toXML();
	string loggerXML = wbLogger_toXML();

    fprintf(stdout, "==$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$\n");
	//fprintf(stdout, "%s", timerXML.c_str());
	//fprintf(stdout, "%s", loggerXML.c_str());

#endif /* WB_USE_JSON */

    wbTimer_delete(_timer);
    wbLogger_delete(_logger);

    _timer = NULL;
    _logger = NULL;

    //wbFile_atExit();

#ifdef WB_DEBUG_MEMMGR_SUPPORT_STATS
    memmgr_print_stats();
#endif /* WB_DEBUG_MEMMGR_SUPPORT_STATS */

    exit(0);

    assert(0);

    return ;
}
