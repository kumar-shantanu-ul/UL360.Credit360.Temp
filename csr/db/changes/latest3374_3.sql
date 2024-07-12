-- Please update version.sql too -- this keeps clean builds in sync
define version=3374
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DECLARE
	v_sids		security.security_pkg.T_SID_IDS;
	PROCEDURE SetStateRoles(
		in_state_id					IN	csr.flow_state.flow_state_id%TYPE,
		in_editable_role_sids		IN	security.security_pkg.T_SID_IDS,
		in_non_editable_role_sids	IN	security.security_pkg.T_SID_IDS,
		in_editable_col_sids		IN	security.security_pkg.T_SID_IDS,
		in_non_editable_col_sids	IN	security.security_pkg.T_SID_IDS,
		in_involved_type_ids		IN	security.security_pkg.T_SID_IDS,
		in_editable_group_sids		IN	security.security_pkg.T_SID_IDS,
		in_non_editable_group_sids	IN	security.security_pkg.T_SID_IDS
	)
	AS
		CURSOR c IS
			SELECT f.flow_sid, f.label flow_label, fs.label state_label
				FROM csr.flow_state fs
				JOIN csr.flow f ON fs.flow_sid = f.flow_sid
			 WHERE fs.flow_state_id = in_state_id;
		ar	c%ROWTYPE;
			t_editable_role_sids 		security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_editable_role_sids);
			t_non_editable_role_sids 	security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_non_editable_role_sids);
			t_editable_col_sids 		security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_editable_col_sids);
			t_non_editable_col_sids 	security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_non_editable_col_sids);
			t_involved_type_ids			security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_involved_type_ids);
			t_editable_group_sids 		security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_editable_group_sids);
			t_non_editable_group_sids 	security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_non_editable_group_sids);
	BEGIN
		-- we audit this, so the long way round (rather than just deleting)
		OPEN c;
		FETCH c INTO ar;
		IF c%NOTFOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Workflow state '||in_state_id||' not found');
		END IF;
	
		IF NOT security.security_pkg.IsAccessAllowedSID(security.security_pkg.getACT, ar.flow_sid, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to flow sid '||ar.flow_sid);
		END IF;
	
		-- deleted roles
		FOR r IN (
			SELECT role_sid, name
				FROM csr.role
			 WHERE role_sid IN (
				SELECT role_sid
					FROM csr.flow_state_role
				 WHERE flow_state_id = in_state_id
				 MINUS
				SELECT column_value FROM TABLE(t_editable_role_sids)
				 MINUS
				SELECT column_value FROM TABLE(t_non_editable_role_sids)
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", deleted role "{1}" for state "{2}"',
				ar.flow_label, r.name, ar.state_label);
	
			DELETE FROM csr.flow_state_role_capability
			 WHERE flow_state_id = in_state_id
				 AND role_sid = r.role_sid;
	
			-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_role too
			DELETE FROM csr.flow_state_role
			 WHERE flow_state_id = in_state_Id
				 AND role_sid = r.role_sid;
		END LOOP;
	
		-- deleted groups
		FOR r IN (
			SELECT gt.sid_id, so.name
				FROM security.group_table gt
				JOIN security.securable_object so on gt.sid_id = so.sid_id
				JOIN security.securable_object_class soc on so.class_id = soc.class_id
			 WHERE (soc.class_name = 'Group' or soc.class_name = 'CSRUserGroup')
				 AND gt.sid_id IN (
				SELECT group_sid
					FROM csr.flow_state_role
				 WHERE flow_state_id = in_state_id
				 MINUS
				SELECT column_value FROM TABLE(t_editable_group_sids)
				 MINUS
				SELECT column_value FROM TABLE(t_non_editable_group_sids)
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", deleted group "{1}" for state "{2}"',
				ar.flow_label, r.name, ar.state_label);
	
			DELETE FROM csr.flow_state_role_capability
			 WHERE flow_state_id = in_state_id
				 AND group_sid = r.sid_id;
	
			-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_role too
			DELETE FROM csr.flow_state_role
			 WHERE flow_state_id = in_state_Id
				 AND group_sid = r.sid_id;
		END LOOP;
	
		-- added roles
		FOR r IN (
			SELECT role_sid, name
				FROM csr.role
			 WHERE role_sid IN (
				(
					SELECT column_value FROM TABLE(t_editable_role_sids)
					 UNION
					SELECT column_value FROM TABLE(t_non_editable_role_sids)
				)
					MINUS
				SELECT role_sid
					FROM csr.flow_state_role
				 WHERE flow_state_id = in_state_id
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", added role "{1}" for state "{2}"',
				ar.flow_label, r.name, ar.state_label);
	
			INSERT INTO csr.flow_state_role(flow_state_id, role_sid, is_editable)
				VALUES (in_state_id, r.role_sid, 0);
		END LOOP;
	
		-- added groups
		FOR r IN (
			SELECT gt.sid_id, so.name
				FROM security.group_table gt
				JOIN security.securable_object so on gt.sid_id = so.sid_id
				JOIN security.securable_object_class soc on so.class_id = soc.class_id
			 WHERE (soc.class_name = 'Group' or soc.class_name = 'CSRUserGroup')
				 AND gt.sid_id IN (
				(
					SELECT column_value FROM TABLE(t_editable_group_sids)
					 UNION
					SELECT column_value FROM TABLE(t_non_editable_group_sids)
				)
				MINUS
				SELECT group_sid
					FROM csr.flow_state_role
				 WHERE flow_state_id = in_state_id
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", added group "{1}" for state "{2}"',
				ar.flow_label, r.name, ar.state_label);
	
			INSERT INTO csr.flow_state_role(flow_state_id, group_sid, is_editable)
				VALUES (in_state_id, r.sid_id, 0);
		END LOOP;
	
		-- deleted columns
		FOR r IN (
			SELECT column_sid, oracle_column name
				FROM cms.tab_column
			 WHERE column_sid IN (
				SELECT column_sid
					FROM csr.flow_state_cms_col
				 WHERE flow_state_id = in_state_id
				 MINUS
				SELECT column_value FROM TABLE(t_editable_col_sids)
				 MINUS
				SELECT column_value FROM TABLE(t_non_editable_col_sids)
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", deleted column "{1}" for state "{2}"',
				ar.flow_label, r.name, ar.state_label);
	
			-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_column too
			DELETE FROM csr.flow_state_cms_col
			 WHERE flow_state_id = in_state_Id
				 AND column_sid = r.column_sid;
		END LOOP;
	
		-- added columns
		FOR r IN (
			SELECT column_sid, oracle_column name
				FROM cms.tab_column
			 WHERE column_sid IN (
				(
					SELECT column_value FROM TABLE(t_editable_col_sids)
					 UNION
					SELECT column_value FROM TABLE(t_non_editable_col_sids)
				)
					MINUS
				SELECT column_sid
					FROM csr.flow_state_cms_col
				 WHERE flow_state_id = in_state_id
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for state "{2}"',
				ar.flow_label, r.name, ar.state_label);
	
			INSERT INTO csr.flow_state_cms_col (flow_state_id, column_sid, is_editable)
				VALUES (in_state_id, r.column_sid, 0);
		END LOOP;
	
		-- deleted invoved
		FOR r IN (
			SELECT flow_involvement_type_id, label
				FROM csr.flow_involvement_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
				 AND flow_involvement_type_id IN (
				SELECT flow_involvement_type_id
					FROM csr.flow_state_involvement
				 WHERE flow_state_id = in_state_id
				 MINUS
				SELECT column_value FROM TABLE(t_involved_type_ids)
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", deleted involvement "{1}" for state "{2}"',
				ar.flow_label, r.label, ar.state_label);
	
			DELETE FROM csr.flow_state_role_capability
			 WHERE flow_state_id = in_state_id
				 AND flow_involvement_type_id = r.flow_involvement_type_id;
	
			-- there's a cascade delete on the FK constraint which deletes from flow_state_transition_column too
			DELETE FROM csr.flow_state_involvement
			 WHERE flow_state_id = in_state_Id
				 AND flow_involvement_type_id = r.flow_involvement_type_id;
		END LOOP;
	
		-- added involved
		FOR r IN (
			SELECT flow_involvement_type_id, label
				FROM csr.flow_involvement_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
				 AND flow_involvement_type_id IN (
				(
					SELECT column_value FROM TABLE(t_involved_type_ids)
				)
					MINUS
				SELECT flow_involvement_type_id
					FROM csr.flow_state_involvement
				 WHERE flow_state_id = in_state_id
			 )
		)
		LOOP
			csr.csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getACT, csr.csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security.security_pkg.getApp,
				ar.flow_sid, 'Altered workflow "{0}", added column "{1}" for state "{2}"',
				ar.flow_label, r.label, ar.state_label);
	
			INSERT INTO csr.flow_state_involvement (flow_state_id, flow_involvement_type_id)
				VALUES (in_state_id, r.flow_involvement_type_id);
		END LOOP;
	
		-- finally set editable or not
		UPDATE csr.flow_state_role
			 SET is_editable = 1
		 WHERE flow_state_id = in_state_id
			 AND role_sid IN (SELECT column_value FROM TABLE(t_editable_role_sids))
			 AND is_editable = 0;
	
		UPDATE csr.flow_state_role
			 SET is_editable = 1
		 WHERE flow_state_id = in_state_id
			 AND group_sid IN (SELECT column_value FROM TABLE(t_editable_group_sids))
			 AND is_editable = 0;
	
		UPDATE csr.flow_state_role
			 SET is_editable = 0
		 WHERE flow_state_id = in_state_id
			 AND role_sid IN (SELECT column_value FROM TABLE(t_non_editable_role_sids))
			 AND is_editable = 1;
	
		UPDATE csr.flow_state_role
			 SET is_editable = 0
		 WHERE flow_state_id = in_state_id
			 AND group_sid IN (SELECT column_value FROM TABLE(t_non_editable_group_sids))
			 AND is_editable = 1;
	
		UPDATE csr.flow_state_cms_col
			 SET is_editable = 1
		 WHERE flow_state_id = in_state_id
			 AND column_sid IN (SELECT column_value FROM TABLE(t_editable_col_sids))
			 AND is_editable = 0;
	
		UPDATE csr.flow_state_cms_col
			 SET is_editable = 0
		 WHERE flow_state_id = in_state_id
			 AND column_sid IN (SELECT column_value FROM TABLE(t_non_editable_col_sids))
			 AND is_editable = 1;
	END;
	FUNCTION SidListToArray(
		in_sid_list	VARCHAR2
	) RETURN security.security_pkg.T_SID_IDS
	AS
		v_sids		security.security_pkg.T_SID_IDS;
	BEGIN
		-- bit icky -- i.e. random spacing etc would probably blow this up
		IF in_sid_list IS NOT NULL THEN
			 SELECT TO_NUMBER(REGEXP_SUBSTR(in_sid_list, '[^,]+',1,ROWNUM))
				 BULK COLLECT INTO v_sids
				 FROM DUAL
			 CONNECT BY ROWNUM <= (LENGTH(in_sid_list) - LENGTH(REPLACE(in_sid_list,',')) + 1);
		ELSE
			SELECT null
				BULK COLLECT INTO v_sids
				FROM DUAL;
		END IF;
	
		RETURN v_sids;
	END;
BEGIN
	FOR r IN (
		SELECT c.host, fs.flow_state_id
			FROM csr.flow f
			JOIN csr.flow_state fs ON f.flow_sid = fs.flow_sid
			JOIN csr.customer c ON f.app_sid = c.app_sid
		 WHERE f.label = 'RBA Audit Workflow'
			 AND fs.label = 'Created'
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		v_sids(1) := security.securableobject_pkg.GetSIDFromPath(null, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/Audit administrators');
		SetStateRoles(
			in_state_id					=> r.flow_state_id,
			in_editable_role_sids		=> SidListToArray(''),
			in_non_editable_role_sids 	=> SidListToArray(''),
			in_editable_col_sids		=> SidListToArray(''),
			in_non_editable_col_sids	=> SidListToArray(''),
			in_involved_type_ids		=> SidListToArray(''),
			in_editable_group_sids		=> v_sids,
			in_non_editable_group_sids	=> SidListToArray('')
		);
		security.user_pkg.logonadmin();
	END LOOP;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail
