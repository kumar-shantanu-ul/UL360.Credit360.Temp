-- Please update version.sql too -- this keeps clean builds in sync
define version=2584
@update_header

CREATE OR REPLACE FUNCTION csr.getSysDate
RETURN DATE
AS
BEGIN
	RETURN SYSDATE;
END;
/

@update_tail
