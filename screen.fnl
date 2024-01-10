(fn reset-screen []
  "For some stupid reason things sometiems get really in ultra-wide.
see:
https://github.com/agzam/spacehammer/issues/171 and
https://github.com/Hammerspoon/hammerspoon/issues/3320"
  (: (hs.screen.mainScreen) :rotate 90)
  (hs.timer.doAfter 0.1 (fn [] (: (hs.screen.mainScreen) :rotate 0))))

(hs.hotkey.bind [:cmd :shift :option :ctrl] "0" reset-screen)

(fn reset-hs []
  ;; (io.popen "killall Hammerspoon && open -a Hammerspoon &")
  (hs.alert "Clearing console")
  (hs.console.clearConsole))

(hs.hotkey.bind [:cmd :shift :ctrl] "0" reset-hs)

(local windows (require :windows))
