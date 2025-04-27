(local yabai (-> "which yabai"
              (hs.execute true)
              (string.gsub "[\n\r]+" " ")))
(local {: eq? } (require :lib.functional))

(local log (hs.logger.new :yabai :debug))

(fn jump-window [dir]
  (hs.execute
   (.. yabai "-m window --focus " dir " || "
       yabai "-m display --focus " dir)))

(fn swap-window [dir]
  (hs.execute
   (.. yabai " -m window --swap " dir
       " || ("
       yabai " -m window --display " dir " && "
       yabai " -m display --focus " dir " && "
       yabai " -m window --warp " (if (= dir :east) :first :last)
       ")")))

(fn current-window []
  (let [w (-> yabai (.. "-m query --windows --window") hs.execute)]
    (hs.json.decode w)))

(fn window-first-last [first-last]
  (let [cur (. (current-window) :id)
        fl (-> yabai (.. "-m query --windows --window " first-last) hs.execute)
        fl (. (hs.json.decode fl) :id)]
    (= cur fl)))

(fn first-window? [] (window-first-last :first))

(fn last-window? [] (window-first-last :last))

(local resize-coeff 100)

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
    (hs.alert params)
    (hs.execute (.. yabai "-m window --resize "
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
    (hs.execute (.. yabai "-m window --resize "
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
    (hs.execute (.. yabai "-m window --resize "
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
    (hs.execute (.. yabai "-m window --resize "
                    (string.format params n n)))))

(fn toggle-maximize []
  (hs.execute (.. yabai "-m window --toggle zoom-fullscreen")))

(fn toggle-float []
  (hs.execute (.. yabai "-m window --toggle float")))


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

 : toggle-maximize
 : toggle-float
 }
