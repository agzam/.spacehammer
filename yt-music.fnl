(local music-app "YouTube Music")

(fn like-this-song []
  (let [cur (hs.window.focusedWindow)
        app (hs.application.find music-app)]
    (app:activate)
    (hs.eventtap.keyStroke nil "escape" app)
    (hs.eventtap.keyStroke nil "i" app)
    (hs.eventtap.keyStroke [:shift] "=" app)
    (hs.eventtap.keyStroke nil "escape" app)
    (cur:focus)))

(fn dislike-this-song []
  (let [cur (hs.window.focusedWindow)
        app (hs.application.find music-app)]
    (app:activate)
    (hs.eventtap.keyStroke nil "escape" app)
    (hs.eventtap.keyStroke nil "i" app)
    (hs.eventtap.keyStroke [:shift] "-" app)
    (hs.eventtap.keyStroke nil "escape" app)
    (cur:focus)))

{:like-this-song like-this-song
 :dislike-this-song dislike-this-song}
