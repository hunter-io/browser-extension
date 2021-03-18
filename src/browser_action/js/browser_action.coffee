loadAccountInformation = ->
  Account.get (json) ->
    if json == "none"
      $(".account-loading").hide()
      $(".account-not-logged").show()
    else
      $(".account-loading").hide()

      $(".account-calls-used").text Utilities.numberWithCommas(json.data.requests.searches.used)
      $(".account-calls-available").text Utilities.numberWithCommas(json.data.requests.searches.available)

      if json.data.plan_level == 0
        $(".account-upgrade-cta").show()

      $(".account-logged").show()

displayError = (html) ->
  $(".error-message").html html
  $("html, body").animate({ scrollTop: 0 }, 300);
  $(".error-container").delay(300).slideDown()
  setTimeout (->
    $(".error-container").slideUp()
    return
  ), 8000


# Prepare what will be diplayed depending on the current page and domain
# - If it's not on a domain name, a default page explain how it works
# - If on LinkedIn, a page explains the feature is no longer available
# - If an article author can be detected on the page, the Author Finder is launched
# - Otherwise, the Domain Search is launched
#
chrome.tabs.query {
  active: true
  currentWindow: true
}, (tabs) ->

  # We track the event
  Analytics.trackEvent "Open browser popup"

  Account.getApiKey (api_key) ->
    # Get account information
    loadAccountInformation()

    chrome.storage.sync.get 'current_leads_list_id', (value) ->
      window.current_leads_list_id = value.current_leads_list_id
      ListSelection.appendSelector()

    window.api_key = api_key
    window.url = tabs[0].url
    window.domain = new URL(tabs[0].url).hostname.replace("www.", "")
    withoutSubDomain = Utilities.withoutSubDomain(window.domain)

    # We clean the subdomain
    if withoutSubDomain
      window.domain = withoutSubDomain

    # We display a special message on LinkedIn
    if window.domain == "linkedin.com"
      $("#linkedin-notification").show()
      $("#loading-placeholder").hide()

    # We display a soft 404 if there is no domain name
    else if window.domain == "" or window.domain.indexOf(".") == -1
      $("#empty-notification").show()
      $("#loading-placeholder").hide()

    else
      chrome.tabs.query {
        active: true
        currentWindow: true
      }, (tabs) ->
        chrome.tabs.sendMessage tabs[0].id, { parsing: "article" }, (response) ->

          if response? && response.is_article
            # Launch the Author Finder
            authorFinder = new AuthorFinder
            authorFinder.launch()

            console.log("Author Finder launched")

          else
            # Launch the Domain Search
            domainSearch = new DomainSearch
            domainSearch.launch()
