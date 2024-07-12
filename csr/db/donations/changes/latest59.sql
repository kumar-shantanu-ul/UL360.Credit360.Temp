-- Please update version.sql too -- this keeps clean builds in sync
define version=59
@update_header

ALTER TABLE donations.tag_group ADD (show_in_filter NUMBER(1) DEFAULT 1 NOT NULL);

@../tag_body

@update_tail
