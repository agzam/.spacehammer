;; Buffer Switching for Window Managers
;;
;; This module provides an Emacs-like buffer switching experience for tiling window managers.
;; It displays a picker (hs.chooser) showing all currently running application windows,
;; allowing you to select a target window that will swap positions in-place with the 
;; currently focused window.
;;
;; The module is designed to be window manager agnostic - it queries windows via yabai
;; but accepts a callback function to handle the actual switching logic. This allows
;; easy adaptation to different WMs (yabai, Aerospace, etc.) by simply changing the
;; callback implementation.
;;
;; Features:
;; - Displays all normal windows (filters out tool windows like Emacs posframes)
;; - Shows app icons for visual identification
;; - Compact picker (20% screen width) suitable for ultra-wide monitors
;; - Searchable list with app name and window title
;; - Preserves tiling layout by swapping window positions
;; - Centers picker in the currently focused window (WM-agnostic positioning)
;;   for better visual context in tiling window managers
;;
;; Usage:
;;   (local buffers (require :buffers))
;;   (local yabai (require :yabai))
;;   (buffers.show-buffer-picker yabai.buffer-switch-handler)

(local log (hs.logger.new "buffers"))

(fn run [cmd]
  "Execute yabai command and return trimmed output"
  (->
   (hs.execute (.. "export PATH=$PATH:/opt/homebrew/bin && " cmd))
   (string.gsub "[\n\r]+$" "")
   (string.gsub "^%*(.-)%s*$" "%1")))

(fn get-current-window-id []
  "Get the currently focused window ID"
  (let [result (run "yabai -m query --windows --window")]
    (when (and result (not= result ""))
      (let [window (hs.json.decode result)]
        (when window
          (. window :id))))))

(fn get-all-windows []
  "Get all yabai-managed windows"
  (let [result (run "yabai -m query --windows")]
    (when (and result (not= result ""))
      (hs.json.decode result))))

(fn normal-window? [window]
  "Check if window is a normal user-facing window (not a tool/internal window)"
  (let [subrole (. window :subrole)
        role (. window :role)
        title (. window :title)]
    ;; Filter out windows with subroles that indicate tool/internal windows
    ;; AXStandardWindow is the normal window subrole
    ;; Keep windows with no subrole or standard window subrole
    (and (or (= subrole "AXStandardWindow")
             (= subrole nil)
             (= subrole ""))
         ;; Also filter out windows with role indicating dialogs/utility
         (not= role "AXUnknown"))))

(fn build-choices [windows current-window-id]
  "Build chooser choices from window list, excluding current window and tool windows"
  (let [choices []]
    (each [_ window (ipairs windows)]
      (let [window-id (. window :id)
            app (. window :app)
            title (. window :title)
            is-visible (. window "is-visible")
            ;; Get app icon by finding the running application and getting its bundle ID
            app-bundle-id (-> app hs.application.find (: :bundleID))
            app-icon (when app-bundle-id
                       (hs.image.imageFromAppBundle app-bundle-id))
            ;; Format: "AppName: WindowTitle"
            display-text (.. app ": " title)]
        ;; Only include normal windows that aren't the current one
        (when (and (not= window-id current-window-id)
                   (normal-window? window))
          (table.insert choices
                       {:text display-text
                        :subText (.. "ID: " window-id 
                                    (if is-visible " [visible]" " [hidden]"))
                        :image app-icon
                        :window-id window-id
                        :app app
                        :title title}))))
    choices))

(fn calculate-chooser-position []
  "Calculate the top-left position to center chooser in the focused window.
   Returns an hs.geometry point or nil to use default screen-centered position."
  (let [focused-win (hs.window.focusedWindow)]
    (when focused-win
      (let [win-frame (focused-win:frame)
            screen (focused-win:screen)
            screen-frame (screen:frame)
            
            ;; Calculate chooser dimensions
            ;; Width is 20% of screen width (as configured in chooser)
            chooser-width (* screen-frame.w 0.20)
            ;; Height: approximate 55px per row + some padding for search box (~50px)
            ;; 10 rows = 550px + 50px = ~600px total
            chooser-height 600
            
            ;; Calculate center position within the focused window
            center-x (+ win-frame.x (/ win-frame.w 2))
            center-y (+ win-frame.y (/ win-frame.h 2))
            
            ;; Calculate top-left corner to center the chooser
            top-left-x (- center-x (/ chooser-width 2))
            top-left-y (- center-y (/ chooser-height 2))
            
            ;; Ensure chooser stays within screen bounds
            bounded-x (math.max screen-frame.x
                               (math.min top-left-x
                                        (- (+ screen-frame.x screen-frame.w)
                                           chooser-width)))
            bounded-y (math.max screen-frame.y
                               (math.min top-left-y
                                        (- (+ screen-frame.y screen-frame.h)
                                           chooser-height)))]
        
        ;; Return hs.geometry point for top-left corner
        (hs.geometry.point bounded-x bounded-y)))))

(fn show-buffer-picker [on-select]
  "Show picker with all available windows. 
   on-select: optional callback (current-window-id target-window-info) -> nil
   where target-window-info is {:window-id :app :title ...}"
  (let [current-window-id (get-current-window-id)
        all-windows (get-all-windows)]
    
    (if (not all-windows)
        (hs.alert "No windows found" 1)
        (let [choices (build-choices all-windows current-window-id)]
          
          (if (= (length choices) 0)
              (hs.alert "No other windows available" 1)
              (let [chooser (hs.chooser.new
                             (fn [selection]
                               (when selection
                                 (if on-select
                                     ;; Call custom handler
                                     (on-select current-window-id 
                                               {:window-id (. selection :window-id)
                                                :app (. selection :app)
                                                :title (. selection :title)})
                                     ;; Default: just log
                                     (do
                                       (log.i (.. "Selected: " (. selection :app) 
                                                 " (ID: " (. selection :window-id) ")"))
                                       (hs.alert (.. "Selected: " (. selection :app)) 1))))))
                    ;; Calculate position centered in focused window (WM-agnostic)
                    ;; Falls back to screen center if no window is focused
                    position (calculate-chooser-position)]
                
                ;; Configure chooser appearance
                (chooser:width 20)  ;; 20% of screen width - compact for ultra-wide
                (chooser:rows 10)   ;; Show 10 rows at a time
                (chooser:searchSubText true)
                (chooser:choices choices)
                (chooser:placeholderText "Select window...")
                
                ;; Show the chooser at calculated position
                ;; If position is nil, chooser will use default screen-centered behavior
                (chooser:show position)))))))

;; Export public API
{: show-buffer-picker}
