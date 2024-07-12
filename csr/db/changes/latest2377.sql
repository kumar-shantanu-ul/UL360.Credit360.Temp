-- Please update version.sql too -- this keeps clean builds in sync
define version=2377
@update_header

DECLARE
	v_check	NUMBER(1);
BEGIN
	SELECT COUNT(*) INTO v_check
	FROM cms.col_type
	WHERE col_type = 36;

	IF v_check = 0 THEN
		INSERT INTO cms.col_type (col_type, description) VALUES (36, 'Substance');
	END IF;
END;
/

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail
