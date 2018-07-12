Utilities =
  # Find if a subdomain can be removed and do it
  withoutSubDomain: (domain) ->
    subdomainsCount = (domain.match(/\./g) or []).length
    if subdomainsCount > 1
      newdomain = domain
      newdomain = newdomain.substring(newdomain.indexOf('.') + 1)
      if newdomain.length > 6
        return newdomain
      else
        return false
    false

  # Add commas separating thousands
  numberWithCommas: (x) ->
    x.toString().replace /\B(?=(\d{3})+(?!\d))/g, ','

  # Display dates easy to read
  dateInWords: (input) ->
    date = undefined
    monthNames = undefined
    splitted_date = undefined
    splitted_date = input.split('-')
    date = new Date(splitted_date[0], splitted_date[1] - 1, splitted_date[2])
    if $(window).width() > 768
      monthNames = [
        'January'
        'February'
        'March'
        'April'
        'May'
        'June'
        'July'
        'August'
        'September'
        'October'
        'November'
        'December'
      ]
    else
      monthNames = [
        'Jan'
        'Feb'
        'Mar'
        'Apr'
        'May'
        'Jun'
        'Jul'
        'Aug'
        'Sep'
        'Oct'
        'Nov'
        'Dec'
      ]
    monthNames[date.getMonth()] + ' ' + date.getDate() + ', ' + date.getFullYear()

  capitalizeFirstLetter: (string) ->
    return string.charAt(0).toUpperCase() + string.slice(1)

  # Open in a new tab
  openInNewTab: (url) ->
    win = window.open(url, '_blank')
    win.focus()
    return

  executeCopy : (text) ->
    input = document.createElement('textarea')
    $('#copy-area').prepend input
    input.value = text
    input.focus()
    input.select()
    document.execCommand 'Copy'
    input.remove()
    return

  # This method attaches a tooltip to the passed DOM element and safely
  # destroys it. If the passed element already has a visible tooltip
  # attached, we do nothing.
  #
  showDismissableTooltip: (selector, title, duration) ->
    # prevents building and finally destroying a new tooltip
    # whereas one is already attached to the selector
    return if selector.next("div.tooltip:visible").length

    selector.tooltip(title: title).tooltip("show")

    setTimeout (->
      selector.tooltip("destroy")
    ), duration


  # Capitalizes the first letter of each word in the string and lower cases
  # the other letters
  #
  toTitleCase: (string) ->
    (string.split(" ").map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join " "


  # Copy the email in an .email tag
  #
  copyEmailListener: ->
    $(".email").mouseover ->
      $(this).parent().find(".copy-status").fadeIn 200
    $(".email").mouseout ->
      $(this).parent().find(".copy-status").fadeOut 200
    $(".email").on "click", ->
      email = $(this).text()
      Utilities.executeCopy(email)
      email_copied = $(this).parent().find(".email-copied")
      email_copied.text(email)
      email_copied.css
        opacity: 0.5
      email_copied.animate
        opacity: 0
        top: "-18px"
      , 300
      , ->
        email_copied.removeAttr "style"
        email_copied.text ""

      copy_status = $(this).parent().find(".copy-status")
      copy_status.show().text("Copied!")
      copy_status.delay(400).fadeOut 200, ->
        copy_status.text("Copy")


# Generate a hash from a string
String::hashCode = ->
  hash = 0
  i = undefined
  chr = undefined
  len = undefined
  if @length == 0
    return hash
  i = 0
  len = @length
  while i < len
    chr = @charCodeAt(i)
    hash = (hash << 5) - hash + chr
    hash |= 0
    i++
  hash
