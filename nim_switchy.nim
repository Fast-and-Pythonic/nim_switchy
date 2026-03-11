# switchy.nim — переключение языка ввода по CapsLock
# Аналог https://github.com/erryox/Switchy
#
# Сборка:  nim c -d:release switchy.nim
# Запуск:  switchy.exe  (работает в фоне, завершить через диспетчер задач)

{.passL: "-mwindows".}

import winim/lean

var hookHandle: HHOOK
var capsHeld: bool = false  # отслеживаем, зажат ли Caps прямо сейчас

proc sendKey(vk: WORD, keyUp: bool) =
   var input: INPUT
   input.`type` = INPUT_KEYBOARD.DWORD
   input.ki.wVk = vk
   input.ki.dwFlags = if keyUp: KEYEVENTF_KEYUP.DWORD else: 0.DWORD
   discard SendInput(1.UINT, addr input, sizeof(INPUT).int32)

proc keyboardHook(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
   if nCode >= 0:
      let kb: ptr KBDLLHOOKSTRUCT = cast[ptr KBDLLHOOKSTRUCT](lParam)
      if kb.vkCode == VK_CAPITAL.DWORD:
         if wParam == WM_KEYDOWN.WPARAM or wParam == WM_SYSKEYDOWN.WPARAM:
            if not capsHeld:
               capsHeld = true
               # Зажимаем Ctrl, быстро тапаем Shift (всплывает индикатор), Ctrl остаётся зажатым
               sendKey(VK_LCONTROL.WORD, false)
               sendKey(VK_SHIFT.WORD, false)
               sendKey(VK_SHIFT.WORD, true)
            # auto-repeat игнорируем
            return 1
         elif wParam == WM_KEYUP.WPARAM or wParam == WM_SYSKEYUP.WPARAM:
            if capsHeld:
               capsHeld = false
               # Отпускаем Ctrl
               sendKey(VK_LCONTROL.WORD, true)
            return 1
   return CallNextHookEx(hookHandle, nCode, wParam, lParam)

proc main() =
   hookHandle = SetWindowsHookEx(WH_KEYBOARD_LL, keyboardHook, 0, 0)
   if hookHandle == 0:
      quit(1)
   
   var msg: MSG
   while GetMessage(addr msg, 0, 0, 0) != 0:
      discard TranslateMessage(addr msg)
      discard DispatchMessage(addr msg)
   
   discard UnhookWindowsHookEx(hookHandle)

main()
