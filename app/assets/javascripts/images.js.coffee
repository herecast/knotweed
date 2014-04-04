updateRows = (ele)->
  if ele.scrollTop() > 0
    ele.attr("rows", parseInt(ele.attr("rows"))+1)

jQuery ->
  submitUrl = $("#image_image").data("uploadUrl")
  $("#image_image").fileupload
    url: submitUrl
    type: "POST"
    dataType: "script"
    dropZone: $("#images")
    formData: (form) ->
      $("fieldset#image_fields").serializeArray()
    add: (e, data) ->
      types = /(\.|\/)(gif|jpe?g|png)$/i
      file = data.files[0]
      if types.test(file.type) || types.test(file.name)
        data.context = $(tmpl("template-upload", file))
        $('#images').prepend(data.context)
        data.submit()
      else
        alert("#{file.name} is not a gif, jpeg, or png image file")
    progress: (e, data) ->
      if data.context
        progress = parseInt(data.loaded / data.total * 100, 10)
        data.context.find('.bar').css('width', progress + '%')
    done: (e, data) ->
      if data.context
        data.context.remove()
      $("span.file-input-name").text("")

  $(document).on 'click', 'a.update-image', (event)->
    event.preventDefault()
    imageId = $(this).data("imageId")
    $.ajax($(this).data("url"), {
      type: "PUT",
      dataType: "script",
      data: { 
        "image": { 
          "caption": $("#image_" + imageId + "_caption").val(),
          "credit": $("#image_" + imageId + "_credit").val()
        }
      }
    })

  # resize textbox
  $(document).on 'keyup', ".caption-field", ->
    updateRows($(this))
