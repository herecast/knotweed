# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/


jQuery ->
  $(document).on 'change', "#annotation_form select#accepted", ->
    $.ajax $(this).data("actionUrl") + "/" + $(this).val(),
      dataType: "script"
