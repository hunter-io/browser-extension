# When the page loads, if it comes from a source in Hunter products, there is
# a hash at the end with the email address to highlight. It will search it in
# this order:
# 1. Visible email address?
# 2. Email address in a mailto link?
# 3. Email address visible elsewhere in the code?

PageContent =
  getEmailInHash: ->
    if window.location.hash
      hash = window.location.hash
      if hash.indexOf(":") != -1 and hash.split(":")[0]
        email = hash.split(":")[1]
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
    containers = @getVisibleEmailContainers(email)
    if containers.length > 0
      # We add a tag around the matching visible email addresses to highlight them
      $(containers).html($(containers[0]).html().replace(email, "<span class=\"hunter-email\">" + email + "</span>"))
      @scrollToEmail()
      @addLocationIcon()
      @displayMessage "found", email, containers.length
    else
      # Next check: is it in a mailto address?
      @highlightMailto email

  highlightMailto: (email) ->
    if $("a[href=\"mailto:" + email + "\"]:visible").length
      $("a[href=\"mailto:" + email + "\"]").addClass "hunter-email"
      @scrollToEmail()
      @addLocationIcon()
      @displayMessage "mailto", email, 1
    else
      @searchCode(email)

  searchCode: (email) ->
    if $("html").html().indexOf(email) != -1
      @displayMessage "code", email, 0
    else
      @displayMessage "notfound", email, 0

  scrollToEmail: ->
    $("html, body").animate { scrollTop: $(".hunter-email:first").offset().top - 300 }, 500

  addLocationIcon: ->
    $(".hunter-email").each (index) ->
      emailEl = $(this)
      position = emailEl.offset()
      emailWidth = emailEl.outerWidth()
      emailHeight = emailEl.outerHeight()
      $("body").prepend "<img src=\"" + DOMPurify.sanitize(chrome.runtime.getURL("/img/location_icon.png")) + "\" alt=\"Here is the email found with Hunter!\" id=\"hunter-email-pointer\"/>"
      $("#hunter-email-pointer").css
        "top": position.top - 63
        "left": position.left + emailWidth / 2 - 25
      $("#hunter-email-pointer").fadeIn 300

  displayMessage: (message, email, count) ->
    src = chrome.runtime.getURL("/html/source_popup.html") + "?email=" + email + "&count=" + count + "&message=" + message
    $("body").prepend "<iframe id='hunter-email-status' src='" + src + "'></iframe>"
    $("body").prepend "<div id='hunter-email-status-close'>&times;</div>"
    $("#hunter-email-status, #hunter-email-status-close").fadeIn 300

    $("#hunter-email-status-close").on "click", ->
      $("#hunter-email-status, #hunter-email-status-close, #hunter-email-pointer").fadeOut()

  getVisibleEmailContainers: (email) ->
    return $("body, body *").contents().filter(->
      @nodeType == 3 and @nodeValue.indexOf(email) >= 0
    ).parent ":visible"

email = PageContent.getEmailInHash()
if email
  PageContent.highlightEmail email
