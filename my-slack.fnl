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

(fn has-class? [el target]
  "True if el's AXDOMClassList contains the target substring."
  (let [dom-cls (el:attributeValue :AXDOMClassList)]
    (var hit false)
    (when dom-cls
      (each [_ cls (ipairs dom-cls) &until hit]
        (when (string.find cls target 1 true)
          (set hit true))))
    hit))

(fn find-by-class [root target max-depth]
  "BFS for the first element whose AXDOMClassList contains target string."
  (var found nil)
  (var queue [{:el root :depth 0}])
  (while (and (not found) (< 0 (length queue)))
    (let [item (table.remove queue 1)
          el item.el
          d item.depth]
      (if (has-class? el target)
          (set found el)
          (when (< d max-depth)
            (let [kids (el:attributeValue :AXChildren)]
              (when kids
                (each [_ kid (ipairs kids)]
                  (table.insert queue {:el kid :depth (+ d 1)}))))))))
  found)

(fn collect-where [root pred max-depth]
  "BFS collecting all elements satisfying pred.
   Does not descend into matched elements."
  (let [results []
        queue [{:el root :depth 0}]]
    (while (< 0 (length queue))
      (let [item (table.remove queue 1)
            el item.el
            d item.depth
            matched (pred el)]
        (when matched (table.insert results el))
        (when (and (not matched) (< d max-depth))
          (let [kids (el:attributeValue :AXChildren)]
            (when kids
              (each [_ kid (ipairs kids)]
                (table.insert queue {:el kid :depth (+ d 1)})))))))
    results))

(fn gc [el n]
  "Get the nth child of an AX element."
  (let [kids (el:attributeValue :AXChildren)]
    (when kids (. kids n))))

;;; Message extraction

(fn collect-text [el]
  "Recursively gather all AXValue text from an element tree."
  (let [val (el:attributeValue :AXValue)
        kids (el:attributeValue :AXChildren)
        parts []]
    (when (and (= (type val) :string) (> (length val) 0)
               (not= (string.match val "^%s+$") val))
      (table.insert parts val))
    (when kids
      (each [_ kid (ipairs kids)]
        (let [sub (collect-text kid)]
          (when (> (length sub) 0)
            (table.insert parts sub)))))
    (table.concat parts " ")))

(fn climb-to-item [el max-hops]
  "Walk up the AXParent chain to the enclosing virtual-list row."
  (var cur el)
  (var hops 0)
  (while (and cur (< hops max-hops)
              (not (has-class? cur "c-virtual_list__item")))
    (set cur (cur:attributeValue :AXParent))
    (set hops (+ hops 1)))
  (when (and cur (has-class? cur "c-virtual_list__item")) cur))

(fn strip-tail [text]
  "Drop trailing time and reaction-count noise from a row aria-label."
  (var t text)
  (set t (pick-values 1 (string.gsub t "%s*%d+ reactions?%.?%s*$" "")))
  (set t (pick-values 1 (string.gsub t "%s*%d+:%d%d [AP]M%.?%s*$" "")))
  t)

(fn parse-title [title]
  "Split a row aria-label 'Sender: text… 10:04 AM.' into (sender text)."
  (let [(sender rest) (string.match title "^(.-):%s+(.*)$")]
    (if sender
        (values sender (strip-tail rest))
        (values "" (strip-tail title)))))

(fn extract-from-stamp [stamp]
  "Build a message record from a timestamp permalink element.
   The row's aria-label carries sender and text; the row frame is used
   for visibility filtering and the highlight overlay."
  (let [ax-url (stamp:attributeValue :AXURL)
        url (and ax-url ax-url.url)]
    (when url
      (let [time-kid (gc stamp 1)
            time (or (and time-kid (time-kid:attributeValue :AXValue)) "")
            item (or (climb-to-item stamp 8) stamp)
            pos (item:attributeValue :AXPosition)
            size (item:attributeValue :AXSize)
            title (item:attributeValue :AXTitle)]
        (when (and pos size)
          (let [(sender text) (if (and title (< 0 (length title)))
                                  (parse-title title)
                                  (values (let [sb (find-by-class item
                                                                  "sender_button"
                                                                  6)]
                                            (or (and sb
                                                     (sb:attributeValue :AXTitle))
                                                ""))
                                          (collect-text item)))]
            {:sender sender
             :text text
             :time time
             :url url
             :frame {:x pos.x :y pos.y :w size.w :h size.h}}))))))

(fn get-visible-messages []
  "Extract visible Slack messages anywhere in the focused window.
   Anchors on timestamp permalinks, so it works in channels, DMs,
   thread panes, search results, and collapsed narrow layouts."
  (let [slack (hs.application.find :Slack)]
    (when slack
      (let [ax-app (ax.applicationElement slack)
            win (or (ax-app:attributeValue :AXFocusedWindow)
                    (let [wins (ax-app:attributeValue :AXWindows)]
                      (when wins (. wins 1))))]
        (when win
          (let [win-pos (win:attributeValue :AXPosition)
                win-size (win:attributeValue :AXSize)
                stamps (collect-where win
                                      (fn [el]
                                        (and (has-class? el "c-timestamp")
                                             (not= (el:attributeValue :AXURL)
                                                   nil)))
                                      40)
                best {}
                order []]
            (each [_ stamp (ipairs stamps)]
              (let [data (extract-from-stamp stamp)]
                ;; h > 20 drops virtualized placeholder rows; the rest is
                ;; a viewport intersection test
                (when (and data (< 20 data.frame.h)
                           (< win-pos.y (+ data.frame.y data.frame.h))
                           (< data.frame.y (+ win-pos.y win-size.h))
                           (< win-pos.x (+ data.frame.x data.frame.w))
                           (< data.frame.x (+ win-pos.x win-size.w)))
                  (let [prev (. best data.url)]
                    (when (not prev)
                      (table.insert order data.url))
                    ;; same permalink can render twice (e.g. thread parent
                    ;; in pane and flexpane); keep the taller rendition
                    (when (or (not prev) (< prev.frame.h data.frame.h))
                      (tset best data.url data))))))
            (let [messages (icollect [_ url (ipairs order)] (. best url))]
              (table.sort messages
                          (fn [a b]
                            (if (= a.frame.x b.frame.x)
                                (< a.frame.y b.frame.y)
                                (< a.frame.x b.frame.x))))
              messages)))))))

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

(fn pick-message [placeholder on-choice]
  "Show a chooser of visible Slack messages, call on-choice with the URL.
   Highlights the corresponding message in Slack as you navigate."
  (let [slack (hs.application.find :Slack)]
    (when slack (slack:activate)))
  (hs.timer.doAfter 0.3
                    (fn []
                      (let [messages (get-visible-messages)]
                        (if (and messages (< 0 (length messages)))
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
                                                              (on-choice choice.url))))]
                              (chooser:placeholderText placeholder)
                              (chooser:width 20)
                              (chooser:rows 10)
                              (chooser:choices reversed)
                              (chooser:hideCallback (fn [] (hide-indicator)))
                              (start-indicator-tracking chooser frame-by-url)
                              (chooser:show))
                            (hs.alert "No messages found in current Slack view"))))))

(fn capture []
  "Pick a visible Slack message and send it to Emacs for capture."
  (pick-message "Select a Slack message" send-to-emacs))

(fn yank-url []
  "Pick a visible Slack message and copy its permalink to the clipboard."
  (pick-message "Yank Slack message link"
                (fn [url]
                  (hs.pasteboard.setContents url)
                  (hs.alert "Slack link copied"))))

(fn visible-messages-json []
  "Visible messages as a JSON string, for consumption outside Hammerspoon."
  (hs.json.encode (or (get-visible-messages) [])))

{:search search
 :capture capture
 :yank-url yank-url
 :get-visible-messages get-visible-messages
 :visible-messages-json visible-messages-json
 :show-indicator show-indicator
 :hide-indicator hide-indicator}
