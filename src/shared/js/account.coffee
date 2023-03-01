Account =
  get: (callback) ->
    @getApiKey (api_key) ->
      if api_key != ''
        url = 'https://api.hunter.io/v2/account?api_key=' + api_key
        $.ajax
          url: url
          headers: 'Email-Hunter-Origin': 'chrome_extension'
          type: 'GET'
          dataType: 'json'
          jsonp: false
          success: (json) ->
            callback json
      else
        callback 'none'

  setApiKey: (api_key) ->
    chrome.storage.sync.set { 'api_key': api_key }, ->
      console.info 'Hunter extension successfully installed.'

  getApiKey: (fn) ->
    chrome.storage.sync.get { 'api_key': false }, (value) ->
      if value.api_key
        api_key = value.api_key
      else
        api_key = ''
      fn api_key

  returnRequestsError: (fn) ->
    $.ajax
      url: "https://api.hunter.io/v2/account?api_key=" + window.api_key
      headers: 'Email-Hunter-Origin': 'chrome_extension'
      type: 'GET'
      data: format: 'json'
      dataType: 'json'
      error: ->
        return chrome.i18n.getMessage("something_went_wrong_on_our_side")
      success: (result) ->
        # the user account hasn't be validated yet. The phone is probably
        # missing.
        if result.data.requests.searches.available == 0 && result.data.requests.verifications.available == 0 && result.data.plan_level == 0
          fn(chrome.i18n.getMessage("please_complete_your_registration"))

        # Otherwise the user has probably been frozen.
        else if result.data.requests.searches.available == 0 && result.data.requests.verifications.available == 0 && result.data.plan_level > 0
          fn(chrome.i18n.getMessage("your_account_has_been_restricted"))

        # the user has a free account, so it means he consumed all his
        # free calls.
        else if result.data.plan_level == 0
          fn(chrome.i18n.getMessage("you_have_reached_your_daily_quota"))

        # the user account has been soft frozen.
        else if result.data.requests.searches.available == 250 && result.data.requests.verifications.available == 250
          fn(chrome.i18n.getMessage("you_have_reached_your_temporary_quota"))

        # the user is on a premium plan and reached his quota
        else if result.data.plan_level < 4
          fn(chrome.i18n.getMessage("your_have_reached_your_monthly_quota"))

        else
          fn(chrome.i18n.getMessage("your_have_reached_your_monthly_enterprise_quota"))
