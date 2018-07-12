# Every time a user make a successful search, we count it in Chrome local storage.
# This is used to display a notification to rate the extension or give feedback.
#
countCall = ->
  chrome.storage.sync.get { 'calls_count': 0 }, (value) ->
    value.calls_count++
    chrome.storage.sync.set 'calls_count': value.calls_count
