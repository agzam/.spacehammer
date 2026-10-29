(fn emacsclient-exe []
  "Locate emacsclient executable."
  (-> "Emacs"
      hs.application.find
      (: :path)
      (: :gsub "Emacs.app" "bin/emacsclient")))

(local { : activate-app } (require :yabai))

;; (local log (hs.logger.new "\tmy-emacs.fnl\t" "debug"))

(hs.hotkey.bind
 [:cmd :ctrl] "1"
 (fn []
   (io.popen (.. (emacsclient-exe) " -e "
                 "'(load-file \"~/.doom.d/modules/custom/org/autoload/org-attach.el\") "
                 "(call-interactively (quote yank-from-clipboard)))' &"))))

(local tab-url-queries
       {"com.apple.Safari" "URL of current tab of front window"
        "com.google.Chrome" "URL of active tab of front window"
        "com.brave.Browser" "URL of active tab of front window"
        "company.thebrowser.Browser" "URL of active tab of front window"
        "com.microsoft.edgemac" "URL of active tab of front window"})

(fn active-tab-url []
  "URL of the active tab in the frontmost browser, else in the default one."
  (let [front (: (hs.application.frontmostApplication) :bundleID)
        browser (if (. tab-url-queries front)
                    front
                    (hs.urlevent.getDefaultHandler "https"))
        query (. tab-url-queries browser)]
    (when query
      (let [(ok url) (hs.osascript.applescript
                      (string.format "tell application id \"%s\" to return %s"
                                     browser query))]
        (when ok url)))))

(fn url-act-in-emacs []
  (let [url (active-tab-url)]
    (when url
      (let [cmd (string.format
                 "emacsclient -e '(embark-ephemeral-act \"%s\")'"
                 (url:gsub "'" "'\\''"))
            full-cmd (string.format "export PATH=$PATH:/opt/homebrew/bin && %s" cmd)
            task (hs.task.new "/bin/sh"
                              (fn [_exit-code _stdout _stderr])
                              ["-c" full-cmd])]
        (activate-app :Emacs)
        (task:start)))))

{ : url-act-in-emacs
  }
