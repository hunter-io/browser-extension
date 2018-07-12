# Counts the main actions made with the extension to know which features
# are the most successful
#
Analytics = trackEvent: (eventName) ->
  url = 'https://hunter.io/events?name=' + eventName
  $.ajax
    url: url
    type: 'POST'
    dataType: 'json'
    jsonp: false
    success: (json) ->
      # Done!

analytics = Object.create(Analytics)
