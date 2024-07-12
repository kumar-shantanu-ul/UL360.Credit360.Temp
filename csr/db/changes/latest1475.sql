-- Please update version.sql too -- this keeps clean builds in sync
define version=1475
@update_header

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_SUMMARY_TASKS
(
	TASK_NAME			VARCHAR2(255) NOT NULL,
	TASK_TYPE_ID		NUMBER(10) NOT NULL,
	COMPANY_SID			NUMBER(10) NOT NULL,
	POSITION			NUMBER(10) NOT NULL,
	DUE_NOW				NUMBER(10),
	OVER_DUE			NUMBER(10),
	REALLY_OVER_DUE		NUMBER(10),
	DUE_SOON			NUMBER(10),
	DUE_LATER			NUMBER(10)
) 
ON COMMIT PRESERVE ROWS; 

@..\chain\chain_link_pkg

@..\chain\chain_link_body
@..\chain\task_body

@update_tail