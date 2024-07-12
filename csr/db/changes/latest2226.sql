-- Please update version.sql too -- this keeps clean builds in sync
define version=2226
@update_header

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_PRODUCT_RESULT_HELPER
( 
	PRODUCT_ID				NUMBER(10) NOT NULL,
	DESCRIPTION				VARCHAR(4000),
	CODE1					VARCHAR(4000),
	CODE2					VARCHAR(100),
	CODE3					VARCHAR(100),
	STATUS 					VARCHAR(100),
	POSITION				NUMBER(10)
) 
ON COMMIT PRESERVE ROWS; 

@..\chain\product_body

@update_tail
