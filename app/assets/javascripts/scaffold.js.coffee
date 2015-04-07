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
