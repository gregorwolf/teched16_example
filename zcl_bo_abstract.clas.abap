class ZCL_BO_ABSTRACT definition
  public
  abstract
  create public .

public section.

  methods CALL_ALL_GETTERS
  final
    importing
      !ENTITY type ref to DATA
    raising
      ZCX_DEMO_BO .
protected section.

  class-methods RAISE_EXCEPTION_ON_ERROR
    importing
      !BAPIRETURN type BAPIRET2TAB optional
    raising
      ZCX_DEMO_BO .
  class-methods GET_SUBCLASS_FROM_INTERFACE
    importing
      !CLSNAME_IN type SEOCLSNAME
    returning
      value(CLSNAME_OUT) type SEOCLSNAME .
  class-methods GET_STRUCT_DESCR
    importing
      !DATA type DATA
    returning
      value(STRUCT_DESCR) type ref to CL_ABAP_STRUCTDESCR
    raising
      /IWBEP/CX_MGW_TECH_EXCEPTION .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_BO_ABSTRACT IMPLEMENTATION.


  METHOD CALL_ALL_GETTERS.
*--------------------------------------------------------------------*
* Fills the entity data object by calling the GET methods for each   *
* field in turn.                                                     *
*                                                                    *
* To work both the GET method and the returning parameter must have  *
* the same name as the ABAP field.                                   *
*                                                                    *
* i.e. KUNNR filled by returning parameter KUNNR of method GET_KUNNR.*
*--------------------------------------------------------------------*

    DATA: struct_descr TYPE REF TO cl_abap_structdescr,
          parameter    TYPE abap_parmbind,
          parameters   TYPE abap_parmbind_tab.

    ASSIGN entity->* TO FIELD-SYMBOL(<entity>).

    TRY.
        struct_descr ?= cl_abap_structdescr=>describe_by_data_ref( entity ).
        LOOP AT struct_descr->components REFERENCE INTO DATA(component).
          CLEAR parameters.
          TRY.
              ASSIGN COMPONENT component->name OF STRUCTURE <entity> TO FIELD-SYMBOL(<comp>).
              IF sy-subrc = 0.
                parameter-name = component->name.
                parameter-kind = cl_abap_objectdescr=>returning.
                GET REFERENCE OF <comp> INTO parameter-value.
                INSERT parameter INTO TABLE parameters.
                DATA(method_name) = |GET_{ component->name }|.
                CALL METHOD me->(method_name)
                  PARAMETER-TABLE parameters.
              ENDIF.
            CATCH cx_sy_dyn_call_error.
          ENDTRY.
        ENDLOOP.
      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.


METHOD get_struct_descr.
*--------------------------------------------------------------------*
* Returns instantiated CL_ABAP_STRUCTDESCR for the linetype of the   *
* passed in itab.                                                    *
*--------------------------------------------------------------------*
  DATA: table_descr    TYPE REF TO cl_abap_tabledescr.

  TRY.
      table_descr ?= cl_abap_tabledescr=>describe_by_data( data ).
      struct_descr ?= table_descr->get_table_line_type( ).
    CATCH cx_sy_move_cast_error INTO DATA(cx_sy_move_cast_error).
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          textid   = /iwbep/cx_mgw_tech_exception=>internal_error
          previous = cx_sy_move_cast_error.
  ENDTRY.
ENDMETHOD.


METHOD get_subclass_from_interface.
*--------------------------------------------------------------------*
* This method walks down the inheritance tree and returns the name   *
* of the last child.                                                 *
*--------------------------------------------------------------------*
    DATA: obj TYPE REF TO cl_oo_object,
          inf TYPE REF TO cl_oo_interface,
          cls TYPE REF TO cl_oo_class.

    DATA(lv_clsname) = clsname_in.

    WHILE clsname_out IS INITIAL.
      TRY.
          obj = cl_oo_object=>get_instance( lv_clsname ).
          TRY.
              cls ?= obj.
              DATA(subclasses) = cls->get_subclasses( ).
              READ TABLE subclasses REFERENCE INTO DATA(subclass) INDEX 1.
              IF sy-subrc  = 0.
                lv_clsname = subclass->clsname.
              ELSE.
                clsname_out = lv_clsname.
              ENDIF.
            CATCH cx_sy_move_cast_error.
              TRY.
                  inf ?= obj.
                  DATA(classes) = inf->get_implementing_classes( ).
                  READ  TABLE classes REFERENCE INTO DATA(class) INDEX 1.
                  IF sy-subrc  = 0.
                    lv_clsname = class->clsname.
                  ELSE.
                    clsname_out = lv_clsname.
                  ENDIF.
                CATCH cx_sy_move_cast_error.
                  clsname_out = lv_clsname.
              ENDTRY.
          ENDTRY.
        CATCH cx_class_not_existent.
          clsname_out = lv_clsname.
      ENDTRY.
    ENDWHILE.

  ENDMETHOD.


METHOD raise_exception_on_error.
*--------------------------------------------------------------------*
* This helper method is designed to take in the BAPIRET2TAB itab,    *
* parse for error messages, and then raise an exception.             *
*--------------------------------------------------------------------*
  LOOP AT bapireturn REFERENCE INTO DATA(lr_return) WHERE type = 'E'.
    MESSAGE ID lr_return->id TYPE lr_return->type NUMBER lr_return->number
            INTO DATA(error_message)
            WITH lr_return->message_v1 lr_return->message_v2 lr_return->message_v3 lr_return->message_v4.
    RAISE EXCEPTION TYPE zcx_demo_bo
      EXPORTING
        textid        = zcx_demo_bo=>error
        error_message = error_message.
  ENDLOOP.

ENDMETHOD.
ENDCLASS.