-- Please update version.sql too -- this keeps clean builds in sync
define version=305
@update_header


INSERT INTO PORTLET (
    PORTLET_ID, NAME, TYPE, SCRIPT_PATH
) VALUES (
    portlet_id_seq.nextval,
    'Supply Chain Messages',
    'Credit360.Portlets.Chain.Messages',
    '/csr/site/portal/Credit360.Portlets.Chain.Messages.js'
); 

INSERT INTO PORTLET (
    PORTLET_ID, NAME, TYPE, SCRIPT_PATH
) VALUES (
    portlet_id_seq.nextval,
    'Supply Chain Mailbox',
    'Credit360.Portlets.Chain.Mailbox',
    '/csr/site/portal/Credit360.Portlets.Chain.Mailbox.js'
);

@update_tail
