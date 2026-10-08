CLASS lhc_ZPM_I_SALES_PRICE DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations FOR zpm_i_sales_price RESULT result.

    METHODS UploadExcel FOR MODIFY
       keys FOR ACTION zpm_i_sales_price~uploadexcel.
    METHODS ValidDates FOR VALIDATE ON SAVE
       keys FOR zpm_i_sales_price~ValidDates.
    METHODS setValidTo FOR DETERMINE ON MODIFY
       keys FOR zpm_i_sales_price~setValidTo.
    METHODS setInitialApprovalStatus FOR DETERMINE ON MODIFY
       keys FOR zpm_i_sales_price~setInitialApprovalStatus.
    METHODS Approve FOR MODIFY
       keys FOR ACTION zpm_i_sales_price~Approve RESULT result.

*    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
*      REQUEST requested_authorizations FOR zpm_i_sales_price RESULT result.
    "!
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zpm_i_sales_price RESULT result.
ENDCLASS.

CLASS lhc_ZPM_I_SALES_PRICE IMPLEMENTATION.

  METHOD get_instance_authorizations.
**
*
**    IF requested_authorizations-%update = if_abap_behv=>mk-on.
**      result-%update = if_abap_behv=>auth-allowed.
**    ENDIF.
**
**    IF requested_authorizations-%delete = if_abap_behv=>mk-on.
**      result-%delete = if_abap_behv=>auth-allowed.
**    ENDIF.
*
  ENDMETHOD.

  METHOD get_instance_features.

    READ ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      FIELDS ( ApprovalStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sales_price).

    result = VALUE #(
      FOR ls_sales_price IN lt_sales_price
      (
        %tky = ls_sales_price-%tky

        %action-Approve = COND #(
          WHEN ls_sales_price-ApprovalStatus = 'Approved'
            THEN if_abap_behv=>fc-o-disabled
          ELSE if_abap_behv=>fc-o-enabled
        )
      )
    ).

  ENDMETHOD.

  METHOD UploadExcel.
    TYPES:
      BEGIN OF ty_sheet_data,
        SalesOrg     TYPE string,
        DistrChannel TYPE string,
        Material     TYPE string,
        Customer     TYPE string,
        ValidFrom    TYPE string,
        ValidTo      TYPE string,
        SalesPrice   TYPE string,
        Currency     TYPE string,
      END OF ty_sheet_data.

    DATA:
      lv_file_content       TYPE xstring,
      lt_sheet_data         TYPE STANDARD TABLE OF ty_sheet_data,
      lt_sales_price_create
        TYPE TABLE FOR CREATE zpm_i_sales_price.

    "------------------------------------------------------------
    " 1. Get uploaded Excel file
    "------------------------------------------------------------

    lv_file_content =
      VALUE #( keys[ 1 ]-%param-_StreamProperties-StreamProperty OPTIONAL ).

    IF lv_file_content IS INITIAL.

      APPEND VALUE #(
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'Please select an Excel file.' )
      ) TO reported-zpm_i_sales_price.

      RETURN.

    ENDIF.


    "------------------------------------------------------------
    " 2. Read Excel document
    "------------------------------------------------------------

    DATA(lo_document) =
      xco_cp_xlsx=>document->for_file_content(
        lv_file_content
      )->read_access( ).

    DATA(lo_worksheet) =
      lo_document->get_workbook(
      )->worksheet->for_name( 'SalesPrice' ).


    "------------------------------------------------------------
    " 3. Select Excel data
    "
    " Row 1 = Header
    " Row 2 onwards = Data
    "
    " A = SalesOrg
    " B = DistrChannel
    " C = Material
    " D = Customer
    " E = ValidFrom
    " F = ValidTo
    " G = SalesPrice
    " H = Currency
    "------------------------------------------------------------

    DATA(lo_selection_pattern) =
      xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
      )->from_column(
          xco_cp_xlsx=>coordinate->for_alphabetic_value( 'A' )
      )->to_column(
          xco_cp_xlsx=>coordinate->for_alphabetic_value( 'H' )
      )->from_row(
          xco_cp_xlsx=>coordinate->for_numeric_value( 2 )
      )->get_pattern( ).


    "------------------------------------------------------------
    " 4. Read Excel rows as STRING
    "------------------------------------------------------------

    DATA(lo_operation) =
      lo_worksheet->select(
        lo_selection_pattern
      )->row_stream(
      )->operation->write_to(
          REF #( lt_sheet_data )
      ).

    lo_operation->set_value_transformation(
      xco_cp_xlsx_read_access=>value_transformation->string_value
    ).

    lo_operation->if_xco_xlsx_ra_operation~execute( ).


    "------------------------------------------------------------
    " 5. Check whether Excel contains data
    "------------------------------------------------------------

    IF lt_sheet_data IS INITIAL.

      APPEND VALUE #(
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'No data found in the Excel file.' )
      ) TO reported-zpm_i_sales_price.

      RETURN.

    ENDIF.


    "------------------------------------------------------------
    " 6. Convert Excel data to RAP CREATE structure
    "------------------------------------------------------------

    LOOP AT lt_sheet_data INTO DATA(ls_sheet).

      APPEND VALUE #(
        %cid         = |UPLOAD_{ sy-tabix }|
        %is_draft    = if_abap_behv=>mk-on
        SalesOrg     = ls_sheet-SalesOrg
        DistrChannel = ls_sheet-DistrChannel
        Material     = ls_sheet-Material
        Customer     = ls_sheet-Customer
        ValidFrom    = CONV d( ls_sheet-ValidFrom )
        ValidTo      = CONV d( ls_sheet-ValidTo )
        SalesPrice   = CONV #( ls_sheet-SalesPrice )
        Currency     = ls_sheet-Currency
      ) TO lt_sales_price_create.

    ENDLOOP.


    "------------------------------------------------------------
    " 7. Create RAP entities using EML
    "------------------------------------------------------------

    MODIFY ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      CREATE AUTO FILL CID
      FIELDS (
        SalesOrg
        DistrChannel
        Material
        Customer
        ValidFrom
        ValidTo
        SalesPrice
        Currency
      )
      WITH lt_sales_price_create

      MAPPED DATA(lt_mapped)
      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).


    "------------------------------------------------------------
    " 8. Handle failed records
    "------------------------------------------------------------

    IF lt_failed IS NOT INITIAL.

      APPEND VALUE #(
        %msg = new_message_with_text(
          severity = if_abap_behv_message=>severity-error
          text     = 'One or more sales price records could not be uploaded.' )
      ) TO reported-zpm_i_sales_price.

      RETURN.

    ENDIF.


    "------------------------------------------------------------
    " 9. Success message
    "------------------------------------------------------------

    APPEND VALUE #(
      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-success
        text     = |{ lines( lt_sales_price_create ) } sales price records uploaded successfully.| )
    ) TO reported-zpm_i_sales_price.

  ENDMETHOD.

*  METHOD get_instance_features.
*
*  ENDMETHOD.


  METHOD ValidDates.

    READ ENTITIES OF zpm_i_sales_price IN LOCAL MODE
     ENTITY zpm_i_sales_price
     FIELDS ( ValidFrom ValidTo )
     WITH CORRESPONDING #( keys )
     RESULT DATA(lt_sales_price).

    LOOP AT lt_sales_price INTO DATA(ls_sales_price).

      IF ls_sales_price-ValidTo < ls_sales_price-ValidFrom.

        APPEND VALUE #(
          %tky = ls_sales_price-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'To date cannot be earlier than From date!'
          )
        ) TO reported-zpm_i_sales_price.

        APPEND VALUE #(
          %tky = ls_sales_price-%tky
        ) TO failed-zpm_i_sales_price.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD setValidTo.

    READ ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      FIELDS ( ValidFrom ValidTo )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sales_price).

    MODIFY ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      UPDATE FIELDS ( ValidTo )
      WITH VALUE #(
        FOR ls_sales_price IN lt_sales_price
        WHERE ( ValidFrom IS NOT INITIAL AND ValidTo IS INITIAL )
        (
          %tky     = ls_sales_price-%tky
          ValidTo  = COND #(
            WHEN ls_sales_price-ValidFrom IS NOT INITIAL
            THEN CONV d(
              |{ ls_sales_price-ValidFrom(4) }1231|
            )
          )
        )
      ).

  ENDMETHOD.

  METHOD setInitialApprovalStatus.
    READ ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      FIELDS ( ApprovalStatus )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sales_price).

    MODIFY ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      UPDATE FIELDS ( ApprovalStatus )
      WITH VALUE #(
        FOR ls_sales_price IN lt_sales_price
        WHERE ( ApprovalStatus IS INITIAL )
        (
          %tky = ls_sales_price-%tky
          ApprovalStatus = 'Pending'
        )
      ).
  ENDMETHOD.

  METHOD Approve.
    MODIFY ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      UPDATE FIELDS ( ApprovalStatus )
      WITH VALUE #(
        FOR key IN keys
        (
          %tky = key-%tky
          ApprovalStatus = 'Approved'
        )
      ).

    READ ENTITIES OF zpm_i_sales_price IN LOCAL MODE
      ENTITY zpm_i_sales_price
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_sales_price).

    result = VALUE #(
      FOR ls_sales_price IN lt_sales_price
      (
        %tky   = ls_sales_price-%tky
        %param = ls_sales_price
      )
    ).
  ENDMETHOD.

ENDCLASS.
