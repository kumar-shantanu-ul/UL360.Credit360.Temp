-- Please update version.sql too -- this keeps clean builds in sync
define version=2275
@update_header

CREATE INDEX CSR.IX_TEMP_INIT_AGGR_VAL_DTM ON CSR.TEMP_INITIATIVE_AGGR_VAL(initiative_sid, initiative_metric_id, region_sid, start_dtm);
CREATE INDEX CSR.IX_INIT_METRIC_TAG_IND_METIND ON CSR.INITIATIVE_METRIC_TAG_IND(app_sid, initiative_metric_id, ind_sid, measure_sid);
CREATE INDEX CSR.IX_INIT_MET_STATE_IND_METIND ON CSR.INITIATIVE_METRIC_STATE_IND(app_sid, initiative_metric_id, ind_sid, measure_sid);

@../initiative_aggr_body

@update_tail
