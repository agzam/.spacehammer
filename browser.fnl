(local windows (require :windows))

(local {: contains?
        : first} (require :lib.functional))

(local browsers ["Brave Browser" "Google Chrome"])

(fn inspect-elements []
  "When I'm working on web related stuff, I often have to inspect elements, and I constantly
press the keybinding without realizing that the browser is not focused. I want to press
Cmd+Shift+c while not only in the browser."
  (let [app (-> (hs.window.focusedWindow) (: :application))
        inspect (fn [app] (: app :selectMenuItem [:View :Developer "Inspect Elements"]))]
    (if (-> app (: :name) (contains? browsers))
        (inspect app)
        (let [browser (hs.application.find (first browsers))]
          (: browser :activate)
          (windows.set-mouse-cursor-at (first browsers))
          (inspect browser)))))

(fn open-new-tab []
  "Too often I press Cmd-Tab in Emacs, thinking the active focus is on the browser."
  (let [app (-> (hs.window.focusedWindow) (: :application))
        new-tab (fn [app] (: app :selectMenuItem [:File "New Tab"]))]
    (if (-> app (: :name) (not= "Emacs"))
        (hs.eventtap.keyStroke [:cmd] "t" app)
        (let [browser (hs.application.find (first browsers))]
          (: browser :activate)
          (windows.set-mouse-cursor-at (first browsers))
          (new-tab browser)))))

{:inspect-elements inspect-elements
 :open-new-tab open-new-tab}
