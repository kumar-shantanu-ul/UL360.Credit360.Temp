-- Please update version.sql too -- this keeps clean builds in sync
define version=2156
@update_header

ALTER TABLE csr.delegation_region ADD hide_after_dtm DATE NULL;
ALTER TABLE csr.delegation_region ADD hide_inclusive NUMBER(1) DEFAULT 0 NOT NULL;

CREATE OR REPLACE VIEW csr.v$delegation_region AS
	SELECT dr.app_sid, dr.delegation_sid, dr.region_sid, dr.mandatory, NVL(drd.description, rd.description) description,
		   dr.pos, dr.aggregate_to_region_sid, dr.visibility, dr.allowed_na, dr.hide_after_dtm, dr.hide_inclusive
	  FROM delegation_region dr
	  JOIN region_description rd
	    ON dr.app_sid = rd.app_sid AND dr.region_sid = rd.region_sid 
	   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_region_description drd
	    ON dr.app_sid = drd.app_sid AND dr.delegation_sid = drd.delegation_sid
	   AND dr.region_sid = drd.region_sid AND drd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

@..\region_pkg
@..\region_body
@..\delegation_body
@..\sheet_body

@update_tail