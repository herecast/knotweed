jQuery ->
  $(".payment-organization-header").on 'click', ->
    org = $(this).data("organizationClass")
    $("." + org).toggle()

