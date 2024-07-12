-- Please update version.sql too -- this keeps clean builds in sync
define version=48
@update_header

CREATE TABLE EXCLUDE_TAG (app_sid number(10) NOT NULL, scheme_sid NUMBER(10) NOT NULL, tag_id NUMBER(10) NOT NULL);

ALTER TABLE exclude_tag ADD CONSTRAINT fk_excl_tag_tag FOREIGN KEY (app_sid, tag_id) references tag(app_Sid, tag_id);
ALTER TABLE exclude_tag ADD CONSTRAINT fk_excl_tag_scheme FOREIGN KEY (app_sid, scheme_sid) references scheme(app_Sid, scheme_sid);

@../tag_pkg
@../tag_body

@update_tail
