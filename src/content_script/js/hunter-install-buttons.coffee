# Update install buttons on Hunter's website
#
chrome.extension.sendMessage {}, (response) ->
  readyStateCheckInterval = setInterval((->
    $('.install-chrome').each (index) ->
      width = $(this).outerWidth()
      $(this).prop 'disabled', true
      $(this).css 'width': width + 'px'
      $(this).html '<i class="fa fa-check" style="margin-right: 5px;"></i>Installed'
  ), 1000)
