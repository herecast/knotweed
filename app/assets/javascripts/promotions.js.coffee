# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
jQuery ->
  $(".create-new-promotion").on 'click', ->
    url = $(this).data("submitUrl")
    data = $(this).parent().prev(".form-inputs").find("input, textarea").serialize()
    $.post(url, data, (data, textStatus, jqXHR) -> alert("success!" + data))

  $("#promotion_promotable_attributes_banner_image").on 'change', ->
    reader = new FileReader()
    input = document.getElementById('promotion_promotable_attributes_banner_image')
    $current = $('#promotion-current-banner-image')
    if $current.length > 0
      handle = (e) -> $current.attr('src', e.target.result)
      reader.onload = handle
      reader.readAsDataURL(input.files[0])
    else
      $el = $('#promotion-preview-image')
      handle = (e) -> $el.attr('src', e.target.result)
      reader.onload = handle
      reader.readAsDataURL(input.files[0])