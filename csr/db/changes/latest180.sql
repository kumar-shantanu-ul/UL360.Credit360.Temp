-- Please update version.sql too -- this keeps clean builds in sync
define version=180
@update_header

prompt Make sure you have svn upped security/db/oracle and aspen2/db... ctrl+c to abort and do this first if you haven't!

prompt enter connection name (e.g. aspen)
connect security/security@&&1
@c:\cvs\security\db\oracle\groups_pkg
@c:\cvs\security\db\oracle\groups_body

connect aspen2/aspen2@&&1
@c:\cvs\aspen2\db\aspenapp_body

connect csr/csr@&&1
@..\csr_app_body
@..\csr_data_body
	 
@update_tail
