(fn kitty-launched []
  ;; always start kitty with window on the left side
  (hs.grid.adjustWindow
   (fn [cell]
     (set cell._x 0)
     (set cell._w 2))
   (hs.window.focusedWindow)))

{:kitty-config
 {:key "kitty"
  :launch kitty-launched}}
