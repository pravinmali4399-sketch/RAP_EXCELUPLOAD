@EndUserText.label: 'Action Param for Uploading Excel'
define root abstract entity ZPM_D_UPLOAD_EXCEL

{
  @UI.hidden        : true
  dummy             : abap_boolean;
  _StreamProperties : association [1] to ZPM_D_FILE_STREAM on 1 = 1;


}
