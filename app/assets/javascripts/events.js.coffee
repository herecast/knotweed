# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('form.event-form').on 'click', '.remove_fields', (event) ->
    confirm('Delete this event instance?')
    if confirm
      $(this).prev('input[type=hidden]').val('1')
      $(this).closest('fieldset').hide()
      event.preventDefault()

  $('form.event-form').on 'click', '.add_fields', (event) ->
    time = new Date().getTime()
    regexp = new RegExp($(this).data('id'), 'g')
    $(this).before($(this).data('fields').replace(regexp, time))
    event.preventDefault()
    $(".datetimepicker").datetimepicker();
    $(".datepicker").datetimepicker({pickTime: false});
    $(".timepicker").datetimepicker({ pickDate: false });
  
