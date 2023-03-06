window = self

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
      try
        hostname = new URL(tabArray[0]['url'])
        Utilities.findRelevantDomain hostname.host, (domain) ->
          window.currentDomain = domain
          updateIconColor()
      catch e
        # The tab is not a valid URL
        setGreyIcon()

# API call to check if there is at least one email address
# We use a special API call for this task to minimize the ressources.
#
# Endpoint: https://extension-api.hunter.io/data-for-domain?domain=site.com
#
updateIconColor = ->
  if window.currentDomain.indexOf(".") == -1
    setGreyIcon()
  else
    Utilities.dataFoundForDomain window.currentDomain, (results) ->
      if results
        setColoredIcon()
      else
        setGreyIcon()


setGreyIcon = ->
  chrome.action.setIcon path:
    "19": chrome.runtime.getURL("../img/icon19_grey.png")
    "38": chrome.runtime.getURL("../img/icon38_grey.png")
  return

setColoredIcon = ->
  chrome.action.setIcon path:
    "19": chrome.runtime.getURL("../img/icon19.png")
    "38": chrome.runtime.getURL("../img/icon38.png")
  return

# When an URL change
chrome.tabs.onUpdated.addListener (tabid, changeinfo, tab) ->
  if tab != undefined
    if tab.url != undefined and changeinfo.status == "complete"
      LaunchColorChange()

# When the active tab changes
chrome.tabs.onActivated.addListener ->
  LaunchColorChange()
