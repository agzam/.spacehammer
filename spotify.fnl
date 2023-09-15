(local modal (require :lib.modal))

(fn spotify-is-running []
  "The built-in function is faulty: https://www.hammerspoon.org/docs/hs.spotify.html#isRunning"
  (hs.application.find "Spotify" true))

(fn vlc-is-running []
  (hs.application.find "VLC" true))

(fn like-this-song []
  (let [spotify (spotify-is-running)]
    (when spotify
      (let [cur (hs.window.focusedWindow)]
        (: spotify :activate)
        (hs.eventtap.keyStroke [:alt :shift] "b" spotify)
        (: cur :focus)))))

(fn dislike-this-song []
  (let [spotify (spotify-is-running)]
    (when spotify
      (let [cur (hs.window.focusedWindow)]
        (: spotify :activate)
        (hs.eventtap.keyStroke [:cmd] "right" spotify)
        (: cur :focus)))))

(fn play-or-pause []
  (if (spotify-is-running)
      (hs.spotify.playpause)
      (: (hs.eventtap.event.newSystemKeyEvent "PLAY" true) :post)))

(fn prev-track []
  (if (spotify-is-running)
      (hs.spotify.previous)

      (match (vlc-is-running)
        app (: app :selectMenuItem ["Playback" "Previous"]))

      (: (hs.eventtap.event.newSystemKeyEvent "PREVIOUS" true) :post)))

(fn next-track []
  (if (spotify-is-running)
      (hs.spotify.next)

      (match (vlc-is-running)
        app (: app :selectMenuItem ["Playback" "Next"]))

      (: (hs.eventtap.event.newSystemKeyEvent "NEXT" true) :post)))

(fn seek-forward []
  (if (match (vlc-is-running)
        app (: app :selectMenuItem ["Playback" "Step Forward"]))

      (match (spotify-is-running)
        app (: app :selectMenuItem ["Playback" "Seek Forward"]))))

(fn seek-backward []
  (if (match (vlc-is-running)
        app (: app :selectMenuItem ["Playback" "Step Backward"]))

      (match (spotify-is-running)
        app (: app :selectMenuItem ["Playback" "Seek Backward"]))))


(fn faster []
  (match (vlc-is-running)
    vlc-app (hs.eventtap.keyStroke [:shift] "." vlc-app)))

(fn slower []
  (match (vlc-is-running)
    vlc-app (hs.eventtap.keyStroke [:shift] "," vlc-app)))

(fn mute []
  (: (hs.eventtap.event.newSystemKeyEvent "MUTE" true) :post))

{:like-this-song like-this-song
 :dislike-this-song dislike-this-song
 :play-or-pause play-or-pause
 :prev-track prev-track
 :next-track next-track
 :seek-forward seek-forward
 :seek-backward seek-backward
 :faster faster
 :slower slower
 :mute mute}
