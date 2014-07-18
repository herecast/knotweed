# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
jQuery ->
  $(".create-new-promotion").on 'click', ->
    url = $(this).data("submitUrl")
    data = $(this).parent().prev(".form-inputs").find("input, textarea").serialize()
    $.post(url, data, (data, textStatus, jqXHR) -> alert("success!" + data))
