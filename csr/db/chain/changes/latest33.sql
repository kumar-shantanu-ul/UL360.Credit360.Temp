define version=33
@update_header

ALTER TABLE CHAIN.CMPNT_PROD_REL_PENDING
	ADD (REJECTED NUMBER(1,0) DEFAULT 0 NOT NULL);

@update_tail
