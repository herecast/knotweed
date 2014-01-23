jQuery ->
  $("#organizations_select").on 'change', ->
    updateContentSetsSelect()

updateContentSetsSelect = ->
  $.ajax({
    url: $("#organizations_select").data("updateContentSetsUrl")
    data: {
      organization_id: $("#organizations_select").val()
    }
    dataType: "script"
  })
