-- Please update version.sql too -- this keeps clean builds in sync
define version=1798
@update_header

CREATE GLOBAL TEMPORARY TABLE CSRIMP.TEMP_ROLE_MAP (
	csrimp_session_id			NUMBER(10),
	user_sid					NUMBER(10),
	region_sid					NUMBER(10),
	role_sid					NUMBER(10),
	inherited_from_sid			NUMBER(10),
	mapped_user_sid				NUMBER(10),
	mapped_region_sid			NUMBER(10),
	mapped_role_sid				NUMBER(10),
	mapped_inherited_from_sid	NUMBER(10)
) ON COMMIT DELETE ROWS;

@..\csrimp\imp_body

@update_tail