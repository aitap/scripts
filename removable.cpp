#include <windows.h>
#include <string>

template <typename T>
void find_iterate(const char * pattern, const T & cb) {
	WIN32_FIND_DATAA fd;

	HANDLE find = FindFirstFileA(pattern, &fd);
	if (find == INVALID_HANDLE_VALUE) return;

	do cb(fd);
	while (FindNextFileA(find, &fd));

	FindClose(find);
}

static void unhide_path(const char * path) {
	std::string pattern(path);
	pattern += pattern.back() == '\\' ? "*" : "\\*";

	find_iterate(pattern.c_str(), [&pattern](const WIN32_FIND_DATAA & fd) {
		if (std::string(".") == fd.cFileName || std::string("..") == fd.cFileName)
			return;

		std::string path = pattern;
		path.pop_back();
		path += fd.cFileName;
		SetFileAttributesA(path.c_str(), FILE_ATTRIBUTE_NORMAL);

		if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
			unhide_path(path.c_str());
	});
}

static void sanitize_drive(const char * drive) {
	// remove read-only/hidden/system attributes
	unhide_path(drive);
	// neutralize autorun.inf
	{
		std::string autorun(drive), bak(drive);
		autorun += "autorun.inf";
		bak += "autorun.bak";

		MoveFileEx(autorun.c_str(), bak.c_str(), MOVEFILE_REPLACE_EXISTING);
	}
	// also rename all shortcuts for good measure
	{
		std::string lnk(drive);
		lnk += "*.lnk";

		find_iterate(lnk.c_str(), [drive](const WIN32_FIND_DATAA & fd) {
			std::string inf(drive);
			inf += fd.cFileName;
			std::string bak = inf + ".bak";
			MoveFile(inf.c_str(), bak.c_str());
		});
	}
}

int main(int argc, char ** argv) {
	if (argc == 1) {
		// enough for 26 letters of "X:\\" and null terminator
		std::string buf(26 * 4 + 1, '\0');
		DWORD n = GetLogicalDriveStringsA(buf.size(), &buf[0]);

		for (size_t offset = 0; offset < (size_t)n; offset += buf.find('\0', offset) + 1)
			if (GetDriveType(&buf[offset]) == DRIVE_REMOVABLE)
				sanitize_drive(&buf[offset]);
	} else {
		for (int i = 1; i < argc; ++i) {
			std::string path(argv[i]);
			// when dragging and dropping a directory (not a drive), the final '\\' is omitted
			if (path.back() != '\\') path += '\\';

			sanitize_drive(path.c_str());
		}
	}
}
