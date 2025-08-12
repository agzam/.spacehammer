;; Stupid Admin By Request Bullshit
(local log (hs.logger.new "abr.fnl" "debug"))

(fn activate []
  (let [abr-app (hs.application.find "Admin By Request")
        inactive? (= nil (abr-app:findWindow "^Administrator Access$"))]
    (when (and
           inactive?
           (hs.application.launchOrFocus "Admin By Request"))

      (hs.timer.waitUntil
       #(not= nil (abr-app:findWindow "Instructions"))
       (fn []
         (hs.eventtap.keyStroke [] :return)))

      (hs.timer.waitUntil
       #(not= nil (abr-app:findWindow "^Request Administrator Access$"))
       (fn []
         (hs.eventtap.keyStroke [] :tab)
         (hs.eventtap.keyStrokes "sudome inmediatamente, pendejo!")
         (hs.eventtap.keyStroke [] :return)))

      (hs.timer.waitUntil
       #(not= nil (abr-app:findWindow "Instructions"))
       (fn []
         (hs.eventtap.keyStroke [] :return))))))

(fn idle-watcher-start []
  (set _G.idle-timer ; gotta store it, so it doesn't get GCed
   (hs.timer.doEvery
    (* 2 60) ;; check every two minutes
    (fn []
      ;; if idled for more than a ...
      (when (< 15 (hs.host.idleTime))
        (activate)))
    ;; keep checking even if errors
    true)))

{ : activate
  : idle-watcher-start}
