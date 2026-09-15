;; Flameshot leaves the capture on the pasteboard; hand it to the clipimg
;; menu in Emacs, which reads the text, saves or uploads it.
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
              "emacsclient --eval \"(call-interactively 'clipimg)\""))
         (: (hs.application.find :Emacs)
            :activate)))))))

(watcher:start)
