-- Please update version.sql too -- this keeps clean builds in sync
define version=1262
@update_header

grant references on cms.web_publication to csr;


ALTER TABLE CSR.AXIS ADD CONSTRAINT FK_AXIS_PUBLICATION_SID
    FOREIGN KEY (APP_SID, PUBLICATION_SID)
    REFERENCES CMS.WEB_PUBLICATION(APP_SID, WEB_PUBLICATION_ID)
;

ALTER TABLE CSR.AXIS_MEMBER ADD CONSTRAINT FK_AXIS_MEMBER_PUBLICATION_SID
    FOREIGN KEY (APP_SID, PUBLICATION_SID)
    REFERENCES CMS.WEB_PUBLICATION(APP_SID, WEB_PUBLICATION_ID)
;

@../strategy_pkg
@../strategy_body
@update_tail
	