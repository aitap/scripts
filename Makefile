CXX = i686-w64-mingw32-g++
CXXFLAGS = --std=c++11 -Wall -Wextra -Wpedantic
LDFLAGS = -mwindows -static-libgcc -static-libstdc++

all: removable.exe

removable.exe: removable.o
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $^ -o $@
