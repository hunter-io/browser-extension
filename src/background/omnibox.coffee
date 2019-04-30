# Allow the user to do a domain search in the omnibox directly
chrome.omnibox.onInputChanged.addListener (text, suggest) ->
  suggestions = [ {
    content: text
    description: 'Search the domain name "' + text + '"'
  } ]
  # Set first suggestion as the default suggestion
  chrome.omnibox.setDefaultSuggestion description: suggestions[0].description
  suggest suggestions
  return

# This event is fired with the user accepts the input in the omnibox.
chrome.omnibox.onInputEntered.addListener (text) ->
  chrome.tabs.create url: 'https://hunter.io/search/' + text + '?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=omnibox'
  return
