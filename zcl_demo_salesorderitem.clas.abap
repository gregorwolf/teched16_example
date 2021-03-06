class ZCL_DEMO_SALESORDERITEM definition
  public
  inheriting from ZCL_BO_ABSTRACT
  create protected .

public section.

  interfaces ZIF_DEMO_SALESORDERITEM .
  interfaces ZIF_GW_METHODS .

  aliases GET
    for ZIF_DEMO_SALESORDERITEM~GET .
  aliases GET_CURRENCY_CODE
    for ZIF_DEMO_SALESORDERITEM~GET_CURRENCY_CODE .
  aliases GET_CURRENCY_TXT
    for ZIF_DEMO_SALESORDERITEM~GET_CURRENCY_TXT .
  aliases GET_NET_AMOUNT
    for ZIF_DEMO_SALESORDERITEM~GET_NET_AMOUNT .
  aliases GET_NODE_KEY
    for ZIF_DEMO_SALESORDERITEM~GET_NODE_KEY .
  aliases GET_PRODUCT_ID
    for ZIF_DEMO_SALESORDERITEM~GET_PRODUCT_ID .
  aliases GET_SO_ID
    for ZIF_DEMO_SALESORDERITEM~GET_SO_ID .
  aliases GET_SO_ITEM_POS
    for ZIF_DEMO_SALESORDERITEM~GET_SO_ITEM_POS .
  aliases GET_TEXT
    for ZIF_DEMO_SALESORDERITEM~GET_TEXT .

  methods CONSTRUCTOR
    importing
      !NODE_KEY type SNWD_NODE_KEY
    raising
      ZCX_DEMO_BO .
protected section.

  types:
    BEGIN OF curr_type,
        waers TYPE waers_curc,
        ltext TYPE ltext,
      END OF curr_type .
  types:
    curr_ttype TYPE TABLE OF curr_type .

  class-data CURRENCY_TEXTS type CURR_TTYPE .

  methods LOAD_ITEM_DATA
    importing
      !NODE_KEY type SNWD_NODE_KEY
    raising
      ZCX_DEMO_BO .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_DEMO_SALESORDERITEM IMPLEMENTATION.


  METHOD constructor.
    super->constructor( ).

    load_item_data( node_key ).
  ENDMETHOD.


  METHOD load_item_data.

    SELECT SINGLE soi~node_key, soi~parent_key, soi~so_item_pos,
      pd~product_id, text~text, soi~net_amount, soi~currency_code
           FROM
             ( snwd_so_i AS soi
                 INNER JOIN
                   snwd_pd AS pd ON soi~product_guid = pd~node_key )
                     LEFT OUTER JOIN
                       snwd_texts AS text ON pd~name_guid = text~parent_key AND text~language = @sy-langu
      INTO CORRESPONDING FIELDS OF @zif_demo_salesorderitem~item_data
      WHERE soi~node_key = @node_key.

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE zcx_demo_bo
        EXPORTING
          textid  = zcx_demo_bo=>not_found
          bo_type = 'SalesOrderItem'
          bo_id   = |{ node_key }|.
    ENDIF.

  ENDMETHOD.


  METHOD zif_demo_salesorderitem~get.

    TRY.
        DATA(inst) = zif_demo_salesorderitem~instances[ node_key = node_key ].
      CATCH cx_sy_itab_line_not_found.
        inst-node_key = node_key.
        DATA(class_name) = get_subclass( 'ZCL_DEMO_SALESORDERITEM' ).
        CREATE OBJECT inst-instance
          TYPE (class_name)
          EXPORTING
            node_key = node_key.
        APPEND inst TO zif_demo_salesorderitem~instances.
    ENDTRY.

    instance ?= inst-instance.

  ENDMETHOD.


  METHOD zif_demo_salesorderitem~get_currency_code.
    currency_code = zif_demo_salesorderitem~item_data-currency_code.
  ENDMETHOD.


  METHOD zif_demo_salesorderitem~get_currency_txt.

    TRY.
        currency_txt = currency_texts[ waers = zif_demo_salesorderitem~item_data-currency_code ]-ltext.
      CATCH cx_sy_itab_line_not_found.
        SELECT *
          FROM tcurt
          APPENDING CORRESPONDING FIELDS OF TABLE currency_texts
          WHERE spras = sy-langu
          AND waers = zif_demo_salesorderitem~item_data-currency_code.
        IF sy-subrc NE 0.
          APPEND VALUE #( waers = zif_demo_salesorderitem~item_data-currency_code ltext = 'N/A' ) TO currency_texts.
        ENDIF.
        currency_txt = currency_texts[ waers = zif_demo_salesorderitem~item_data-currency_code ]-ltext.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_demo_salesorderitem~get_net_amount.
    net_amount = zif_demo_salesorderitem~item_data-net_amount.
  ENDMETHOD.


  METHOD zif_demo_salesorderitem~get_node_key.
    node_key = zif_demo_salesorderitem~item_data-node_key.
  ENDMETHOD.


  method ZIF_DEMO_SALESORDERITEM~GET_PRODUCT_ID.
    product_id = zif_demo_salesorderitem~item_data-product_id.
  endmethod.


  METHOD zif_demo_salesorderitem~get_so_id.

    so_id = zcl_demo_salesorder=>get( zif_demo_salesorderitem~item_data-parent_key )->get_so_id( ).

  ENDMETHOD.


  METHOD zif_demo_salesorderitem~get_so_item_pos.
    so_item_pos = zif_demo_salesorderitem~item_data-so_item_pos.
  ENDMETHOD.


  method ZIF_DEMO_SALESORDERITEM~GET_TEXT.
    text = zif_demo_salesorderitem~item_data-text.
  endmethod.


  METHOD zif_gw_methods~create_deep_entity.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
      EXPORTING
        textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
        method = 'ZIF_GW_METHODS~CREATE_DEEP_ENTITY'.
  ENDMETHOD.


  METHOD zif_gw_methods~create_entity.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
      EXPORTING
        textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
        method = 'ZIF_GW_METHODS~CREATE_ENTITY'.
  ENDMETHOD.


  METHOD zif_gw_methods~delete_entity.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
      EXPORTING
        textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
        method = 'ZIF_GW_METHODS~DELETE_ENTITY'.
  ENDMETHOD.


  METHOD zif_gw_methods~execute_action.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
      EXPORTING
        textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
        method = 'ZIF_GW_METHODS~EXECUTE_ACTION'.
  ENDMETHOD.


  METHOD zif_gw_methods~get_entity.

    TRY.
        zcl_demo_salesorder=>get_using_so_id(
          CONV #( it_key_tab[ name = 'SalesOrderId' ]-value )
          )->get_item_by_pos(
          CONV #( it_key_tab[ name = 'ItemNo' ]-value )
          )->zif_gw_methods~map_to_entity( REF #( er_entity ) ).

      CATCH cx_root INTO DATA(cx_root).
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            textid   = /iwbep/cx_mgw_busi_exception=>business_error
            previous = cx_root
            message  = |{ cx_root->get_text( ) }|.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_gw_methods~get_entityset.

    FIELD-SYMBOLS: <entityset> TYPE STANDARD TABLE.
    ASSIGN et_entityset TO <entityset>.

    " Use RTTS/RTTC to create anonymous object like line of et_entityset
    DATA: entity         TYPE REF TO data.
    TRY.
        DATA(struct_descr) = get_struct_descr( et_entityset ).
        CREATE DATA entity TYPE HANDLE struct_descr.
        ASSIGN entity->* TO FIELD-SYMBOL(<entity>).
      CATCH cx_sy_create_data_error INTO DATA(cx_sy_create_data_error).
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid   = /iwbep/cx_mgw_tech_exception=>internal_error
            previous = cx_sy_create_data_error.
    ENDTRY.

    TRY.
        DATA(osreftab) = zcl_demo_salesorder=>get_using_so_id(
          CONV #( it_key_tab[ name = 'SalesOrderId' ]-value )
          )->get_items( ).

        IF io_tech_request_context->has_inlinecount( ) = abap_true.
          es_response_context-inlinecount = lines( osreftab ).
        ENDIF.

        " Fill entities
        DATA: item TYPE REF TO zif_demo_salesorderitem.
        LOOP AT osreftab INTO DATA(osref).
          item ?= osref.
          APPEND INITIAL LINE TO <entityset> REFERENCE INTO entity.
          CHECK io_tech_request_context->has_count( ) NE abap_true.
          item->zif_gw_methods~map_to_entity( entity ).
        ENDLOOP.

      CATCH cx_sy_itab_line_not_found zcx_demo_bo INTO DATA(exception).
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
          EXPORTING
            textid   = /iwbep/cx_mgw_busi_exception=>business_error
            previous = exception
            message  = |{ exception->get_text( ) }|.
    ENDTRY.

  ENDMETHOD.


  METHOD zif_gw_methods~map_to_entity.
    call_all_getters( entity ).
  ENDMETHOD.


  METHOD zif_gw_methods~update_entity.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_not_impl_exc
      EXPORTING
        textid = /iwbep/cx_mgw_not_impl_exc=>method_not_implemented
        method = 'ZIF_GW_METHODS~UPDATE_ENTITY'.
  ENDMETHOD.
ENDCLASS.