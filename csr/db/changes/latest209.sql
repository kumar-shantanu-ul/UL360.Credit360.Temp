-- Please update version.sql too -- this keeps clean builds in sync
define version=209
@update_header


ALTER TABLE CUSTOMER ADD (
	SELF_REG_GROUP_SID			NUMBER(10, 0)	NULL,
    SELF_REG_NEEDS_APPROVAL		NUMBER(1, 0)	DEFAULT 1 NOT NULL
);


ALTER TABLE AUTOCREATE_USER ADD (
	ACTIVATED_DTM				DATE			NULL,
	REJECTED_DTM				DATE			NULL
);

CREATE OR REPLACE VIEW V$AUTOCREATE_USER AS
	SELECT user_name, app_sid, guid, requested_dtm, approved_dtm, approved_by_user_sid, created_user_sid, activated_dtm
	  FROM autocreate_user
	 WHERE rejected_dtm IS NULL;


@update_tail

