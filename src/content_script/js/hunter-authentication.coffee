# Hunter extension can be used without authentification but with low
# limitation. When the quota is reached, user is invited to connect to its
# account. The extention will read the API key on the website and store it in
# Chrome local storage.
#
chrome.extension.sendMessage {}, (response) ->
  if location.pathname == '/chrome/welcome' or location.pathname == '/firefox/welcome' or location.pathname == '/search' or location.pathname == '/dashboard'
    # We read the API key
    api_key = document.getElementById('api_key').innerHTML.trim()
    Account.setApiKey api_key
    # We inform the website that the extension is installed
    $('#is-extension-installed').val true
