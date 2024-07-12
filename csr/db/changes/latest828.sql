-- Please update version.sql too -- this keeps clean builds in sync
define version=828
@update_header


ALTER TABLE CSR.LOGISTICS_TAB_MODE MODIFY SET_DISTANCE_SP NULL;
ALTER TABLE CSR.LOGISTICS_TAB_MODE MODIFY GET_ROWS_SP NULL;

update csr.logistics_tab_mode
  set SET_DISTANCE_SP = null,
    GET_ROWS_SP = null
 where processor_class IN ('Logistics.Modes.AirportJobProcessor','Logistics.Modes.AirCountryJobProcessor');

create index csr.ix_distance_transport_mod on csr.distance (transport_mode_id);
create index csr.ix_ind_validatio_ind_sid on csr.ind_validation_rule (app_sid, ind_sid);
create index csr.ix_logistics_err_tab_sid_proce on csr.logistics_error_log (app_sid, tab_sid, processor_class);
create index csr.ix_logistics_tab_transport_mod on csr.logistics_tab_mode (transport_mode_id);


@..\logistics_pkg
@..\logistics_body

@update_tail
