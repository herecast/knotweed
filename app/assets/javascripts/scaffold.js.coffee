jQuery ->
  # datatables with only sortable
  $("table.sortable").dataTable
    "bPaginate": false
    "bLengthChange": false
    "bFilter": false
    "bSort": true
    "bInfo": false

  # may want to change this in the future, but for now:
  # any form submit button inside a modal should close the modal
  $(document).on "ajax:success", "form", ->
    $(this).parents(".modal").modal("hide")
    
  # our users keep submitting forms multiple times by clicking and clicking,
  # so we need to do this across the board.
  $('form').submit (event)->
    $(this).find("input[type='submit']").attr("disabled", "disabled")
    # I'm not really sure how best to handle this, since we can't reliably predict
    # when each callback attached to submit is running. The problem is that we have other
    # callback functions that prevent submit if validation fails, or similar,
    # so we need to check if the form submission was prevented.
    window.setTimeout (event)->
      if event.isDefaultPrevented()
        $('form').find("input[type='submit']").attr('disabled', '')
    , 2000, event
