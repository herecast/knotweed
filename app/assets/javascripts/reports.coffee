jQuery ->
  $(document).on 'click', '.existing-fields-for-report_params span.close', ->
    $(this).next(".control-group").find("input.hidden").val(true) # set _delete field to true
    $(this).parent(".report-param").hide()

  $(document).on 'click', '.recipient-action-link', ->
    event.preventDefault()
    $('#report_recipient_form .modal-body').text('Loading...')
    $('#report_recipient_form').modal()
    $('.modal#report_recipient_form .modal-body').load $(this).data('formUrl')
