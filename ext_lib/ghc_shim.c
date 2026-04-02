/*
 * Shim to provide linker symbols expected by GHC RTS when linking
 * as a shared library. These symbols are normally provided by the
 * linker only for executables.
 *
 * Only needed on Linux (ELF). macOS (Mach-O) does not use these symbols.
 */

#ifdef __linux__

__attribute__((visibility("hidden")))
void (*__fini_array_start[0])() __attribute__((section(".fini_array"))) = {};

__attribute__((visibility("hidden")))
void (*__fini_array_end[0])() = {};

#endif
