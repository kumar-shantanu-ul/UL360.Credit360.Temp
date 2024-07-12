-- Please update version.sql too -- this keeps clean builds in sync
define version=1849
@update_header
--Recompiling measure package; added to delete conversion
@..\measure_pkg;
@..\measure_body;

@update_tail