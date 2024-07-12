-- Please update version.sql too -- this keeps clean builds in sync
define version=1099
@update_header
CREATE GLOBAL TEMPORARY TABLE DONATIONS.RECIPIENT_TAG_CONDITION
(
	tag_group_sid	number(10),
	tag_id			number(10)
) ON COMMIT DELETE ROWS;

@../donations/donation_pkg
@../donations/donation_body
@../donations/tag_body
@../donations/funding_commitment_body
@update_tail
