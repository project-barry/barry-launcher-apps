/* Barry Simulator.exe: starts Barry Simulator (sim\sim.py) with the Python
 * that comes with it (python\pythonw.exe), with no console window. Its
 * output goes to %LOCALAPPDATA%\Barry Simulator\Barry Simulator.log.
 *
 * Built by build-windows.ps1:
 *   rc launcher.rc
 *   cl /O2 /DUNICODE /D_UNICODE launcher.c launcher.res user32.lib shell32.lib
 *      /link /SUBSYSTEM:WINDOWS /OUT:"Barry Simulator.exe"
 */
#include <windows.h>
#include <shlobj.h>
#include <wchar.h>

static void fail(const wchar_t *what, const wchar_t *path)
{
    wchar_t msg[2 * MAX_PATH + 200];
    swprintf(msg, sizeof msg / sizeof *msg,
             L"Barry Simulator could not start: %s\n\n%s\n\n"
             L"Unzip the whole Barry Simulator folder and run Barry Simulator.exe from it.", what, path);
    MessageBoxW(NULL, msg, L"Barry Simulator", MB_OK | MB_ICONERROR);
}

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE previous, PWSTR args, int show)
{
    wchar_t dir[MAX_PATH], python[MAX_PATH], script[MAX_PATH], line[3 * MAX_PATH];
    wchar_t logdir[MAX_PATH], logpath[MAX_PATH];
    (void)instance; (void)previous; (void)args; (void)show;

    /* The folder this program is in. */
    if (!GetModuleFileNameW(NULL, dir, MAX_PATH)) return 1;
    wchar_t *slash = wcsrchr(dir, L'\\');
    if (slash) *slash = 0;

    swprintf(python, MAX_PATH, L"%s\\python\\pythonw.exe", dir);
    swprintf(script, MAX_PATH, L"%s\\sim\\sim.py", dir);
    if (GetFileAttributesW(python) == INVALID_FILE_ATTRIBUTES) { fail(L"its Python is missing", python); return 1; }
    if (GetFileAttributesW(script) == INVALID_FILE_ATTRIBUTES) { fail(L"sim.py is missing", script); return 1; }
    swprintf(line, sizeof line / sizeof *line, L"\"%s\" -u \"%s\"", python, script);

    /* The log, appended to. */
    HANDLE log = INVALID_HANDLE_VALUE;
    if (SUCCEEDED(SHGetFolderPathW(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, logdir))) {
        wcscat_s(logdir, MAX_PATH, L"\\Barry Simulator");
        CreateDirectoryW(logdir, NULL);
        swprintf(logpath, MAX_PATH, L"%s\\Barry Simulator.log", logdir);
        SECURITY_ATTRIBUTES sa = { sizeof sa, NULL, TRUE };
        log = CreateFileW(logpath, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE, &sa,
                          OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    }

    STARTUPINFOW si = { sizeof si };
    PROCESS_INFORMATION pi;
    if (log != INVALID_HANDLE_VALUE) {
        si.dwFlags = STARTF_USESTDHANDLES;
        si.hStdInput = NULL;
        si.hStdOutput = log;
        si.hStdError = log;
    }
    if (!CreateProcessW(python, line, NULL, NULL, log != INVALID_HANDLE_VALUE, CREATE_NO_WINDOW, NULL, dir,
                        &si, &pi)) {
        fail(L"Windows would not run its Python", python);
        return 1;
    }
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    if (log != INVALID_HANDLE_VALUE) CloseHandle(log);
    return 0;
}
