# We send 2 data points to the web app:
# - That the extension is installed.
# - The version currently installed. Can be used to debug with support.
#
$("#is-extension-installed").val true
$("#extension-version").val chrome.runtime.getManifest().version
