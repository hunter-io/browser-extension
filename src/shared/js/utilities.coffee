Utilities =
  # Return a decomposition of all successive subdomains in an array
  # In some rare case, this function might remove the main domain name and let only the
  # TLD. To mitigate these cases, we check if we can find emails by adding back one level
  # in the function "findRelevantDomain".
  #
  decomposeSubDomains: (domain) ->
    domains = [domain]

    loop
      newDomain = domain.substring(domain.indexOf('.') + 1)
      subdomainsCount = (newDomain.match(/\./g) or []).length

      if (subdomainsCount == 0 || newDomain.length <= 7) then break
      domain = newDomain
      domains.push newDomain

    return domains

  # This function decides if it's relevant to remove the highest found subdomain or not.
  # If we find data by keeping the subdomain, this is the domain we will use.
  #
  findRelevantDomain: (domain, fn) ->
    # In any case, we won't try emails on domain starting with "www."
    domain = domain.replace(/^www\./i, "")

    domains = @decomposeSubDomains(domain)

    return fn(domain) if domains.length == 1

    withSubdomain = domains[domains.length - 2]
    withoutSubdomain = domains.pop()

    @dataFoundForDomain withSubdomain, (results) ->
      if results
        return fn(withSubdomain)
      else
        return fn(withoutSubdomain)

  # Check if we have data for the given domain name, by using a dedicated API endpoint.
  #
  dataFoundForDomain: (domain, fn) ->
    fetch(Api.dataForDomain(domain)).then((response) ->
      response.json()
    ).then((response) ->
      if response == 1
        fn(true)
      else
        fn(false)
    ).catch (error) ->
      console.warn error
      fn(false)

  # Localize a given HTML string.
  #
  localizeHTML: (html) ->
    html = $("<div>#{html}</div>")

    html.find("[data-locale]").each () ->
      $(this).text(chrome.i18n.getMessage($(this).data("locale")))

    html.find("[data-locale-title]").each () ->
      $(this).prop("title", chrome.i18n.getMessage($(this).data("localeTitle")))

    return html.html()

  # Add commas separating thousands
  #
  numberWithCommas: (x) ->
    x.toString().replace /\B(?=(\d{3})+(?!\d))/g, ','

  # Display dates easy to read
  #
  dateInWords: (input) ->
    date = undefined
    monthNames = undefined
    splitted_date = undefined
    splitted_date = input.split('-')
    date = new Date(splitted_date[0], splitted_date[1] - 1, splitted_date[2])
    if $(window).width() > 768
      monthNames = [
        chrome.i18n.getMessage("january")
        chrome.i18n.getMessage("february")
        chrome.i18n.getMessage("march")
        chrome.i18n.getMessage("april")
        chrome.i18n.getMessage("may")
        chrome.i18n.getMessage("june")
        chrome.i18n.getMessage("july")
        chrome.i18n.getMessage("august")
        chrome.i18n.getMessage("september")
        chrome.i18n.getMessage("october")
        chrome.i18n.getMessage("november")
        chrome.i18n.getMessage("december")
      ]
    else
      monthNames = [
        chrome.i18n.getMessage("jan")
        chrome.i18n.getMessage("feb")
        chrome.i18n.getMessage("mar")
        chrome.i18n.getMessage("apr")
        chrome.i18n.getMessage("may")
        chrome.i18n.getMessage("jun")
        chrome.i18n.getMessage("jul")
        chrome.i18n.getMessage("aug")
        chrome.i18n.getMessage("sep")
        chrome.i18n.getMessage("oct")
        chrome.i18n.getMessage("nov")
        chrome.i18n.getMessage("dec")
      ]
    monthNames[date.getMonth()] + ' ' + date.getDate() + ', ' + date.getFullYear()

  capitalizeFirstLetter: (string) ->
    return string.charAt(0).toUpperCase() + string.slice(1)

  # Open in a new tab
  #
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
    $(".copy-email").on "click", ->
      email = $(this).data("email")
      Utilities.executeCopy(email)
      $(this).next().find(".tooltip-inner").text("Copied!")

  # Sort an object by values
  #
  sortObject: (array) ->
    sortable = []
    for el of array
      sortable.push [
        el
        array[el]
      ]
    sortable.sort (a, b) ->
      b[1] - a[1]

    return sortable

  # Converts to MD5
  #
  MD5: (s) ->
    C = Array()
    P = undefined
    h = undefined
    E = undefined
    v = undefined
    g = undefined
    Y = undefined
    X = undefined
    W = undefined
    V = undefined
    S = 7
    Q = 12
    N = 17
    M = 22
    A = 5
    z = 9
    y = 14
    w = 20
    o = 4
    m = 11
    l = 16
    j = 23
    U = 6
    T = 10
    R = 15
    O = 21

    L = (k, d) ->
      k << d | k >>> 32 - d

    K = (G, k) ->
      I = undefined
      d = undefined
      F = undefined
      H = undefined
      x = undefined
      F = G & 2147483648
      H = k & 2147483648
      I = G & 1073741824
      d = k & 1073741824
      x = (G & 1073741823) + (k & 1073741823)
      if I & d
        return x ^ 2147483648 ^ F ^ H
      if I | d
        if x & 1073741824
          x ^ 3221225472 ^ F ^ H
        else
          x ^ 1073741824 ^ F ^ H
      else
        x ^ F ^ H

    r = (d, F, k) ->
      d & F | ~d & k

    q = (d, F, k) ->
      d & k | F & ~k

    p = (d, F, k) ->
      d ^ F ^ k

    n = (d, F, k) ->
      F ^ (d | ~k)

    u = (G, F, aa, Z, k, H, I) ->
      G = K(G, K(K(r(F, aa, Z), k), I))
      K L(G, H), F

    f = (G, F, aa, Z, k, H, I) ->
      G = K(G, K(K(q(F, aa, Z), k), I))
      K L(G, H), F

    D = (G, F, aa, Z, k, H, I) ->
      G = K(G, K(K(p(F, aa, Z), k), I))
      K L(G, H), F

    t = (G, F, aa, Z, k, H, I) ->
      G = K(G, K(K(n(F, aa, Z), k), I))
      K L(G, H), F

    e = (G) ->
      Z = undefined
      F = G.length
      x = F + 8
      k = (x - (x % 64)) / 64
      I = (k + 1) * 16
      aa = Array(I - 1)
      d = 0
      H = 0
      while H < F
        Z = (H - (H % 4)) / 4
        d = H % 4 * 8
        aa[Z] = aa[Z] | G.charCodeAt(H) << d
        H++
      Z = (H - (H % 4)) / 4
      d = H % 4 * 8
      aa[Z] = aa[Z] | 128 << d
      aa[I - 2] = F << 3
      aa[I - 1] = F >>> 29
      aa

    B = (x) ->
      k = ''
      F = ''
      G = undefined
      d = undefined
      d = 0
      while d <= 3
        G = x >>> d * 8 & 255
        F = '0' + G.toString(16)
        k = k + F.substr(F.length - 2, 2)
        d++
      k

    J = (k) ->
      k = k.replace(/rn/g, 'n')
      d = ''
      F = 0
      while F < k.length
        x = k.charCodeAt(F)
        if x < 128
          d += String.fromCharCode(x)
        else
          if x > 127 and x < 2048
            d += String.fromCharCode(x >> 6 | 192)
            d += String.fromCharCode(x & 63 | 128)
          else
            d += String.fromCharCode(x >> 12 | 224)
            d += String.fromCharCode(x >> 6 & 63 | 128)
            d += String.fromCharCode(x & 63 | 128)
        F++
      d

    s = J(s)
    C = e(s)
    Y = 1732584193
    X = 4023233417
    W = 2562383102
    V = 271733878
    P = 0
    while P < C.length
      h = Y
      E = X
      v = W
      g = V
      Y = u(Y, X, W, V, C[P + 0], S, 3614090360)
      V = u(V, Y, X, W, C[P + 1], Q, 3905402710)
      W = u(W, V, Y, X, C[P + 2], N, 606105819)
      X = u(X, W, V, Y, C[P + 3], M, 3250441966)
      Y = u(Y, X, W, V, C[P + 4], S, 4118548399)
      V = u(V, Y, X, W, C[P + 5], Q, 1200080426)
      W = u(W, V, Y, X, C[P + 6], N, 2821735955)
      X = u(X, W, V, Y, C[P + 7], M, 4249261313)
      Y = u(Y, X, W, V, C[P + 8], S, 1770035416)
      V = u(V, Y, X, W, C[P + 9], Q, 2336552879)
      W = u(W, V, Y, X, C[P + 10], N, 4294925233)
      X = u(X, W, V, Y, C[P + 11], M, 2304563134)
      Y = u(Y, X, W, V, C[P + 12], S, 1804603682)
      V = u(V, Y, X, W, C[P + 13], Q, 4254626195)
      W = u(W, V, Y, X, C[P + 14], N, 2792965006)
      X = u(X, W, V, Y, C[P + 15], M, 1236535329)
      Y = f(Y, X, W, V, C[P + 1], A, 4129170786)
      V = f(V, Y, X, W, C[P + 6], z, 3225465664)
      W = f(W, V, Y, X, C[P + 11], y, 643717713)
      X = f(X, W, V, Y, C[P + 0], w, 3921069994)
      Y = f(Y, X, W, V, C[P + 5], A, 3593408605)
      V = f(V, Y, X, W, C[P + 10], z, 38016083)
      W = f(W, V, Y, X, C[P + 15], y, 3634488961)
      X = f(X, W, V, Y, C[P + 4], w, 3889429448)
      Y = f(Y, X, W, V, C[P + 9], A, 568446438)
      V = f(V, Y, X, W, C[P + 14], z, 3275163606)
      W = f(W, V, Y, X, C[P + 3], y, 4107603335)
      X = f(X, W, V, Y, C[P + 8], w, 1163531501)
      Y = f(Y, X, W, V, C[P + 13], A, 2850285829)
      V = f(V, Y, X, W, C[P + 2], z, 4243563512)
      W = f(W, V, Y, X, C[P + 7], y, 1735328473)
      X = f(X, W, V, Y, C[P + 12], w, 2368359562)
      Y = D(Y, X, W, V, C[P + 5], o, 4294588738)
      V = D(V, Y, X, W, C[P + 8], m, 2272392833)
      W = D(W, V, Y, X, C[P + 11], l, 1839030562)
      X = D(X, W, V, Y, C[P + 14], j, 4259657740)
      Y = D(Y, X, W, V, C[P + 1], o, 2763975236)
      V = D(V, Y, X, W, C[P + 4], m, 1272893353)
      W = D(W, V, Y, X, C[P + 7], l, 4139469664)
      X = D(X, W, V, Y, C[P + 10], j, 3200236656)
      Y = D(Y, X, W, V, C[P + 13], o, 681279174)
      V = D(V, Y, X, W, C[P + 0], m, 3936430074)
      W = D(W, V, Y, X, C[P + 3], l, 3572445317)
      X = D(X, W, V, Y, C[P + 6], j, 76029189)
      Y = D(Y, X, W, V, C[P + 9], o, 3654602809)
      V = D(V, Y, X, W, C[P + 12], m, 3873151461)
      W = D(W, V, Y, X, C[P + 15], l, 530742520)
      X = D(X, W, V, Y, C[P + 2], j, 3299628645)
      Y = t(Y, X, W, V, C[P + 0], U, 4096336452)
      V = t(V, Y, X, W, C[P + 7], T, 1126891415)
      W = t(W, V, Y, X, C[P + 14], R, 2878612391)
      X = t(X, W, V, Y, C[P + 5], O, 4237533241)
      Y = t(Y, X, W, V, C[P + 12], U, 1700485571)
      V = t(V, Y, X, W, C[P + 3], T, 2399980690)
      W = t(W, V, Y, X, C[P + 10], R, 4293915773)
      X = t(X, W, V, Y, C[P + 1], O, 2240044497)
      Y = t(Y, X, W, V, C[P + 8], U, 1873313359)
      V = t(V, Y, X, W, C[P + 15], T, 4264355552)
      W = t(W, V, Y, X, C[P + 6], R, 2734768916)
      X = t(X, W, V, Y, C[P + 13], O, 1309151649)
      Y = t(Y, X, W, V, C[P + 4], U, 4149444226)
      V = t(V, Y, X, W, C[P + 11], T, 3174756917)
      W = t(W, V, Y, X, C[P + 2], R, 718787259)
      X = t(X, W, V, Y, C[P + 9], O, 3951481745)
      Y = K(Y, h)
      X = K(X, E)
      W = K(W, v)
      V = K(V, g)
      P += 16
    i = B(Y) + B(X) + B(W) + B(V)
    i.toLowerCase()

# Generate a hash from a string
#
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
