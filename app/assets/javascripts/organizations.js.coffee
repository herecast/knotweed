# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('.archive-checkbox').on 'click', ->
    $(this).parent().submit()

  $('#images .image-container input[type="file"]').on 'change', ->
    parent_container = $(this).parents('.image-container')
    reader = new FileReader()
    reader.onload = (e) ->
      parent_container.find("img").attr('src',e.target.result)
    reader.readAsDataURL(this.files[0])

  $('#images .image-container input[type="checkbox"]').on 'change', ->
    parent_container = $(this).parents('.image-container')
    if $(this).is(':checked')
      parent_container.find("img").hide()
    else
      parent_container.find("img").show()

  # add new business location
  $("#new_business_location_button").on 'click', ->
    event.preventDefault()
    $("#business_location_form").modal()
    $(".modal#business_location_form .modal-body").load $(this).data("formUrl"), ->
      $(".modal-body").find(".chosen-select").chosen()
      prepHoursInterface()
  # edit existing location
  $(document).on 'click', '.edit-business-location-link', ->
    event.preventDefault()
    $('#business_location_form').modal()
    $(".modal#business_location_form .modal-body").load $(this).data("formUrl"), ->
      $(".modal-body").find(".chosen-select").chosen()
      prepHoursInterface()


prepHoursInterface = () ->
  $('.add-hours-link-organizations').on 'click', ->
    $('#business_location_hours').append '
      <div class="row-fluid">
        <div class="span6">
          <input class="span12" id="business_location_hours"
           name="business_location[hours][]" value="" />
        </div>
        <div class="span2 offset4">
          <div class="btn btn-danger remove-hours-field">
            X
          </div>
        </div>
      </div>'
  $(document).on 'click', '.remove-hours-field', ->
    $(this).parents('.row-fluid').first().remove()
