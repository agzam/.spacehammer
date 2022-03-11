(local windows (require :windows))

(fn scroll-up
  []
  (windows.set-mouse-cursor-at :Webex)
  (hs.eventtap.scrollWheel [0 3] {}))

(fn scroll-down
  []
  (windows.set-mouse-cursor-at :Webex)
  (hs.eventtap.scrollWheel [0 -3] {}))

(fn prev-chat
  []
  (hs.eventtap.keyStroke [:alt] "up"))

(fn next-chat
  []
  (hs.eventtap.keyStroke [:alt] "down"))

{:scroll-up scroll-up
 :scroll-down scroll-down
 :prev-chat prev-chat
 :next-chat next-chat
 :config {:key "Webex"
          :keys [{:mods [:ctrl]
                  :key :e
                  :action "webex:scroll-up"}
                 {:mods [:ctrl]
                  :key :y
                  :action "webex:scroll-down"}
                 {:mods [:cmd]
                  :key :k
                  :action "webex:prev-chat"}
                 {:mods [:cmd]
                  :key :j
                  :action "webex:next-chat"}]}}
