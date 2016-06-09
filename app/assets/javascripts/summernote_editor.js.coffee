$ ->
  $('[data-provider="summernote"]').each ->
    $(this).summernote({
      toolbar: [
        ["style", ["bold", "italic", "underline", "clear"]],
        ["link", ['link']],
        ["para", ["ol", "ul"]]
      ]
    })