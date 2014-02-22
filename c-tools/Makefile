

##########################################
# INPUT
##########################################
CXX=g++
DEFINES=-DWB_USE_JSON # -DWB_USE_SANDBOX
DEFINES+=-DWB_USE_CUSTOM_MALLOC -DWB_USE_COURSERA
CXX_FLAGS=-fPIC -x c++ -O0 -g -I . -I /usr/local/cuda-5.0/include -I jannson -L $(HOME)/usr/lib -Wall  -I$(HOME)/usr/include $(DEFINES)
LIBS=-lm -ljansson -lstdc++ -lrt -lcuda -L$(HOME)/usr/lib

##########################################
##########################################

SOURCES :=  wbArg.cpp              \
			wbBase64.cpp           \
			wbComparator.cpp       \
			wbExit.cpp             \
			wbExport.cpp           \
			wbFile.cpp             \
			wbImage.cpp            \
			wbImport.cpp           \
			wbInit.cpp             \
			wbLogger.cpp           \
			wbMemoryManager.cpp    \
			wbPPM.cpp              \
			wbSandbox.cpp          \
			wbCUDA.cpp			   \
			wbSolution.cpp         \
			wbString.cpp           \
			wbTimer.cpp


##############################################
# OUTPUT
##############################################

EXES = libwb.a libwb.so

.SUFFIXES : .o .cpp


OBJECTS = $(SOURCES:.cpp=.o)

##############################################
# OUTPUT
##############################################


.cpp.o:
	$(CXX) $(DEFINES) $(CXX_FLAGS) -c -o $@ $<


libwb.so:     $(OBJECTS)
	$(CXX) -fPIC -shared $(LIBS) -o Linux-x86-64/$@ $(OBJECTS)

libwb.a:     $(OBJECTS)
	ar rcs -o Linux-x86-64/$@ $(OBJECTS)

clean:
	-rm -f $(EXES) *.o *~


