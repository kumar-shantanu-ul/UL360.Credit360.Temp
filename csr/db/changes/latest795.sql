-- Please update version.sql too -- this keeps clean builds in sync
define version=795
@update_header

ALTER TABLE CSR.TAG_GROUP ADD APPLIES_TO_NON_COMPLIANCES NUMBER(1) DEFAULT 0 NOT NULL;

CREATE TABLE CSR.NON_COMPLIANCE_TAG
(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TAG_ID               NUMBER(10, 0)    NOT NULL,
    NON_COMPLIANCE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_NON_COMPLIANCE_TAG PRIMARY KEY (APP_SID, TAG_ID, NON_COMPLIANCE_ID)
);

CREATE INDEX CSR.IX_NON_CMPL_TAG_NON_CMPL ON CSR.NON_COMPLIANCE_TAG(APP_SID, NON_COMPLIANCE_ID)
;

ALTER TABLE CSR.NON_COMPLIANCE_TAG ADD CONSTRAINT FK_NON_CMPL_TAG
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID)
;

ALTER TABLE CSR.NON_COMPLIANCE_TAG ADD CONSTRAINT FK_NON_CMPL_TAG_NON_CMPL 
    FOREIGN KEY (APP_SID, NON_COMPLIANCE_ID)
    REFERENCES CSR.NON_COMPLIANCE(APP_SID, NON_COMPLIANCE_ID)
;

CREATE OR REPLACE VIEW csr.TAG_GROUP_IR_MEMBER AS
SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, region_tag.region_sid, ind_tag.ind_sid, non_compliance_tag.non_compliance_id
FROM tag_group_member tgm, 
  	tag t LEFT OUTER JOIN ind_tag ON ind_tag.tag_id = t.tag_id 
    	LEFT OUTER JOIN region_tag ON region_tag.tag_id = t.tag_id
    	LEFT OUTER JOIN non_compliance_tag ON non_compliance_tag.tag_id = t.tag_id
WHERE tgm.tag_id = t.tag_id
 AND tgm.TAG_ID = t.TAG_ID
;

@..\audit_pkg
@..\tag_pkg
@..\audit_body
@..\tag_body

@update_tail
