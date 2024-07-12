-- Please update version.sql too -- this keeps clean builds in sync
define version=792
@update_header

ALTER TABLE CHAIN.FILE_GROUP
MODIFY(COMPANY_SID  NULL);


ALTER TABLE CHAIN.file_group ADD (
    CONSTRAINT FG_COMPANY_CHK CHECK ((company_sid IS NOT NULL) OR (download_permission_id = 1)));
-- We are only allowed to skip the company_sid if the dowmload permission type is chain_pkg.DOWNLOAD_PERM_EVERYONE	




@update_tail
