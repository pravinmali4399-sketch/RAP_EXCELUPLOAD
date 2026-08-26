@EndUserText.label: 'Abstract Entity For Excel Upload'
define root abstract entity ZPM_D_FILE_STREAM
{
  @Semantics.largeObject.mimeType: 'MimeType'
  @Semantics.largeObject.fileName: 'FileName'
  @Semantics.largeObject.contentDispositionPreference: #INLINE
  @EndUserText.label: 'Select Excel file'
  StreamProperty : abap.rawstring(0);

  @UI.hidden: true
  MimeType : abap.char(128);

  @UI.hidden: true
  FileName : abap.char(128);
}
