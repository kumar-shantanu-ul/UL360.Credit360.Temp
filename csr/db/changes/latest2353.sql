-- Please update version.sql too -- this keeps clean builds in sync
define version=2353
@update_header

--New capability to allow a user to download all templatde reports generated in their app
BEGIN

	BEGIN
		INSERT INTO csr.capability (name, allow_by_default) VALUES ('Download all templated reports', 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

@../templated_report_pkg
@../templated_report_body

@update_tail
