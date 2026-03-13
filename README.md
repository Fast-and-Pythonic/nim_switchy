# nim_switchy
An analog of [Switchy](https://github.com/erryox/Switchy) on Nim. Simply switches the input language by pressing the Caps Lock key.

Usage:
- CapsLock to change keyboard layout
- Shift+CapsLock to toggle CapsLock state
- Alt+CapsLock to enable/disable Switchy

Just put Nim_Switchy.exe in the startup folder (to open it press Win+R and type shell:startup).
If you want to hide the pop-up in Windows 10/11, put in this folder a shortcut with nopopup parameter instead of the file itself.

Note: for keyboard layout switching to work in programs running with administrator privileges, Switchy must also be run with administrator privileges. This can be automated using Task Scheduler.

