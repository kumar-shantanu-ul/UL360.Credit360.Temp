-- Please update version.sql too -- this keeps clean builds in sync
define version=39
@update_header


BEGIN
UPDATE sheet_action_permission SET can_save = 0, can_return = 1 WHERE sheet_action_id = 3 AND user_level = 1;
UPDATE sheet_action_permission SET can_return = 0, can_save = 1 WHERE sheet_action_id = 2 AND user_level = 2;
END;
/

ALTER TABLE CUSTOMER ADD (CONTACT_EMAIL VARCHAR2(255) NULL);


ALTER TABLE FEED ADD (XSL_DOC CLOB);

alter table feed_request add (
    IMP_SESSION_SID       NUMBER(10, 0));


ALTER TABLE FEED_REQUEST ADD CONSTRAINT RefIMP_SESSION321 
    FOREIGN KEY (IMP_SESSION_SID)
    REFERENCES IMP_SESSION(IMP_SESSION_SID);


alter table delegation modify schedule_xml not null;

@update_tail
