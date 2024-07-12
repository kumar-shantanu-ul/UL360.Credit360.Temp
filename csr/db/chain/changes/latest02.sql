define version=2
@update_header

CREATE GLOBAL TEMPORARY TABLE tt_user_details
(
	USER_SID			NUMBER(10),
	FULL_NAME           VARCHAR2(256), -- nice data types (from csr_user)
	FRIENDLY_NAME		VARCHAR2(255),
	PHONE_NUMBER		VARCHAR2(100),
	JOB_TITLE			VARCHAR2(100),
	VISIBILITY_ID       NUMBER(10)
) ON COMMIT PRESERVE ROWS;


ALTER TABLE CUSTOMER_OPTIONS ADD (CHAIN_IMPLEMENTATION VARCHAR2(100));

UPDATE CUSTOMER_OPTIONS SET CHAIN_IMPLEMENTATION = 'MAERSK';

@..\company_user_pkg
@..\company_user_body

@update_tail