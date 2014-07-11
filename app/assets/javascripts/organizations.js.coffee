# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $("#organizations_select").on 'change', ->
    updateContentSetsSelect()

  # add new business location
  $("#new_business_location_button").on 'click', ->
    $(".modal#business_location_form .modal-body").load($(this).data("formUrl"))
  # edit existing location
  $(document).on 'click', '.edit-business-location-link', ->
    $(".modal#business_location_form .modal-body").load($(this).data("formUrl"))

updateContentSetsSelect = ->
  $.ajax({
    url: $("#organizations_select").data("updateContentSetsUrl")
    data: {
      organization_id: $("#organizations_select").val()
    }
    dataType: "script"
  })
