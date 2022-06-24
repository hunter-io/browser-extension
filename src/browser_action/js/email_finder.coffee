EmailFinder = ->
  {
    full_name: @full_name
    domain: @domain
    email: @email
    score: @score
    sources: @sources

    validateForm: ->
      _this = @
      $("#full-name-field").one "keyup", (e) ->
        setTimeout (->
          if (
            $("#full-name-field").val().indexOf(" ") != -1 &&
            $("#full-name-field").val().length > 4
          )
            if (
              $("#email-finder").is(":hidden") &&
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
      $.ajax
        url: Api.emailFinder(_this.domain, _this.full_name, window.api_key)
        headers: "Email-Hunter-Origin": "chrome_extension"
        type: "GET"
        data: format: "json"
        dataType: "json"
        jsonp: false
        xhrFields:
          withCredentials: true
        error: (xhr, statusText, err) ->
          $(".email-finder-loader").hide()

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

        success: (result) ->
          if result.data.email == null
            $(".email-finder-loader").hide()
            displayError "We didn't find the email address of this person."
          else
            _this.domain = result.data.domain
            _this.email = result.data.email
            _this.score = result.data.score
            _this.accept_all = result.data.accept_all
            _this.verification = result.data.verification
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

      # Display: complete search link or Sign up CTA
      unless @trial
        $(".header-search-link").attr "href", "https://hunter.io/search/" + @domain + "?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=browser_popup"
        $(".header-search-link").show()
      else
        $(".header-signup-link").show()

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
        @method = "This email address is our best guess for this person. We haven't found it on the web."

      # Prepare the template
      Handlebars.registerHelper "ifIsVerified", (verification_status, options) ->
        if verification_status == "valid"
          return options.fn(this)
        options.inverse this

      Handlebars.registerHelper "md5", (options) ->
        new Handlebars.SafeString(Utilities.MD5(options.fn(this)))

      template = JST["src/browser_action/templates/finder.hbs"]
      finder_html = $(template(@))

      # Generate the DOM with the template and display it
      $("#email-finder").html finder_html
      $("#email-finder").slideDown 200

      # Display: the sources if any
      if @sources.length > 0
        $(".finder-result-sources").show()

      # Display: the tooltips
      $("[data-toggle='tooltip']").tooltip()

      # Event: the copy action
      Utilities.copyEmailListener()

      $(".finder-result-pic img").on "load", ->
        $(this).css "opacity", "1"

      # Display: the button to save the lead
      lead_button = $(".finder-result-email .save-lead-button")
      lead_button.data
        first_name: @first_name
        last_name: @last_name
        email: @email
        confidence_score: @score

      lead = new LeadButton
      lead.saveButtonListener(lead_button)
      lead.disableSaveLeadButtonIfLeadExists(lead_button)

    cleanFinderResults: ->
       $("#email-finder").html ""
       $("#email-finder").hide()
  }
