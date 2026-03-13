# switchy.nim — переключение языка ввода по CapsLock
# Аналог https://github.com/erryox/Switchy
#
# Сборка:  nim c -d:release switchy.nim
# Запуск:  switchy.exe  (работает в фоне, завершить через диспетчер задач)

{.passL: "-mwindows".}

import winim/lean

var hookHandle: HHOOK
var capsHeld: bool = false      # отслеживаем, зажат ли Caps прямо сейчас
var didLangSwitch: bool = false # нажали Caps без Shift → нужно отпустить Ctrl при keyup
var bypassCaps: int = 0         # сколько следующих CapsLock-событий пропустить (не перехватывать)
var enabled: bool = true        # включён ли перехват (Alt+CapsLock для переключения)

proc sendKey(vk: WORD, keyUp: bool) =
   var input: INPUT
   input.`type` = INPUT_KEYBOARD.DWORD
   input.ki.wVk = vk
   input.ki.dwFlags = if keyUp: KEYEVENTF_KEYUP.DWORD else: 0.DWORD
   discard SendInput(1.UINT, addr input, sizeof(INPUT).int32)

proc keyboardHook(nCode: int32, wParam: WPARAM, lParam: LPARAM): LRESULT {.stdcall.} =
   if nCode >= 0:
      let kb: ptr KBDLLHOOKSTRUCT = cast[ptr KBDLLHOOKSTRUCT](lParam)
      # Alt+CapsLock → включить/выключить Switchy
      if kb.vkCode == VK_CAPITAL.DWORD and
         (wParam == WM_KEYDOWN.WPARAM or wParam == WM_SYSKEYDOWN.WPARAM):
         let altHeld = (GetAsyncKeyState(VK_MENU.int32) and 0x8000'i16) != 0
         if altHeld:
            enabled = not enabled
            return 1
      if kb.vkCode == VK_CAPITAL.DWORD and enabled:
         # Пропускаем синтетические CapsLock, которые сами же отправили
         if bypassCaps > 0:
            dec bypassCaps
            return CallNextHookEx(hookHandle, nCode, wParam, lParam)
         if wParam == WM_KEYDOWN.WPARAM or wParam == WM_SYSKEYDOWN.WPARAM:
            if not capsHeld:
               capsHeld = true
               let shiftHeld = (GetAsyncKeyState(VK_SHIFT.int32) and 0x8000'i16) != 0
               if shiftHeld:
                  # Shift+Caps → отправляем настоящий CapsLock в систему (обходя хук)
                  bypassCaps = 2  # пропустить keydown + keyup
                  sendKey(VK_CAPITAL.WORD, false)
                  sendKey(VK_CAPITAL.WORD, true)
                  didLangSwitch = false
               else:
                  # Caps без Shift → переключаем язык (Ctrl+Shift)
                  sendKey(VK_LCONTROL.WORD, false)
                  sendKey(VK_SHIFT.WORD, false)
                  sendKey(VK_SHIFT.WORD, true)
                  didLangSwitch = true
            # auto-repeat игнорируем
            return 1
         elif wParam == WM_KEYUP.WPARAM or wParam == WM_SYSKEYUP.WPARAM:
            if capsHeld:
               capsHeld = false
               if didLangSwitch:
                  # Отпускаем Ctrl только если переключали язык
                  sendKey(VK_LCONTROL.WORD, true)
                  didLangSwitch = false
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
