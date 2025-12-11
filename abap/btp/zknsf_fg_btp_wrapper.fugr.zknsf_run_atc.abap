FUNCTION zknsf_run_atc.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(E_MESSAGE) TYPE  STRING
*"     VALUE(E_ERROR) TYPE  ABAP_BOOLEAN
*"----------------------------------------------------------------------
  TRY.
      DATA(transaction_manager) =
    /bobf/cl_tra_trans_mgr_factory=>get_transaction_manager(  ).
      transaction_manager->set_transaction_context( iv_enqueue_scope = /bobf/if_conf_c=>sc_enqueue_scope_dialog ).


      DATA(service_manager) =
        /bobf/cl_tra_serv_mgr_factory=>get_service_manager(
        iv_bo_key = if_sycm_aps_i_project_c=>sc_bo_key ).


      SELECT SINGLE projectid FROM zknsf_i_projects INTO @DATA(project_id).
      IF sy-subrc <> 0.
        " No Project exists!
        e_message = |Failed: No Project Exists|.
        e_error = abap_true.
        RETURN.
      ENDIF.


      DATA key_table TYPE /bobf/t_frw_key.
      APPEND VALUE /bobf/s_frw_key( key = project_id ) TO key_table.

      DATA(object_configuration) =
        /bobf/cl_frw_factory=>get_configuration(
        if_sycm_aps_i_project_c=>sc_bo_key
        ).


      service_manager->do_action( EXPORTING iv_act_key = if_sycm_aps_i_project_c=>sc_action-sycm_aps_i_project-run_atc
                                            it_key     = key_table
                                  IMPORTING eo_message = DATA(messages) ).


    CATCH cx_root.
      e_message = |Unkown Error|.
      e_error = abap_true.
      RETURN.
  ENDTRY.


ENDFUNCTION.
