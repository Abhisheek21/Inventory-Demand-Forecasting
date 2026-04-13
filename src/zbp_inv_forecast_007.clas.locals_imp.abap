CLASS lhc_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: tt_master TYPE STANDARD TABLE OF zinv_master_007 WITH EMPTY KEY,
           tt_demand TYPE STANDARD TABLE OF zinv_demand_007 WITH EMPTY KEY.

    TYPES: BEGIN OF ty_buffer,
             master        TYPE tt_master,
             master_delete TYPE tt_master,
             demand        TYPE tt_demand,
             demand_delete TYPE tt_demand,
           END OF ty_buffer.

    CLASS-DATA mt_buffer TYPE ty_buffer.
ENDCLASS.

CLASS lhc_ForecastHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR ForecastHeader RESULT result.
    METHODS create FOR MODIFY IMPORTING entities FOR CREATE ForecastHeader.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE ForecastHeader.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE ForecastHeader.
    METHODS read FOR READ IMPORTING keys FOR READ ForecastHeader RESULT result.
    METHODS lock FOR LOCK IMPORTING keys FOR LOCK ForecastHeader.
    METHODS rba_Demand FOR READ IMPORTING keys_rba FOR READ ForecastHeader\_Demand FULL result_requested RESULT result LINK association_links.
    METHODS cba_Demand FOR MODIFY IMPORTING entities_cba FOR CREATE ForecastHeader\_Demand.
    METHODS forecast FOR MODIFY IMPORTING keys FOR ACTION ForecastHeader~forecast RESULT result.
ENDCLASS.

CLASS lhc_ForecastHeader IMPLEMENTATION.
  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys ( %tky = key-%tky
                                        %action-forecast = if_abap_behv=>auth-allowed
                                        %op-%update = if_abap_behv=>auth-allowed ) ).
  ENDMETHOD.

  METHOD forecast.
    LOOP AT keys INTO DATA(ls_key).
      " Extract values from the Popup Parameter (%param)
      DATA(lv_percent) = ls_key-%param-forecast_percent.

      READ TABLE lhc_buffer=>mt_buffer-master WITH KEY product_id = ls_key-product_id ASSIGNING FIELD-SYMBOL(<fs_m>).
      IF sy-subrc = 0.
        <fs_m>-current_stock = <fs_m>-current_stock + ( <fs_m>-current_stock * lv_percent / 100 ).
      ELSE.
        SELECT SINGLE * FROM zinv_master_007 WHERE product_id = @ls_key-product_id INTO @DATA(ls_db_master).
        ls_db_master-current_stock = ls_db_master-current_stock + ( ls_db_master-current_stock * lv_percent / 100 ).
        INSERT ls_db_master INTO TABLE lhc_buffer=>mt_buffer-master.
      ENDIF.
    ENDLOOP.

    " Refresh and report results back to UI
    READ ENTITIES OF ZI_INV_FORECAST_007 IN LOCAL MODE
      ENTITY ForecastHeader ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated).
    result = VALUE #( FOR res IN lt_updated ( %tky = res-%tky %param = res ) ).
  ENDMETHOD.

  METHOD create.
    LOOP AT entities INTO DATA(ls_entity).
      INSERT CORRESPONDING #( ls_entity ) INTO TABLE lhc_buffer=>mt_buffer-master.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).
      READ TABLE lhc_buffer=>mt_buffer-master WITH KEY product_id = ls_entity-product_id ASSIGNING FIELD-SYMBOL(<fs_master>).
      IF sy-subrc <> 0.
        SELECT SINGLE * FROM zinv_master_007 WHERE product_id = @ls_entity-product_id INTO @DATA(ls_db).
        INSERT ls_db INTO TABLE lhc_buffer=>mt_buffer-master ASSIGNING <fs_master>.
      ENDIF.

      " Update fields based on control structure
      IF ls_entity-%control-product_name = if_abap_behv=>mk-on. <fs_master>-product_name = ls_entity-product_name. ENDIF.
      IF ls_entity-%control-current_stock = if_abap_behv=>mk-on. <fs_master>-current_stock = ls_entity-current_stock. ENDIF.
      IF ls_entity-%control-reorder_level = if_abap_behv=>mk-on. <fs_master>-reorder_level = ls_entity-reorder_level. ENDIF.
      IF ls_entity-%control-category      = if_abap_behv=>mk-on. <fs_master>-category      = ls_entity-category. ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      INSERT VALUE #( product_id = ls_key-product_id ) INTO TABLE lhc_buffer=>mt_buffer-master_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    " Criticality calculation removed
    SELECT * FROM zinv_master_007 FOR ALL ENTRIES IN @keys
      WHERE product_id = @keys-product_id INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Demand.
    IF keys_rba IS NOT INITIAL.
      SELECT * FROM zinv_demand_007 FOR ALL ENTRIES IN @keys_rba
        WHERE product_id = @keys_rba-product_id INTO CORRESPONDING FIELDS OF TABLE @result.
    ENDIF.
  ENDMETHOD.

  METHOD cba_Demand.
    LOOP AT entities_cba INTO DATA(ls_cba).
      LOOP AT ls_cba-%target INTO DATA(ls_target).
        DATA(ls_demand) = CORRESPONDING zinv_demand_007( ls_target ).
        ls_demand-product_id = ls_cba-product_id.
        IF ls_demand-demand_id IS INITIAL.
          ls_demand-demand_id = cl_abap_context_info=>get_system_time( ).
        ENDIF.
        INSERT ls_demand INTO TABLE lhc_buffer=>mt_buffer-demand.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_DemandItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE DemandItem.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE DemandItem.
    METHODS read FOR READ IMPORTING keys FOR READ DemandItem RESULT result.
    METHODS rba_Header FOR READ IMPORTING keys_rba FOR READ DemandItem\_Header FULL result_requested RESULT result LINK association_links.
ENDCLASS.

CLASS lhc_DemandItem IMPLEMENTATION.
  METHOD update.
    LOOP AT entities INTO DATA(ls_entity).
      READ TABLE lhc_buffer=>mt_buffer-demand WITH KEY demand_id = ls_entity-demand_id ASSIGNING FIELD-SYMBOL(<fs_d>).
      IF sy-subrc <> 0.
         SELECT SINGLE * FROM zinv_demand_007 WHERE demand_id = @ls_entity-demand_id INTO @DATA(ls_db).
         INSERT ls_db INTO TABLE lhc_buffer=>mt_buffer-demand ASSIGNING <fs_d>.
      ENDIF.
      IF ls_entity-%control-quantity_sold = if_abap_behv=>mk-on. <fs_d>-quantity_sold = ls_entity-quantity_sold. ENDIF.
      IF ls_entity-%control-demand_date   = if_abap_behv=>mk-on. <fs_d>-demand_date   = ls_entity-demand_date. ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
    LOOP AT keys INTO DATA(ls_key).
      INSERT VALUE #( demand_id = ls_key-demand_id ) INTO TABLE lhc_buffer=>mt_buffer-demand_delete.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    SELECT * FROM zinv_demand_007 FOR ALL ENTRIES IN @keys WHERE demand_id = @keys-demand_id INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD rba_Header.
    IF keys_rba IS NOT INITIAL.
      SELECT product_id FROM zinv_demand_007 FOR ALL ENTRIES IN @keys_rba WHERE demand_id = @keys_rba-demand_id INTO TABLE @DATA(lt_links).
      IF lt_links IS NOT INITIAL.
        " Criticality calculation removed
        SELECT * FROM zinv_master_007 FOR ALL ENTRIES IN @lt_links WHERE product_id = @lt_links-product_id INTO CORRESPONDING FIELDS OF TABLE @result.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_ZI_INV_FORECAST_007 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_ZI_INV_FORECAST_007 IMPLEMENTATION.
  METHOD save.
    IF lhc_buffer=>mt_buffer-master IS NOT INITIAL.
      MODIFY zinv_master_007 FROM TABLE @lhc_buffer=>mt_buffer-master.
    ENDIF.
    IF lhc_buffer=>mt_buffer-master_delete IS NOT INITIAL.
      DELETE zinv_master_007 FROM TABLE @lhc_buffer=>mt_buffer-master_delete.
    ENDIF.
    IF lhc_buffer=>mt_buffer-demand IS NOT INITIAL.
      MODIFY zinv_demand_007 FROM TABLE @lhc_buffer=>mt_buffer-demand.
    ENDIF.
    IF lhc_buffer=>mt_buffer-demand_delete IS NOT INITIAL.
      DELETE zinv_demand_007 FROM TABLE @lhc_buffer=>mt_buffer-demand_delete.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    CLEAR lhc_buffer=>mt_buffer.
  ENDMETHOD.
ENDCLASS.
