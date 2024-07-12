-- Please update version.sql too -- this keeps clean builds in sync
define version=2541
@update_header

DECLARE
	v_wrong_named_card_id		NUMBER(10);
BEGIN
	-- Get card ID of filter that is incorrect.
	SELECT card_id
	  INTO v_wrong_named_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Credit360.Issues.Filters.IssuesCustomFieldsFilter');

	UPDATE chain.filter_type SET description = 'Issue Custom Fields Filter' WHERE card_id = v_wrong_named_card_id;
	UPDATE chain.card SET description = 'Issue Custom Fields Filter' WHERE card_id = v_wrong_named_card_id;
END;
/

-- Create dummy package so we can drop rubbish from initial checkin (if already run).
CREATE OR REPLACE PACKAGE chain.temp_card_pkg
IS

PROCEDURE aProc (
	in_num		  	IN	NUMBER
);

END temp_card_pkg;
/

DROP PACKAGE chain.temp_card_pkg;

-- Fix duplicate CSR capability (differences in basedata) or incorrect name of capability.
DECLARE
	v_count		NUMBER(10);
BEGIN
	-- See if there are two.
	SELECT COUNT(name)
	  INTO v_count
	  FROM csr.capability
	 WHERE lower(name) = 'delete and copy values';
	
	IF v_count > 1 THEN
		-- Delete the one that has the capital letter (which isn't used elsewhere).
		DELETE FROM csr.capability WHERE name = 'Delete and copy VALUES';
	ELSE
		-- Otherwise, just update the existing one.
		UPDATE csr.capability SET name = 'Delete and copy values' WHERE name = 'Delete and copy VALUES';
	END IF;
END;
/

@update_tail
