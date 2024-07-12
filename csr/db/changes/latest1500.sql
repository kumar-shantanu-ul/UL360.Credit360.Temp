-- Please update version.sql too -- this keeps clean builds in sync
define version=1500
@update_header

BEGIN
	EXECUTE IMMEDIATE 'alter table csr.import_feed_request modify (processed_dtm date null)';
EXCEPTION
	WHEN OTHERS THEN NULL;
END;
/

@update_tail