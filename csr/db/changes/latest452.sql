-- Please update version.sql too -- this keeps clean builds in sync
define version=452
@update_header

INSERT INTO PORTLET (
    PORTLET_ID, NAME, TYPE, SCRIPT_PATH
) VALUES (
    portlet_id_seq.nextval,
    'Help',
    'Credit360.Portlets.Help',
    '/csr/site/portal/Portlets/Help.js'
);

@update_tail
