# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  # content form logic
  # edit venue link logic
  $("#content_business_location_id").select2
    allowClear: true
  # hide and show based on whether a venue is selected
  $("#content_business_location_id").on 'change', ->
    val = $(this).select2('val')
    if val.length > 0
      $("#edit_venue_link").show()
      form_url = $("#edit_venue_link").data("formUrl")
      new_form_url = form_url.replace(/[0-9]+/, val)
      $("#edit_venue_link").data("formUrl", new_form_url)
    else
      $("#edit_venue_link").hide()

  $(".venue-link").on 'click', ->
    $("#embedded_business_location_form").load $(this).data('formUrl'), ->
      $("#embedded_business_location_form").show(200)
      $("#embedded_business_location_form").find("span.close").show()
        .on 'click', ->
          $("#embedded_business_location_form").html("").hide()

  # rather than write an extra view for this embedded form, we're overriding
  # the submit button's default action and submitting the fields via jQuery
  $(document).on 'click', '#embedded_business_location_form input[type="submit"]', (e) ->
    e.preventDefault()
    $.ajax $(this).data("submitUrl"),
      type: $(this).data("submitMethod")
      data: $("#embedded_business_location_form input[type!='submit']").serialize()
      success: ->
        $("#embedded_business_location_form").html("").hide()

  $(document).on 'click', '#locate_on_map_button', ->
    base_src_url = $("#confirm_location_map").data("baseSrcUrl")
    loc_string = ""
    if ($("#business_location_locate_include_name").prop('checked'))
      loc_string = loc_string + $("#business_location_name").val() + " "
    loc_string = loc_string +  $("#business_location_address").val()
    new_src = base_src_url.replace(/q=.*/, "q=" + loc_string)
    console.log new_src
    $("#confirm_location_map").attr("src", new_src)
