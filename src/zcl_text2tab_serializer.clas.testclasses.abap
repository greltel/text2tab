**********************************************************************
* MACRO
**********************************************************************

define append_dummy.
  e_dummy_struc-tdate    = &1.
  e_dummy_struc-tchar    = &2.
  e_dummy_struc-tstring  = &3.
  e_dummy_struc-tdecimal = &4.
  e_dummy_struc-tnumber  = &5.
  e_dummy_struc-traw     = &6.
  e_dummy_struc-tinteger = &7.
  e_dummy_struc-talpha   = &8.
  e_dummy_struc-tfloat   = &9.
  append e_dummy_struc to e_dummy_tab.
end-of-definition.

define test_field.
  ls_dummy-&1 = &2.
  read table lt_components with key name = '&1' assigning <comp>.
  l_act = o->serialize_field( i_value = ls_dummy-&1 is_component = <comp> ).
  cl_abap_unit_assert=>assert_equals( act = l_act exp = &3 ).
end-of-definition.

**********************************************************************
* Test Class definition
**********************************************************************

class ltcl_text2tab_serializer_test definition final
  for testing
  risk level harmless
  duration short.

  public section.

    types:
      begin of ty_dummy,
        mandt    type mandt,
        tdate    type datum,
        tchar    type c length 8,
        traw     type x length 1,
        tstring  type string,
        talpha   type veri_alpha,
        tdecimal type dmbtr,
        tnumber  type n length 4,
        tinteger type i,
        tfloat   type f,
      end of ty_dummy,
      tt_dummy type standard table of ty_dummy with default key.

    types:
      begin of ty_dummy_with_ddic,
        uname type uname,
        datum type datum,
        uzeit type uzeit,
      end of ty_dummy_with_ddic.

  private section.
    constants c_tab   like cl_abap_char_utilities=>horizontal_tab value cl_abap_char_utilities=>horizontal_tab.
    constants c_crlf  like cl_abap_char_utilities=>cr_lf value cl_abap_char_utilities=>cr_lf.
    constants c_lf    like cl_abap_char_utilities=>newline value cl_abap_char_utilities=>newline.

    data o type ref to zcl_text2tab_serializer.  "class under test

* ==== TESTING ===

    methods integrated for testing.
    methods header_only for testing raising zcx_text2tab_error.
    methods serialize_header for testing raising zcx_text2tab_error.
    methods given_fields for testing raising zcx_text2tab_error.
    methods with_descr for testing raising zcx_text2tab_error.

    methods serialize_date for testing.
    methods serialize_field for testing.
    methods negatives for testing.
    methods create for testing.

    methods bind_data_and_fields for testing raising zcx_text2tab_error.
    methods raise_on_no_data for testing raising zcx_text2tab_error.

* ==== HELPERS ===

    methods setup.
    methods get_dummy_data
      exporting
        e_dummy_struc         type ty_dummy
        e_dummy_tab           type tt_dummy
        e_given_fields_list   type zcl_text2tab_serializer=>tt_fields_list
        e_given_fields_str    type string
        e_dummy_struc_str     type string
        e_dummy_string        type string
        e_dummy_string_w_descr type string
        e_dummy_header        type string.

endclass.

class zcl_text2tab_serializer definition local friends ltcl_text2tab_serializer_test.

**********************************************************************
* Implementation
**********************************************************************

class ltcl_text2tab_serializer_test implementation.

  method setup.
    data lx type ref to zcx_text2tab_error.
    try.
      o = zcl_text2tab_serializer=>create( ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>fail( lx->get_text( ) ).
    endtry.
  endmethod.

  method integrated.
    data:
      lv_act       type string,
      lv_exp_struc type string,
      lv_exp_tab   type string,
      lt_tab       type tt_dummy,
      ls_struc     type ty_dummy,
      lx type ref to zcx_text2tab_error.

    get_dummy_data( importing
      e_dummy_struc     = ls_struc
      e_dummy_tab       = lt_tab
      e_dummy_string    = lv_exp_tab
      e_dummy_struc_str = lv_exp_struc ).

    try.
      lv_act = o->serialize( lt_tab ).
      cl_abap_unit_assert=>assert_equals( act = lv_act exp = lv_exp_tab ).

      lv_act = o->serialize( ls_struc ).
      cl_abap_unit_assert=>assert_equals( act = lv_act exp = lv_exp_struc ).

    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>fail( lx->get_text( ) ).
    endtry.
  endmethod.

  method header_only.

    data lv_act type string.
    data lv_exp_string type string.
    data lt_tab       type tt_dummy.

    get_dummy_data( importing
      e_dummy_tab       = lt_tab
      e_dummy_header    = lv_exp_string ).

    lv_act = o->serialize(
      i_data        = lt_tab
      i_header_only = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = lv_exp_string ).

  endmethod.

  method serialize_header.

    data lv_act type string.
    data lt_tab type table of ty_dummy_with_ddic.
    data lt_fields_only type zcl_text2tab_serializer=>tt_fields_list.
    data lx type ref to zcx_text2tab_error.

    " Fail on wrong header_type
    try.
      lv_act = o->serialize_header(
        i_header_type = ''
        i_data = lt_tab ).
      cl_abap_unit_assert=>fail( ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals(
        act = lx->code
        exp = 'HT').
    endtry.

    " Complete data set
    lv_act = o->serialize_header(
      i_header_type = zcl_text2tab_serializer=>c_header-descriptions
      i_data = lt_tab ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = |User Name\tDate\tTime| ).

    lv_act = o->serialize_header(
      i_header_type = zcl_text2tab_serializer=>c_header-technical_names
      i_data = lt_tab ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = |UNAME\tDATUM\tUZEIT| ).


    " With listed fields
    append 'DATUM' to lt_fields_only.
    append 'UZEIT' to lt_fields_only.

    lv_act = o->serialize_header(
      i_header_type = zcl_text2tab_serializer=>c_header-descriptions
      i_data = lt_tab
      i_fields_only = lt_fields_only ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = |Date\tTime| ).

    lv_act = o->serialize_header(
      i_header_type = zcl_text2tab_serializer=>c_header-technical_names
      i_data = lt_tab
      i_fields_only = lt_fields_only ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = |DATUM\tUZEIT| ).

  endmethod.

  method given_fields.

    data lv_act        type string.
    data lv_exp_string type string.
    data lt_tab        type tt_dummy.
    data lt_fields_only type zcl_text2tab_serializer=>tt_fields_list.

    get_dummy_data( importing
      e_dummy_tab         = lt_tab
      e_given_fields_list = lt_fields_only
      e_given_fields_str  = lv_exp_string ).

    o = zcl_text2tab_serializer=>create( ).
    lv_act = o->serialize(
      i_data        = lt_tab
      i_fields_only = lt_fields_only ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = lv_exp_string ).

  endmethod.

  method with_descr.

    data lv_act type string.
    data lv_exp type string.
    data lt_tab type table of ty_dummy_with_ddic.
    data lt_fields_only type zcl_text2tab_serializer=>tt_fields_list.

    field-symbols <i> like line of lt_tab.
    append initial line to lt_tab assigning <i>.
    <i>-uname = 'HELLO'.
    <i>-datum = '20210901'.
    <i>-uzeit = '100102'.

    lv_exp = 'User Name\tDate\tTime\n' &&
      'UNAME\tDATUM\tUZEIT\n' &&
      'HELLO\t01.09.2021\t100102'.
    replace all occurrences of '\t' in lv_exp with c_tab.
    replace all occurrences of '\n' in lv_exp with c_crlf.

    o = zcl_text2tab_serializer=>create( i_add_header_descr = 'E' ).
    lv_act = o->serialize( i_data = lt_tab ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = lv_exp ).

    " With listed fields
    append 'DATUM' to lt_fields_only.
    append 'UZEIT' to lt_fields_only.

    lv_exp = 'Date\tTime\n' &&
      'DATUM\tUZEIT\n' &&
      '01.09.2021\t100102'.
    replace all occurrences of '\t' in lv_exp with c_tab.
    replace all occurrences of '\n' in lv_exp with c_crlf.

    o = zcl_text2tab_serializer=>create( i_add_header_descr = 'E' ).
    lv_act = o->serialize(
      i_data = lt_tab
      i_fields_only = lt_fields_only ).

    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = lv_exp ).

  endmethod.

**********************************************************************

  method get_dummy_data.

    data l_offs    type i.
    data l_string  type string.

    l_string = 'MANDT\tTDATE\tTCHAR\tTRAW\tTSTRING\tTALPHA\tTDECIMAL\tTNUMBER\tTINTEGER\tTFLOAT\n'
            && '\t01.01.2015\tTrololo1\t8A\tString1\t100000\t1234567.81\t2015\t1111\t1.12345\n'
            && '\t02.01.2016\tTrololo2\t8B\tString2\t200000\t1234567.82\t2016\t2222\t1.1\n'
            && '\t03.01.2016\tTrololo3\t8C\tString3\t300000\t1234567.83\t2015\t3333\t1000' .

    replace all occurrences of '\t' in l_string with c_tab.
    replace all occurrences of '\n' in l_string with c_crlf.

    clear e_dummy_tab.

    "             TDATE      TCHAR      TSTRING   TDECIMAL    TNUM TRAW  TINT  TALPHA      TFLOAT
    append_dummy '20150101' 'Trololo1' 'String1' '1234567.81' 2015 '8A'  1111 '0000100000' '1.12345'.
    append_dummy '20160102' 'Trololo2' 'String2' '1234567.82' 2016 '8B'  2222 '0000200000' '1.10'.
    append_dummy '20160103' 'Trololo3' 'String3' '1234567.83' 2015 '8C'  3333 '0000300000' '1000.00'.

    read table e_dummy_tab into e_dummy_struc index 1.
    e_dummy_string = l_string.

    l_offs = find( val = l_string sub = c_crlf ).
    e_dummy_header = l_string+0(l_offs).
    l_offs = find( val = l_string sub = c_crlf off = l_offs + 1 ). " second crlf
    e_dummy_struc_str = l_string+0(l_offs).

    append 'TCHAR' to e_given_fields_list.
    append 'TNUMBER' to e_given_fields_list.

    e_given_fields_str =
      'TCHAR\tTNUMBER\n' &&
      'Trololo1\t2015\n' &&
      'Trololo2\t2016\n' &&
      'Trololo3\t2015' .

    replace all occurrences of '\t' in e_given_fields_str with c_tab.
    replace all occurrences of '\n' in e_given_fields_str with c_crlf.

    e_dummy_string_w_descr =
      'Client\tDate\t\t\t\tALPHA\tAmount in LC\t\t\t\n' &&
      'MANDT\tTDATE\tTCHAR\tTRAW\tTSTRING\tTALPHA\tTDECIMAL\tTNUMBER\tTINTEGER\tTFLOAT\n' &&
      '\t01.01.2015\tTrololo1\t8A\tString1\t100000\t1234567.81\t2015\t1111\t1.12345\n' &&
      '\t02.01.2016\tTrololo2\t8B\tString2\t200000\t1234567.82\t2016\t2222\t1.1\n' &&
      '\t03.01.2016\tTrololo3\t8C\tString3\t300000\t1234567.83\t2015\t3333\t1000' .

    replace all occurrences of '\t' in e_dummy_string_w_descr with c_tab.
    replace all occurrences of '\n' in e_dummy_string_w_descr with c_crlf.

  endmethod.       " get_dummy_data

  method serialize_date.
    data l_act type string.

    l_act = zcl_text2tab_serializer=>serialize_date( i_date = '20180901' iv_date_format = 'DMY' ).
    cl_abap_unit_assert=>assert_equals( act = l_act exp = '01092018' ).
    l_act = zcl_text2tab_serializer=>serialize_date( i_date = '20180901' iv_date_format = 'DMY.' ).
    cl_abap_unit_assert=>assert_equals( act = l_act exp = '01.09.2018' ).
    l_act = zcl_text2tab_serializer=>serialize_date( i_date = '20180901' iv_date_format = 'YMD-' ).
    cl_abap_unit_assert=>assert_equals( act = l_act exp = '2018-09-01' ).
    l_act = zcl_text2tab_serializer=>serialize_date( i_date = '00000000' iv_date_format = 'YMD-' ).
    cl_abap_unit_assert=>assert_equals( act = l_act exp = '' ).

  endmethod.

  method serialize_field.

    data lx        type ref to zcx_text2tab_error.
    data l_act     type string.
    data ls_dummy  type ty_dummy.
    data ld_type   type ref to cl_abap_structdescr.
    data lt_components type zcl_text2tab_utils=>tt_comp_descr.
    data lv_meins type meins.
    data ls_comp like line of lt_components.

    field-symbols: <comp> like line of lt_components.

    ld_type ?= cl_abap_typedescr=>describe_by_data( ls_dummy ).

    try.
      lt_components = zcl_text2tab_utils=>describe_struct( ld_type ).

      test_field TFLOAT '1.123456' '1.12346'.
      test_field TFLOAT '1.00'     '1'.
      test_field TFLOAT '1.10'     '1.1'.
      test_field TFLOAT '1231.10'  '1231.1'.
      test_field TFLOAT '-1231.10' '-1231.1'.

      o->mv_decimal_sep = ','.
      test_field TFLOAT '1.10'     '1,1'.
      o->mv_max_frac_digits = 3.
      test_field TFLOAT '1.123456' '1,123'.

      test_field TDECIMAL  '1.12'       '1,12'.
      test_field TDECIMAL  '-1.12'      '-1,12'.
      test_field TDECIMAL  '1111.12'    '1111,12'.
      test_field TALPHA    '0000100000' '100000'.
      test_field TINTEGER  3333         '3333'.

      test_field TDATE  '20180901' '01.09.2018'.
      test_field TDATE  '00000000' ''.
      test_field TDATE  '' ''.

      lv_meins          = 'KG'.
      ls_comp-type_kind = cl_abap_typedescr=>typekind_char.
      l_act = o->serialize_field( i_value = lv_meins is_component = ls_comp ).
      cl_abap_unit_assert=>assert_equals( act = l_act exp = 'KG' ).

    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>fail( lx->get_text( ) ).
    endtry.

    " Negative tests
    try.
      clear lx.
      lv_meins = '??'.
      ls_comp-type_kind = cl_abap_typedescr=>typekind_char.
      ls_comp-edit_mask = 'CUNIT'.
      l_act = o->serialize_field( i_value = lv_meins is_component = ls_comp ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals( act = lx->code exp = 'CF' ).
    endtry.
    cl_abap_unit_assert=>assert_not_initial( lx ).

  endmethod.

  method negatives.
    data:
      lx        type ref to zcx_text2tab_error,
      l_act     type string.
    data:
      begin of ls_deep,
        str type string,
        tab type tt_dummy,
      end of ls_deep.

    try.
      clear lx.
      o->serialize( i_data = l_act ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals( act = lx->code exp = 'ST' ).
    endtry.
    cl_abap_unit_assert=>assert_not_initial( lx ).

    try.
      clear lx.
      o->serialize( i_data = ls_deep ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals( act = lx->code exp = 'ET' ).
    endtry.
    cl_abap_unit_assert=>assert_not_initial( lx ).

  endmethod.

  method create.
    data lx type ref to zcx_text2tab_error.

    try.
      clear lx.
      o = zcl_text2tab_serializer=>create( i_date_format = 'YYM-' ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals( act = lx->code exp = 'UD' ).
    endtry.
    cl_abap_unit_assert=>assert_not_initial( lx ).

  endmethod.

  method bind_data_and_fields.

    data lv_act type string.
    data lv_exp type string.
    data lv_exp_limited type string.
    data lt_tab type tt_dummy.
    data lt_fields_only type zcl_text2tab_serializer=>tt_fields_list.

    get_dummy_data( importing
      e_dummy_tab       = lt_tab
      e_dummy_string    = lv_exp ).

    o->bind_data( lt_tab ).
    lv_act = o->serialize( ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = lv_exp ).

    clear lv_exp.
    get_dummy_data( importing
      e_given_fields_list = lt_fields_only
      e_given_fields_str  = lv_exp_limited ).

    o->bind_fields_only( lt_fields_only ).
    lv_act = o->serialize( ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = lv_exp_limited ).

    " chained sample
    lv_act = zcl_text2tab_serializer=>create(
      )->bind_fields_only( lt_fields_only
      )->bind_data( lt_tab
      )->serialize( ).
    cl_abap_unit_assert=>assert_equals(
      act = lv_act
      exp = lv_exp_limited ).

  endmethod.

  method raise_on_no_data.

    data lx type ref to zcx_text2tab_error.
    data lt_tab type tt_dummy.

    try.
      o->serialize( ).
      cl_abap_unit_assert=>fail( ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals(
        act = lx->code
        exp = 'ND' ).
    endtry.

    try.
      o->serialize_header( ).
      cl_abap_unit_assert=>fail( ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals(
        act = lx->code
        exp = 'ND' ).
    endtry.

    o->bind_data( lt_tab ).

    try.
      o->serialize( lt_tab ).
      cl_abap_unit_assert=>fail( ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals(
        act = lx->code
        exp = 'AB' ).
    endtry.

    try.
      o->serialize_header( lt_tab ).
      cl_abap_unit_assert=>fail( ).
    catch zcx_text2tab_error into lx.
      cl_abap_unit_assert=>assert_equals(
        act = lx->code
        exp = 'AB' ).
    endtry.

  endmethod.

endclass.
