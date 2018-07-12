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
        return 'Something went wrong on our side. Please try again later.'
      success: (result) ->
        # the user account hasn't be validated yet. The phone is probably
        # missing.
        if result.data.calls.available == 0 && result.data.plan_level == 0
          fn('Please complete your registration on the <a target="_blank" href="https://hunter.io/search?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup">website</a> to use the extension.')

        # Otherwise the user has probably been frozen.
        else if result.data.calls.available == 0 && result.data.plan_level > 0
          fn('Your account has been restricted. Please <a target="_blank" href="https://hunter.io/search?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup">connect to your account</a> on Hunter for more information.')

        # the user has a free account, so it means he consumed all his
        # free calls.
        else if result.data.plan_level == 0
          fn('You have reached your free monthly quota. Please <a target="_blank" href="https://hunter.io/subscriptions?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup">subscribe to a premium plan</a> to make more requests.')

        # the user account has been soft frozen.
        else if result.data.calls.available == 500
          fn('You have reached your temporary quota. You will get your full access as soon as we validate your account.')

        # the user is on a premium plan and reached his quota
        else if result.data.plan_level < 4
          fn('You have reached your monthly quota. Please <a target="_blank" href="https://hunter.io/subscriptions?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup">upgrade to a bigger plan</a> to make more requests.')

        else
          fn('You have reached your monthly quota. Please contact us to be able to make more requests.')
