-- Please update version.sql too -- this keeps clean builds in sync
define version=2097
@update_header

DECLARE
  v_attribute_id  security.security_pkg.T_ATTRIBUTE_ID;
BEGIN
	security.user_pkg.logonadmin(NULL);
	
	security.attribute_pkg.CreateDefinition(
		security.security_pkg.GetACT, security.class_pkg.GetClassId('CSRData'), 
		'issue-view-source-goes-to-deepest-sheet', 0, NULL, v_attribute_id);

EXCEPTION
  WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
    NULL;
END;
/

@../sheet_pkg
@../sheet_body
@../issue_body

@update_tail