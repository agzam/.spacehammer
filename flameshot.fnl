;; I'm just gonna wait for Flameshot to capture an image and attempt to OCR it
(local
 watcher
 (hs.application.watcher.new
  (fn [name event app]
    (when (and (= name "Flameshot")
               (= event hs.application.watcher.deactivated)
               (hs.pasteboard.readImage))
      (hs.timer.doAfter
       0.1
       (fn []
         (hs.execute
          (.. "export PATH=$PATH:/opt/homebrew/bin && "
              "emacsclient --eval \"(call-interactively 'ocr-clipboard-content)\""))
         (: (hs.application.find :Emacs)
            :activate)))))))

(watcher:start)
