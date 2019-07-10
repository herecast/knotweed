# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  # hide and show based on whether a venue is selected
  $("#event_venue_id").on 'change', ->
    val = $(this).val()
    if val.length > 0
      $("#edit_venue_link").show()
      form_url = $("#edit_venue_link").data("formUrl")
      new_form_url = form_url.replace(/[0-9]+/, val)
      $("#edit_venue_link").data("formUrl", new_form_url)
    else
      $("#edit_venue_link").hide()

  $(document).on 'click', '#locate_on_map_button', ->
    base_src_url = $("#confirm_location_map").data("baseSrcUrl")
    loc_string = ""
    if ($("#business_location_locate_include_name").prop('checked'))
      loc_string = loc_string + $("#business_location_name").val() + " "
    # this is used on both business_location forms and on business_profile forms
    if $('#business_location_address').length > 0
      loc_string += $("#business_location_address").val()
      loc_string += ' ' + $("#business_location_city").val()
      loc_string += ' ' + $("#business_location_state").val()
      loc_string += ' ' + $("#business_location_zip").val()
    else # then we're on biz profile
      loc_string += ' ' + $('#business_profile_business_location_attributes_address').val()
      loc_string += ' ' + $('#business_profile_business_location_attributes_city').val()
      loc_string += ' ' + $('#business_profile_business_location_attributes_state').val()
      loc_string += ' ' + $('#business_profile_business_location_attributes_zip').val()

    new_src = base_src_url.replace(/q=.*/, "q=" + loc_string)
    console.log new_src
    $("#confirm_location_map").attr("src", new_src)
