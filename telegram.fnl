(require-macros :lib.macros)

(fn scroll-up
  []
  (hs.eventtap.keyStroke [] "pageup"))

(fn scroll-down
  []
  (hs.eventtap.keyStroke [] "pagedown"))

(fn edit-previous
  []
  (hs.eventtap.keyStroke [] "up"))

(fn contacts
  []
  (when-let [app (: (hs.window.focusedWindow) :application)]
            (: app :selectMenuItem ["Window" "Contacts"])))

(fn prev-chat
  []
  (hs.eventtap.keyStroke [:alt] "up"))

(fn next-chat
  []
  (hs.eventtap.keyStroke [:alt] "down"))

{:scroll-up scroll-up
 :scroll-down scroll-down
 :edit-previous edit-previous
 :prev-chat prev-chat
 :next-chat next-chat
 :contacts contacts
 :telegram-config {:key "Telegram"
                   :keys [{:mods [:ctrl]
                           :key :e
                           :action "telegram:scroll-down"}
                          {:mods [:ctrl]
                           :key :y
                           :action "telegram:scroll-up"}
                          {:mods [:cmd]
                           :key :e
                           :action "telegram:edit-previous"}
                          {:mods [:cmd]
                           :key :k
                           :action "telegram:prev-chat"}
                          {:mods [:cmd]
                           :key :j
                           :action "telegram:next-chat"}
                          {:mods [:cmd]
                           :key :t
                           :action "telegram:contacts"}]}}
