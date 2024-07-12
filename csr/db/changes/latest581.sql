-- Please update version.sql too -- this keeps clean builds in sync
define version=581
@update_header

CREATE GLOBAL TEMPORARY TABLE temp_ind
(
	app_sid		NUMBER(10, 0) NOT NULL,
	ind_sid		NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_temp_ind PRIMARY KEY (app_sid, ind_sid)
) ON COMMIT DELETE ROWS;

@..\pending_body

@update_tail
