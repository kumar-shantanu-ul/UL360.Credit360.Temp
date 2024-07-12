-- Please update version.sql too -- this keeps clean builds in sync
define version=53
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	INITIATIVE_END_DTM         DATE
);

UPDATE customer_options SET
	initiative_end_dtm = TO_DATE('01-JAN-2012')
 WHERE app_sid = (
	SELECT app_sid
	  FROM csr.customer
	 WHERE host = 'rbsenv.credit360.com'
 );

COMMIT;

@update_tail
