# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

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
