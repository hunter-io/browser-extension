DomainSearch = ->
  {
    # Used to display full department names
    department_names: {
      executive: "Executive",
      it: "IT / Engineering",
      finance: "Finance",
      management: "Management",
      sales: "Sales",
      legal: "Legal",
      support: "Support",
      hr: "Human Resources",
      marketing: "Marketing",
      communication: "Communication",
      education: "Education",
      design: "Arts & Design",
      health: "Medical & Health",
      operations: "Operations & Logistics"
    }

    launch: ->
      @domain = window.domain
      @trial = (typeof window.api_key == "undefined" || window.api_key == "")
      @fetch()

    fetch: () ->
      _this = @
      _this.cleanSearchResults()

      _this.department = _this.departmentFilter()
      _this.type = _this.typeFilter()

      if _this.department or _this.type
        $('.filters__clear').show()
      else
        $('.filters__clear').hide()

      $.ajax
        url: Api.domainSearch(_this.domain, _this.department, _this.type, window.api_key)
        headers: "Email-Hunter-Origin": "chrome_extension"
        type: "GET"
        data: format: "json"
        dataType: "json"
        jsonp: false
        error: (xhr) ->
          $("#loading-placeholder").hide()
          $("#domain-search").show()
          $(".filters").css("visibility", "hidden")

          if xhr.status == 400
            displayError "Sorry, something went wrong with the query."
          else if xhr.status == 401
            $(".connect-again-container").show()
          else if xhr.status == 403
            $("#blocked-notification").show()
          else if xhr.status == 429
            unless _this.trial
              Account.returnRequestsError (e) ->
                displayError e
            else
              $(".connect-container").show()
          else
            displayError DOMPurify.sanitize(xhr.responseJSON["errors"][0]["details"])

        success: (result) ->
          _this.webmail = result.data.webmail
          _this.pattern = result.data.pattern
          _this.accept_all = result.data.accept_all
          _this.verification = result.data.verification
          _this.organization = result.data.organization
          _this.results = result.data.emails
          _this.results_count = result.meta.results
          _this.offset = result.meta.offset
          _this.type = result.meta.params.type

          $("#loading-placeholder").hide()
          $("#domain-search").show()
          $(".filters").removeAttr("style")

          # Not logged in: we hide the Email Finder
          if _this.trial
            $(".filters__by-name").hide()
            $(".find-by-name").hide()

          _this.manageFilters()
          _this.clearFilters()
          _this.render()

    render: ->
      # Is webmail -> STOP
      if @webmail == true
        $("#domain-search").addClass("ds-no-results")
        $(".webmail-container .domain").text @domain
        $(".webmail-container").show()
        return

      # No results -> STOP
      if @results_count == 0
        if @type or @department
          $(".no-result-with-filters-container").show()
        else
          $("#domain-search").addClass("ds-no-results")
          $(".no-result-container .domain").text @domain
          $(".no-result-container").show()

        return

      # Display: the current domain
      $("#current-domain").text @domain

      # Remove "no-results" class
      $("#domain-search").removeClass("ds-no-results")

      # Activate dropdown
      $("[data-toggle='dropdown']").dropdown()

      # Display: complete search link or Sign up CTA
      unless @trial
        $(".header-search-link").attr "href", "https://hunter.io/search/" + @domain + "?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=browser_popup"
        $(".header-search-link").show()

      # Display: the number of results
      if @results_count == 1 then s = "" else s = "s"
      $("#domain-search .results-header__count").html DOMPurify.sanitize(Utilities.numberWithCommas(@results_count)) + " result" + s + " for <strong>" + DOMPurify.sanitize(@domain) + "</strong>"

      # Display: the email pattern if any, with the Email Finder form
      if @pattern != null
        $(".filters__by-name").show()
        $(".results-header__pattern").show()
        $(".results-header__pattern strong").html(@addPatternTitle(@pattern) + "@" + @domain)
        $("[data-toggle='tooltip']").tooltip()

        # Email Finder
        $(".ds-finder-form-company__name").text @organization
        $(".ds-finder-form-company__domain").text @domain
        $(".ds-finder-form-company__logo").attr "src", "https://logo.clearbit.com/" + @domain
        @openFindbyName()
        emailFinder = new EmailFinder
        emailFinder.validateForm()

      # Display: the updated number of requests
      loadAccountInformation()

      # We count call to measure use
      countCall()
      @feedbackNotification()

      # Display: the results
      @showResults()

      # Render: set again an auto height on html
      $("html").css
        height: "auto"

      # Display: link to see more
      if @results_count > 10
        remaining_results = @results_count - 10
        $(".search-results").append "<a class='see-more h-button h-button--sm' target='_blank' href='https://hunter.io/search/" + DOMPurify.sanitize(@domain) + "?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=browser_popup'>See all the results (" + DOMPurify.sanitize(Utilities.numberWithCommas(remaining_results)) + " more)</a>"


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
        else if result.confidence >= 70
          result.confidence_score_class = "high-score"
        else
          result.confidence_score_class = "average-score"

        # Save leads button
        unless _this.trial
          result.lead_button = "<button class='ds-result__save h-button h-button--sm save-lead-button' type='button'>Save</button>"
        else
          result.lead_button = ""

        # Full name
        if result.first_name != null && result.last_name != null
          result.full_name = DOMPurify.sanitize(result.first_name) + " " + DOMPurify.sanitize(result.last_name)

        if result.department
          result.department = DOMPurify.sanitize(_this.department_names[result.department])


        Handlebars.registerHelper "userDate", (options) ->
          new Handlebars.SafeString(Utilities.dateInWords(options.fn(this)))

        Handlebars.registerHelper "ifIsVerified", (verification_status, options) ->
          if verification_status == "valid"
            return options.fn(this)
          options.inverse this

        Handlebars.registerHelper "ifIsAcceptAll", (options) ->
          if _this.accept_all
            return options.fn(this)
          options.inverse this

        # Integrate the result
        template = JST["src/browser_action/templates/search_results.hbs"]
        result_tag = $(template(result))
        $(".search-results").append(result_tag)

        # Add the lead's data
        save_lead_button = result_tag.find(".save-lead-button")
        save_lead_button.data
          email: result.value
        lead = new LeadButton
        lead.saveButtonListener(save_lead_button)
        lead.disableSaveLeadButtonIfLeadExists(save_lead_button)

        # Hide beautifully if the user is not logged
        result_tag.find(".email").html result_tag.find(".email").text().replace("**", "<span data-toggle='tooltip' data-placement='top' title='Please sign up to uncover the email addresses'>aa</span>")

      @openSources()
      $(".search-results").show()
      $("[data-toggle='tooltip']").tooltip()

      # For people not logged in, the copy and verification functions are not displayed
      if _this.trial
        $(".ds-result__verification").remove()
      else
        @searchVerificationListener()
        Utilities.copyEmailListener()


    searchVerificationListener: ->
      _this = @
      $(".verification-link").unbind("click").click ->

        verification_link_tag = $(this)
        verification_result_tag = $(this).parent().find(".verification-result")

        email = verification_link_tag.data("email")

        return if !email

        verification_link_tag.html("<i class='far fa-spin fa-spinner-third'></i> Verifying…</div>")
        verification_link_tag.attr("disabled", "true")

        # Launch the API call
        $.ajax
          url: Api.emailVerifier(email, window.api_key)
          headers: "Email-Hunter-Origin": "chrome_extension"
          type: "GET"
          data: format: "json"
          dataType: "json"
          jsonp: false
          error: (xhr, statusText, err) ->
            verification_link_tag.removeAttr("disabled")
            verification_link_tag.show()

            if xhr.status == 400
              displayError "Sorry, something went wrong with the query."
            else if xhr.status == 401
              $(".connect-again-container").show()
            else if xhr.status == 403
              $("#domain-search").hide()
              $("#blocked-notification").show()
            else if xhr.status == 429
              unless _this.trial
                Account.returnRequestsError (e) ->
                  displayError e
              else
                $(".connect-container").show()
            else
              displayError DOMPurify.sanitize(xhr.responseJSON["errors"][0]["details"])


          success: (result, statusText, xhr) ->
            if xhr.status == 202
              verification_link_tag.removeAttr("disabled")
              verification_link_tag.html("<span class='fa fa-exclamation-triangle'></span> Retry")
              displayError 'The email verification is taking longer than expected. Please try again later.'

            else if xhr.status == 222
              verification_link_tag.removeAttr("disabled")
              verification_link_tag.html("<span class='fa fa-exclamation-triangle'></span> Retry")
              displayError DOMPurify.sanitize(result.errors[0].details)
              return

            else
              verification_link_tag.remove()

              if result.data.status == "valid"
                verification_result_tag.html("
                  <span class='tag tag--success' data-toggle='tooltip' data-placement='top' title='Valid'>
                    <span class='tag__label'>
                      <i aria-hidden='true' class='tag__icon fas fa-shield-check'></i>
                      " + result.data.score + "%
                    </span>
                  </span>")
              else if result.data.status == "invalid"
                verification_result_tag.html("
                  <span class='tag tag--danger' data-toggle='tooltip' data-placement='top' title='Invalid'>
                    <span class='tag__label'>
                      <i aria-hidden='true' class='tag__icon fas fa-shield-xmark'></i>
                      " + result.data.score + "%
                    </span>
                  </span>")
              else if result.data.status == "accept_all"
                verification_result_tag.html("
                  <span class='tag tag--warning' data-toggle='tooltip' data-placement='top' title='Accept All'>
                    <span class='tag__label'>
                      <i aria-hidden='true' class='tag__icon fas fa-shield-check'></i>
                      " + result.data.score + "%
                    </span>
                  </span>")
              else
                verification_result_tag.html("
                  <span class='tag' data-toggle='tooltip' data-placement='top' title='Unknown'>
                    <span class='tag__label'>
                      <i aria-hidden='true' class='tag__icon fas fa-shield-slash'></i>
                      " + result.data.score + "%
                    </span>
                  </span>")

            # We update the number of requests
            loadAccountInformation()


    openSources: ->
      $(".sources-link").unbind("click").click (e) ->
        if $(this).parents(".ds-result").find(".ds-result__sources").is(":visible")
          $(this).parents(".ds-result").find(".ds-result__sources").slideUp 300
          $(this).find(".fa-angle-up").removeClass("fa-angle-up").addClass("fa-angle-down")
        else
          $(this).parents(".ds-result").find(".ds-result__sources").slideDown 300
          $(this).find(".fa-angle-down").removeClass("fa-angle-down").addClass("fa-angle-up")

    openFindbyName: ->
      $(".filters__by-name").unbind("click").click (e) ->
        if $("#find-by-name").is(":visible")
          $(this).attr "aria-expanded", "false"
          $("#find-by-name").hide()
        else
          $(this).attr "aria-expanded", "true"
          $("#find-by-name").show()
          $("#full-name-field").focus()


    manageFilters: ->
      _this = @
      $(document).on 'click', '.dropdown .dropdown-menu', (e) ->
        e.stopPropagation()

      $('.apply-filters').unbind().on "click", ->
        checked = $(this).parent().find('[type="checkbox"]:checked, [type="radio"]:checked')
        checkedCount = checked.length
        dropdownContainer = $(this).parents(".dropdown")

        dropdownContainer.removeClass("open")
        dropdownContainer.find('.h-button[data-toggle]').attr("aria-expanded", "false")

        if checkedCount > 0
          dropdownContainer.find('.h-button[data-toggle]').attr("data-selected-filters", checkedCount)
        else
          dropdownContainer.find('.h-button[data-toggle]').removeAttr("data-selected-filters")

        _this.fetch()

    typeFilter: ->
      value = $("#type-filters [type='radio']:checked").val()

    departmentFilter: ->
      department = null
      $("#departments-filters [type='checkbox']").each ->
        if $(this).is(":checked")
          department = $(this).val()
          return false

      department

    clearFilters: ->
      _this = @
      $(".clear-filters").unbind().on "click", ->
        $('.filters').find('[type="checkbox"]:checked, [type="radio"]:checked').each ->
          $(this).prop("checked", false)

        $('.filters [data-selected-filters]').removeAttr("data-selected-filters")
        _this.fetch()


    addPatternTitle: (pattern) ->
      pattern = pattern
        .replace("{first}", "<abbr data-toggle='tooltip' data-placement='top' title='First name'>{first}</abbr>")
        .replace("{last}", "<abbr data-toggle='tooltip' data-placement='top' title='Last name'>{last}</abbr>")
        .replace("{f}", "<abbr data-toggle='tooltip' data-placement='top' title='First name initial'>{f}</abbr>")
        .replace("{l}", "<abbr data-toggle='tooltip' data-placement='top' title='Last name initial'>{l}</abbr>")
      pattern


    cleanSearchResults: ->
      $("#loading-placeholder").show()
      $(".search-results").html ""
      $(".no-result-with-filters-container").hide()


    feedbackNotification: ->
      chrome.storage.sync.get "calls_count", (value) ->
        if value["calls_count"] >= 20
          chrome.storage.sync.get "has_given_feedback", (value) ->
            if typeof value["has_given_feedback"] == "undefined"
              $(".feedback-notification").slideDown 300

      # Ask to note the extension
      $("#open-rate-notification").click ->
        $(".feedback-notification").slideUp 300
        $(".rate-notification").slideDown 300

      # Ask to give use feedback
      $("#open-contact-notification").click ->
        $(".feedback-notification").slideUp 300
        $(".contact-notification").slideDown 300

      $(".feedback-link").click ->
        chrome.storage.sync.set "has_given_feedback": true
  }
