-- Please update version.sql too -- this keeps clean builds in sync
define version=2270
@update_header

CREATE OR REPLACE VIEW csr.v$deleg_plan_delegs AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpcd.delegation_sid template_deleg_sid,
		   dpdrd.maps_to_root_deleg_sid, d.delegation_sid applied_to_delegation_sid, d.lvl, d.is_leaf
	  FROM deleg_plan_col dpc
	  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id AND dpc.app_sid = dpcd.app_sid
	  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpcd.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpcd.app_sid = dpdrd.app_sid
	  JOIN (
		SELECT CONNECT_BY_ROOT delegation_sid root_delegation_sid, delegation_sid, level lvl, connect_by_isleaf is_leaf
		  FROM delegation
		 START WITH parent_sid = app_sid
		CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid
	  ) d ON d.root_delegation_sid = dpdrd.maps_to_root_deleg_sid;

@..\deleg_plan_pkg
@..\deleg_plan_body

@update_tail
