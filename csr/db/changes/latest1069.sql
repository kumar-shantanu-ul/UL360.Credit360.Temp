-- Please update version.sql too -- this keeps clean builds in sync
define version=1069
@update_header

ALTER TABLE CSR.CSR_USER ADD (
	imp_session_mount_point_sid	NUMBER(10) NULL
);

ALTER TABLE CSR.CSR_USER ADD CONSTRAINT FK_CSR_USER_IMP_SESSION 
    FOREIGN KEY (APP_SID, imp_session_mount_point_sid)
    REFERENCES CSR.IMP_SESSION(APP_SID, IMP_SESSION_SID);
    
@update_tail
