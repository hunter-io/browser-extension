loadAccountInformation = ->
  Account.get (json) ->
    if json == "none"
      $(".account-loading").hide()
      $(".account-not-logged").show()
    else
      $(".account-loading").hide()

      $(".account-calls-used").text Utilities.numberWithCommas(json.data.requests.searches.used)
      $(".account-calls-available").text Utilities.numberWithCommas(json.data.requests.searches.available)
      $(".account-avatar__img").attr "src", "https://ui-avatars.com/api/?name=" + json.data.first_name + "+" + json.data.last_name + "&background=0F8DF4&color=fff&rounded=true"
      $(".account-avatar__img").attr "alt", json.data.first_name + " " + json.data.last_name

      if json.data.plan_level == 0
        $(".account-upgrade-cta").show()

      $(".account-logged").show()

displayError = (html) ->
  $("#error-message").html html
  $("html, body").animate({ scrollTop: 0 }, 300);
  $("#error-message-container").delay(300).slideDown()

# Prepare what will be diplayed depending on the current page and domain
# - If it's not on a domain name, a default page explain how it works
# - If on LinkedIn, a page explains the feature is no longer available
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

    currentDomain = new URL(tabs[0].url).hostname

    # We clean the subdomains when relevant
    Utilities.findRelevantDomain currentDomain, (domain) ->
      window.domain = domain

      # We display a special message on LinkedIn
      if window.domain == "linkedin.com"
        $("#linkedin-notification").show()
        $("#loading-placeholder").hide()

      # We display a soft 404 if there is no domain name
      else if window.domain == "" or window.domain.indexOf(".") == -1
        $("#empty-notification").show()
        $("#loading-placeholder").hide()

      else
        # Launch the Domain Search
        domainSearch = new DomainSearch
        domainSearch.launch()
