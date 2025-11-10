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

(fn url-act-in-emacs []
  (let [current-app (hs.application.frontmostApplication)
        app-name (current-app:name)
        browsers ["Safari" "Google Chrome" "Firefox" "Arc" "Brave Browser" "Microsoft Edge"]
        is-browser (accumulate [found false _ browser (ipairs browsers)]
                     (or found (= app-name browser)))]

    ;; Get URL based on context
    (var url nil)
    (if is-browser
        ;; Get URL from browser
        (let [script (match app-name
                       "Safari" "tell application \"Safari\" to return URL of current tab of front window"
                       "Google Chrome" "tell application \"Google Chrome\" to return URL of active tab of front window"
                       "Arc" "tell application \"Arc\" to return URL of active tab of front window"
                       "Brave Browser" "tell application \"Brave Browser\" to return URL of active tab of front window"
                       "Firefox" "tell application \"Firefox\" to return URL of active tab of front window"
                       "Microsoft Edge" "tell application \"Microsoft Edge\" to return URL of active tab of front window"
                       _ nil)]
          (when script
            (let [(ok result) (hs.osascript.applescript script)]
              (when ok (set url result)))))
        
        ;; Check clipboard for URL
        (let [clipboard-text (hs.pasteboard.getContents)]
          (when (and clipboard-text 
                     (or (clipboard-text:match "^https?://")
                         (clipboard-text:match "^www%.")))
            (set url clipboard-text))))
    
    ;; Send to Emacs if we have a URL
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
