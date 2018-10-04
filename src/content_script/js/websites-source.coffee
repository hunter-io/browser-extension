PageContent =
  getEmailInHash: ->
    if window.location.hash
      hash = window.location.hash
      if hash.indexOf(':') != -1 and hash.split(':')[0]
        email = hash.split(':')[1]
        if @validateEmail(email)
          email
        else
          false
      else
        false
    else
      false

  validateEmail: (email) ->
    re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
    re.test email

  highlightEmail: (email) ->
    _this = this
    options =
      'element': 'mark'
      'className': 'hunter-email'
      'done': (counter) ->
        if counter > 0
          _this.scrollToEmail()
          _this.addLocationIcon()
          _this.displayMessage 'found', email, counter
        else
          # If there is not email address visible, then we search in the mailto
          # links.
          _this.highlightMailto email
        return
    context = document.querySelector('body')
    instance = new Mark(context)
    instance.mark email, options

  highlightMailto: (email) ->
    if $('a[href=\'mailto:' + email + '\']').length
      $('a[href=\'mailto:' + email + '\']').addClass 'hunter-email'
      @scrollToEmail()
      @addLocationIcon()
      @displayMessage 'mailto', email, 1
    else
      @searchCode(email)

  searchCode: (email) ->
    if $('html').html().indexOf(email) != -1
      @displayMessage 'code', email, 0
    else
      @displayMessage 'notfound', email, 0

  scrollToEmail: ->
    $('html, body').delay(2000).animate { scrollTop: $('.hunter-email:first').offset().top - 300 }, 500

  addLocationIcon: ->
    $('.hunter-email').each (index) ->
      emailEl = $(this)
      position = emailEl.offset()
      emailWidth = emailEl.outerWidth()
      emailHeight = emailEl.outerHeight()
      $('body').prepend '<img src=\'' + DOMPurify.sanitize(chrome.extension.getURL('/img/location_icon.png')) + '\' alt=\'Here is the email found on Hunter!\' id=\'hunter-email-pointer\'/>'
      $('#hunter-email-pointer').css
        'top': position.top - 63
        'left': position.left + emailWidth / 2 - 25
      $('#hunter-email-pointer').delay(2000).fadeIn 500

  displayMessage: (message, email, count) ->
    src = chrome.extension.getURL('/html/source_popup.html') + '?email=' + email + '&count=' + count + '&message=' + message
    $('body').prepend '<iframe id="hunter-email-status" src="' + src + '"></iframe>'
    $('body').prepend '<div id="hunter-email-status-close">&times;</div>'
    $('#hunter-email-status, #hunter-email-status-close').delay(500).fadeIn()

    $('#hunter-email-status-close').on 'click', ->
      $('#hunter-email-status, #hunter-email-status-close, #hunter-email-pointer').fadeOut()

# When the page loads, if it comes from a source in Hunter products, there is
# a hash at the end with the email address to find.
#
chrome.extension.sendMessage {}, (response) ->
  email = PageContent.getEmailInHash()
  if email
    PageContent.highlightEmail email
