-- Please update version.sql too -- this keeps clean builds in sync
define version=1706
@update_header

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

BEGIN
	INSERT INTO csr.std_factor_set (std_factor_set_id, name)
	VALUES (30, 'US Environmental Protection Agency (EPA) - Climate Leaders (2011)');
	
	INSERT INTO csr.std_factor_set (std_factor_set_id, name)
	VALUES (31, 'US Energy Information Administration - Voluntary Reporting of Greenhouse Gases (2010)');
END;
/

@update_tail