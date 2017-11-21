#pragma once

#include <windows.h>
#include <string>

class Logger {

private:
	std::string _filepath;
	FILE *_file;

public:
	Logger(std::string filepath);

	void print(const char *string);
	void print(std::string string) { this->print(string.c_str());  }

	static Logger *loggers[10];
	static void setupLogFilepath(int logId, std::string filepath);
	static void setThreadName(const char *name);
};


#ifdef _DEBUG
#define _DEBUG_LOGGER
#endif

#define _DEBUG_LOGGER

#ifdef _DEBUG_LOGGER
#define lprint(a) Logger::loggers[0]->print(std::string("") + __FUNCTION__ + " " + a);
#define _lprint(a) Logger::loggers[0]->print(std::string("") + a);
#define eprint(a) Logger::loggers[1]->print(std::string("") + __FUNCTION__ + " " + a);
#define _eprint(a) Logger::loggers[1]->print(std::string("") + a);
#else
#define lprint(a)
#define _lprint(a)
#define eprint(a)
#define _eprint(a)
#endif