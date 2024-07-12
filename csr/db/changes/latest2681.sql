--Please update version.sql too -- this keeps clean builds in sync
define version=2681
@update_header

DECLARE
	v_exists		NUMBER;
BEGIN

	SELECT count(*)
	  INTO v_exists
	  FROM csr.source_type
	 WHERE description = 'Scheduled import';
	
	IF v_exists = 0 THEN
		INSERT INTO csr.source_type
			(source_type_id, description)
		VALUES
			(15, 'Scheduled import');
	END IF;

END;
/

@update_tail
