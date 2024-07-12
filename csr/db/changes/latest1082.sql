-- Please update version.sql too -- this keeps clean builds in sync
define version=1082
@update_header
GRANT SELECT, REFERENCES ON csr.region_tag TO donations;
GRANT SELECT, REFERENCES ON csr.tag_group TO donations;
GRANT SELECT, REFERENCES ON csr.tag_group_member TO donations;
GRANT SELECT, REFERENCES ON csr.tag TO donations;

CREATE GLOBAL TEMPORARY TABLE DONATIONS.region_tag_condition
(
	tag_group_id	number(10),
	tag_id			number(10)
) ON COMMIT DELETE ROWS;

-- 
-- TABLE: REGION_FILTER_TAG_GROUP 
--

CREATE TABLE DONATIONS.REGION_FILTER_TAG_GROUP(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_TAG_GROUP_ID    NUMBER(10, 0),
    CONSTRAINT PK141 PRIMARY KEY (APP_SID)
)
;


-- 
-- TABLE: REGION_FILTER_TAG_GROUP 
--

ALTER TABLE DONATIONS.REGION_FILTER_TAG_GROUP ADD CONSTRAINT RefTAG_GROUP253 
    FOREIGN KEY (APP_SID,REGION_TAG_GROUP_ID)
    REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID)
;

@../donations/tag_pkg
@../donations/tag_body
@../donations/options_body
@../donations/donation_pkg
@../donations/donation_body

@../donations/funding_commitment_pkg
@../donations/funding_commitment_body

@update_tail
