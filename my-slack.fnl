(local ax (require :hs.axuielement))

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

;;; AX tree helpers

(fn find-by-class [root target max-depth]
  "BFS for the first element whose AXDOMClassList contains target string."
  (var found nil)
  (var queue [{:el root :depth 0}])
  (while (and (not found) (> (length queue) 0))
    (let [item (table.remove queue 1)
          el item.el
          d item.depth
          dom-cls (el:attributeValue :AXDOMClassList)]
      (when dom-cls
        (each [_ cls (ipairs dom-cls) &until found]
          (when (string.find cls target 1 true)
            (set found el))))
      (when (and (not found) (< d max-depth))
        (let [kids (el:attributeValue :AXChildren)]
          (when kids
            (each [_ kid (ipairs kids)]
              (table.insert queue {:el kid :depth (+ d 1)})))))))
  found)

(fn gc [el n]
  "Get the nth child of an AX element."
  (let [kids (el:attributeValue :AXChildren)]
    (when kids (. kids n))))

;;; Message extraction

(fn skip-class? [cls-str]
  "True for DOM class strings belonging to non-content parts of a message."
  (or (string.find cls-str "sender_button" 1 true)
      (string.find cls-str "c-timestamp" 1 true)
      (string.find cls-str "reaction_bar" 1 true)
      (string.find cls-str "reply_count" 1 true)
      (string.find cls-str "reply_bar" 1 true)
      (string.find cls-str "message_actions" 1 true)
      (string.find cls-str "message_kit__file" 1 true)
      (string.find cls-str "avatar" 1 true)
      (string.find cls-str "file_gallery" 1 true)))

(fn collect-text [el]
  "Recursively gather all AXValue text from an element tree."
  (let [val (el:attributeValue :AXValue)
        kids (el:attributeValue :AXChildren)
        parts []]
    (when (and val (> (length val) 0) (not= (string.match val "^%s+$") val))
      (table.insert parts val))
    (when kids
      (each [_ kid (ipairs kids)]
        (let [sub (collect-text kid)]
          (when (> (length sub) 0)
            (table.insert parts sub)))))
    (table.concat parts " ")))

(fn extract-msg [msg-el]
  "Pull sender, timestamp URL, display time, text, and screen frame
   from a message list item."
  (let [hover (gc msg-el 1)
        actions (when hover (gc hover 1))]
    (when actions
      (let [kids (actions:attributeValue :AXChildren)
            pos (actions:attributeValue :AXPosition)
            size (actions:attributeValue :AXSize)
            result {:sender ""
                    :url nil
                    :time ""
                    :text ""
                    :frame (when (and pos size)
                             {:x pos.x :y pos.y :w size.w :h size.h})}]
        (when kids
          (each [_ child (ipairs kids)]
            (let [role (or (child:attributeValue :AXRole) "")
                  dom-cls (child:attributeValue :AXDOMClassList)
                  cls-str (if dom-cls (table.concat dom-cls ",") "")]
              (when (string.find cls-str "sender_button" 1 true)
                (tset result :sender (or (child:attributeValue :AXTitle) "")))
              (when (string.find cls-str "c-timestamp" 1 true)
                (let [ax-url (child:attributeValue :AXURL)
                      time-kid (gc child 1)]
                  (when (and ax-url ax-url.url)
                    (tset result :url ax-url.url))
                  (when time-kid
                    (tset result :time
                          (or (time-kid:attributeValue :AXValue) "")))))
              (when (and (not (skip-class? cls-str))
                         (or (= role :AXStaticText) (= role :AXGroup)
                             (= role :AXList)))
                (let [txt (collect-text child)]
                  (when (> (length txt) 0)
                    (tset result :text (.. result.text " " txt))))))))
        (when result.url result)))))

(fn get-visible-messages []
  "Extract messages within the message pane's visible viewport."
  (let [slack (hs.application.find :Slack)]
    (when slack
      (let [ax-app (ax.applicationElement slack)
            wins (ax-app:attributeValue :AXWindows)
            win (when wins (. wins 1))]
        (when win
          (let [msg-pane (find-by-class win "p-message_pane" 20)]
            (when msg-pane
              (let [pane-pos (msg-pane:attributeValue :AXPosition)
                    pane-size (msg-pane:attributeValue :AXSize)
                    pane-top pane-pos.y
                    pane-bottom (+ pane-pos.y pane-size.h)
                    ax-list (find-by-class msg-pane "sr-only" 5)]
                (when ax-list
                  (let [items (ax-list:attributeValue :AXChildren)
                        messages []]
                    (each [_ item (ipairs items)]
                      (let [data (extract-msg item)]
                        (when (and data data.frame (< 20 data.frame.h)
                                   (< pane-top data.frame.y)
                                   (< (+ data.frame.y data.frame.h) pane-bottom))
                          (table.insert messages data))))
                    messages))))))))))

;;; Emacs integration

(fn send-to-emacs [url]
  "Send a Slack message URL to Emacs for capture."
  (hs.execute (.. "export PATH=$PATH:/opt/homebrew/bin && "
                  "emacsclient --eval \"(slacko-thread-capture \\\"" url
                  "\\\")\""))
  (let [emacs (hs.application.find :Emacs)]
    (when emacs (emacs:activate))))

;;; Visual indicator - highlights the selected message in Slack

(var indicator-canvas nil)
(var indicator-timer nil)

(fn show-indicator [frame]
  "Draw or move the highlight indicator to the given screen frame."
  (when (and frame (< 20 frame.h))
    (if indicator-canvas
        (indicator-canvas:frame frame)
        (do
          (set indicator-canvas (hs.canvas.new frame))
          (indicator-canvas:appendElements [{:type :rectangle
                                             :action :stroke
                                             :strokeColor {:red 0.2
                                                           :green 0.8
                                                           :blue 1
                                                           :alpha 0.85}
                                             :strokeWidth 3
                                             :roundedRectRadii {:xRadius 8
                                                                :yRadius 8}}
                                            {:type :rectangle
                                             :action :fill
                                             :fillColor {:red 0.2
                                                         :green 0.8
                                                         :blue 1
                                                         :alpha 0.06}}])
          (indicator-canvas:level hs.canvas.windowLevels.overlay)
          (indicator-canvas:clickActivating false)
          (indicator-canvas:behaviorAsLabels [:canJoinAllSpaces :transient])))
    (indicator-canvas:show)))

(fn hide-indicator []
  "Remove the highlight indicator and stop tracking."
  (when indicator-timer
    (indicator-timer:stop)
    (set indicator-timer nil))
  (when indicator-canvas
    (indicator-canvas:delete)
    (set indicator-canvas nil)))

(fn start-indicator-tracking [chooser frame-by-url]
  "Poll the chooser's highlighted row and update the indicator overlay.
   Uses URL from selectedRowContents to find the correct message frame,
   so filtering in the chooser still highlights the right message."
  (var last-url nil)
  (set indicator-timer
       (hs.timer.new 0.1 (fn []
                           (if (chooser:isVisible)
                               (let [contents (chooser:selectedRowContents)]
                                 (when contents
                                   (let [url contents.url]
                                     (when (not= url last-url)
                                       (set last-url url)
                                       (let [frame (. frame-by-url url)]
                                         (if frame
                                             (show-indicator frame)
                                             (when indicator-canvas
                                               (indicator-canvas:hide))))))))
                               (hide-indicator)))))
  (indicator-timer:start))

(fn capture-avatar [win-img wf frame]
  "Crop avatar from a window snapshot using window-relative coordinates.
   Avoids screen coordinate issues across monitors."
  (when (and win-img frame (< 20 frame.h))
    (let [wx (+ (- frame.x wf.x) 28)
          wy (+ (- frame.y wf.y) 6)]
      (when (and (< 0 wx) (< 0 wy))
        (win-img:croppedCopy (hs.geometry.rect wx wy 40 40))))))

;;; Chooser UI

(fn capture []
  "Show a chooser of visible Slack messages, send selected to Emacs.
   Highlights the corresponding message in Slack as you navigate."
  (let [slack (hs.application.find :Slack)]
    (when slack (slack:activate)))
  (hs.timer.doAfter 0.3
                    (fn []
                      (let [messages (get-visible-messages)]
                        (if (and messages (> (length messages) 0))
                            (let [slack-win (let [s (hs.application.find :Slack)]
                                              (when s (. (s:allWindows) 1)))
                                  win-img (when slack-win (slack-win:snapshot))
                                  wf (when slack-win (slack-win:frame))
                                  choices []
                                  _ (each [_ msg (ipairs messages)]
                                      (table.insert choices
                                                    {:text (.. msg.sender ": "
                                                               (string.sub (string.gsub msg.text
                                                                                        "^%s+"
                                                                                        "")
                                                                           1 120))
                                                     :subText msg.time
                                                     :image (capture-avatar win-img
                                                                            wf
                                                                            msg.frame)
                                                     :url msg.url}))
                                  ;; Reverse so newest message is at the top
                                  reversed []
                                  frame-by-url (collect [_ msg (ipairs messages)]
                                                 (values msg.url msg.frame))
                                  _ (for [i (length choices) 1 -1]
                                      (table.insert reversed (. choices i)))
                                  chooser (hs.chooser.new (fn [choice]
                                                            (hide-indicator)
                                                            (when (and choice
                                                                       choice.url)
                                                              (send-to-emacs choice.url))))]
                              (chooser:placeholderText "Select a Slack message")
                              (chooser:width 20)
                              (chooser:rows 10)
                              (chooser:choices reversed)
                              (chooser:hideCallback (fn [] (hide-indicator)))
                              (start-indicator-tracking chooser frame-by-url)
                              (chooser:show))
                            (hs.alert "No messages found in current Slack view"))))))

{:search search :capture capture :get-visible-messages get-visible-messages}
