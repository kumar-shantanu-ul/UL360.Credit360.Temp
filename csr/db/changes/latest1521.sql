-- Please update version.sql too -- this keeps clean builds in sync
define version=1521
@update_header

CREATE OR REPLACE TYPE CHAIN.T_NEWSFLASH_ROW AS 
  OBJECT ( 
	NEWSFLASH_ID 		NUMBER(10),
	RELEASED_DTM 		DATE,
	CONTENT 			CLOB,
	FOR_USERS 			NUMBER(1),
	FOR_SUPPLIERS 		NUMBER(1)
  );
/

CREATE OR REPLACE TYPE CHAIN.T_NEWSFLASH_TABLE AS
 TABLE OF T_NEWSFLASH_ROW;
/ 


@..\chain\newsflash_pkg
@..\chain\newsflash_body

@update_tail
