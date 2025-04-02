(fn search [search-term]
  (let [_ (hs.application.launchOrFocus :Slack)
        app (hs.application.find :Slack)]
    (app:selectMenuItem [:File :Workspace :QlikDev])
    (when app
      (hs.eventtap.keyStroke ["cmd"] "g" 0 app)
      (hs.eventtap.keyStroke ["alt" "ctrl"] "Delete" 0 app)
      (hs.eventtap.keyStrokes search-term app)
      (hs.eventtap.keyStroke [] :return 0 app))))

{:search search}
