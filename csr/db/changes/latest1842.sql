-- Please update version too -- this keeps clean builds in sync
define version=1842
@update_header

@../chain/admin_helper_pkg
@../chain/admin_helper_body

CREATE GLOBAL TEMPORARY TABLE "CHAIN"."TT_CUSTOMER_OPTIONS_PARAM" ( "ID" NUMBER(10,0) NOT NULL ENABLE, "NAME" VARCHAR2(100 BYTE) NOT NULL ENABLE, "VALUE" VARCHAR2(4000 BYTE) NOT NULL ENABLE, "DATA_TYPE" VARCHAR2(100 BYTE) NOT NULL ENABLE, "NULLABLE" NUMBER(1) NOT NULL ENABLE ) ON COMMIT DELETE ROWS ;

@update_tail
