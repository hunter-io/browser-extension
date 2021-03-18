# When an URL changes
#
# Check if email addresses are available for the current domain and update the
# color of the browser icon
#
LaunchColorChange = ->
  chrome.tabs.query {
    currentWindow: true
    active: true
  }, (tabArray) ->
    if tabArray[0]["url"] != window.currentDomain
      window.currentDomain = url_domain(tabArray[0]["url"]).replace("www.", "")
      withoutSubDomain = Utilities.withoutSubDomain(window.currentDomain)
      if withoutSubDomain
        window.currentDomain = withoutSubDomain
      updateIconColor()


# API call to check if there is at least one email address
# We use a special API call for this task to minimize the ressources.
#
# Endpoint: https://extension-api.hunter.io/data-for-domain?domain=site.com
#
updateIconColor = ->
  if window.currentDomain.indexOf(".") == -1
    setGreyIcon()
  else
    chrome.storage.sync.get "hunter_blocked", (value) ->
      if value["hunter_blocked"]
        setColoredIcon()
      else
        $.ajax
          url: "https://extension-api.hunter.io/data-for-domain?domain=" + window.currentDomain
          type: "GET"
          jsonp: false
          success: (html) ->
            if html == "1"
              setColoredIcon()
            else
              setGreyIcon()

          error: (xhr) ->
            if xhr.status == 403
              chrome.storage.sync.set "hunter_blocked": true
            setGreyIcon()

setGreyIcon = ->
  chrome.browserAction.setIcon path:
    "19": chrome.extension.getURL("../img/icon19_grey.png")
    "38": chrome.extension.getURL("../img/icon38_grey.png")
  return

setColoredIcon = ->
  chrome.browserAction.setIcon path:
    "19": chrome.extension.getURL("../img/icon19.png")
    "38": chrome.extension.getURL("../img/icon38.png")
  return

url_domain = (data) ->
  a = document.createElement("a")
  a.href = data
  a.hostname


# Add context links on right click on the icon
#
addBrowserMenuLinks = ->
  chrome.contextMenus.create
    "id": "dashboard"
    "title": "Dashboard"
    "contexts": [ "browser_action" ]
  chrome.contextMenus.create
    "id": "leads"
    "title": "Leads"
    "contexts": [ "browser_action" ]
  chrome.contextMenus.create
    "id": "upgrade"
    "title": "Upgrade"
    "contexts": [ "browser_action" ]
  chrome.contextMenus.create
    "id": "faqs"
    "title": "Tutorial"
    "contexts": [ "browser_action" ]

# When an URL change
chrome.tabs.onUpdated.addListener (tabid, changeinfo, tab) ->
  url = tab.url
  if url != undefined and changeinfo.status == "complete"
    LaunchColorChange()

# When the active tab changes
chrome.tabs.onActivated.addListener ->
  LaunchColorChange()

addBrowserMenuLinks()

chrome.contextMenus.onClicked.addListener (info, tab) ->
  switch info.menuItemId
    when "dashboard"
      chrome.tabs.create url: "https://hunter.io/dashboard?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=context_menu_browser_action"
    when "leads"
      chrome.tabs.create url: "https://hunter.io/leads?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=context_menu_browser_action"
    when "upgrade"
      chrome.tabs.create url: "https://hunter.io/subscriptions?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=context_menu_browser_action"
    when "faqs"
      chrome.tabs.create url: "https://hunter.io/help/articles/2-hunter-s-chrome-extension?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=context_menu_browser_action"
  return
