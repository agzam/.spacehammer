(local { : map
         : filter
         : first
         : last
         : sort
         } (require :lib.functional))

(fn reset-screen []
  "For some stupid reason things sometiems get really in ultra-wide.
see:
https://github.com/agzam/spacehammer/issues/171 and
https://github.com/Hammerspoon/hammerspoon/issues/3320"
  (: (hs.screen.mainScreen) :rotate 90)
  (hs.timer.doAfter 0.1 (fn [] (: (hs.screen.mainScreen) :rotate 0))))

(hs.hotkey.bind [:cmd :shift :option :ctrl] "0" reset-screen)

(fn reset-hs []
  ;; (io.popen "killall Hammerspoon && open -a Hammerspoon &")
  (hs.alert "Clearing console")
  (hs.console.clearConsole))

(hs.hotkey.bind [:cmd :shift :ctrl] "0" reset-hs)

(local log (hs.logger.new "screen.fnl" "debug"))

(fn opposite [dir]
  (case dir
    :right :left
    :left :right
    :west :east
    :east :west))

(fn is-far-side [win side]
  (let [frame (win:frame)
        screen (win:screen)
        screen-frame (screen:frame)]
    (case side
      :right
      (<= (+ screen-frame.x screen-frame.w)
          (+ frame.x frame.w))
      :left (<= frame.x screen-frame.x))))

(fn find-adjacent-window [win direction]
  (let [frame (win:frame)
        screen (win:screen)
        ord (hs.window.orderedWindows)
        cands (case direction
                :east (win:windowsToEast ord true)
                :west (win:windowsToWest ord true))]
    ;; (log.d (hs.inspect (map (fn [x] (x:level)) cands)))
    (->> cands
         (filter (fn [w] (= (w:screen) screen)))
         (filter (fn [w] (w:isStandard)))
         (filter (fn [w] (let [f (w:frame)]
                           (case direction
                             :west (<= (+ f.x f.w) frame.x)
                             :east (<= (+ frame.x frame.w) f.x)))))
         ;; (sort (fn [a b]
         ;;         (let [af (a:frame) bf (b:frame)]
         ;;           (< (+ bf.x bf.w) (+ af.x af.w)))))
         first)))

(fn is-snapped [win1 win2 side]
  (let [w1f (win1:frame) w2f (when win2 (win2:frame))]
    (when w2f
      (case side
        :right (= (+ w1f.x w1f.w 1) w2f.x)
        :left  (= (+ w2f.x w2f.w) (- w1f.x 1))))))

(fn snap-windows [win adj action side]
  (let [wf (win:frame)
        af (adj:frame)]
    (case side
      :right (win:setFrame {:x wf.x :y wf.y :h wf.h
                            :w (- af.x wf.x 1)})
      :left (win:setFrame {:x (+ af.x af.w 1)
                           :y wf.y :h wf.h
                           :w (+ wf.w (- wf.x af.w af.x))}))))

(fn resize-windows [win adj action side]
  (let [d 100
        wf (win:frame) af (adj:frame)
        scr-frm (: (win:screen) :frame)
        scr-frm (: (win:screen) :frame)
        min-width (* scr-frm.w 0.15)]
    (case [action side]
      [:widen :left] (let [w-good? (< min-width (- af.w d))
                           x (if w-good? (- wf.x d) wf.x)
                           w (if w-good? (+ wf.w d) wf.w)
                           aw (if w-good? (- af.w d) af.w)]
                       (win:setFrame {:x x :y wf.y :h wf.h :w w})
                       (adj:setFrame {:x af.x :y af.y :h af.h :w aw}))
      [:shrink :left] (let [w-good? (< min-width (- wf.w d))
                            x (if w-good? (+ wf.x d) wf.x)
                            w (if w-good? (- wf.w d) wf.w)
                            aw (if w-good? (+ af.w d) af.w)]
                        (win:setFrame {:x x :y wf.y :h wf.h :w w})
                        (adj:setFrame {:x af.x :y af.y :h af.h :w aw}))
      [:widen :right]  (let [w-good? (< min-width (- af.w d))
                             w (if w-good? (+ wf.w d) wf.w)
                             ax (if w-good? (+ af.x d) af.x)
                             aw (if w-good? (- af.w d) af.w)]
                         (win:setFrame {:x wf.x :y wf.y :h wf.h :w w})
                         (adj:setFrame {:x ax :y af.y :h af.h :w aw}))
      [:shrink :right] (let [w-good? (< min-width (- wf.w d))
                             w (if w-good? (- wf.w d) wf.w)
                             ax (if w-good? (- af.x d) af.x)
                             aw (if w-good? (+ af.w d) af.w)]
                         (win:setFrame {:x wf.x :y wf.y :h wf.h :w w})
                         (adj:setFrame {:x ax :y af.y :h af.h :w aw})))))

(fn resize-window [win action side]
  (let [d 100 wf (win:frame)
        scr-frm (: (win:screen) :frame)
        min-width (* scr-frm.w 0.15)]
    (case [action side]
      [:widen :left] (let [x (if (< scr-frm.x (- wf.x d)) (- wf.x d) scr-frm.x)]
                       (win:setFrame {:x x :y wf.y :h wf.h :w (+ wf.w d)}))
      [:shrink :left] (let [x (if (< min-width (- wf.w d)) (+ wf.x d) wf.x)
                            w (if (not= x wf.x) (- wf.w d) wf.w)]
                        (win:setFrame {:x x :y wf.y :h wf.h :w w}))
      [:widen :right] (win:setFrame {:x wf.x :y wf.y :h wf.h :w (+ wf.w d)})
      [:shrink :right] (let [w (if (< min-width (- wf.w d)) (- wf.w d) wf.w)]
                         (win:setFrame {:x wf.x :y wf.y :h wf.h :w w})))))

(fn shrink-window [win side direction]
  (let [adjacent (find-adjacent-window win direction)
        snapped (is-snapped win adjacent side)]
    (if adjacent
        (if (not snapped)
            (snap-windows win adjacent :shrink side)
            (resize-windows win adjacent :shrink side))
        (resize-window win :shrink side))))

(fn widen-window [win side direction]
  (let [adjacent (find-adjacent-window win direction)
        snapped (is-snapped win adjacent side)]
    (if adjacent
        (if (not snapped)
            (snap-windows win adjacent :widen side)
            (resize-windows win adjacent :widen side))
        (resize-window win :widen side))))

(fn adjust-window-size [direction]
  (let [primary-side direction
        secondary-side (opposite direction)
        primary-direction (case direction :right :east :left :west)
        secondary-direction (opposite primary-direction)
        win (hs.window.focusedWindow)]
    (if (is-far-side win primary-side)
        (shrink-window win secondary-side secondary-direction)
        (widen-window win primary-side primary-direction))))

{
 : adjust-window-size
}
