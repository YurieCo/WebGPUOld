
#include	<wb.h>


wbLogger_t _logger = NULL;

static inline wbBool wbLogEntry_hasNext(wbLogEntry_t elem) {
    return wbLogEntry_getNext(elem) != NULL;
}

static inline wbLogEntry_t wbLogEntry_new() {
    wbLogEntry_t elem;

    elem = wbNew(struct st_wbLogEntry_t);

    wbLogEntry_setMessage(elem, NULL);
    wbLogEntry_setTime(elem, _hrtime());
#ifndef NDEBUG
    wbLogEntry_setLevel(elem, wbLogLevel_TRACE);
#else
    wbLogEntry_setLevel(elem, wbLogLevel_OFF);
#endif
    wbLogEntry_setNext(elem, NULL);

    wbLogEntry_setLine(elem, -1);
    wbLogEntry_setFile(elem, NULL);
    wbLogEntry_setFunction(elem, NULL);

    return elem;
}

static inline wbLogEntry_t wbLogEntry_initialize(wbLogLevel_t level, string msg, const char * file,
                                                 const char * fun, int line) {
    wbLogEntry_t elem;

    elem = wbLogEntry_new();

    wbLogEntry_setLevel(elem, level);

    wbLogEntry_setMessage(elem, wbString_duplicate(msg));

    wbLogEntry_setLine(elem, line);
    wbLogEntry_setFile(elem, file);
    wbLogEntry_setFunction(elem, fun);

    return elem;
}

static inline void wbLogEntry_delete(wbLogEntry_t elem) {
    if (elem != NULL) {
        if (wbLogEntry_getMessage(elem) != NULL) {
            wbFree(wbLogEntry_getMessage(elem));
        }
        wbDelete(elem);
    }
    return ;
}

static inline const char * getLevelName(wbLogLevel_t level) {
    switch (level) {
        case wbLogLevel_unknown:
            return "Unknown";
        case wbLogLevel_OFF:
            return "Off";
        case wbLogLevel_FATAL:
            return "Fatal";
        case wbLogLevel_ERROR:
            return "Error";
        case wbLogLevel_WARN:
            return "Warn";
        case wbLogLevel_INFO:
            return "Info";
        case wbLogLevel_DEBUG:
            return "Debug";
        case wbLogLevel_TRACE:
            return "Trace";
    }
    return NULL;
}

#ifdef WB_USE_JSON
static inline json_t * wbLogEntry_toJSON(wbLogEntry_t elem) {
    if (elem != NULL) {
        json_t * res = json_object();
        json_t * type = json_string("LogEntry");
        json_t * level = json_string(getLevelName(wbLogEntry_getLevel(elem)));
        json_t * msg = json_string(wbLogEntry_getMessage(elem));
        json_t * fun = json_string(wbLogEntry_getFunction(elem));
        json_t * file = json_string(wbLogEntry_getFile(elem));
        json_t * line = json_integer(wbLogEntry_getLine(elem));
        json_t * time = json_integer(wbLogEntry_getTime(elem));

        json_object_set(res, "Type", type);
        json_object_set(res, "Level", level);
        json_object_set(res, "Message", msg);
        json_object_set(res, "File", file);
        json_object_set(res, "Function", fun);
        json_object_set(res, "Line", line);
        json_object_set(res, "Time", time);

        return res;
    }
    return NULL;
}
#endif /* WB_USE_JSON */

static inline string wbLogEntry_toXML(wbLogEntry_t elem) {
    if (elem != NULL) {
		stringstream ss;

		ss << "<entry>\n";
			ss << "<type>" << "LoggerElement" << "</type>\n";
			ss << "<level>" << wbLogEntry_getLevel(elem) << "</level>\n";
			ss << "<message>" << wbLogEntry_getMessage(elem) << "</message>\n";
			ss << "<file>" << wbLogEntry_getFile(elem) << "</file>\n";
			ss << "<function>" << wbLogEntry_getFunction(elem) << "</function>\n";
			ss << "<line>" << wbLogEntry_getLine(elem) << "</line>\n";
		ss << "</entry>\n";

        return ss.str();
    }
    return "";
}

wbLogger_t wbLogger_new() {
    wbLogger_t logger;

    logger = wbNew(struct st_wbLogger_t);

    wbLogger_setLength(logger, 0);
    wbLogger_setHead(logger, NULL);
#ifndef NDEBUG
    wbLogger_getLevel(logger) = wbLogLevel_TRACE;
#else
    wbLogger_getLevel(logger) = wbLogLevel_OFF;
#endif

    return logger;
}


static inline void _wbLogger_setLevel(wbLogger_t logger, wbLogLevel_t level) {
    wbLogger_getLevel(logger) = level;
}

static inline void _wbLogger_setLevel(wbLogLevel_t level) {
	wb_init();
    _wbLogger_setLevel(_logger, level);
}

#define wbLogger_setLevel(level)				_wbLogger_setLevel(wbLogLevel_##level)

void wbLogger_clear(wbLogger_t logger) {
    if (logger != NULL) {
        wbLogEntry_t tmp;
        wbLogEntry_t iter;

        iter = wbLogger_getHead(logger);
        while (iter != NULL) {
            tmp = wbLogEntry_getNext(iter);
            wbLogEntry_delete(iter);
            iter = tmp;
        }

        wbLogger_setLength(logger, 0);
        wbLogger_setHead(logger, NULL);
    }
}

void wbLogger_delete(wbLogger_t logger) {
    if (logger != NULL) {
        wbLogger_clear(logger);
        wbDelete(logger);
    }
    return ;
}

void wbLogger_append(wbLogLevel_t level, string msg, const char * file,
                     const char * fun, int line) {
    wbLogEntry_t elem;
    wbLogger_t logger;

    wb_init();

    logger = _logger;

    if (wbLogger_getLevel(logger) < level) {
        return ;
    }

    elem = wbLogEntry_initialize(level, msg, file, fun, line);

    if (wbLogger_getHead(logger) == NULL) {
        wbLogger_setHead(logger, elem);
    } else {
        wbLogEntry_t prev = wbLogger_getHead(logger);

        while (wbLogEntry_hasNext(prev)) {
            prev = wbLogEntry_getNext(prev);
        }
        wbLogEntry_setNext(prev, elem);
    }

#if 0
	if (level <= wbLogger_getLevel(logger) && elem) {
		const char * levelName = getLevelName(level);

		fprintf(stderr,
			"= LOG: %s: %s (In %s:%s on line %d). =\n",
			levelName,
			wbLogEntry_getMessage(elem),
			wbLogEntry_getFile(elem),
			wbLogEntry_getFunction(elem),
			wbLogEntry_getLine(elem));
	}
#endif

    wbLogger_incrementLength(logger);

    return ;
}

#ifdef WB_USE_JSON
json_t * wbLogger_toJSON() {
    return wbLogger_toJSON(_logger);
}

json_t * wbLogger_toJSON(wbLogger_t logger) {
    if (logger != NULL) {
        wbLogEntry_t iter;

        json_t * res = json_object();
        json_t * type = json_string("Logger");
        json_t * elems = json_array();

        for (iter = wbLogger_getHead(logger); iter != NULL; iter = wbLogEntry_getNext(iter)) {
            json_array_append(elems, wbLogEntry_toJSON(iter));
        }

        json_object_set(res, "Type", type);
        json_object_set(res, "Elements", elems);

        return res;
    }
    return NULL;
}
#endif /* WB_USE_JSON */


string wbLogger_toXML() {
    return wbLogger_toXML(_logger);
}

string wbLogger_toXML(wbLogger_t logger) {
    if (logger != NULL) {
        wbLogEntry_t iter;
		stringstream ss;

		ss << "<logger>\n";
			ss << "<type>" << "Logger" << "</type>\n";
			ss << "<elements>\n";
				for (iter = wbLogger_getHead(logger); iter != NULL; iter = wbLogEntry_getNext(iter)) {
					ss << wbLogEntry_toXML(iter);
				}
			ss << "</elements>\n";
		ss << "</logger>\n";

        return ss.str();
    }
    return "";
}


