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

{:inspect-elements inspect-elements}
