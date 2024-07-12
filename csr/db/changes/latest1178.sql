-- Please update version.sql too -- this keeps clean builds in sync
define version=1178
@update_header

CREATE GLOBAL TEMPORARY TABLE CT.TT_PS_ITEM_SEARCH
(
	ITEM_ID NUMBER(10) NOT NULL,
	SPEND NUMBER(20,10) NOT NULL
) ON COMMIT DELETE ROWS;

@..\ct\products_services_pkg
@..\ct\products_services_body

@update_tail
