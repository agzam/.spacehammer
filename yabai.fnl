(local { : count : last : filter : first : find : contains? : seq?} (require :lib.functional))
(local emacs (require :emacs))

(local log (hs.logger.new "yabai"))
(local locked-windows {})
(local { : flash-focused-window } (require :screen))

(fn run [cmd]
  (->
   (hs.execute (.. "export PATH=$PATH:/opt/homebrew/bin && " cmd))
   (string.gsub "[\n\r]+$" "")
   (string.gsub "^%*(.-)%s*$" "%1")))

(fn jump-window [dir]
  (run (.. "yabai -m window --focus " dir " || "
           "yabai -m display --focus " dir)))

(fn swap-window [dir]
  (run
   (.. "yabai -m window --swap " dir
       " || ("
       "yabai -m window --display " dir " && "
       "yabai -m display --focus " dir " && "
       "yabai -m window --warp " (if (= dir :east) :first :last)
       ")")))

(fn current-window []
  (let [w (run "yabai -m query --windows --window")]
    (when (not (or (= w nil)
                   (= w "")))
      (hs.json.decode w))))

(fn current-space []
  (let [s (run "yabai -m query --spaces --space")]
    (hs.json.decode s)))

(fn window-first-last [first-last]
  (let [cw (current-window)]
    (when cw
      (let [cur (. cw :id)
            fl (run (.. "yabai -m query --windows --window " first-last))
            fl (-> fl (hs.json.decode) (.  :id))]
        (= cur fl)))))

(fn space-first-last [first-last]
  (let [cs (current-space)]
    (when cs
      (let [display-idx (run "yabai -m query --displays --display | jq '.index'")
            cur (. cs :id)
            spc-idx (case first-last :first 0 :last -1)
            fl (run (string.format
                     "yabai -m query --spaces | jq '[.[] | select(.display == %s)] | .[%s]'"
                     display-idx spc-idx))
            fl (-> fl (hs.json.decode) (.  :id))]
        (= cur fl)))))

(fn display-first-last [first-last]
  (let [cd (-?> (run "yabai -m query --displays --display")
                hs.json.decode)]
    (when cd
      (let [cur (. cd :id)
            fl (run (.. "yabai -m query --displays --display " first-last))
            fl (-> fl (hs.json.decode) (.  :id))]
        (= cur fl)))))

(fn first-window? [] (window-first-last :first))
(fn last-window? [] (window-first-last :last))
(fn first-space? [] (space-first-last :first))
(fn last-space? [] (space-first-last :last))
(fn first-display? [] (display-first-last :first))
(fn last-display? [] (display-first-last :last))

(local resize-coeff 120)

(fn jump-window-recent []
  (run "yabai -m window --focus recent"))

(fn resize-left []
  (let [cw  (current-window)]
   (when cw
     (let [n resize-coeff
           split-type (. cw :split-type)
           split-child (. cw :split-child)
           params (match [(first-window?)
                          (last-window?)
                          split-type
                          split-child]
                    (where [f] f) "right:-%s:%s"
                    (where [_ l _] l) "left:-%s:%s"
                    (where [_ _ "vertical" "first_child"]) "right:-%s:%s"
                    (where [_ _ "vertical" "second_child"]) "left:-%s:%s"
                    (where [_ _ "horizontal"]) "right:-%s:%s")]
       (run (.. "yabai -m window --resize "
                (string.format params n n)))))))

(fn resize-right []
  (let [cw (current-window)]
    (when cw
      (let [n resize-coeff
            split-type (. cw :split-type)
            split-child (. cw :split-child)
            params (match [(first-window?)
                           (last-window?)
                           split-type
                           split-child]
                     (where [f] f) "right:%s:%s"
                     (where [_ l _] l) "left:%s:%s"
                     (where [_ _ "vertical" "first_child"]) "right:%s:%s"
                     (where [_ _ "vertical" "second_child"]) "left:%s:-%s"
                     (where [_ _ "horizontal"]) "left:%s:-%s")]
        (run (.. "yabai -m window --resize "
                 (string.format params n n)))))))

(fn resize-up []
  (let [n resize-coeff
        split-type (. (current-window) :split-type)
        params (match [(first-window?)
                       (last-window?)
                       split-type]
                 (where [f] f) "bottom:%s:-%s"
                 (where [_ l _] l) "top:%s:-%s"
                 (where [_ _ "vertical"]) "top:%s:-%s"
                 (where [_ _ "horizontal"]) "top:%s:-%s")]
    (run (.. "yabai -m window --resize "
             (string.format params n n)))))

(fn resize-down []
  (let [n resize-coeff
        split-type (. (current-window) :split-type)
        params (match [(first-window?)
                       (last-window?)
                       split-type]
                 (where [f] f) "bottom:-%s:%s"
                 (where [_ l _] l) "top:-%s:%s"
                 (where [_ _ "vertical"]) "bottom:%s:%s"
                 (where [_ _ "horizontal"]) "bottom:-%s:%s")]
    (run (.. "yabai -m window --resize "
             (string.format params n n)))))

(fn toggle-maximize []
  (run (.. "yabai -m window --toggle zoom-fullscreen")))

(fn minimize []
  (run (.. "yabai -m window --minimize")))

(fn toggle-float []
  (run (.. "yabai -m window --toggle float")))

(fn toggle-sticky []
  (run "yabai -m window --toggle sticky"))

(fn balance []
  (run "yabai -m space --balance"))

(tset table :index-of
  (fn [tbl value]
    (var idx nil)
    (each [i v (ipairs tbl)]
      (when (= v value)
        (set idx i)))
    idx))

(fn show-space-label []
  (let [focused-id (hs.spaces.focusedSpace)
        disp-id (hs.spaces.spaceDisplay focused-id)
        spc-names  (hs.spaces.missionControlSpaceNames)
        disp-spcs (. spc-names disp-id)]
    (hs.alert (. disp-spcs focused-id) 0.3)))

(fn space-next []
  (run "yabai -m space --focus next || yabai -m space --focus first")
  (hs.timer.doAfter 0.1 show-space-label))

(fn space-previous []
  (run "yabai -m space --focus prev || yabai -m space --focus last")
  (hs.timer.doAfter 0.1 show-space-label))

(fn jump-to-space [idx]
  (run (.. "yabai -m space --focus " idx))
  (hs.timer.doAfter 0.1 show-space-label))

(fn jump-space-recent []
  (run "yabai -m space --focus recent")
  (hs.timer.doAfter 0.1 show-space-label))

(fn try-move-window-adjacent-space [direction]
  (let [cmd (.. "yabai -m window --space " direction " --focus 2>&1")
        error-msg (.. "could not locate the " direction " space")
        result (run cmd)]
    (when (not (result:find error-msg)) result)))

(fn move-window-adjacent-space-with-fallback [primary-dir fallback-dir]
  (or (try-move-window-adjacent-space primary-dir)
      (try-move-window-adjacent-space fallback-dir)
      (do
        (run "yabai -m space --create")
        (try-move-window-adjacent-space primary-dir))))

(fn move-to-prev-space []
  (move-window-adjacent-space-with-fallback "prev" "next"))

(fn move-to-next-space []
  (move-window-adjacent-space-with-fallback "next" "prev"))

(fn move-to-space [target-space]
  ;; (log.setLogLevel 5)
  (let [cmd (.. "yabai -m window --space " target-space " --focus")
        _ (log.d cmd )
        result (run cmd)]
    (if (not (result:find "could not locate space"))
        result
        (do
          ;; Space doesn't exist, create one more and try again
          (run "yabai -m space --create")
          (run cmd)))))

(fn remove-space []
  (run "yabai -m space --destroy 2>&1"))

(fn activate-app [app-name]
  (let [id (-> (.. "yabai -m query --windows | jq '.[] | "
                   "select(.app==\"" app-name "\") | .id' | tail -n1")
               run
               (string.gsub "[\n\r]+" ""))
        blank? #(or (= $1 nil) (= $1 ""))]
    (if (blank? id)
        (hs.application.launchOrFocus app-name)
        (run (.. "yabai -m window --focus " id)))
    (flash-focused-window)))

(fn edit-with-emacs []
  (let [emacs-space
        (run (.. "yabai -m query --windows "
                 "| jq -r \".[] | select(.app==\\\"Emacs\\\") | .space\""))]
    (emacs.edit-with-emacs)
    (run (.. "yabai -m space --focus " emacs-space))))

(fn other-screen-idx []
  (let [current (-> "yabai -m query --displays --display | jq '.index'"
                    (run) (tonumber 10))
        total (-> "yabai -m query --displays | jq 'length'"
                  (run) (tonumber 10))]
    (+ (% current total) 1)))

(fn move-to-other-screen []
  (let [other (other-screen-idx)]
    (run (.. "yabai -m window --display " other
             " && yabai -m display --focus " other))))

(fn space-visible-windows []
  (let [spc-wins (run "yabai -m query --spaces --space | jq '.windows'")
        spc-wins (hs.json.decode spc-wins)
        visible (run "yabai -m query --windows | jq '[.[] | select(.\"is-visible\" == true)]'")
        visible (hs.json.decode visible)]
    (if (seq? spc-wins)
        (->> visible
             (filter #(-> $1 (. :id) (contains? spc-wins))))
        [])))

(fn next-window []
  (let [no-windows? #(-> (space-visible-windows) (count) (< 1))]
    (match [(last-window?)
            (last-space?)
            (last-display?)]

      (where [true false true])
      (do
        (hs.alert "last window, left display - next screen")
        (run (.. "yabai -m display --focus " (other-screen-idx))))

      (where [true true false])
      (do
        (hs.alert "last window, last space, right display - next screen, last space")
        (run (.. "yabai -m display --focus " (other-screen-idx)))
        (run "yabai -m space --focus last")
        (when (no-windows?)
          (run "yabai -m space --focus prev"))
        )

      (where [true false false])
      (do
        (hs.alert "last window, on the right display")
        (run "yabai -m space --focus next"))

      (where [true true true])
      (do
        (hs.alert "last window, last space, on the left display")
        (run "yabai -m space --focus prev"))

      (where [false _ _])
      (run "yabai -m window --focus next")

      ;; (where [_ true true])
      ;; (do
      ;;   (hs.alert "last window, last space")
      ;;   (run "yabai -m space --focus first"))
      ;; (where [_ true _])
      ;; (do
      ;;   (hs.alert "last window, not last space")
      ;;   )
      ;; (where [_ _ _])
      ;; (do
      ;;   (hs.alert "there are windows, this is not last, and not a last space either")
      ;;   (run "yabai -m window --focus next"))
      )))

(fn prev-window []
  (run "yabai -m window --focus prev"))

;; State for window cycling
(var window-ids [])
(var current-index 1)
(var window-count 0)

(fn get-all-window-ids []
  "Get array of all window IDs from yabai"
  (let [result (run "yabai -m query --windows")
        windows (hs.json.decode result)
        ids []]
    (each [_ win (ipairs windows)]
      (table.insert ids (. win :id)))
    ids))

(fn find-index [id ids]
  "Find index of id in ids array, returns nil if not found"
  (var found nil)
  (each [i wid (ipairs ids)]
    (when (= wid id)
      (set found i)))
  found)

(fn should-reset-cycle? [cur-id all-ids]
  "Check if we should reset the cycle"
  (or
   ;; Window count changed
   (not= (length all-ids) window-count)
   ;; Current window not in our stored list (switched elsewhere)
   (not (find-index cur-id window-ids))))

(fn init-cycle []
  "Initialize/reset the cycle with fresh window list"
  (let [cur-result (run "yabai -m query --windows --window")
        cur-win (hs.json.decode cur-result)
        cur-id (. cur-win :id)
        all-ids (get-all-window-ids)]
    (set window-ids all-ids)
    (set window-count (length all-ids))
    (set current-index (or (find-index cur-id all-ids) 1))))

(fn swap-next-window []
  (let [cur-result (run "yabai -m query --windows --window")
        cur-win (hs.json.decode cur-result)
        cur-id (. cur-win :id)
        all-ids (get-all-window-ids)]
    
    ;; Reset if needed
    (when (should-reset-cycle? cur-id all-ids)
      (init-cycle))
    
    ;; Cycle to next
    (when (< 1 (length window-ids))
      (let [next-idx (if (>= current-index (length window-ids)) 1 (+ current-index 1))
            target-id (. window-ids next-idx)]
        (run (.. "yabai -m window --swap " target-id))
        (run (.. "yabai -m window --focus " target-id))
        (set current-index next-idx)
        (flash-focused-window)))))

(fn swap-prev-window []
  (let [cur-result (run "yabai -m query --windows --window")
        cur-win (hs.json.decode cur-result)
        cur-id (. cur-win :id)
        all-ids (get-all-window-ids)]
    
    ;; Reset if needed
    (when (should-reset-cycle? cur-id all-ids)
      (init-cycle))
    
    ;; Cycle to prev
    (when (< 1 (length window-ids))
      (let [prev-idx (if (<= current-index 1) (length window-ids) (- current-index 1))
            target-id (. window-ids prev-idx)]
        (run (.. "yabai -m window --swap " target-id))
        (run (.. "yabai -m window --focus " target-id))
        (set current-index prev-idx)
        (flash-focused-window)))))

;; There's no built-in yabai feature that allows you lock given window
;; dimensions. Yet we can mark windows as 'locked' and then resize
;; them to whatever size they want to be through the dedicated signal
;;
;; Important, in order for this to work, yabairc should contain the following line:
;;
;; yabai -m signal --add event=window_resized action="hs -c 'local yb=require(\"yabai\") yb[\"redraw-locked-window-sizes\"]()'"
(fn toggle-lock-window-sizing []
  (let [cw (hs.window.focusedWindow)
        cw-id (cw:id)
        locked? (-> locked-windows (. cw-id))
        space-win-ids (-> (current-space) (. :windows))]
    (if locked?
        (do
          (tset locked-windows cw-id nil)
          (hs.alert (.. "🔓 Unlocking " (. cw :app) " window")))
        (do
          ;; only one window per space can be locked
          (each [_ k (ipairs space-win-ids)]
            (tset locked-windows k nil))
          (tset locked-windows cw-id (. cw :frame))
          (hs.alert (.. "🔐 Lock " (. cw :app) " window"))))))

;; (fn generate-resize-params [window-id current-frame previous-frame]
;;   "Generate yabai resize parameters to restore window to previous size.
;;    Takes window ID, current frame table {x y w h}, and previous frame table {x y w h}."
;;   (let [width-delta (- previous-frame.w current-frame.w)
;;         height-delta (- previous-frame.h current-frame.h)
;;         width-direction (if (> width-delta 0) "right" "left")
;;         height-direction (if (> height-delta 0) "bottom" "top")
;;         width-amount (math.abs width-delta)
;;         height-amount (math.abs height-delta)
;;         commands []]

;;     ;; Add width resize command if needed
;;     (when (not= width-delta 0)
;;       (table.insert commands
;;         (string.format "yabai -m window %s --resize %s:%d:0"
;;                       window-id
;;                       width-direction
;;                       width-amount)))

;;     ;; Add height resize command if needed
;;     (when (not= height-delta 0)
;;       (table.insert commands
;;         (string.format "yabai -m window %s --resize %s:0:%d"
;;                       window-id
;;                       height-direction
;;                       height-amount)))

;;     ;; Return commands joined with " && " if multiple commands
;;     (table.concat commands " && ")))

;; (local watcher hs.window.filter.default)
;; (var last-redraw-locked-time 0)

;; (watcher:subscribe
;;  hs.window.filter.windowMoved
;;  (fn [win app event]
;;    (log.d "🦋")
;;    (log.d (hs.inspect (win:id)))
;;    (log.d (hs.inspect locked-windows))
;;    (let [now (hs.timer.localTime)]
;;      (when (< 1 (- now last-redraw-locked-time))
;;        (set last-redraw-locked-time now)
;;        (let [w (collect [k v (pairs locked-windows)]
;;                  (when (= k (win:id)) (values k v)))
;;              id (next w) p (. w id)]

;;          (log.d (hs.inspect w))
;;          (when id
;;            (let [c (run (.. "yabai -m query --windows --window " id))
;;                  c (-> c hs.json.decode (. :frame))
;;                  width-delta (- p.w c.w)
;;                  height-delta (- p.h c.h)
;;                  width-dir (if (< 0 width-delta) :right :left)
;;                  height-dir (if (< 0 height-delta) :bottom :top)
;;                  width-amount (math.abs width-delta)
;;                  height-amount (math.abs height-delta)]
;;              (when (not= width-delta 0)
;;                (run (string.format
;;                      "yabai -m window %s --resize %s:%d:0"
;;                      id width-dir width-amount)))
;;              (when (not= height-delta 0)
;;                (run (string.format
;;                      "yabai -m window %s --resize %s:%d:0"
;;                      id height-dir height-amount))))))))))

{: run

 :jump-window-left #(jump-window :west)
 :jump-window-right #(jump-window :east)
 :jump-window-above #(jump-window :north)
 :jump-window-below #(jump-window :south)

 :swap-window-left #(swap-window :west)
 :swap-window-right #(swap-window :east)
 :swap-window-above #(swap-window :north)
 :swap-window-below #(swap-window :south)

 : resize-left
 : resize-right
 : resize-up
 : resize-down

 : jump-window-recent
 : toggle-maximize
 : minimize
 : toggle-float
 : toggle-sticky
 : balance

 : space-next
 : space-previous

 : jump-to-space
 : jump-space-recent

 : move-to-space
 : move-to-next-space
 : move-to-prev-space
 : remove-space

 : activate-app
 : edit-with-emacs

 : move-to-other-screen

 : next-window
 : prev-window
 : swap-next-window
 : swap-prev-window

 : toggle-lock-window-sizing

 ;; Buffer switching handler for yabai
 :buffer-switch-handler
 (fn [current-window-id target-window-info]
   "Swap current window with target window in yabai"
   (let [target-id (. target-window-info :window-id)]
     (run (.. "yabai -m window " target-id " --swap " current-window-id))
     (run (.. "yabai -m window --focus " target-id))))

 :restart-service #(run "yabai --restart-service")
 }
