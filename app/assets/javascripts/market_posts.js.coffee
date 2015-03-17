# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->

  $(document).on 'click', '#locate_address_button', ->
    base_src_url = $("#confirm_location_map").data("baseSrcUrl")
    loc_string = ""
    loc_string = loc_string +  $("#market_post_locate_address").val()
    new_src = base_src_url.replace(/q=.*/, "q=" + loc_string)
    console.log new_src
    $("#confirm_location_map").attr("src", new_src)
