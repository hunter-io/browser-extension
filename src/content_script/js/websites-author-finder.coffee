chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->

  # The content script is asked to check if the current
  # page looks like an article
  if request.parsing == 'article'
    jsonld = $('script[type="application/ld+json"]')

    try
      data = JSON.parse jsonld.text()

      if data? && (data["@type"] == "Article")
        # It looks like an article. Let's share the news!
        sendResponse is_article: true

      else
        sendResponse is_article: false

    catch e
      sendResponse is_article: false




