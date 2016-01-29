jQuery ->
  # if the user has selected a 'managed organization', we want to hide the global
  # role options. If they deselect the managed organization, re-show the global
  # options
  $('.user-role-form select').on 'change', ->
    if $(this).val().length > 0
      $('.global-roles').hide()
    else
      $('.global-roles').show()
