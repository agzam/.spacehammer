(fn emacsclient-exe []
  "Locate emacsclient executable."
  (-> "Emacs"
      hs.application.find
      (: :path)
      (: :gsub "Emacs.app" "bin/emacsclient")))

(local log (hs.logger.new "\tmy-emacs.fnl\t" "debug"))

(hs.hotkey.bind
 [:cmd :ctrl] "1"
 (fn []
   (io.popen (.. (emacsclient-exe) " -e "
                 "'(load-file \"~/.doom.d/modules/custom/org/autoload/org-attach.el\") "
                 "(call-interactively (quote yank-from-clipboard)))' &"))))
