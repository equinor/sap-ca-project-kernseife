CLASS zknsf_cl_atc_run_sadl DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sadl_exit_calc_element_read.
    INTERFACES if_ycm_aps_persistence.

    ALIASES project_state FOR if_ycm_aps_persistence~co_project_status.
    ALIASES atc_state FOR if_ycm_aps_persistence~co_atc_state.

    METHODS constructor.

  PRIVATE SECTION.

    CONSTANTS:
      c_started_by_initial       TYPE c LENGTH 12 VALUE '-',
      c_started_on_initial       TYPE d VALUE 0,
      c_number_entities_initial  TYPE i VALUE 0,
      c_number_entities_finished TYPE i VALUE 100,
      c_phase_check_objects      TYPE i VALUE 4,
      c_phase_compute_objects    TYPE i VALUE 3.

    DATA:
      mr_atc_helper    TYPE REF TO if_ycm_aps_atc_helper,
      mr_atc_phase     TYPE REF TO lif_atc_phase,
      mr_call_function TYPE REF TO lif_call_function.

    METHODS: get_atc_run_details
      IMPORTING
                i_atc_run_series TYPE satc_d_ci_config_serie_name
                i_project_id     TYPE sycm_aps_project_id
      RETURNING VALUE(result)    TYPE sycm_aps_i_atc_run_state,

      convert_char_to_int
        IMPORTING i_char       TYPE sychar10
        RETURNING VALUE(r_int) TYPE i,

      get_state_text
        IMPORTING i_s4h_state     TYPE sycm_aps_i_atc_run_state-s4h_state
        RETURNING VALUE(r_result) TYPE sycm_aps_i_atc_run_state-s4h_state_text,

      calculate_crit_indicator
        IMPORTING i_state                 TYPE sycm_aps_atc_state
        RETURNING VALUE(r_crit_indicator) TYPE i,

      run_series_is_scheduled
        IMPORTING i_project_status TYPE data
        RETURNING VALUE(result)    TYPE abap_boolean,

      get_number_of_check_failures
        IMPORTING
          i_project_id                   TYPE sycm_aps_project_id
        RETURNING
          VALUE(r_number_check_failures) TYPE int8.

ENDCLASS.



CLASS zknsf_cl_atc_run_sadl IMPLEMENTATION.


  METHOD calculate_crit_indicator.

    CASE i_state.
      WHEN atc_state-failed.
        r_crit_indicator  = 1.
      WHEN atc_state-not_started
            OR atc_state-scheduled
            OR atc_state-failed_old_available
            OR atc_state-running
            OR atc_state-running_old_available.
        r_crit_indicator = 2.
      WHEN OTHERS.
        r_crit_indicator = 3.
    ENDCASE.

  ENDMETHOD.


  METHOD constructor.
    mr_atc_helper    = NEW cl_ycm_aps_atc_helper( ).
    mr_atc_phase     = NEW lcl_atc_phase( ).
    mr_call_function = NEW lcl_call_function( ).
  ENDMETHOD.


  METHOD convert_char_to_int.
    r_int = CONV numc10( i_char ).
  ENDMETHOD.


  METHOD get_atc_run_details.

    DATA(last_run)    = mr_atc_helper->get_last_run_info_for_series( i_atc_run_series ).
    DATA(last_result) = mr_atc_helper->get_last_result_info_for_serie( i_atc_run_series ).
    DATA(number_check_failures) = get_number_of_check_failures( i_project_id ).

    IF last_run IS NOT INITIAL.

      DATA(phase_details) = mr_atc_phase->get_details( last_run-exec_id ).

      result-s4h_state      = |{ last_run-state ALIGN = LEFT }|.
      result-s4h_started_on = last_run-started_on.
      result-s4h_started_by = last_run-created_by.
      result-s4h_total      = me->convert_char_to_int( VALUE #( phase_details[ phase_key = c_phase_compute_objects ]-nbr_entities_total_c ) ).
      result-s4h_processed  = me->convert_char_to_int( VALUE #( phase_details[ phase_key = c_phase_check_objects ]-nbr_entities_processed_c ) ).
      result-s4h_total  = COND #( WHEN result-s4h_processed > result-s4h_total THEN result-s4h_processed ELSE result-s4h_total ).
      result-s4h_failed     = number_check_failures.

      IF result-s4h_state = atc_state-finished AND result-s4h_failed > 0.
        result-s4h_state = atc_state-finished_with_warning.
      ENDIF.

      IF last_result IS NOT INITIAL.
        result-s4h_state = |1{ result-s4h_state }|.
      ENDIF.

    ELSEIF last_result IS NOT INITIAL.
      result-s4h_state = COND #( WHEN number_check_failures = 0 THEN atc_state-finished ELSE atc_state-finished_with_warning ).
      result-s4h_started_on = last_result-scheduled_on_ts.
      result-s4h_started_by = last_result-scheduled_by.
      result-s4h_processed = c_number_entities_finished.
      result-s4h_total = c_number_entities_finished.
      result-s4h_failed = number_check_failures.
    ELSE.
      result-s4h_state = atc_state-not_started.
      result-s4h_started_on = c_started_on_initial.
      result-s4h_started_by = c_started_by_initial.
      result-s4h_processed = c_number_entities_initial.
      result-s4h_total = c_number_entities_initial.
      result-s4h_failed = c_number_entities_initial.
    ENDIF.

  ENDMETHOD.


  METHOD get_number_of_check_failures.

    SELECT SINGLE FROM sycm_aps_c_check_failure
      FIELDS COUNT(*)
      WHERE project_id = @i_project_id
      GROUP BY project_id
      INTO      @r_number_check_failures ##WARN_OK.

  ENDMETHOD.


  METHOD get_state_text.
    SELECT SINGLE FROM sycm_aps_i_atc_run_state_text
      FIELDS text
      WHERE run_state = @i_s4h_state
      INTO @r_result.
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA result TYPE zknsf_i_run_state.

    LOOP AT it_original_data ASSIGNING FIELD-SYMBOL(<project>).
      READ TABLE ct_calculated_data ASSIGNING FIELD-SYMBOL(<fs_calculated_data>) INDEX sy-tabix.

      ASSIGN COMPONENT 'PROJECTID' OF STRUCTURE <project> TO FIELD-SYMBOL(<project_id>).
      ASSIGN COMPONENT 'STATUS' OF STRUCTURE <project> TO FIELD-SYMBOL(<project_status>).

      SELECT SINGLE FROM sycma_project FIELDS atc_run_series WHERE project_id = @<project_id> INTO @DATA(atc_run_series).

      IF atc_run_series IS INITIAL.
        result-runstate          = atc_state-not_started.
        result-startedby     = c_started_by_initial.
        result-startedon     = c_started_on_initial.
      ELSE.
        result = me->get_atc_run_details(
          i_atc_run_series = atc_run_series
          i_project_id     = <project_id>
        ).
      ENDIF.

      IF result-runstate = atc_state-not_started AND me->run_series_is_scheduled( <project_status> ).
        result-runstate = atc_state-scheduled.
      ENDIF.

      result-criticalindicator = calculate_crit_indicator( result-runstate ).
      result-runstatetext     = get_state_text( result-runstate ).
      result-startedby     = mr_call_function->get_user_full_name( CONV #( result-startedby ) ).

      MOVE-CORRESPONDING result TO <fs_calculated_data>.
    ENDLOOP.

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info ##NEEDED.
  ENDMETHOD.


  METHOD run_series_is_scheduled.

    result  = xsdbool( i_project_status = project_state-new OR
                       i_project_status = project_state-loading_namespaces OR
                       i_project_status = project_state-loading_objects OR
                       i_project_status = project_state-loading_usage OR
                       i_project_status = project_state-default_scoping_in_progress ).

  ENDMETHOD.
ENDCLASS.
