(local windows (require :windows))

(local {: contains?
        : first} (require :lib.functional))

(local browsers ["Brave Browser" "Firefox" "Google Chrome"])

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

(fn activate-tab
  [window-index tab-index]
  (let [script
        (string.format
         "const Brave = Application('%s');
          const winIndex = %s;
          const tabIndex = %s;
          const win = Brave.windows()[winIndex - 1];
          if(win) {
            const tab = win.tabs()[tabIndex - 1];
            if(tab) {
              win.activeTabIndex = tabIndex;
              win.index = 1;
              Brave.activate();
            } else {
              'Tab index out of range';
            }
          } else {
            'Window index out of range';
         }" (first browsers)
          window-index tab-index)]
    (hs.osascript.javascript script)))

(fn browser-tabs []
  "Returns the table of currently opened browser tabs,
where each tab represented as k/v pairs of:
{tabIndex, title, url, windowIndex}"
  (let [script
        (string.format
         "const browser = Application('%s');
          let tabsInfo = [];
          browser.windows().forEach((window, windowIndex) => {
            window.tabs().forEach((tab, tabIndex) => {
              let tabInfo = {
                windowIndex: windowIndex + 1,
                tabIndex: tabIndex + 1,
                url: tab.url(),
                title: tab.name()
              };
              tabsInfo.push(tabInfo);
            });
          });
          tabsInfo;" (first browsers))
        (_ tabs) (hs.osascript.javascript script)]
    tabs))

{:inspect-elements inspect-elements
 :open-new-tab open-new-tab
 :browser-tabs browser-tabs
 :activate-tab activate-tab}
