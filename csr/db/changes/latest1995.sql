-- Please update version.sql too -- this keeps clean builds in sync
define version=1995
@update_header

ALTER TABLE csrimp.issue ADD FORECAST_DTM DATE;
ALTER TABLE csrimp.issue ADD LAST_FORECAST_DTM DATE;
ALTER TABLE csrimp.issue_action_log ADD OLD_FORECAST_DTM DATE;
ALTER TABLE csrimp.issue_action_log ADD NEW_FORECAST_DTM DATE;
ALTER TABLE csrimp.issue_type ADD SHOW_FORECAST_DTM NUMBER(1,0) DEFAULT 0 NOT NULL;

@../schema_body
@../csrimp/imp_body

@update_tail