#include "Logger.h"
#include <stdio.h>
#include <vector>
#include <time.h>
#include <boost/algorithm/string.hpp>
#include <boost/thread/mutex.hpp>
#include <map>

// --------------------------------------------------------------------

boost::mutex _writeMutex;

typedef std::map<DWORD, std::string> ThreadNamesMap;
ThreadNamesMap threadNamesMap;

void Logger::setThreadName(const char *name) {
	boost::unique_lock<boost::mutex> scoped_lock(_writeMutex);
	threadNamesMap.insert(std::pair<DWORD, std::string>(GetCurrentThreadId(), std::string(name)));
}

Logger::Logger(std::string filepath) : _filepath (filepath) {

	_file = NULL;
}

void Logger::print(const char *string) {

	if (_file == NULL) {
		_writeMutex.lock();
		_file = fopen(_filepath.c_str(), "a+b");
		_writeMutex.unlock();
		this->print("\n\nstarted");
	}

	boost::unique_lock<boost::mutex> scoped_lock(_writeMutex);

	auto id = GetCurrentThreadId();
	std::map<DWORD, std::string>::iterator it = threadNamesMap.find(id);

	std::string *td = NULL;
	if (it != threadNamesMap.end()) {
		td = &it->second;
	}


	time_t rawtime;
	struct tm * timeinfo;
	char buffer[80];
	
	time(&rawtime);
	timeinfo = localtime(&rawtime);

	strftime(buffer, 80, "[%Y-%m-%d %H:%M:%S] ", timeinfo);

	std::vector<std::string> strs;
	boost::split(strs, std::string(string), boost::is_any_of("\n"));
	char sb[80];

	auto bl1 = strlen(buffer);

	if (td) {
		if (td->length() > 18) {
			sprintf(sb, "[%-18s] ", td->c_str());
			fwrite(buffer, bl1, 1, _file);
			fwrite(sb, strlen(sb), 1, _file);
			fwrite("\n", 1, 1, _file);
			sprintf(sb, "[%18d] ", (int)id);
		}
		else {
			sprintf(sb, "[%-18s] ", td->c_str());
		}
	}
	else {
		sprintf(sb, "[%18d] ", (int)id);
	}

	auto bl2 = strlen(sb);
	for (std::vector<std::string>::iterator it = strs.begin(); it != strs.end(); ++it) {
		std::string s = *it;
		fwrite(buffer, bl1, 1, _file);
		fwrite(sb, bl2, 1, _file);
		fwrite(s.c_str(), s.length(), 1, _file);
		fwrite("\n", 1, 1, _file);
	}

	fflush(_file);
}


// --------------------------------------------------------------------

Logger *Logger::loggers[10];

void Logger::setupLogFilepath(int logId, std::string filepath) {
	Logger::loggers[logId] = new Logger(filepath);
}

