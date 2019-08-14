#ifdef ANDROID
#include "android/event-config.h"
#elif defined(__APPLE__)
#include "mac/event-config.h"
#elif defined(__linux__)
#include "linux/event-config.h"
#elif defined(_WIN32)
#include "win32/event-config.h"
#endif