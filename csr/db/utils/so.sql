SELECT
	sid_id
,	name so_name
,	(SELECT class_name FROM security.securable_object_class WHERE class_id = securable_object.class_id) cls_name
,	CASE (SELECT class_name FROM security.securable_object_class WHERE class_id = securable_object.class_id)
		WHEN 'CSRUser' THEN (SELECT DISTINCT user_name FROM csr.csr_user WHERE csr_user_sid = securable_object.sid_id)
		WHEN 'AspenApp' THEN (SELECT host FROM csr.customer WHERE app_sid = securable_object.sid_id)
		WHEN 'CSRApp' THEN (SELECT host FROM csr.customer WHERE app_sid = securable_object.sid_id)
		WHEN 'CSRDelegation' THEN (SELECT name FROM csr.delegation WHERE delegation_sid = securable_object.sid_id)
		WHEN 'CSRIndicator' THEN (SELECT description FROM csr.v$ind WHERE ind_sid = securable_object.sid_id)
		WHEN 'CSRRegion' THEN (SELECT description FROM csr.v$region WHERE region_sid = securable_object.sid_id)
		WHEN 'CSRModel' THEN (SELECT name FROM csr.model WHERE model_sid = securable_object.sid_id)
		WHEN 'CSRModelInstance' THEN (SELECT description FROM csr.model_instance WHERE model_instance_sid = securable_object.sid_id)
		WHEN 'CSRPortlet' THEN (SELECT name FROM csr.customer_portlet cp JOIN csr.portlet p ON cp.portlet_id = p.portlet_id WHERE customer_portlet_sid = securable_object.sid_id)
		WHEN 'CSRFlow' THEN (SELECT label FROM csr.flow WHERE flow_sid = securable_object.sid_id)
		ELSE null END info
,	dacl_id
,	application_sid_id
FROM
	security.securable_object
START WITH
	sid_id = &1
CONNECT BY
	sid_id = PRIOR parent_sid_id
ORDER BY
	level DESC
;