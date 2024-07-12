-- Please update version.sql too -- this keeps clean builds in sync
define version=260
@update_header

INSERT INTO portlet VALUES (portlet_id_seq.nextval, 'Add Donation', 'Credit360.Portlets.AddDonation', NULL, '/csr/site/portal/Credit360.Portlets.AddDonation');
COMMIT;
@update_tail
