# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $(document).on 'click', '.existing-fields-for-report_job_params span.close', ->
    $(this).next(".control-group").find("input.hidden").val(true) # set _delete field to true
    $(this).parent(".report-job-param").hide()

  $(document).on 'click', '.recipient-action-link', ->
    event.preventDefault()
    $('#report_job_recipient_form .modal-body').text('Loading...')
    $('#report_job_recipient_form').modal()
    $('.modal#report_job_recipient_form .modal-body').load $(this).data('formUrl'), ->
      Numerous.init()
      # I think we have to duplicate (almost) this code because those classes are actually
      # based on IDs that Numerous requires, and are on the same page here, so have to be
      # different
      $(document).on 'click', '.existing-fields-for-recipient_job_params span.close', ->
        $(this).next(".control-group").find("input.hidden").val(true) # set _delete field to true
        $(this).parent(".recipient-job-param").hide()

