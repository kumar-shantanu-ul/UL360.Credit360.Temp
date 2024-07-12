-- Please update version.sql too -- this keeps clean builds in sync
define version=1560
@update_header


CREATE OR REPLACE TYPE CHAIN.T_BUSINESS_UNIT_ROW AS 
  OBJECT ( 
	COMPANY_ID          NUMBER(10),
	DESCRIPTION 		VARCHAR2(255),
	IS_PRIMARY 			NUMBER(1)
  );
/

CREATE OR REPLACE TYPE CHAIN.T_BUSINESS_UNIT_TABLE AS
 TABLE OF T_BUSINESS_UNIT_ROW;
/ 

@..\chain\report_pkg
@..\chain\report_body

@update_tail
