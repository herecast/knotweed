jQuery ->
  # datatables with only sortable
  $("table.sortable").dataTable
    "bPaginate": false
    "bLengthChange": false
    "bFilter": false
    "bSort": true
    "bInfo": false
