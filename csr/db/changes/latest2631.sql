--Please update version.sql too -- this keeps clean builds in sync
define version=2631
@update_header

-- Fix duff basedata.
DECLARE
	v_correct_exists	NUMBER(1);
BEGIN
	-- Audit type 120 was added to base data but the latest script adds it as 21... (FB52288)
	SELECT COUNT(*)
	  INTO v_correct_exists
	  FROM csr.audit_type
	 WHERE audit_type_id = 21;
	
	IF v_correct_exists != 1 THEN
		-- Insert correct audit type, update existing records and remove the old one.
		INSERT INTO csr.audit_type (audit_type_group_id, audit_type_id, label) VALUES (1, 21, 'Survey change');
		
		UPDATE csr.audit_log
		   SET audit_type_id = 21
		 WHERE audit_type_id = 120;
		
		-- Delete old one.
		DELETE FROM csr.audit_type where audit_type_id = 120;
	END IF;
END;
/
	
@update_tail