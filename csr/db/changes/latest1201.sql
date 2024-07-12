-- Please update version.sql too -- this keeps clean builds in sync
define version=1201
@update_header

CREATE TABLE CT.SUPPLIER_STATUS (
    STATUS_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(1000) NOT NULL,
    CONSTRAINT PK_SUPPLIER_STATUS PRIMARY KEY (STATUS_ID)
);

ALTER TABLE CT.SUPPLIER ADD STATUS_ID NUMBER(10) DEFAULT 0 NOT NULL;

BEGIN
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (0, 'New');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (1, 'HotspotterInvitationSent');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (2, 'AcceptedHotspotterInvitation');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (3, 'CompletedHotspotter');
	INSERT INTO CT.SUPPLIER_STATUS (STATUS_ID, DESCRIPTION) VALUES (4, 'HotspotterCompletedOnBehalfOfSupplier');
END;
/

ALTER TABLE CT.SUPPLIER ADD CONSTRAINT SUPPLIER_STATUS_SUPPLIER 
    FOREIGN KEY (STATUS_ID) REFERENCES CT.SUPPLIER_STATUS (STATUS_ID);

@update_tail
