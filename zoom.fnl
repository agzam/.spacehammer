(require-macros :lib.macros)

(hs.hotkey.bind
 [:cmd :shift :option :ctrl] "m"
 (fn []
   (let [zoom (hs.application.find "zoom.us")
         win (zoom:findWindow "Zoom Meeting")
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
   (let [zoom (hs.application.find "zoom.us")
         win (zoom:findWindow "Zoom Meeting")
         video? (zoom:findMenuItem ["Meeting" "Start video"])]
     (if (and win video?)
         (do
           (zoom:selectMenuItem ["Meeting" "Start video"])
           (hs.alert "👁 Everyone can see you now! 👁"))
         (do
           (zoom:selectMenuItem ["Meeting" "Stop video"])
           (hs.alert "You are in the dark! 🕯"))))))
