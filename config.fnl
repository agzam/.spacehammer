(require-macros :lib.macros)
(require-macros :lib.advice.macros)
(local windows (require :windows))
(local emacs (require :emacs))
(local slack (require :slack))
(local vim (require :vim))
(local multimedia (require :multimedia))
(local zoom (require :zoom))
(local screen (require :screen))
(local coroutine (require :coroutine))
(local yabai (require :yabai))

(local {:concat concat
        :logf logf} (require :lib.functional))

(require :my-emacs)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; WARNING
;; Make sure you are customizing ~/.spacehammer/config.fnl and not
;; ~/.hammerspoon/config.fnl
;; Otherwise you will lose your customizations on upstream changes.
;; A copy of this file should already exist in your ~/.spacehammer directory.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Table of Contents
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; [x] w - windows
;; [x] |-- w - Last window
;; [x] |-- cmd + hjkl - jumping
;; [x] |-- hjkl - halves
;; [x] |-- alt + hjkl - increments
;; [x] |-- shift + hjkl - resize
;; [x] |-- n, p - next, previous screen
;; [x] |-- shift + n, p - up, down screen
;; [x] |-- g - grid
;; [x] |-- m - maximize
;; [x] |-- c - center
;; [x] |-- u - undo
;;
;; [x] a - apps
;; [x] |-- e - emacs
;; [x] |-- g - chrome
;; [x] |-- f - firefox
;; [x] |-- i - iTerm
;; [x] |-- s - Slack
;; [x] |-- b - Brave
;;
;; [x] j - jump
;;
;; [x] m - media
;; [x] |-- h - previous track
;; [x] |-- l - next track
;; [x] |-- k - volume up
;; [x] |-- j - volume down
;; [x] |-- s - play\pause
;; [x] |-- a - launch player
;;
;; [x] x - emacs
;; [x] |-- c - capture
;; [x] |-- z - note
;; [x] |-- f - fullscreen
;; [x] |-- v - split
;;
;; [x] alt-n - next-app
;; [x] alt-p - prev-app


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Actions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn activator
  [app-name]
  "
  A higher order function to activate a target app. It's useful for quickly
  binding a modal menu action or hotkey action to launch or focus on an app.
  Takes a string application name
  Returns a function to activate that app.

  Example:
  (local launch-emacs (activator \"Emacs\"))
  (launch-emacs)
  "
  (fn activate []
    (yabai.activate-app app-name)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; If you would like to customize this we recommend copying this file to
;; ~/.spacehammer/config.fnl. That will be used in place of the default
;; and will not be overwritten by upstream changes when spacehammer is updated.
(local music-app "YouTube Music")
;; (local music-app "Spotify")

(local return
       {:key :space
        :title "Back"
        :action :previous})


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local window-jumps
       [{:mods []
         :key "hjkl"
         :title "Jump"}
        {:mods []
         :key :h
         :action #(yabai.jump-window-left)}
        {:mods []
         :key :k
         :action #(yabai.jump-window-above)}
        {:mods []
         :key :j
         :action #(yabai.jump-window-below)}
        {:mods []
         :key :l
         :action #(yabai.jump-window-right)}])

(local window-swaps
       [{:key "hjkl"
         :title "swaps"}
        {:mods [:Shift]
         :key :H
         :action #(yabai.swap-window-left)}
        {:mods [:Shift]
         :key :l
         :action #(yabai.swap-window-right)}
        {:mods [:Shift]
         :key :k
         :action #(yabai.swap-window-above)}
        {:mods [:Shift]
         :key :j
         :action #(yabai.swap-window-below)}])

(local window-increments
       [{:mods [:alt]
         :key "hjkl"
         :title "Increments"}
        {:mods [:alt]
         :key :h
         :action "windows:resize-inc-left"
         :repeatable true}
        {:mods [:alt]
         :key :j
         :action "windows:resize-inc-bottom"
         :repeatable true}
        {:mods [:alt]
         :key :k
         :action "windows:resize-inc-top"
         :repeatable true}
        {:mods [:alt]
         :key :l
         :action "windows:resize-inc-right"
         :repeatable true}])

(local window-resize
       [{:mods []
         :key "[]"
         :title "Resize"}
        {:mods []
         :key "["
         :action #(yabai.resize-left)
         :repeatable true}
        {:mods []
         :key "]"
         :action #(yabai.resize-right)
         :repeatable true}
        {:mods [:shift]
         :key "["
         :action #(yabai.resize-up)
         :repeatable true}
        {:mods [:shift]
         :key "]"
         :action #(yabai.resize-down)
         :repeatable true}])

(local window-bindings
       (concat
        [return
         {:key :w
          :title "Last Window"
          :action #(yabai.jump-window-recent)}]
        window-jumps
        window-swaps
        ;; window-increments
        window-resize
        [{:key "o"
          :action #(yabai.move-to-other-screen)}
         {:key :m
          :title "Maximize"
          :action #(yabai.toggle-maximize)}
         {:key "-"
          :title "Minimize"
          :action #(yabai.minimize)}
         {:key :f
          :title "float"
          :action #(yabai.toggle-float)}
         {:key :s
          :title "sticky"
          :action #(yabai.toggle-sticky)}
         {:key "="
          :title "balance"
          :action #(yabai.balance)}]))

(local spaces-bindings
       [{:mods [:Shift]
         :key "."
         :title "move to next"
         :action #(yabai.move-to-next-space)}
        {:mods [:Shift]
         :key ","
         :title "move to prev"
         :action #(yabai.move-to-prev-space)}
        {:key "k"
         :title "prev space"
         :action #(yabai.space-previous)}
        {:key "j"
         :title "next space"
         :action #(yabai.space-next)}
        {:key "Tab"
         :action #(yabai.jump-space-recent)}])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Apps Menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(hs.hotkey.bind [:cmd :shift :option :ctrl] "1" (activator "Slack"))
(hs.hotkey.bind [:cmd :shift :option :ctrl] "2" (activator "brave browser"))
(hs.hotkey.bind [:cmd :shift :option :ctrl] "3" (activator "Emacs"))

(fn shell-escape [str]
  (: (str:gsub "[\\%$\"`''()]" "\\%0") :gsub "!" "\\!"))

(hs.hotkey.bind
 [:cmd :shift :option :ctrl] "s"
 (fn []
   "TTS Speak selected text."
   (io.popen "killall sox")
   (hs.eventtap.keyStroke [:cmd] :c)
   (let [cmd (string.format
              (.. "echo \"%s\" | /opt/homebrew/bin/docker run --rm -i piper-tts "
                  "--model en_US-hfc_female-medium.onnx "
                  "--length_scale 0.7 --sentence_silence 0.1 --output_raw "
                  "| /opt/homebrew/bin/sox -t raw -r 22050 -b 16 -e signed-integer -c 1 -v 0.7 - -d &")
              (hs.pasteboard.readString))
         _ (hs.alert "Speaking...")
         ;; logger (hs.logger.new :foo :debug)
         ;; _ (logger.d cmd)
         co (coroutine.create #(io.popen cmd))]
     (coroutine.resume co))))

(hs.hotkey.bind
 [:cmd :shift :option :ctrl] "k"
 (fn [] "Stop speaking." (io.popen "killall sox")))

(local app-bindings
       [return
        {:key :e
         :title "Emacs"
         :action (activator "Emacs")}
        {:key :b
         :title "Browser"
         :action (activator "Brave Browser")}
        ;; {:key :f
        ;;  :title "Firefox"
        ;;  :action (activator "Firefox")}
        {:key :i
         :title "Terminal"
         :action (activator "kitty")}
        {:key :s
         :title "Slack"
         :action (activator "Slack")}
        {:key :t
         :title "Telegram"
         :action (activator "Telegram")}
        {:key :m
         :title music-app
         :action (activator music-app)}
        {:key    :j
         :title  "Jump"
         :action #(windows.jump)}
        ;; {:key :d
        ;;  :title "Discord"
        ;;  :action (activator "Discord")}
        {:key :z
         :title "Zoom"
         :action (activator "zoom.us")}])

(require :yt-music)

(local media-bindings
       [return
        {:key :s
         :title "Play or Pause"
         :action "multimedia:play-or-pause"}
        {:key :h
         :title "Prev Track"
         :action "multimedia:prev-track"}
        {:key :l
         :title "Next Track"
         :action "multimedia:next-track"}
        {:key :j
         :title "Volume Down"
         :action "multimedia:volume-down"
         :repeatable true}
        {:key :k
         :title "Volume Up"
         :action "multimedia:volume-up"
         :repeatable true}
        {:key :a
         :title (.. "Launch " music-app)
         :action (activator music-app)}
        {:key :1
         :mods [:shift]
         :title "Like this song"
         :action "yt-music:like-this-song"}
        {:key "3"
         :mods [:shift]
         :title "Dislike this song"
         :action "yt-music:dislike-this-song"}])

(local emacs-bindings
       [return
        {:key :c
         :title "Capture"
         :action (fn [] (emacs.capture))}
        {:key :z
         :title "Note"
         :action (fn [] (emacs.note))}
        {:key :v
         :title "Split"
         :action "emacs:vertical-split-with-emacs"}
        {:key :f
         :title "Full Screen"
         :action "emacs:full-screen"}])


(local zoom (require :zoom))
(local zoom-bindings
       [return
        {:key :g
         :title "group windows"
         :action zoom.group-zoom-windows}])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Menu & Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local menu-items
       [{:key    :space
         :title  "Alfred"
         :action (activator "Alfred 5")}
        {:key   :w
         :title "Window"
         ;; :enter "windows:enter-window-menu"
         ;; :exit "windows:exit-window-menu"
         :items window-bindings}
        {:key   :l
         :title "Spaces"
         :enter "windows:enter-spaces-menu"
         :exit "windows:exit-spaces-menu"
         :items spaces-bindings}
        {:key   :a
         :title "Apps"
         :items app-bindings}

        {:key   :m
         :title "Media"
         :items media-bindings}
        {:key   :x
         :title "Emacs"
         :items emacs-bindings}
        {:key   :z
         :title "Zoom"
         :items zoom-bindings}
        {:key "]"
         :action #(yabai.space-next)}
        {:key "["
         :action #(yabai.space-previous)}
        {:key "1" :action #(yabai.jump-space 1)}
        {:key "2" :action #(yabai.jump-space 2)}
        {:key "3" :action #(yabai.jump-space 3)}
        {:key "4" :action #(yabai.jump-space 4)}
        {:key "5" :action #(yabai.jump-space 5)}])

(require :browser)
(require :language)

(local common-keys
       [{:mods [:cmd]
         :key :space
         :action "lib.modal:activate-modal"}
        {:mods [:cmd :ctrl]
         :key "."
         :action "apps:next-app"}
        {:mods [:cmd :ctrl]
         :key ","
         :action "apps:prev-app"}
        {:mods [:cmd :ctrl]
         :key "`"
         :action hs.toggleConsole}
        {:mods [:cmd :ctrl]
         :key :o
         :action #(yabai.edit-with-emacs)}
        {:mods [:cmd :shift]
         :key :c
         :action "browser:inspect-elements"}
        {:mods [:cmd]
         :key :t
         :action "browser:open-new-tab"}
        {:mods [:cmd :ctrl]
         :key "\\"
         :action "language:switch-layout"}
        {:mods [:cmd :alt]
         :key "h"
         :action
         (fn []
           (hs.eventtap.keyStroke [] "left"))}
        {:mods [:cmd :alt]
         :key "l"
         :action
         (fn []
           (hs.eventtap.keyStroke [] "right"))}
        {:mods [:cmd :alt]
         :key "k"
         :action
         (fn []
           (hs.eventtap.keyStroke [] "up"))}
        {:mods [:cmd :alt]
         :key "j"
         :action
         (fn []
           (hs.eventtap.keyStroke [] "down"))}])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; App Specific Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local browser-keys
       [{:mods [:cmd :shift]
         :key :l
         :action "chrome:open-location"}
        {:mods [:cmd]
         :key :k
         :action "chrome:next-tab"
         :repeat true}
        {:mods [:cmd]
         :key :j
         :action "chrome:prev-tab"
         :repeat true}])

(local browser-items
       (concat
        menu-items
        [{:key "'"
          :title "Edit with Emacs"
          :action "emacs:edit-with-emacs"}]))

(local brave-config
       {:key "Brave Browser"
        :keys browser-keys
        :items browser-items})

(local chrome-config
       {:key "Google Chrome"
        :keys browser-keys
        :items browser-items})

(local firefox-config
       {:key "Firefox"
        :keys browser-keys
        :items browser-items})

(local emacs-config
       {:key "Emacs"
        :activate (fn [] (vim.disable))
        :deactivate (fn [] (vim.enable))
        :launch "emacs:maximize"
        :items []
        :keys []})

(local grammarly-config
       {:key "Grammarly"
        :items (concat
                menu-items
                [{:mods [:ctrl]
                  :key :c
                  :title "Return to Emacs"
                  :action "grammarly:back-to-emacs"}])
        :keys ""})

(local hammerspoon-config
       {:key "Hammerspoon"
        :items (concat
                menu-items
                [{:key :r
                  :title "Reload Console"
                  :action hs.reload}
                 {:key :c
                  :title "Clear Console"
                  :action hs.console.clearConsole}])
        :keys []})

(local my-slack (require :my-slack))

(local slack-config
       {:key "Slack"
        :keys [
               ;; {:mods [:cmd]
               ;;  :key  :g
               ;;  :action "slack:scroll-to-bottom"}
               {:mods [:ctrl]
                :key :r
                :action "slack:add-reaction"}
               {:mods [:ctrl]
                :key :h
                :action "slack:prev-element"}
               {:mods [:ctrl]
                :key :l
                :action "slack:next-element"}
               {:mods [:ctrl]
                :key :t
                :action "slack:thread"}
               {:mods [:ctrl]
                :key :p
                :action "slack:prev-day"}
               {:mods [:ctrl]
                :key :n
                :action "slack:next-day"}
               {:mods [:ctrl]
                :key :y
                :action "slack:scroll-up"
                :repeat true}
               {:mods [:ctrl]
                :key :e
                :action "slack:scroll-down"
                :repeat true}
               {:mods [:ctrl]
                :key :i
                :action "slack:next-history"
                :repeat true}
               {:mods [:ctrl]
                :key :o
                :action "slack:prev-history"
                :repeat true}
               {:mods [:ctrl]
                :key :j
                :action "slack:down"
                :repeat true}
               {:mods [:ctrl]
                :key :k
                :action "slack:up"
                :repeat true}
               {:mods [:ctrl]
                :key :n
                :action "slack:down"
                :repeat true}
               {:mods [:ctrl]
                :key :p
                :action "slack:up"
                :repeat true}]})

(local {:telegram-config telegram-config} (require :telegram))
(local {:config webex-config} (require :webex))
(local {:kitty-config kitty-config} (require :kitty))

(local apps
       [brave-config
        chrome-config
        firefox-config
        emacs-config
        grammarly-config
        hammerspoon-config
        slack-config
        telegram-config
        webex-config
        kitty-config])

(local config
       {:title "Main Menu"
        :items menu-items
        :keys  common-keys
        ;; :enter (fn [] (windows.hide-display-numbers))
        ;; :exit  (fn [] (windows.hide-display-numbers))
        :apps  apps
        :hyper {:key :F18}
        :modules {:windows {:center-ratio "30:60"}}
        :grid {:size "6x3"}})


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set hs.window.animationDuration 0)
(tset hs.alert.defaultStyle :fadeInDuration 0.1)
(tset hs.alert.defaultStyle :fadeOutDuration 0.1)
(set hs.grid.ui.showExtraKeys true)
(hs.logger.historySize 0)
;; (local repl (require :repl))
;; (repl.run (repl.start {:port "9898"}))

config
