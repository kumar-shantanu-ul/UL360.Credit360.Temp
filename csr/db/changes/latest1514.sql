-- Please update version.sql too -- this keeps clean builds in sync
define version=1514
@update_header

@../chain/helper_pkg
@../chain/helper_body
@../chain/chain_link_pkg
@../chain/chain_link_body
@../chain/invitation_body
@../chain/uninvited_body

@update_tail