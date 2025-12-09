CLASS lcl_atc_phase DEFINITION CREATE PUBLIC FINAL.

  PUBLIC SECTION.
    INTERFACES lif_atc_phase.
ENDCLASS.

CLASS lcl_atc_phase IMPLEMENTATION.

  METHOD lif_atc_phase~get_details.
    DATA(atc_phase_detail_util) = cl_satc_ui_mon_run_ph_provider=>get_instance( sy-uname ).
    atc_phase_detail_util->set_filter( i_exec_id ).
    result = atc_phase_detail_util->get_details( ).
  ENDMETHOD.

ENDCLASS.

class lcl_call_function definition create PUBLIC FINAL.

  public section.
    INTERFACES lif_call_function.
endclass.

class lcl_call_function implementation.

  method lif_call_function~get_user_full_name.
    DATA lv_user_description TYPE usr21.

    CALL FUNCTION 'SUSR_USER_ADDRESS_READ'
      EXPORTING
        user_name  = i_user
      IMPORTING
        user_usr21 = lv_user_description
      EXCEPTIONS
        OTHERS     = 1.

    IF sy-subrc = 0 and lv_user_description-techdesc <> space.
      result = lv_user_description-techdesc.
    ELSE.
      result = i_user.
    ENDIF.
  endmethod.

endclass.
