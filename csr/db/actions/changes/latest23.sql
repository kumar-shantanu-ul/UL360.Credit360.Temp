-- Please update version.sql too -- this keeps clean builds in sync
define version=23
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD (
	USE_ACTIONS_V2           NUMBER(1, 0)     DEFAULT 0 NOT NULL
);

UPDATE customer_options SET use_actions_v2 = 1
 WHERE app_sid IN (
 	SELECT app_sid FROM csr.customer 
 	 WHERE host = 'london2012.credit360.com'
 	    OR host = 'london2012test.credit360.com'
 	    OR host = 'london2012ali.credit360.com'
 	    OR host = 'london2012sue.credit360.com'
 	    OR host = 'britishland.credit360.com'
 	    OR host = 'example.credit360.com'
	); 
COMMIT;

@update_tail
