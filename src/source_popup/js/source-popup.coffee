findGetParameter = (parameterName) ->
  result = null
  tmp = []
  location.search.substr(1).split('&').forEach (item) ->
    tmp = item.split('=')
    if tmp[0] == parameterName
      result = decodeURIComponent(tmp[1])
  result

email = DOMPurify.sanitize(findGetParameter('email'))
count = DOMPurify.sanitize(findGetParameter('count'))
message = DOMPurify.sanitize(findGetParameter('message'))

if findGetParameter('message') == 'found'
  if findGetParameter('count') == '1'
    popup_message = '<strong>' + DOMPurify.sanitize(email) + '</strong> has been found on the page.'
  else
    popup_message = '<strong>' + DOMPurify.sanitize(email) + '</strong> has been found ' + DOMPurify.sanitize(count) + ' times on the page.'
else if findGetParameter('message') == 'mailto'
  popup_message = '<strong>' + DOMPurify.sanitize(email) + '</strong> found in the \'mailto:\' link.'
else
  popup_message = 'The email address couldn\'t be found on the page. This probably means this page has been updated since our lastest visit.'

document.getElementById('message').innerHTML = popup_message
document.getElementById('close').addEventListener 'click', closePopup
