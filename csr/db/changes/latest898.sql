-- Please update version.sql too -- this keeps clean builds in sync
define version=898
@update_header


ALTER TABLE CSR.DELEG_PLAN_DELEG_REGION DROP CONSTRAINT CHK_DELEG_PLAN_DR_PENDING_DEL;
ALTER TABLE CSR.DELEG_PLAN_SURVEY_REGION DROP CONSTRAINT CHK_DELEG_PLAN_SR_PENDING_DEL;


ALTER TABLE CSR.DELEG_PLAN_DELEG_REGION ADD (
	REGION_SELECTION              VARCHAR2(1)      DEFAULT 'R' NOT NULL,
	CONSTRAINT CHK_DELEG_PLAN_DR_PENDING_DEL CHECK (PENDING_DELETION IN (0,1,2)),
	CONSTRAINT CHK_DLG_PLN_DLG_RGN_RS CHECK (REGION_SELECTION IN ('R','L','P'))
); 
ALTER TABLE CSR.DELEG_PLAN_SURVEY_REGION ADD (
	REGION_SELECTION              VARCHAR2(1)      DEFAULT 'R' NOT NULL,
	CONSTRAINT CHK_DELEG_PLAN_SR_PENDING_DEL CHECK (PENDING_DELETION IN (0,1,2)),
	CONSTRAINT CHK_DLG_PLN_SRV_RGN_RS CHECK (REGION_SELECTION IN ('R','L','P'))
);


CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_DELEG_REGION AS
	SELECT dpc.deleg_plan_sid, dpdr.deleg_plan_col_deleg_id, dpc.deleg_plan_col_id, dpc.is_hidden, 
		dpcd.delegation_sid, dpdr.region_sid, dpdr.maps_to_root_deleg_sid, 
		dpdr.has_manual_amends, dpdr.pending_deletion, dpdr.region_selection
	  FROM deleg_plan_deleg_region dpdr
		JOIN deleg_plan_col_deleg dpcd ON dpdr.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		JOIN deleg_plan_col dpc ON dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id;

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_SURVEY_REGION AS
	SELECT dpc.deleg_plan_sid, dpsr.deleg_plan_col_survey_id, dpc.deleg_plan_col_id, dpc.is_hidden, 
		dpcs.survey_sid, dpsr.region_sid, dpsr.maps_to_survey_response_id, 
		dpsr.has_manual_amends, dpsr.pending_deletion, dpsr.region_selection
	  FROM deleg_plan_survey_region dpsr
		JOIN deleg_plan_col_survey dpcs ON dpsr.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN deleg_plan_col dpc ON dpcs.deleg_plan_col_survey_id = dpc.deleg_plan_col_survey_id;

@..\csr_data_pkg
@..\deleg_plan_pkg
@..\deleg_plan_body

@update_tail
