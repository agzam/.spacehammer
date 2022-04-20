(local log (hs.logger.new "Emacs" "debug"))
(local {: for-each
        : filter
        : first} (require :lib.functional))

(fn switch-layout []
  "I struggle all the time switching input layout, because the system layout is not
   compatible with Emacs. This function ensures that on system layout change - Emacs emit
   the right key sequence internally."
  (let [app-name (-?> (hs.window.focusedWindow) (: :application) (: :name))
        next-layout (first (filter
                            (fn [l] (not= l (hs.keycodes.currentLayout)))
                            (hs.keycodes.layouts)))]
    (if (= app-name :Emacs)
        (do
          (hs.keycodes.setLayout "U.S.")
          ;; There's a bug either in Fennel or in Hammerspoon, it doesn't emit certain
          ;; keystrokes like a backslash.
          ;; The default Emacs keybinding for `(toggle-input-method)` is set to <C-\>
          ;; I had to add `(map! "C-<f12>" #'toggle-input-method)` in my config
          (hs.eventtap.keyStroke [:ctrl] :f12))
        (hs.keycodes.setLayout next-layout))))

{:switch-layout switch-layout}
