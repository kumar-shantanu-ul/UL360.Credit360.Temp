-- Please update version.sql too -- this keeps clean builds in sync
define version=1626
@update_header

-- check and correct all calls to donation_pkg.createdonation, amendDonation
ALTER TABLE donations.scheme ADD track_donation_end_dtm NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE donations.donation ADD end_dtm DATE;


@../donations/donation_pkg
@../donations/donation_body
@../donations/scheme_body
							 
@update_tail
