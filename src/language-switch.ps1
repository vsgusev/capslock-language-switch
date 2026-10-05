# CapsLock switches the keyboard layout, without hooks or simulated keystrokes.
# install.ps1 remaps CapsLock to F24 in the keyboard driver (Scancode Map).
# Here F24 is a regular global hotkey, and the layout change is requested from
# the active window the same way the Windows language bar does it.

Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

public static class LanguageSwitch {
    [StructLayout(LayoutKind.Sequential)]
    struct MSG { public IntPtr hwnd; public uint message; public IntPtr wParam; public IntPtr lParam; public uint time; public int x, y; }

    [DllImport("user32.dll", SetLastError = true)] static extern bool RegisterHotKey(IntPtr hwnd, int id, uint mods, uint vk);
    [DllImport("user32.dll")] static extern int GetMessage(out MSG msg, IntPtr hwnd, uint min, uint max);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, IntPtr pid);
    [DllImport("user32.dll")] static extern IntPtr GetKeyboardLayout(uint thread);
    [DllImport("user32.dll")] static extern int GetKeyboardLayoutList(int n, IntPtr[] list);
    [DllImport("user32.dll")] static extern bool PostMessage(IntPtr hwnd, uint msg, IntPtr wParam, IntPtr lParam);

    const uint MOD_NOREPEAT = 0x4000;
    const uint VK_F24 = 0x87;
    const uint WM_HOTKEY = 0x0312;
    const uint WM_INPUTLANGCHANGEREQUEST = 0x0050;

    public static void Run() {
        // Fails if another instance already holds the hotkey
        if (!RegisterHotKey(IntPtr.Zero, 1, MOD_NOREPEAT, VK_F24)) throw new Win32Exception();
        MSG msg;
        while (GetMessage(out msg, IntPtr.Zero, 0, 0) > 0)
            if (msg.message == WM_HOTKEY) SwitchNext();
    }

    // Layouts belong to threads, so the next one is counted from the active window's thread
    static void SwitchNext() {
        IntPtr hwnd = GetForegroundWindow();
        if (hwnd == IntPtr.Zero) return;
        IntPtr current = GetKeyboardLayout(GetWindowThreadProcessId(hwnd, IntPtr.Zero));
        var layouts = new IntPtr[GetKeyboardLayoutList(0, null)];
        GetKeyboardLayoutList(layouts.Length, layouts);
        if (layouts.Length < 2) return;
        int next = (Array.IndexOf(layouts, current) + 1) % layouts.Length;
        PostMessage(hwnd, WM_INPUTLANGCHANGEREQUEST, IntPtr.Zero, layouts[next]);
    }
}
'@

[LanguageSwitch]::Run()
