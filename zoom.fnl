(require-macros :lib.macros)

(local { : run } (require :yabai))

(fn group-zoom-windows []
  (let [output (run "yabai -m query --windows | jq '[.[] | select(.app==\"zoom.us\")]'")
        windows (hs.json.decode output)
        main-window (accumulate [found nil
                                 _ w (ipairs windows)]
                      (if (= w.title "Zoom Meeting") w found))
        other-windows (icollect [_ w (ipairs windows)]
                        (when (not= w.id main-window.id) w))]

    (when main-window
      ;; First, focus on the main window's space
      (run (.. "yabai -m window --focus " main-window.id))

      ;; Place windows to the right of main window
      (each [_ w (ipairs other-windows)]
        (run (.. "yabai -m window " main-window.id " --insert east"))
        (run (.. "yabai -m window " w.id " --warp " main-window.id))))))

(hs.hotkey.bind
 [:cmd :shift :option :ctrl] "m"
 (fn []
   (let [win (hs.window.find "Zoom Meeting.*")
         zoom (win:application)
         mute? (zoom:findMenuItem ["Meeting" "Unmute audio"])]
     (if (and win mute?)
         (do
           (zoom:selectMenuItem ["Meeting" "Unmute audio"])
           (hs.alert "You can talk now!"))
         (do
           (zoom:selectMenuItem ["Meeting" "Mute audio"])
           (hs.alert "🙉 You are now muted! 🙊"))))))

(hs.hotkey.bind
 [:cmd :shift :option :ctrl] "p"
 (fn []
   (let [win (hs.window.find "Zoom Meeting.*")
         zoom (win:application)
         video? (zoom:findMenuItem ["Meeting" "Start video"])]
     (if (and win video?)
         (do
           (zoom:selectMenuItem ["Meeting" "Start video"])
           (hs.alert "👁 Everyone can see you now! 👁"))
         (do
           (zoom:selectMenuItem ["Meeting" "Stop video"])
           (hs.alert "You are in the dark! 🕯"))))))

(hs.hotkey.bind
 [:cmd :shift :option :ctrl] "a"
 (fn []
   (let [win (hs.window.find "Zoom Meeting.*")
         zoom (win:application)
         mi ["Meeting" "Keep on top"]
         keep-on-top? (. (zoom:findMenuItem mi) :ticked)]
     (if (and win keep-on-top?)
         (do
           (zoom:selectMenuItem mi)
           (hs.alert "Zoom Window is normal now"))
         (do
           (zoom:selectMenuItem mi)
           (hs.alert "🎢 Zoom now on top! 🎢"))))))


{: group-zoom-windows}
