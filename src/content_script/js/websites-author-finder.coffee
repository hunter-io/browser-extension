chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->

  # The content script is asked to check if the current
  # page looks like an article
  if request.parsing == "article"

    # One easy and quite reliable way to check is to read the Open Graph
    # information that might be provided.
    open_graph_type = $("meta[property='og:type']").attr("content")

    # It looks like an article. Let's share the news!
    if open_graph_type == "article"
      sendResponse is_article: true

    else
      sendResponse is_article: false
