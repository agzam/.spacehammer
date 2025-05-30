(local { : count : last : filter : first} (require :lib.functional))
(local emacs (require :emacs))

(local log (hs.logger.new :yabai :debug))

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

(local resize-coeff 120)

(fn jump-window-recent []
  (run "yabai -m window --focus recent"))

(fn resize-left []
  (let [n resize-coeff
        cw  (current-window)
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
             (string.format params n n)))))

(fn resize-right []
  (let [n resize-coeff
        cw  (current-window)
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
             (string.format params n n)))))

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

(fn space-next []
  ;; Unlike yabai method, this doesn't require scripting addition enabled.
  (let [spaces (hs.spaces.spacesForScreen)
        current-space (hs.spaces.focusedSpace)
        current-idx (table.index-of spaces current-space)
        next-idx (if (= current-idx (length spaces)) 1 (+ current-idx 1))
        next-space (. spaces next-idx)]
    (hs.spaces.gotoSpace next-space)))

(fn space-previous []
  ;; Unlike yabai method, this doesn't require scripting addition enabled.
  (let [spaces (hs.spaces.spacesForScreen)
        current-space (hs.spaces.focusedSpace)
        current-idx (table.index-of spaces current-space)
        prev-idx (if (= current-idx 1) (length spaces) (- current-idx 1))
        prev-space (. spaces prev-idx)]
    (hs.spaces.gotoSpace prev-space)))

(fn jump-space [idx]
  (run (.. "yabai -m space --focus " idx)))

(fn jump-space-recent []
  (run "yabai -m space --focus recent"))

(fn move-to-next-space []
  (let [spcs* (run "yabai -m query --spaces --display")
        spcs (hs.json.decode spcs*)
        single-space? (-> spcs count (= 1))]
    (when single-space?
      (run "yabai -m space --create"))
    (run "yabai -m window --space next")))

(fn move-to-prev-space []
  (run "yabai -m window --space prev --focus"))

(fn activate-app [app-name]
  (let [id (-> (.. "yabai -m query --windows | jq '.[] | "
                   "select(.app==\"" app-name "\") | .id' | tail -n1")
               run
               (string.gsub "[\n\r]+" ""))
        blank? #(or (= $1 nil) (= $1 ""))]
    (if (blank? id)
        (hs.application.launchOrFocus app-name)
        (run (.. "yabai -m window --focus " id)))))

(fn edit-with-emacs []
  (let [emacs-space
        (run (.. "yabai -m query --windows "
                 "| jq -r \".[] | select(.app==\\\"Emacs\\\") | .space\""))]
    (emacs.edit-with-emacs)
    (run (.. "yabai -m space --focus " emacs-space))))

(fn move-to-other-screen []
  (let [other (other-screen-idx)]
    (run (.. "yabai -m window --display " other
             " && yabai -m display --focus " other))))



{
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

 : jump-space
 : jump-space-recent

 : move-to-next-space
 : move-to-prev-space

 : activate-app
 : edit-with-emacs

 : move-to-other-screen
 }
