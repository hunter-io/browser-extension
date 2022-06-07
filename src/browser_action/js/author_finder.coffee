AuthorFinder = ->
  {
    launch: ->
      @url = window.url
      @trial = (typeof window.api_key == "undefined" || window.api_key == "")
      @fetch()

    fetch: ->
      # @cleanFinderResults()

      _this = @
      $.ajax
        url: Api.authorFinder(_this.url, 3, window.api_key)
        headers: "Email-Hunter-Origin": "chrome_extension"
        type: "GET"
        data: format: "json"
        dataType: "json"
        jsonp: false
        error: (xhr, statusText, err) ->
          # If any error occurs, we move to the Domain Search logic. If there
          # are issues with the account, it will be managed from there.
          _this.switchToDomainSearch()

        success: (result) ->
          if result.data.email == null
            # If we coulnd't find the author's email address, we display
            # the Domain Search instead
            _this.switchToDomainSearch()
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
      $("#loading-placeholder").hide()
      $("#author-finder").show()

      # Display: complete search link or Sign up CTA
      unless @trial
        $("#author-finder .header-search-link").html("See " + DOMPurify.sanitize(@domain) + " email addresses")

        _this = this
        $("#author-finder .header-search-link").unbind("click").click ->
          _this.switchToDomainSearch()

        $("#author-finder .header-search-link").show()
      else
        $("#author-finder .header-signup-link").show()

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
      $("#author-finder .finder-result").html finder_html
      $("#author-finder").show()

      # Display: the sources if any
      if @sources.length > 0
        $("#author-finder .finder-result-sources").show()

      # Display: the tooltips
      $("[data-toggle='tooltip']").tooltip()

      # Event: the copy action
      Utilities.copyEmailListener()

      $("#author-finder .finder-result-pic img").on "load", ->
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

    switchToDomainSearch: ->
      $("#author-finder").hide()
      $("#author-finder .finder-result").html ""

      domainSearch = new DomainSearch
      domainSearch.launch()
  }
