Api =
  # Domain Search
  domainSearch: (domain, department, api_key) ->
    if department != null && typeof department != 'undefined'
      department = '&department=' + department
    else
      department = ''

    if api_key
      auth = '&api_key=' + api_key
      'https://api.hunter.io/v2/domain-search?limit=10&offset=0&domain=' + domain + department + auth
    else
      'https://api.hunter.io/trial/v2/domain-search?domain=' + domain

  # Email Finder
  emailFinder: (domain, full_name, api_key) ->
    if full_name != null && typeof full_name != 'undefined'
      full_name = '&full_name=' + encodeURIComponent(full_name)
    else
      full_name = ''

    if api_key
      auth = '&api_key=' + api_key
      'https://api.hunter.io/v2/email-finder?domain=' + domain + full_name + auth
    else
      'https://api.hunter.io/trial/v2/email-finder?domain=' + domain + full_name

  # Author Finder
  authorFinder: (url, api_key) ->
    if api_key
      auth = '&api_key=' + api_key
      'https://api.hunter.io/v2/author-finder?max_duration=5&url=' + url + auth
    else
      'https://api.hunter.io/trial/v2/author-finder?max_duration=5&url=' + url

  # Email Verifier
  emailVerifier: (email, api_key) ->
    if api_key
      auth = '&api_key=' + api_key
      'https://api.hunter.io/v2/email-verifier?email=' + encodeURIComponent(email) + auth
    else
      'https://api.hunter.io/trial/v2/email-finder?domain=' + encodeURIComponent(email)

  # Email count
  emailCount: (domain) ->
    'https://api.hunter.io/v2/email-count?domain=' + domain

  # Leads
  leads: (api_key) ->
    'https://api.hunter.io/v2/leads?api_key=' + api_key

  # Leads exist
  leadsExist: (email, api_key) ->
    'https://api.hunter.io/v2/leads/exist?email=' + encodeURIComponent(email) + '&api_key=' + api_key

  #Lead lists
  leadsList: (api_key) ->
    'https://api.hunter.io/v2/leads_lists?limit=100&api_key=' + api_key
