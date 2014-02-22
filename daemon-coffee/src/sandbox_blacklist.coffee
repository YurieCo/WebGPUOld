
sandbox_black_list = [
	"setjmp",
	"longjmp",
	"signal",
	"raise",
	"asctime",
	"clock",
	"ctime"
	"difftime",
	"gmtime",
	"localtime",
	"mktime",
	"strftime" 
	"time",
	"memchr",
	"memcmp",
	"memcpy",
	"memmove",
	"memset",
	"strcat",
	"strncat",
	"strchr",
	"strcmp",
	"strncmp",
	"strcoll",
	"strcpy",
	"strncpy",
	"strcspn",
	"strerror",
	"strlen",
	"strpbrk",
	"strrchr",
	"strspn",
	"strstr",
	"strtok",
	"strxfrm",
	"abort",
	"abs",
	"atexit",
	"atof",
	"atoi",
	"atol",
	"bsearch",
	"calloc",
	"div",
	"exit",
	"getenv",
	"labs",
	"ldiv",
	"mblen",
	"mbstowcs",
	"mbtowc",
	"qsort",
	"rand",
	"realloc",
	"srand",
	"strtod",
	"strtol",
	"strtoul",
	"system",
	"wcstombs",
	"wctomb",
	"clearerr",
	"fclose",
	"feof",
	"ferror",
	"fflush",
	"fgetpos",
	"fopen",
	"fread",
	"freopen",
	"fseek",
	"fsetpos",
	"ftell",
	"fwrite",
	"remove",
	"rename",
	"rewind",
	"setbuf",
	"setvbuf",
	"tmpfile",
	"tmpnam",
	"fprintf",
	"fscanf",
	"scanf",
	"sprintf",
	"sscanf",
	"vfprintf",
	"vprintf",
	"vsprintf",
	"fgetc",
	"fgets",
	"fputc",
	"fputs",
	"getc",
	"getchar",
	"gets",
	"putc",
	"putchar",
	"puts",
	"ungetc",
	"perror",
	"stdout",
	"stderr",
	"stdin",
	"va_start",
	"va_arg",
	"va_end",
	"__asm__",
	"asm",
]

module.exports = {
	list: sandbox_black_list
}

