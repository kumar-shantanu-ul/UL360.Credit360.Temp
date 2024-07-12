-- Please update version.sql too -- this keeps clean builds in sync
define version=408
@update_header

UPDATE portlet SET script_path = '/csr/site/portal/Portlets/AddDonation.js' WHERE name = 'Add Donation';

@update_tail
