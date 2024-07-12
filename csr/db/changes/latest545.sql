-- Please update version.sql too -- this keeps clean builds in sync
define version=545
@update_header

DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM aspen2.version;
	IF v_version < 17 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||&version||' CANNOT BE APPLIED TO A ***ASPEN2*** DATABASE OF VERSION '||v_version||' (cvs\aspen2\db\changes) =======');
	END IF;
END;
/

@..\csr_data_body

@update_tail
