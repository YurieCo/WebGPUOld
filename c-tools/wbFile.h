

#ifndef __WB_FILE_H__
#define __WB_FILE_H__

typedef struct st_wbFile_t {
	int index;
	char * file;
	char * mode;
	FILE * handle;
} * wbFile_t;

#define wbFile_getIndex(file)			((file)->index)
#define wbFile_getFileName(file)		((file)->file)
#define wbFile_getMode(file)			((file)->mode)
#define wbFile_getFileHandle(file)		((file)->handle)

#define wbFile_setIndex(file, val)		(wbFile_getIndex(file) = val)
#define wbFile_setFileName(file, val)	(wbFile_getFileName(file) = val)
#define wbFile_setMode(file, val)		(wbFile_getMode(file) = val)
#define wbFile_setFileHandle(file, val)	(wbFile_getFileHandle(file) = val)

wbFile_t wbFile_new(void);
void wbFile_delete(wbFile_t file);
void wbFile_close(wbFile_t file);
void wbFile_init(void);
void wbFile_atExit(void);
int wbFile_count(void);
wbFile_t wbFile_open(const char * fileName, const char * mode);
wbFile_t wbFile_open(const char * fileName);
char * wbFile_read(wbFile_t file, size_t size, size_t count);
char * wbFile_read(wbFile_t file, size_t len);
void wbFile_rewind(wbFile_t file);
size_t wbFile_size(wbFile_t file);
char * wbFile_read(wbFile_t file);
char * wbFile_readLine(wbFile_t file);
void wbFile_write(wbFile_t file, const void * buffer, size_t size, size_t count);
void wbFile_write(wbFile_t file, const void * buffer, size_t len);
void wbFile_write(wbFile_t file, const char * buffer);
void wbFile_writeLine(wbFile_t file, const char * buffer0);
void wbFile_write(wbFile_t file, string buffer);
void wbFile_writeLine(wbFile_t file, string buffer0);
wbBool wbFile_existsQ(const char * path);
char * wbFile_extension(const char * file);

#endif /* __WB_FILE_H__ */


