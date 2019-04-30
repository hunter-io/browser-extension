# Open a tab when it's installed
#
chrome.runtime.onInstalled.addListener (object) ->
  if object.reason == 'install'
    chrome.tabs.create url: 'https://hunter.io/users/sign_up?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=new_install'
  return
  
# Open another tab when it's uninstalled
#
chrome.runtime.setUninstallURL 'https://hunter.io/chrome/uninstall?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=uninstall'
