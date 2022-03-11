(local windows (require :windows))

(local default-browser "Brave Browser")

(fn inspect-elements []
  "When I'm working on web related stuff, I often have to inspect elements, and I constantly
press the keybinding without realizing that the browser is not focused. I want to press
Cmd+Shift+c while not only in the browser."
  (let [app (-> (hs.window.focusedWindow) (: :application))
        inspect (fn [app] (: app :selectMenuItem [:View :Developer "Inspect Elements"]))]
    (if (= (-> app (: :name)) default-browser)
        (inspect app)
        (let [browser (hs.application.find default-browser)]
          (: browser :activate)
          (windows.set-mouse-cursor-at default-browser)
          (inspect browser)))))

{:inspect-elements inspect-elements}
