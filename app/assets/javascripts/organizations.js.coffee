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

  $(".add-new-field-link").on 'click', ->
    field_type = $(this).data("fieldType")
    val = $(this).next(".new-serialized-field").val()
    $(this).next(".new-serialized-field").val("")
    if val.length == 0
      return
    $(this).parent().nextAll(".serialized-field-header").after('
      <div class="row-fluid serialized-field-row">
        <div class="span2">
          <label for="' + val + '">' + val + '</label>
        </div>
        <div class="span6">
          <input class="span12" id="organization_'+ field_type + '_' + val + '" name="organization[' + field_type + '][' + val + ']" size="30" type="text" value="" />
        </div>
        <div class="span2">
          <div class="btn btn-danger remove-serialized-field">
            X
          </div>
        </div>
      </div>
    ')
  $(document).on 'click', '.remove-serialized-field', ->
    $(this).parents(".serialized-field-row").remove()


updateContentSetsSelect = ->
  $.ajax({
    url: $("#organizations_select").data("updateContentSetsUrl")
    data: {
      organization_id: $("#organizations_select").val()
    }
    dataType: "script"
  })
