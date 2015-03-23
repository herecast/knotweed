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

  # validate we have a title and a description
  $(".btn.btn-primary.mp_submit").on 'click', (event) -> validateMarketPost(event)
  $(".btn.btn-success.mp_submit_continue").on 'click', (event) -> validateMarketPost(event)
  $(".btn.btn-success.mp_submit_next").on 'click', (event) -> validateMarketPost(event)
  $(".btn.btn-success.mp_submit_new").on 'click', (event) -> validateMarketPost(event)

validateMarketPost = (event) ->
  validated = true
  if $("#market_post_content_attributes_title").val().length == 0
    $(".string.required.control-label").addClass("text-red")
    validated =false

  if CKEDITOR.instances.market_post_content_attributes_raw_content.getData().length == 0
    $(".text.required.control-label").addClass("text-red")
    validated = false

  if !validated
    event.preventDefault()
    $("html,body").animate { scrollTop: $(".string.required.control-label").offset().top }, 500
    return false
