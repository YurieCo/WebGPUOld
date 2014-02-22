
#include    <wb.h>
#include    <wbCUDA.h>

#ifndef WB_DEFAULT_HEAP_SIZE
#define WB_DEFAULT_HEAP_SIZE (1024*1024*120)
#endif /* WB_DEFAULT_HEAP_SIZE */


static bool _initializedQ = wbFalse;


#ifndef _MSC_VER
__attribute__ ((__constructor__))
#endif /* _MSC_VER */
void wb_init(void) {
    if (_initializedQ == wbTrue) {
        return ;
    }

    cuInit(0);

#ifdef WB_USE_CUSTOM_MALLOC
    wbMemoryManager_new(WB_DEFAULT_HEAP_SIZE);
#endif /* WB_USE_CUSTOM_MALLOC */

#ifdef WB_USE_JSON
    _solution_correctQ = NULL;
#endif /* WB_USE_JSON */


#ifdef _MSC_VER
    QueryPerformanceFrequency((LARGE_INTEGER*) &_hrtime_frequency);
#endif

    _timer = wbTimer_new();
    _logger = wbLogger_new();
    _initializedQ = wbTrue;

    wbFile_init();

	wbSandbox_new();

    atexit(wb_atExit);
}


