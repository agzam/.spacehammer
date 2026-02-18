(fn search [search-term]
  (let [_ (hs.application.launchOrFocus :Slack)
        app (hs.application.find :Slack)]
    (app:selectMenuItem [:File :Workspace :QlikDev])
    (when app
      (hs.eventtap.keyStroke ["cmd"] "g" 0 app)
      (hs.timer.usleep 500)
      (hs.eventtap.keyStroke ["alt" "ctrl"] "Delete" 0 app)
      (hs.eventtap.keyStrokes search-term app)
      (hs.eventtap.keyStroke [] :return 0 app))))

;;; Message/thread capture via accessibility API
;;;
;;; When a message is selected in Slack (blue border via Up arrow),
;;; reads the message URL from the AX tree and sends to Emacs.

(fn find-timestamp-url [focused]
  "Walk the focused element's AX tree to find the timestamp link URL."
  (let [children (focused:attributeValue "AXChildren")]
    (when (and children (> (length children) 0))
      (let [msg (. children 1)
            msg-kids (msg:attributeValue "AXChildren")]
        (when (and msg-kids (> (length msg-kids) 0))
          (let [actions (. msg-kids 1)
                action-kids (actions:attributeValue "AXChildren")]
            (when action-kids
              (var url nil)
              (each [_ kid (ipairs action-kids) &until url]
                (let [dom-cls (kid:attributeValue "AXDOMClassList")]
                  (when dom-cls
                    (each [_ cls (ipairs dom-cls) &until url]
                      (when (string.match cls "c%-timestamp")
                        (let [ax-url (kid:attributeValue "AXURL")]
                          (when (and ax-url ax-url.url)
                            (set url ax-url.url))))))))
              url)))))))

(fn get-selected-message-url []
  "Get the URL of the currently selected message in Slack."
  (let [slack (hs.application.find "Slack")]
    (when slack
      (let [ax (hs.axuielement.applicationElement slack)
            focused (ax:attributeValue "AXFocusedUIElement")]
        (when focused
          (find-timestamp-url focused))))))

(fn send-to-emacs [url]
  (hs.execute
   (.. "export PATH=$PATH:/opt/homebrew/bin && "
       "emacsclient --eval \"(slacko-thread-capture \\\"" url "\\\")\""
       ))
  (let [emacs (hs.application.find :Emacs)]
    (when emacs (emacs:activate))))

(fn capture []
  "Read selected Slack message URL and send to Emacs.
   If no message is selected, press Up to select the last one."
  (let [slack (hs.application.find "Slack")]
    (when slack (slack:activate)))
  (hs.timer.usleep 200000)
  (let [url (get-selected-message-url)]
    (if url
        (send-to-emacs url)
        ;; No selection - press Up to select last message, then retry
        (do
          (hs.eventtap.keyStroke {} :up)
          (hs.timer.usleep 500000)
          (let [url2 (get-selected-message-url)]
            (if url2
                (send-to-emacs url2)
                (hs.alert "Could not find a Slack message to capture")))))))

{:search search
 :capture capture
 :get-selected-message-url get-selected-message-url}
