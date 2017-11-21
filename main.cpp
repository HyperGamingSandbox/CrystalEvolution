#include <windows.h>

#include "CrystalEvolution\Logger.h"
#include "Seed\Starter.h"

#ifdef _DEBUG	

const char *loadLuaFile(const char *dir, const char *filename, size_t *sz) {

	char buf[512];
	sprintf(buf, "%s\\%s.lua", dir, filename);
	FILE *f = fopen(buf, "rb");
	if (f == NULL) {
		return NULL;
	}

	fseek(f, 0, SEEK_END);
	*sz = ftell(f);
	fseek(f, 0, SEEK_SET);
	char *text = new char[*sz];
	fread(text, *sz, 1, f);

	fclose(f);
	
	return text;
}

#else

Seed::FilePack *filePack = NULL;

const char *loadLuaFile(const char *dir, const char *filename, size_t *sz) {
	
	if (filePack == NULL) {
		return NULL;
	}

	char b[256];
	sprintf_s(b, "%s.lua", filename);

	auto e = filePack->get(b);
	if (e == NULL) {
		return NULL;
	}
	auto data = filePack->load(e);
	*sz = e->getSize();

	return (const char *)data;
}

#endif

int APIENTRY wWinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance, _In_ LPWSTR lpCmdLine, _In_ int nCmdShow) {

#ifdef _DEBUG_LOGGER
	Logger::setupLogFilepath(0, "debug.log");
	Logger::setupLogFilepath(1, "error.log");
	Logger::setThreadName("main");
#endif

	_lprint("");

#ifdef _DEBUG	
	Seed::addLuaSearchDirectory("D:\\development\\projects\\Seed\\lua");
	Seed::addLuaSearchDirectory("lua");
#else
	filePack = new Seed::FilePack("data.pack");

	typedef void *(*LoadDataCallback)(const char *filename, size_t *sz);
	extern LoadDataCallback loadDataCallback;
	typedef void *pvoid;
	loadDataCallback = [](const char *filename, size_t *sz) -> pvoid {
		
		auto e = filePack->get(filename);
		if (e == NULL) {
			return NULL;
		}
		auto data = filePack->load(e);
		*sz = e->getSize();

		return (void *)data;
	};

#endif
	Seed::setupLuaLoadFileCallback(loadLuaFile);

	Seed::addCoreFunction("lprint", [](lua_State *L) {

		CHECK_ARG(1, string);
		
		union variant {
			long long int i;
			unsigned int u;
			float        f;
			double       d;
			const char * s;
			void *       v;
		};
		variant args[16];
		int aindex = 0;

		size_t sz;
		auto format = lua_tolstring(L, 1, &sz);
		auto formatPointer = format;
		int apos = 2;
		while (sz > 0) {
			if (*formatPointer == '%') {
				sz--;
				formatPointer++;
				switch (*formatPointer) {
				case 's':
					CHECK_ARG(apos, string);
					args[aindex++].s = lua_tostring(L, apos++);
					break;
				case 'd': 
					CHECK_ARG(apos, integer);
					args[aindex++].i = lua_tointeger(L, apos++);
					break;
				}
			}
			formatPointer++;
			sz--;
		}

		char buffer[1024];
		vsprintf(buffer, format, (char *)&args[0]);

		std::string arg = buffer;

		std::string p;
		lua_getglobal(L, "debug");
		lua_getfield(L, -1, "traceback");

		if (lua_pcall(L, 0, 1, 0)) {
		}
		else {
			const char* stackTrace = lua_tostring(L, -1);
			lua_pop(L, 1);
			std::string s(stackTrace);
			/*
			[2017-04-03 23:36:09] [main              ] stack traceback:
			[2017-04-03 23:36:09] [main              ] 	[C]: in function 'lprint'
			[2017-04-03 23:36:09] [main              ] 	[string "start.lua"]:6: in main chunk
			[2017-04-03 23:36:09] [main              ] 	[C]: in function 'pcall'
			[2017-04-03 23:36:09] [main              ] 	[string "core.lua"]:113: in function <[string "core.lua"]:83>
			*/
			auto f = s.find("[string \"", 0);
			if (f > 0) {
				auto f2 = s.find("\"]", f);
				p = s.substr(f + 9, f2 - f - 9);

				auto f3 = s.find(":", f2 + 3);
				std::string p2 = s.substr(f2 + 3, f3 - f2 - 3);

				char buf[1024];
				sprintf(buf, "[%-24s%4s] ", p.c_str(), p2.c_str());
				p = buf;
			}
			
		}

		_lprint(p + arg);

		return 0;
	});

	auto r = Seed::start(hInstance, nCmdShow);
	if(r.length()) {
		eprint(r);
		OutputDebugStringA(r.c_str());
		OutputDebugStringA("\n");
		return 1;
	}

	return 0;
}