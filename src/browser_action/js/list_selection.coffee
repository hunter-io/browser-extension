ListSelection =
  appendSelector: ->
    _this = this
    _this.getLeadsLists (json) ->
      if json != "none"
        $(".list-select-container").append "<select id='leads-list' class='leads-manager__list h-select h-select--sm'></select>"

        # We determine the selected list
        if window.current_leads_list_id
          selected_list_id = window.current_leads_list_id
        else
          selected_list_id = json.data.leads_lists[0].id

        # We add all the lists in the select field
        json.data.leads_lists.forEach (val, i) ->
          if parseInt(selected_list_id) == parseInt(val.id)
            selected = "selected='selected'"
          else
            selected = ""
          $(".leads-manager__list").append "<option "+selected+" value='"+val.id+"'>"+val.name+"</option>"

        # We add a link to the current list
        $(".leads-manager__link").attr "href", "https://hunter.io/leads?leads_list_id=" + selected_list_id + "&utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=browser_popup"
        $(".leads-manager__list").append "<option value='new_list'>" + chrome.i18n.getMessage("create_a_new_list") + "...</option>"

        _this.updateCurrent()

  updateCurrent: ->
    $(".leads-manager__list").on "change", ->
      if $(this).val() == "new_list"
        Utilities.openInNewTab "https://hunter.io/leads-lists/new?utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension"
      else
        chrome.storage.sync.set "current_leads_list_id": $(this).val()
        window.current_leads_list_id = $(this).val()
        $(".leads-manager__link").attr "href", "https://hunter.io/leads?leads_list_id="+$(this).val()+"&utm_source=chrome_extension&utm_medium=chrome_extension&utm_campaign=extension&utm_content=browser_popup"

  getLeadsLists: (callback) ->
    Account.getApiKey (api_key) ->
      if api_key != ""
        $.ajax
          url: Api.leadsList(window.api_key)
          headers: "Email-Hunter-Origin": "chrome_extension"
          type: "GET"
          dataType: "json"
          jsonp: false
          success: (json) ->
            callback json
      else
        callback "none"
