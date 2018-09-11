chrome.extension.sendMessage {}, (response) ->
  if location.pathname == '/chrome/welcome' or location.pathname == '/firefox/welcome' or location.pathname == '/search'

    # Hunter extension can be used without authentification but the data returned by
    # the API is limited. When the quota is reached, the user is invited to log in.
    # The extention will read the API key on the website and store it in
    # Chrome local storage.
    #
    api_key = document.getElementById('api_key').innerHTML.trim()
    Account.setApiKey api_key

    # We send 2 data points to the web app:
    # - That the extension is installed
    # - The version currently installed. Can be used to debug with support.
    #
    $('#is-extension-installed').val true
    $("#extension-version").val chrome.runtime.getManifest().version
