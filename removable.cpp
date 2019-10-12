#include <windows.h>
#include <string>

static void unhide_path(const char * path) {
	std::string pattern(path);
	pattern += pattern.back() == '\\' ? "*" : "\\*";

	WIN32_FIND_DATAA fd;
	HANDLE find = FindFirstFileA(pattern.c_str(), &fd);
	if (find == INVALID_HANDLE_VALUE) return;
	do {
		if (std::string(".") == fd.cFileName || std::string("..") == fd.cFileName) continue;
		SetFileAttributesA(fd.cFileName, FILE_ATTRIBUTE_NORMAL);
		if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
			unhide_path(fd.cFileName);
	} while (FindNextFileA(find, &fd));
	FindClose(find);
}

int main(int argc, char ** argv) {
	if (argc <= 1) {
		std::string buf(26 * 4 + 1, '\0');
		DWORD n = GetLogicalDriveStringsA(buf.size(), &buf[0]);
		for (size_t offset = 0; offset < (size_t)n; offset += buf.find('\0', offset) + 1)
			if (GetDriveType(&buf[offset]) == DRIVE_REMOVABLE)
				unhide_path(&buf[offset]);
	} else {
		for (int i = 1; i < argc; ++i)
			unhide_path(argv[i]);
	}
}
