INTERFACE lif_atc_phase.
  METHODS:
    get_details
      IMPORTING i_exec_id     TYPE satc_d_project_execution_id
      RETURNING VALUE(result) TYPE cl_satc_ui_mon_run_ph_provider=>ty_t_details.
ENDINTERFACE.

INTERFACE lif_call_function.
  METHODS
    get_user_full_name
      IMPORTING i_user        TYPE xubname
      RETURNING VALUE(result) TYPE suidtechdesc.
ENDINTERFACE.
