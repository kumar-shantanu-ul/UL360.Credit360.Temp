-- Please update version.sql too -- this keeps clean builds in sync
define version=56
@update_header

ALTER TABLE donations.donation_doc ADD description VARCHAR2(2048);

ALTER TABLE donations.customer_options ADD document_description_enabled NUMBER(1);


connect csr/csr@&_CONNECT_IDENTIFIER

GRANT EXECUTE ON csr.fileupload_pkg TO donations;

connect donations/donations@&_CONNECT_IDENTIFIER

@../donation_pkg
@../donation_body
@../options_body

@update_tail
