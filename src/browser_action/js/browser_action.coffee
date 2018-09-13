DomainSearch = ->
  {
    domain: @domain
    webmail: @webmail
    pattern: @pattern
    organization: @organization
    results: @results
    results_count: @results_count
    offset: @offset
    limit: @limit
    type: @type
    trial: @trial
    departments: @departments

    launch: ->
      @domain = window.domain
      @trial = (typeof window.api_key == "undefined" || window.api_key == "")
      Analytics.trackEvent 'Open browser popup'
      @fetch()

      unless @trial
        @getDepartments()

    fetch: () ->
      _this = @
      unless _this.trial
        url = 'https://api.hunter.io/v2/domain-search?limit=10&offset=0&domain=' + window.domain + '&api_key=' + window.api_key
      else
        url = 'https://api.hunter.io/trial/v2/domain-search?domain=' + window.domain
      $.ajax
        url: url
        headers: 'Email-Hunter-Origin': 'chrome_extension'
        type: 'GET'
        data: format: 'json'
        dataType: 'json'
        jsonp: false
        error: (xhr) ->
          $('.search-placeholder').hide()

          if xhr.status == 400
            displayError 'Sorry, something went wrong on the query.'
          else if xhr.status == 401
            $('.connect-again-container').show()
          else if xhr.status == 403
            $('#domain-search').hide()
            $('#blocked-notification').show()
          else if xhr.status == 429
            unless _this.trial
              Account.returnRequestsError (e) ->
                displayError e
            else
              $('.connect-container').show()
          else
            response = $.parseJSON(xhr.responseText)
            displayError DOMPurify.sanitize(response["errors"][0]["details"])

        success: (result) ->
          _this.webmail = result.data.webmail
          _this.pattern = result.data.pattern
          _this.organization = result.data.organization
          _this.results = result.data.emails
          _this.results_count = result.meta.results
          _this.offset = result.meta.offset
          _this.type = result.meta.params.type

          $(".search-placeholder").hide()

          # Not logged in: we hide the Email Finder
          if _this.trial
            $('#full-name-field').hide()

          _this.render()

    getDepartments: ->
      _this = @
      $.ajax
        url: 'https://api.hunter.io/v2/email-count?domain=' + window.domain
        headers: 'Email-Hunter-Origin': 'chrome_extension'
        type: 'GET'
        data: format: 'json'
        dataType: 'json'
        success: (result) ->
          # After sorting it will be an array of this form
          # [["executive", 5], ["hr", 3], ["it”, 1], ...]
          _this.departments = Utilities.sortObject(result.data.department)

          Handlebars.registerHelper 'ifGreaterThanZero', (count, options) ->
            if count > 0
              return options.fn(this)
            options.inverse this

          Handlebars.registerHelper 'departmentName', (options) ->
            department_names = { executive: "Executive", it: "IT / Engineering", finance: "Finance", management: "Management", sales: "Sales", legal: "Legal", support: "Support", hr: "Human Ressources", marketing: "Marketing", communication: "Communication" }
            new Handlebars.SafeString(department_names[options.fn(this)])

          template = JST["src/browser_action/templates/departments.hbs"]
          departments_content = $(template(_this))
          $('.departments-container').html(departments_content)

          $(".more-departments-button").on "click", ->
            $('.departments-container a').css
              display: "inline-block"
            $(this).hide()


    render: ->
      # Is webmail -> STOP
      if @webmail == true
        $(".webmail-container .domain").text @domain
        $(".webmail-container").show()
        return

      # No results -> STOP
      if @results_count == 0
        $(".no-result-container .domain").text @domain
        $(".no-result-container").show()
        return

      # Display: the current domain
      $('#current-domain').text @domain

      # Display: complete search link or Sign up CTA
      unless @trial
        $('#complete-search').attr 'href', 'https://hunter.io/search/' + @domain + '?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup'
        $('#complete-search').show()
      else
        $('#signup-cta').show()

      # Display: the number of results
      if @results_count == 1 then s = '' else s = 's'
      $('#results-number').html DOMPurify.sanitize(Utilities.numberWithCommas(@results_count)) + ' result' + s + ' for <strong>' + DOMPurify.sanitize(@domain) + '</strong>'

      # Display: the email pattern if any, with the Email Finder form
      if @pattern != null
        $(".people-search-container").show()
        $(".domain-pattern strong").html(@addPatternTitle(@pattern) + "@" + @domain)
        $("[data-toggle='tooltip']").tooltip()

        emailFinder = new EmailFinder
        emailFinder.validateForm()

      # Display: the updated number of requests
      @loadAccountInformation()

      # We count call to measure use
      countCall()
      @feedbackNotification()

      # Display: the results
      @showResults()

      # Render: set again an auto body height after forcing it
      $("body").css
        height: "auto"

      # Display: link to see more
      if @results_count > 10
        remaining_results = @results_count - 10
        $('.search-results').append '<a class="see-more white-btn" target="_blank" href="https://hunter.io/search/' + DOMPurify.sanitize(@domain) + '?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup">See all the results (' + DOMPurify.sanitize(Utilities.numberWithCommas(remaining_results)) + ' more)</a>'


    showResults: ->
      _this = @
      @results.slice(0,10).forEach (result) ->

        # Sources
        if result.sources.length == 1
          result.sources_link = "1 source"
        else if result.sources.length >= 20
          result.sources_link = "20+ sources"
        else
          result.sources_link = result.sources.length + " sources"

        # Confidence score color
        if result.confidence < 30
          result.confidence_score_class = "low-score"
        else if result.confidence > 70
          result.confidence_score_class = "high-score"
        else
          result.confidence_score_class = "average-score"

        # Save leads button
        unless _this.trial
          result.lead_button = "<button class='save_lead_button action_lead_button round' data-toggle='tooltip' data-placement='top' title='Save the lead'><i class='fas fa-plus'></i></button>"
        else
          result.lead_button = ""

        # If at least the first and last names are available, we're going to display it on the
        # page with all the other data
        if result.first_name != null && result.last_name != null
          result.additional_data = "<div class='additional-data'>"
          result.additional_data += "<span class='name'>" + DOMPurify.sanitize(result.first_name) + " " + DOMPurify.sanitize(result.last_name) + "</span>"

          if result.position != null
            result.additional_data += "<span class='position'>" + DOMPurify.sanitize(result.position) + "</span>"

          if result.linkedin != null
            result.additional_data += "<a class='fab fa-linkedin-square' href='" + DOMPurify.sanitize(result.linkedin) + "' target='_blank' rel='nofollow'></a>"

          if result.twitter != null
            result.additional_data += "<a class='fab fa-twitter-square' href='https://twitter.com/" + DOMPurify.sanitize(result.twitter) + "' target='_blank' rel='nofollow'></a>"

          if result.phone_number != null
            result.additional_data += "<span class='phone'>" + DOMPurify.sanitize(result.phone_number) + "</span>"

          result.additional_data += "</div>"

        else
          additional_data = ""

        Handlebars.registerHelper 'userDate', (options) ->
          new Handlebars.SafeString(Utilities.dateInWords(options.fn(this)))

        Handlebars.registerHelper 'ifIsVerified', (confidence, options) ->
          if confidence > 95
            return options.fn(this)
          options.inverse this

        # Integrate the result
        template = JST["src/browser_action/templates/search_results.hbs"]
        result_tag = $(template(result))
        $('.search-results').append(result_tag)

        # Add the lead's data
        save_lead_button = result_tag.find(".save_lead_button")
        save_lead_button.data
          email: result.value
        lead = new LeadButton
        lead.saveButtonListener(save_lead_button)
        lead.disableSaveLeadButtonIfLeadExists(save_lead_button)

        # Hide beautifully if the user is not logged
        result_tag.find('.email').html result_tag.find('.email').text().replace('**', '<span data-toggle="tooltip" data-placement="top" title="Please sign up to uncover the email addresses">aa</span>')

      @openSources()
      $(".search-results").show()
      $('[data-toggle="tooltip"]').tooltip()

      # For people not logged in, the copy and verification functions are not displayed
      if _this.trial
        $(".verification-link, .verification-result, .copy-status, .email-copied").remove()
      else
        @searchVerificationListener()
        Utilities.copyEmailListener()


    searchVerificationListener: ->
      _this = @
      $(".verification-link").unbind("click").click ->

        verification_link_tag = $(this)
        verification_result_tag = $(this).parent().find(".verification-result")

        verification_link_tag.remove()
        verification_result_tag.html("
          <div class='light-grey'>
            <i class='fas fa-spin fa-spinner-third'></i> Verifying...
          </div>").css({ display: "inline-block" })

        email = verification_link_tag.data("email");
        unless _this.trial
          url = 'https://api.hunter.io/v2/email-verifier?email=' + email + '&api_key=' + window.api_key
        else
          url = 'https://api.hunter.io/trial/v2/email-verifier?email=' + email

        # Launch the API call
        $.ajax
          url: url
          headers: 'Email-Hunter-Origin': 'chrome_extension'
          type: 'GET'
          data: format: 'json'
          dataType: 'json'
          jsonp: false
          error: (xhr, statusText, err) ->
            verification_result_tag.html("")
            verification_link_tag.show()

            if xhr.status == 400
              displayError 'Sorry, something went wrong on the query.'
            else if xhr.status == 401
              $('.connect-again-container').show()
            else if xhr.status == 403
              $('#domain-search').hide()
              $('#blocked-notification').show()
            else if xhr.status == 429
              unless _this.trial
                Account.returnRequestsError (e) ->
                  displayError e
              else
                $('.connect-container').show()
            else
              response = $.parseJSON(xhr.responseText)
              displayError DOMPurify.sanitize(response["errors"][0]["details"])


          success: (result, statusText, xhr) ->
            if xhr.status == 202
              verification_result_tag.html("
                <div class='dark-orange'>
                  <i class='fa fa-exclamation-triangle'></i>
                  <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to retry the verification'>Retry</a>
                </div>")
              displayError 'The email verification is taking longer than expected. Please try again later.'

            else
              if result.data.result == "deliverable"
                verification_result_tag.html("
                  <div class='green'>
                    <i class='fa fa-check'></i>
                    <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to see the complete check result'>Deliverable</a>
                  </div>")
              else if result.data.result == "risky"
                verification_result_tag.html("
                  <div class='dark-orange'>
                    <i class='fa fa-exclamation-triangle'></i>
                    <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to see the complete check result'>Risky</a>
                  </div>")
              else
                verification_result_tag.html("
                  <div class='red'>
                    <i class='fa fa-times'></i>
                    <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to see the complete check result'>Undeliverable</a>
                  </div>")

            # We remove the copy label since it can make the line too long
            verification_result_tag.parent().find(".copy-status").remove()

            # We update the number of requests
            _this.loadAccountInformation()


    openSources: ->
      $(".sources-link").unbind("click").click (e) ->
        if $(this).parent().parent().parent().find(".sources-list").is(":visible")
          $(this).parent().parent().parent().find(".sources-list").slideUp 300
          $(this).find(".fa-angle-up").removeClass("fa-angle-up").addClass("fa-angle-down")
        else
          $(this).parent().parent().parent().find(".sources-list").slideDown 300
          $(this).find(".fa-angle-down").removeClass("fa-angle-down").addClass("fa-angle-up")


    addPatternTitle: (pattern) ->
      pattern = pattern
        .replace('{first}', '<span data-toggle="tooltip" data-placement="top" title="First name">{first}</span>')
        .replace('{last}', '<span data-toggle="tooltip" data-placement="top" title="Last name">{last}</span>')
        .replace('{f}', '<span data-toggle="tooltip" data-placement="top" title="First name initial">{f}</span>')
        .replace('{l}', '<span data-toggle="tooltip" data-placement="top" title="Last name initial">{l}</span>')
      pattern




    loadAccountInformation: ->
      Account.get (json) ->
        if json == 'none'
          $('.account-loading').hide()
          $('.account-not-logged').show()
        else
          $('.account-loading').hide()
          $('.account-calls-used').text Utilities.numberWithCommas(json.data.calls.used)
          $('.account-calls-available').text Utilities.numberWithCommas(json.data.calls.available)
          $('.account-logged').show()


    feedbackNotification: ->
      chrome.storage.sync.get 'calls_count', (value) ->
        if value['calls_count'] >= 10
          chrome.storage.sync.get 'has_given_feedback', (value) ->
            if typeof value['has_given_feedback'] == 'undefined'
              $('.feedback-notification').slideDown 300

      # Ask to note the extension
      $('#open-rate-notification').click ->
        $('.feedback-notification').slideUp 300
        $('.rate-notification').slideDown 300

      # Ask to give use feedback
      $('#open-contact-notification').click ->
        $('.feedback-notification').slideUp 300
        $('.contact-notification').slideDown 300

      $('.feedback_link').click ->
        chrome.storage.sync.set 'has_given_feedback': true
  }


EmailFinder = ->
  {
    full_name: @full_name
    domain: @domain
    email: @email
    score: @score
    sources: @sources

    validateForm: ->
      _this = @
      $('#full-name-field').one 'keyup', (e) ->
        setTimeout (->
          if (
            $("#full-name-field").val().indexOf(" ") != -1 &&
            $("#full-name-field").val().length > 4
          )
            if (
              $(".email-finder-result-container").is(":hidden") &&
              $("#flash .alert-danger").length == 0 &&
              typeof $("#full-name-field").data("bs.tooltip") == "undefined"
            )
              $("#full-name-field").tooltip(title: "Press enter to find the email address.").tooltip("show")
        ), 6000

      $("#email-finder-search").unbind().submit ->
        if (
          $("#full-name-field").val().indexOf(" ") == -1 ||
          $("#full-name-field").val().length <= 4
        )
          $("#full-name-field").tooltip(title: "Please enter the full name of the person to find the email address.").tooltip("show")
        else
          _this.submit()

        false

    submit: ->
      $(".email-finder-loader").show()
      @domain = window.domain
      @full_name = $("#full-name-field").val()
      @fetch()

    fetch: ->
      @cleanFinderResults()

      if typeof $("#full-name-field").data("bs.tooltip") != "undefined"
        $("#full-name-field").tooltip("destroy")

      _this = @
      unless _this.trial
        url = 'https://api.hunter.io/v2/email-finder?domain=' + _this.domain + '&full_name=' + _this.full_name + '&api_key=' + window.api_key
      else
        url = 'https://api.hunter.io/trial/v2/email-finder?domain=' + _this.domain + '&full_name=' + _this.full_name

      $.ajax
        url: url
        headers: 'Email-Hunter-Origin': 'chrome_extension'
        type: 'GET'
        data: format: 'json'
        dataType: 'json'
        jsonp: false
        error: (xhr, statusText, err) ->
          $('.email-finder-loader').hide()

          if xhr.status == 400
            displayError 'Sorry, something went wrong on the query.'
          else if xhr.status == 401
            $('.connect-again-container').show()
          else if xhr.status == 403
            $('#domain-search').hide()
            $('#blocked-notification').show()
          else if xhr.status == 429
            unless _this.trial
              Account.returnRequestsError (e) ->
                displayError e
            else
              $('.connect-container').show()
          else
            response = $.parseJSON(xhr.responseText)
            displayError DOMPurify.sanitize(response["errors"][0]["details"])

        success: (result) ->
          if result.data.email == null
            $('.email-finder-loader').hide()
            displayError 'We didn\'t find the email address of this person.'
          else
            _this.domain = result.data.domain
            _this.email = result.data.email
            _this.score = result.data.score
            _this.position = result.data.position
            _this.company = result.data.company
            _this.twitter = result.data.twitter
            _this.linkedin = result.data.linkedin
            _this.sources = result.data.sources
            _this.first_name = Utilities.toTitleCase(result.data.first_name)
            _this.last_name = Utilities.toTitleCase(result.data.last_name)

            _this.render()

    render: ->
      $(".email-finder-loader").hide()

      # Confidence score color
      if @score < 30
        @confidence_score_class = "low-score"
      else if @score > 70
        @confidence_score_class = "high-score"
      else
        @confidence_score_class = "average-score"

      # The title of the profile
      if @position? && @company?
        @title = "#{@position} at #{@company}"
      else if @position?
        @title = "#{@position} at #{@domain}"
      else if @company?
        @title = @company
      else
        @title = @domain


      # Display: the method used
      if @sources.length > 0
        s = if @sources.length == 1 then "" else "s"
        @method = "We found this email address <strong>" + @sources.length + "</strong> time"+s+" on the web."
      else
        @method = "This is our best guess for this person. We haven't found this email on the web."

      # Prepare the template
      Handlebars.registerHelper 'ifIsVerified', (confidence, options) ->
        if confidence > 95
          return options.fn(this)
        options.inverse this

      Handlebars.registerHelper 'md5', (options) ->
        new Handlebars.SafeString(App.userDate(options.fn(this)))

      template = JST["src/browser_action/templates/email_finder.hbs"]
      finder_html = $(template(@))

      # Generate the DOM with the template and display it
      $(".email-finder-result-container").html finder_html
      $(".email-finder-result-container").slideDown 200

      # Display: the sources if any
      if @sources.length > 0
        $(".email-finder-result-sources").show()

      # Display: the tooltips
      $('[data-toggle="tooltip"]').tooltip()

      # Event: the copy action
      Utilities.copyEmailListener()

      # Display: the button to save the lead
      lead_button = $(".email-finder-result-email .save_lead_button")
      lead_button.data
        first_name: @first_name
        last_name: @last_name
        email: @email
        confidence_score: @score

      lead = new LeadButton
      lead.saveButtonListener(lead_button)
      lead.disableSaveLeadButtonIfLeadExists(lead_button)


    cleanFinderResults: ->
       $(".email-finder-result-container").html ""
       $(".email-finder-result-container").hide()

  }


LeadButton = ->
  {
    first_name: @first_name
    last_name: @last_name
    position: @position
    email: @email
    company: @organization
    website: window.domain
    source: "Hunter (Domain Search)"
    phone_number: @phone_number
    linkedin_url: @linkedin
    twitter: @twitter

    saveButtonListener: (selector) ->
      _this = this
      $(selector).unbind("click").click ->
        lead_button = $(this)
        lead = lead_button.data()

        lead_button.prop "disabled", true
        lead_button.find(".fas")
                   .removeClass("fa-plus")
                   .addClass("fa-spin fa-spinner-third")
        lead_button.tooltip("destroy")

        attributes = [
          'first_name'
          'last_name'
          'position'
          'email'
          'company'
          'website'
          'source'
          'phone_number'
          'linkedin_url'
          'twitter'
          'email'
        ]

        lead = {}
        attributes.forEach (attribute) ->
          if _this[attribute] == undefined
            lead[attribute] = lead_button.data(attribute)
          else
            lead[attribute] = _this[attribute]

        if window.current_leads_list_id
          lead['leads_list_id'] = window.current_leads_list_id

        _this.save(lead, lead_button)

    save: (lead, button) ->
      $.ajax
        url: 'https://api.hunter.io/v2/leads?api_key='+window.api_key
        headers: 'Email-Hunter-Origin': 'chrome_extension'
        type: 'POST'
        data: lead
        dataType: 'json'
        jsonp: false
        error: (xhr, statusText, err) ->
          button.find(".fas")
                .removeClass("fa-spin fa-spinner-third")
                .addClass("fa-times")
          button.find(".lead_status").text "Failed"
          displayError DOMPurify.sanitize(response["errors"][0]["details"])

        success: (response) ->
          button.css({'border': '2px solid #60ad1d'})
          button.find('.fas')
                .removeClass('fa-spin fa-spinner-third')
                .addClass('fa-check')
                .attr('Saved in your leads')
          button.find(".lead_status").text "Saved"

    disableSaveLeadButtonIfLeadExists: (selector) ->
      $(selector).each ->
        lead_button = $(this)
        lead = $(this).data()
        $.ajax
          url: 'https://api.hunter.io/v2/leads/exist?email='+lead.email+'&api_key='+window.api_key
          headers: 'Email-Hunter-Origin': 'chrome_extension'
          type: 'GET'
          data: format: 'json'
          dataType: 'json'
          jsonp: false
          success: (response) ->
            if response.data.id != null
              lead_button.find('.fas')
                         .removeClass('fa-plus')
                         .addClass('fa-check')
                         .attr('title', 'Saved in your leads')
              lead_button.find(".lead_status").text "Saved"
              lead_button.prop 'disabled', true
  }


ListSelection =
  appendSelector: ->
    _this = this
    _this.getLeadsLists (json) ->
      if json != 'none'
        $('.list_select_container').html '<select class="list_select"></select>'
        jQuery.each json.data.leads_lists, (i, val) ->
          if parseInt(window.current_leads_list_id) == parseInt(val.id)
            selected = 'selected="selected"'
          else
            selected = ''
          $('.list_select').append '<option '+selected+' value="'+val.id+'">'+val.name+'</option>'

        # If we notice the current list no longer exists, we take the first one
        if window.current_leads_list_id
          $('.view_list_link').attr 'href', 'https://hunter.io/leads?leads_list_id='+window.current_leads_list_id+'?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup'

        $('.list_select').append '<option value="new_list">Create a new list...</option>'

        _this.updateCurrent()

  updateCurrent: ->
    $('.list_select').on 'change', ->
      if $(this).val() == 'new_list'
        Utilities.openInNewTab 'https://hunter.io/leads_lists/new?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension'
      else
        chrome.storage.sync.set 'current_leads_list_id': $(this).val()
        window.current_leads_list_id = $(this).val()
        $('.view_list_link').attr 'href', 'https://hunter.io/leads?leads_list_id='+$(this).val()+'?utm_source=chrome_extension&utm_medium=extension&utm_campaign=extension&utm_content=browser_popup'


  getLeadsLists: (callback) ->
    Account.getApiKey (api_key) ->
      if api_key != ''
        url = 'https://api.hunter.io/v2/leads_lists?api_key='+api_key
        $.ajax
          url: url
          headers: 'Email-Hunter-Origin': 'chrome_extension'
          type: 'GET'
          dataType: 'json'
          jsonp: false
          success: (json) ->
            callback json
      else
        callback 'none'

displayError = (html) ->
  $('.error-message').html html
  $('.error-container').slideDown()
  setTimeout (->
    $('.error-container').slideUp()
    return
  ), 8000


# Prepare what will be diplayed depending on the current domain
# - If not on a domain name, we tell the user how it works
# - If on LinkedIn, we explain the feature is no longer available
# - Otherwise, we launch the Domain Search
#
chrome.tabs.query {
  active: true
  currentWindow: true
}, (tabs) ->

  Account.getApiKey (api_key) ->
    window.api_key = api_key

    window.domain = new URL(tabs[0].url).hostname.replace('www.', '')
    withoutSubDomain = Utilities.withoutSubDomain(window.domain)

    # We clean the subdomain
    if withoutSubDomain
      window.domain = withoutSubDomain

    # We display a special message on LinkedIn
    if window.domain == 'linkedin.com'
      $('#linkedin-notification').show()

    # We display a soft 404 if there is no domain name
    else if window.domain == '' or window.domain.indexOf('.') == -1
      $('#empty-notification').show()

    else
      # Launch the Domain Search
      $('#domain-search').show()
      domainSearch = new DomainSearch
      domainSearch.launch()

      # Get account information
      domainSearch.loadAccountInformation()

      chrome.storage.sync.get 'current_leads_list_id', (value) ->
        window.current_leads_list_id = value.current_leads_list_id
        ListSelection.appendSelector()
