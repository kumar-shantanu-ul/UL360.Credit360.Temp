-- Please update version.sql too -- this keeps clean builds in sync
define version=1359
@update_header 

CREATE GLOBAL TEMPORARY TABLE CSRIMP.TEMP_IMP_SET_VAL
(
	IMP_VAL_ID						NUMBER(10) NOT NULL,
	SET_VAL_ID						NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;
CREATE INDEX CSRIMP.IX_TEMP_IMP_SET_VAL ON CSRIMP.TEMP_IMP_SET_VAL (IMP_VAL_ID, SET_VAL_ID);

grant select,insert,update on csr.tab_portlet to csrimp;

@../csrimp/imp_body
@../csr_data_body

@update_tail
