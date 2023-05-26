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

(fn open-emacs-on-primary-screen []
  "Emacs sometimes accidentally gets opened on the secondary monitor.
No me gusto esto."
  (let [cur-screen (hs.mouse.getCurrentScreen)
        primary (hs.screen.primaryScreen)]
    (if (and (not= cur-screen primary)
             (not (hs.application.find "Emacs")))
        (do
          (hs.application.launchOrFocus "Emacs")
          (hs.timer.doAfter
           .1
           (fn []
             (->
              (hs.application.find "Emacs")
              (: :mainWindow)
              (: :moveToScreen primary)))))
        (windows.activate-app "Emacs"))))

{:open-emacs-on-primary-screen
  open-emacs-on-primary-screen}
