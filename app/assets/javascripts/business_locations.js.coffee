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

  $(".venue-link").on 'click', ->
    $("#embedded_business_location_form").load $(this).data('formUrl'), ->
      $("#embedded_business_location_form").show(200)
      # so, the original form view that we're loading here uses "remote: true" rails UJS
      # the catch is that since this form is rendered inside another form element,
      # the browser removes the actual form tag, and then things get really wonky.
      # the solution I'm going with is to unbind all click events from the submit button
      # once we're done loading the form (which removes rails UJS bindings),
      # then rebind the custom submit method we want on this particular incarnation.
      $('#embedded_business_location_form input[type="submit"]').unbind('click')
      # rather than write an extra view for this embedded form, we're overriding
      # the submit button's default action and submitting the fields via jQuery
      $('#embedded_business_location_form input[type="submit"]').on 'click', (e) ->
        e.preventDefault()
        $.ajax $(this).data("submitUrl"),
          type: $(this).data("submitMethod")
          data: $("#embedded_business_location_form").find("input, select").serialize()
          beforeSend: ->
            $('#embedded_business_location_form input[type="submit"]').attr('disabled', 'disabled')
            $('#embedded_business_location_form').spin()
          error: ->
            $('#embedded_business_location_form input[type="submit"]').attr('disabled', '')
            $('#embedded_business_location_form').spin(false)
          success: ->
            $("#embedded_business_location_form").html("").hide()
      $("#embedded_business_location_form").find("span.close").show()
        .on 'click', ->
          $("#embedded_business_location_form").html("").hide()

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
