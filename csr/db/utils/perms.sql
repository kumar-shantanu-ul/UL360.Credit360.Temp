SELECT
	acl.sid_id acl_sid
,	(SELECT name FROM security.securable_object WHERE sid_id = acl.sid_id) name
,	CASE acl.ace_type WHEN 1 THEN 'ALLOW' WHEN 2 THEN 'DENY' ELSE CAST(acl.ace_type AS VARCHAR2(5)) END "GRANT"
,	CASE WHEN BITAND(acl.ace_flags, 512) <> 0 THEN 'A' ELSE '-' END
||	CASE WHEN BITAND(acl.ace_flags, 256) <> 0 THEN 'wA' ELSE '--' END
||	CASE WHEN BITAND(acl.ace_flags, 128) <> 0 THEN 'rA' ELSE '--' END
||	CASE WHEN BITAND(acl.ace_flags, 64) <> 0 THEN 'L' ELSE '-' END
||	CASE WHEN BITAND(acl.ace_flags, 32) <> 0 THEN 'P' ELSE '-' END
||	CASE WHEN BITAND(acl.ace_flags, 16) <> 0 THEN 'O' ELSE '-' END
||	CASE WHEN BITAND(acl.ace_flags, 8) <> 0 THEN 'C' ELSE '-' END
||	CASE WHEN BITAND(acl.ace_flags, 4) <> 0 THEN 'D' ELSE '-' END
||	CASE WHEN BITAND(acl.ace_flags, 2) <> 0 THEN 'W' ELSE '-' END
||	CASE WHEN BITAND(acl.ace_flags, 1) <> 0 THEN 'R' ELSE '-' END "AwArALPOCDWR"
,	bitand(acl.permission_set, 17179868160) non_standard
,	CASE WHEN BITAND(acl.ace_flags, 4) <> 0 THEN 'I' ELSE '-' END || CASE WHEN BITAND(acl.ace_flags, 2) <> 0 THEN 'H' ELSE '-' END || CASE WHEN BITAND(acl.ace_flags, 1) <> 0 THEN 'D' ELSE '-' END "IHD"
,	act.sid_id
,	CASE act.act_type WHEN 1 THEN 'USER' WHEN 2 THEN 'GROUP' ELSE CAST(act.act_type AS VARCHAR2(5)) END type
,	securable_object.name principal
--,	securable_object.parent_sid_id
--,	securable_object.class_id
,	(SELECT class_name FROM security.securable_object_class WHERE class_id = securable_object.class_id) cls_name
,	securable_object.flags
,	securable_object.owner
,	securable_object.link_sid_id
,	securable_object.application_sid_id app_sid
,	acl.acl_id
  FROM security.act
  JOIN security.securable_object ON securable_object.sid_id = act.sid_id
  JOIN security.acl ON acl.acl_id = securable_object.dacl_id
 WHERE act_id = '&1'
 ORDER BY act_index, acl_index;
