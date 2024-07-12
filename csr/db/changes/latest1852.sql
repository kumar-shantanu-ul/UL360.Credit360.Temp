-- Please update version.sql too -- this keeps clean builds in sync
define version=1852
@update_header

@../donations/funding_commitment_pkg
@../donations/funding_commitment_body

@update_tail