-- Please update version.sql too -- this keeps clean builds in sync
define version=410
@update_header

ALTER TABLE REGION ADD (
	ACQUISITION_DTM	DATE 
);

ALTER TABLE DELEGATION ADD (
	MASTER_DELEGATION_SID NUMBER(10) 
);

ALTER TABLE DELEGATION ADD CONSTRAINT RefDELEGATION1428 
    FOREIGN KEY (APP_SID, MASTER_DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID);

@..\region_pkg.sql
@..\dataview_body.sql
@..\vb_legacy_body.sql
@..\range_body.sql
@..\utility_pkg.sql
@..\utility_body.sql
@..\meter_pkg.sql
@..\meter_body.sql
@..\utility_report_body.sql
@..\csr_data_pkg.sql
@..\pending_pkg.sql
@..\pending_body.sql
@..\indicator_pkg.sql
@..\region_body.sql
@..\sheet_body.sql
@..\val_datasource_body.sql
@..\schema_body.sql
@..\delegation_pkg.sql
@..\delegation_body.sql
@..\imp_body.sql

@update_tail
