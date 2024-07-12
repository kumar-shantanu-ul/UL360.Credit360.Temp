-- Please update version.sql too -- this keeps clean builds in sync
define version=860
@update_header

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_COL AS
	SELECT deleg_plan_col_id, deleg_plan_sid, d.name label, dpc.is_hidden, 'Delegation' type, dpcd.delegation_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		JOIN delegation d ON dpcd.delegation_sid = d.delegation_sid
	 UNION
	SELECT deleg_plan_col_id, deleg_plan_sid, qs.label, dpc.is_hidden, 'Survey' type, dpcs.survey_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_survey dpcs ON dpc.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN quick_survey qs ON dpcs.survey_sid = qs.survey_sid;

@..\deleg_plan_body

ALTER TABLE CSRIMP.DELEGATION_IND DROP CONSTRAINT CK_DELEG_IND_VISIBLE;
ALTER TABLE CSRIMP.DELEGATION_IND ADD CONSTRAINT CK_DELEG_IND_VISIBLE CHECK (VISIBILITY IN ('SHOW','READONLY','HIDE'));



@update_tail
