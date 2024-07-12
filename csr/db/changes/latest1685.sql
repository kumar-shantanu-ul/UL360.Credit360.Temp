-- Please update version.sql too -- this keeps clean builds in sync
define version=1685
@update_header

ALTER TABLE chain.filter_value ADD description VARCHAR2(255);

CREATE OR REPLACE VIEW CHAIN.v$filter_value AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END) description
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP');

DECLARE
	v_filters_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	-- Fix superadmin personal filters add while not logged into an app so the SO
	-- doesn't become app-specific. clear app_sid if they exist already.
	FOR r IN (
		SELECT csr_user_sid
		  FROM csr.superadmin
	) LOOP
		BEGIN
			v_filters_sid := security.securableobject_pkg.GetSidFromPath(
				security.security_pkg.GetAct, r.csr_user_sid, 'Filters');
			UPDATE security.securable_object
			   SET application_sid_id = NULL
			 WHERE sid_id = v_filters_sid;
		EXCEPTION WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.securableobject_pkg.CreateSO(
				security.security_pkg.GetAct, r.csr_user_sid,
				security.security_pkg.SO_CONTAINER, 'Filters', v_filters_sid);
		END;
	END LOOP;
END;
/

@..\issue_pkg
@..\chain\filter_pkg

@..\issue_body
@..\csr_user_body
@..\chain\filter_body

@update_tail


