;; Stupid Admin By Request Bullshit
(local log (hs.logger.new "abr.fnl" "debug"))

(fn bury []
  "push the fucking thing out of my sight"
  (let [yabai (require :yabai)
        abr-app (hs.application.find "Admin By Request")
        w (abr-app:findWindow "Administrator Access")]
    (when w
      (w:focus)
      (yabai.run "yabai -m window --space 3"))))

(fn activate []
  (var email-field nil)
  (var reason-field nil)
  (let [abr-app (hs.application.find "Admin By Request")
        active? (abr-app:findWindow "^Administrator Access$")]
    (if active?
        (bury)
        (do
          (hs.application.launchOrFocus "Admin By Request")
          (hs.timer.waitUntil
           #(not= nil (abr-app:findWindow "Instructions"))
           (fn []
             (hs.eventtap.keyStroke [] :return)))
          
          (hs.timer.waitUntil
           #(not= nil (abr-app:findWindow "^Request Administrator Access$"))
           (fn []
             (let [win (abr-app:findWindow "^Request Administrator Access$")
                   ax (hs.axuielement.windowElement win)
                   fields (ax:childrenWithRole "AXTextField")
                   buttons (ax:childrenWithRole "AXButton")]
               
               (each [_ field (ipairs fields)]
                 (let [placeholder (field:attributeValue "AXPlaceholderValue")]
                   (if (and placeholder (string.match placeholder "Email.*"))
                       (set email-field field)
                       (set reason-field field))))
               
               (email-field:setAttributeValue "AXValue" "ryl@qlik.com")
               
               (var focused false)
               (: (abr-app:findWindow "^Request Administrator Access$") :focus)
               (while (not focused)
                 (hs.timer.usleep 50000) 
                 (hs.eventtap.keyStroke [] :tab)
                 (hs.timer.usleep 50000) 
                 (set focused (reason-field:attributeValue "AXFocused")))
               
               (when focused
                 (hs.eventtap.keyStrokes "sudome inmediatamente, pinche cabron!"))
               
               (hs.timer.usleep 100000)
               (each [_ button (ipairs buttons)]
                 (when (= (button:attributeValue "AXTitle") "OK")
                     (button:performAction "AXPress")
                     (hs.timer.waitUntil
                      #(not= nil (abr-app:findWindow "Administrator Access"))
                      bury))))))
          
          (hs.timer.waitUntil
           #(not= nil (abr-app:findWindow "Instructions"))
           (fn []
             (: (abr-app:findWindow "Instructions") :focus)
             (hs.eventtap.keyStroke [] :return)))))))

(fn idle-watcher-start []
  (hs.alert "ABR's gotta run")
  (set _G.idle-timer ; gotta store it, so it doesn't get GCed
   (hs.timer.doEvery
    (* 3 60) ;; check every three minutes
    (fn []
      ;; if idled for more than a ...
      (when (< 30 (hs.host.idleTime))
        (activate)))
    ;; keep checking even if errors
    true)))

(fn idle-watcher-stop []
  (when _G.idle-timer
    (_G.idle-timer:stop)
    (hs.alert "ABR will stop trying")))

(fn toggle-watcher []
  (if (and _G.idle-timer (_G.idle-timer:running))
      (idle-watcher-stop)
      (idle-watcher-start)))

{ : activate
  : idle-watcher-start
  : idle-watcher-stop
  : toggle-watcher}
