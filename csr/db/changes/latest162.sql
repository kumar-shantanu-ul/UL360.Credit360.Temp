-- Please update version.sql too -- this keeps clean builds in sync
define version=162
@update_header

ALTER TABLE section DROP CONSTRAINT RefSECTION_VERSION831;

UPDATE section SET visible_version_number = NVL(section_pkg.GetLatestCheckedInVersion(section_sid),1);

ALTER TABLE section MODIFY visible_version_number NOT NULL;

ALTER TABLE SECTION ADD CONSTRAINT RefSECTION_VERSION831
    FOREIGN KEY (SECTION_SID, VISIBLE_VERSION_NUMBER)
    REFERENCES SECTION_VERSION(SECTION_SID, VERSION_NUMBER)
    DEFERRABLE INITIALLY DEFERRED
;

@../text/section_body
	  
@update_tail
