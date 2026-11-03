#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// Creates a console for the process, and redirects stdout and stderr to it for both C and C++ I/O.
void CreateAndAttachConsole();

// Takes a null-terminated wchar_t* encoded in UTF-16 and returns a std::string encoded in UTF-8.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// Gets the command line arguments passed to the process as an array of UTF-8 strings.
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_

