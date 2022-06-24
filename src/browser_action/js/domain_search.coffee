DomainSearch = ->
  {
    department_names: { executive: "Executive", it: "IT / Engineering", finance: "Finance", management: "Management", sales: "Sales", legal: "Legal", support: "Support", hr: "Human Resources", marketing: "Marketing", communication: "Communication" }

    launch: ->
      @domain = window.domain
      @trial = (typeof window.api_key == "undefined" || window.api_key == "")
      @fetch()

    fetch: () ->
      _this = @
      _this.cleanSearchResults()

      _this.department = _this.departmentFilter()

      $.ajax
        url: Api.domainSearch(_this.domain, _this.department, window.api_key)
        headers: "Email-Hunter-Origin": "chrome_extension"
        type: "GET"
        data: format: "json"
        dataType: "json"
        jsonp: false
        xhrFields:
          withCredentials: true
        error: (xhr) ->
          $("#loading-placeholder").hide()
          $("#domain-search").show()

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

          # Not logged in: we hide the Email Finder
          if _this.trial
            $("#full-name-field").hide()

          - unless _this.trial || _this.department || _this.results_count == 0
            _this.getDepartments()

          _this.render()

    getDepartments: ->
      _this = @
      $.ajax
        url: Api.emailCount(_this.domain)
        headers: "Email-Hunter-Origin": "chrome_extension"
        type: "GET"
        data: format: "json"
        dataType: "json"
        success: (result) ->
          # After sorting it will be an array of this form
          # [["executive", 5], ["hr", 3], ["it”, 1], ...]
          _this.departments = Utilities.sortObject(result.data.department)

          Handlebars.registerHelper "ifGreaterThanZero", (count, options) ->
            if count > 0
              return options.fn(this)
            options.inverse this

          Handlebars.registerHelper "departmentName", (options) ->
            new Handlebars.SafeString(_this.department_names[options.fn(this)])

          template = JST["src/browser_action/templates/departments.hbs"]
          departments_content = $(template(_this))
          $(".departments-container").html(departments_content)
          $(".departments-container").show()

          $(".more-departments-button").on "click", ->
            $(".departments-container div").css
              display: "inline-block"
            $(this).hide()

          _this.manageDepartmentFilters()


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
      $("#current-domain").text @domain

      # Display: complete search link or Sign up CTA
      unless @trial
        $("#domain-search .header-search-link").attr "href", "https://hunter.io/search/" + @domain + "?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=browser_popup"
        $("#domain-search .header-search-link").show()
      else
        $("#domain-search .header-signup-link").show()

      # Display: the number of results
      if @results_count == 1 then s = "" else s = "s"
      $("#domain-search .header-subtitle").html DOMPurify.sanitize(Utilities.numberWithCommas(@results_count)) + " result" + s + " for <strong>" + DOMPurify.sanitize(@domain) + "</strong>"

      # Display: the email pattern if any, with the Email Finder form
      if @pattern != null
        $(".people-search-container").show()
        $(".domain-pattern strong").html(@addPatternTitle(@pattern) + "@" + @domain)
        $("[data-toggle='tooltip']").tooltip()

        emailFinder = new EmailFinder
        emailFinder.validateForm()

      # Display: the updated number of requests
      loadAccountInformation()

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
        $(".search-results").append "<a class='see-more btn-white' target='_blank' href='https://hunter.io/search/" + DOMPurify.sanitize(@domain) + "?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=browser_popup'>See all the results (" + DOMPurify.sanitize(Utilities.numberWithCommas(remaining_results)) + " more) <i class='far fa-external-link'></i></a>"


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
          result.lead_button = "<button class='save-lead-button action-lead-button round' data-toggle='tooltip' data-placement='top' title='Save the lead'><i class='fas fa-plus'></i></button>"
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

        else if result.position != null
          result.additional_data = "<div class='additional-data no-entity'><span class='position'>" + DOMPurify.sanitize(result.position) + "</span></div>"

        else if result.department != null
          result.additional_data = "<div class='additional-data no-entity'><span class='department'>" + DOMPurify.sanitize(_this.department_names[result.department]) + "</span></div>"

        else
          result.additional_data = ""


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
        $(".verification-link, .verification-result, .copy-status, .email-copied").remove()
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

        verification_link_tag.remove()
        verification_result_tag.html("
          <div class='light-grey'>
            <i class='fas fa-spin fa-spinner-third'></i> Verifying...
          </div>").css({ display: "inline-block" })

        # Launch the API call
        $.ajax
          url: Api.emailVerifier(email, window.api_key)
          headers: "Email-Hunter-Origin": "chrome_extension"
          type: "GET"
          data: format: "json"
          dataType: "json"
          jsonp: false
          error: (xhr, statusText, err) ->
            verification_result_tag.html("")
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
              verification_result_tag.html("
                <div class='dark-orange'>
                  <i class='fa fa-exclamation-triangle'></i>
                  <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to retry the verification'>Retry</a>
                </div>")
              displayError 'The email verification is taking longer than expected. Please try again later.'

            else if xhr.status == 222
              verification_result_tag.html("")
              displayError DOMPurify.sanitize(result.errors[0].details)
              return

            else
              if result.data.status == "valid"
                verification_result_tag.html("
                  <div class='green'>
                    <i class='fas fa-check'></i>
                    <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to see the complete check result'>Valid</a>
                  </div>")
              else if result.data.status == "invalid"
                verification_result_tag.html("
                  <div class='red'>
                    <i class='fas fa-times'></i>
                    <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to see the complete check result'>Invalid</a>
                  </div>")
              else if result.data.status == "accept_all"
                verification_result_tag.html("
                  <div class='dark-orange'>
                    <i class='fas fa-exclamation-triangle'></i>
                    <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to see the complete check result'>Accept all</a>
                  </div>")
              else
                verification_result_tag.html("
                  <div class='light-grey'>
                    <i class='fas fa-question'></i>
                    <a href='https://hunter.io/verify/#{DOMPurify.sanitize(email)}' target='_blank' title='Click to see the complete check result'>Unknown/a>
                  </div>")

            # We remove the copy label since it can make the line too long
            verification_result_tag.parent().find(".copy-status").remove()

            # We update the number of requests
            loadAccountInformation()


    openSources: ->
      $(".sources-link").unbind("click").click (e) ->
        if $(this).parent().parent().parent().find(".sources-list").is(":visible")
          $(this).parent().parent().parent().find(".sources-list").slideUp 300
          $(this).find(".fa-angle-up").removeClass("fa-angle-up").addClass("fa-angle-down")
        else
          $(this).parent().parent().parent().find(".sources-list").slideDown 300
          $(this).find(".fa-angle-down").removeClass("fa-angle-down").addClass("fa-angle-up")


    manageDepartmentFilters: ->
      _this = @
      $(".department-filter").unbind().on "click", ->
        $(".department-label[data-department='" + $(this).data('department') + "']").css
          "display": "inline-block"
        $(".departments-container").hide()
        $("#departments-filters input[type='checkbox']").prop("checked", false)
        $("#departments-filters input[type='checkbox'][name='" + $(this).data("department") + "']").prop("checked", true)
        _this.fetch()

      $(".close-department").unbind().on "click", ->
        $(".department-label").hide()
        $("#departments-filters input[type='checkbox']").prop("checked", false)
        $(".departments-container").show()
        _this.fetch()

    typeFilter: ->
      value = $("#type-filter input[type='radio']:checked").val()
      if value == "all" then null else value

    departmentFilter: ->
      department = null
      $("#departments-filters input[type='checkbox']").each ->
        if $(this).is(":checked")
          department = $(this).attr("name")
          return false

      department


    addPatternTitle: (pattern) ->
      pattern = pattern
        .replace("{first}", "<span data-toggle='tooltip' data-placement='top' title='First name'>{first}</span>")
        .replace("{last}", "<span data-toggle='tooltip' data-placement='top' title='Last name'>{last}</span>")
        .replace("{f}", "<span data-toggle='tooltip' data-placement='top' title='First name initial'>{f}</span>")
        .replace("{l}", "<span data-toggle='tooltip' data-placement='top' title='Last name initial'>{l}</span>")
      pattern


    cleanSearchResults: ->
      $("#loading-placeholder").show()
      $(".search-results").html ""
      $(".people-search-container, .email-finder-results-container").hide()
      $(".departments").hide()
      $("li.department").css("display", "none")


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
