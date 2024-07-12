-- Please update version.sql too -- this keeps clean builds in sync
define version=2715
@update_header

-- base data
UPDATE CSR.AUDIT_TYPE SET LABEL = 'Finding change'
 WHERE AUDIT_TYPE_GROUP_ID = 1
   AND AUDIT_TYPE_ID = 91;

UPDATE csr.flow_capability SET description = 'Findings'
 WHERE flow_capability_id = 3
   AND flow_alert_class = 'audit';

UPDATE csr.flow_capability SET description = 'Import findings'
 WHERE flow_capability_id = 11
   AND flow_alert_class = 'audit';

UPDATE csr.module SET description = 'Enable audit/finding filtering pages'
 WHERE module_id = 42;

-- Menu item for default findings
UPDATE security.menu
   SET description = 'Default findings'
 WHERE LOWER(action) = '/csr/site/audit/admin/defaultnoncompliances.acds'
   AND description = 'Default non-compliances';

DECLARE
	v_count number := 0;
BEGIN
	FOR r IN (
		SELECT app_sid, internal_audit_sid FROM csr.internal_audit
	) LOOP
		UPDATE csr.audit_log
		   SET param_1 = 'Finding label'
		 WHERE audit_type_id = 91
		   AND description = '{0} changed from "{1}" to "{2}"'
		   AND param_1 = 'Non-compliance label'
		   AND app_sid = r.app_sid
		   AND object_sid = r.internal_audit_sid;
		v_count := v_count + SQL%ROWCOUNT;
		
		UPDATE csr.audit_log
		   SET description = CASE description
				WHEN 'Non-compliance added: {0} ({1})' THEN 'Finding added: {0} ({1})'
				WHEN 'Non-compliance closed: {0} ({1})' THEN 'Finding closed: {0} ({1})'
				WHEN 'Non-compliance reopened: {0} ({1})' THEN 'Finding reopened: {0} ({1})'
				WHEN 'Non-compliance deleted: {0} ({1})' THEN 'Finding deleted: {0} ({1})'
				ELSE description END
		 WHERE audit_type_id = 91
		   AND description IN ('Non-compliance added: {0} ({1})', 'Non-compliance closed: {0} ({1})', 'Non-compliance reopened: {0} ({1})', 'Non-compliance deleted: {0} ({1})')
		   AND app_sid = r.app_sid
		   AND object_sid = r.internal_audit_sid;
		v_count := v_count + SQL%ROWCOUNT;
		
	END LOOP;
	dbms_output.put_line('Updated: '||v_count||' audit log entries');
END;
/

@..\audit_body

@update_tail
