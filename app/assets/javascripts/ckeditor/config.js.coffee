CKEDITOR.editorConfig = (config) ->
  config.height = "400px"
  config.toolbar = [
      [ 'Bold','Italic','Underline' ],
      [ 'Link','Unlink' ],
      ['PasteText'],
      ['SpellChecker', 'Scayt'],
      [ 'Source' ],
  ];
  true
