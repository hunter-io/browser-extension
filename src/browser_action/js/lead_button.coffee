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
          "first_name"
          "last_name"
          "position"
          "email"
          "company"
          "website"
          "source"
          "phone_number"
          "linkedin_url"
          "twitter"
          "email"
        ]

        lead = {}
        attributes.forEach (attribute) ->
          if _this[attribute] == undefined
            lead[attribute] = lead_button.data(attribute)
          else
            lead[attribute] = _this[attribute]

        if window.current_leads_list_id
          lead["leads_list_id"] = window.current_leads_list_id

        _this.save(lead, lead_button)

    save: (lead, button) ->
      $.ajax
        url: Api.leads(api_key)
        headers: "Email-Hunter-Origin": "chrome_extension"
        type: "POST"
        data: lead
        dataType: "json"
        jsonp: false
        xhrFields:
          withCredentials: true
        error: (xhr, statusText, err) ->
          button.find(".fas")
                .removeClass("fa-spin fa-spinner-third")
                .addClass("fa-times")
          button.find(".lead-status").text "Failed"
          displayError DOMPurify.sanitize(xhr.responseJSON["errors"][0]["details"])

          if xhr.status == 422
            window.current_leads_list_id = undefined

        success: (response) ->
          button.css({"border": "2px solid #60ad1d"})
          button.find(".fas")
                .removeClass("fa-spin fa-spinner-third")
                .addClass("fa-check")
                .attr("Saved in your leads")
          button.find(".lead-status").text "Saved"

    disableSaveLeadButtonIfLeadExists: (selector) ->
      $(selector).each ->
        lead_button = $(this)
        lead = $(this).data()
        $.ajax
          url: Api.leadsExist(lead.email, window.api_key)
          headers: "Email-Hunter-Origin": "chrome_extension"
          type: "GET"
          data: format: "json"
          dataType: "json"
          jsonp: false
          xhrFields:
            withCredentials: true
          success: (response) ->
            if response.data.id != null
              lead_button.find(".fas")
                         .removeClass("fa-plus")
                         .addClass("fa-check")
                         .attr("title", "Saved in your leads")
              lead_button.find(".lead-status").text "Saved"
              lead_button.prop "disabled", true
  }
