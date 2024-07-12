-- Please update version.sql too -- this keeps clean builds in sync
define version=754
@update_header

CREATE GLOBAL TEMPORARY TABLE csr.TEMP_VDS_IND
(
	IND_SID							NUMBER(10) NOT NULL,
	AGGREGATE						VARCHAR2(24) NOT NULL
)
ON COMMIT DELETE ROWS;

@../val_datasource_body

@update_tail
