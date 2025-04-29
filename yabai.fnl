(local { : count : last : filter : first} (require :lib.functional))
(local emacs (require :emacs))

(local log (hs.logger.new :yabai :debug))

(fn run [cmd]
  (hs.execute
   (.. "export PATH=$PATH:/opt/homebrew/bin && " cmd)))

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
    (hs.json.decode w)))

(fn window-first-last [first-last]
  (let [cur (. (current-window) :id)
        fl (run (.. "yabai -m query --windows --window " first-last))
        fl (. (hs.json.decode fl) :id)]
    (= cur fl)))

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

(fn toggle-float []
  (run (.. "yabai -m window --toggle float")))

(fn toggle-sticky []
  (run "yabai -m window --toggle sticky"))

(fn balance []
  (run "yabai -m space --balance"))

(fn space-next []
  (let [spcs* (run "yabai -m query --spaces --display")
        spcs (hs.json.decode spcs*)
        single-space? (-> spcs count (= 1))
        cur (->> spcs (filter #(-> $1 (. :has-focus))) first)
        last? (-> (last spcs) (. :index) (= (. cur :index)))]
    (when single-space?
      (run "yabai -m space --create"))
    (if last?
        (run "yabai -m space --focus 1")
        (run "yabai -m space --focus next"))))

(fn space-previous []
  (let [spcs* (run "yabai -m query --spaces --display")
        spcs (hs.json.decode spcs*)
        spaces? (->> spcs count (< 1))
        cur (->> spcs (filter #(-> $1 (. :has-focus))) first)
        first? (-> (first spcs) (. :index) (= (. cur :index)))]
    (if (and spaces? first?)
        (run (.. "yabai -m space --focus " (count spcs)))
        (run (.. "yabai -m space --focus prev")))))

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
                   "select(.app==\"" app-name "\") | .id' | head -n1")
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
  (let [disp (run "yabai -m query --displays --display | jq '.index'")
        disp (tonumber disp)
        other (case disp
                ;; I have only two monitors
                1 2
                2 1)]
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
