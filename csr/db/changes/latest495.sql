-- Please update version.sql too -- this keeps clean builds in sync
define version=495
@update_header

BEGIN
	INSERT INTO issue_type (app_sid, issue_type_id, label)
	SELECT UNIQUE(app_sid), 4, 'Scheduled task'
	  FROM issue_type;
END;
/

@update_tail
