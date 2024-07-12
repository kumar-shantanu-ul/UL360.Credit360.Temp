-- Please update version.sql too -- this keeps clean builds in sync
define version=1223
@update_header

UPDATE security.menu 
   SET description = 'VC Business structure',
       action = '/csr/site/ct/admin/businessStructureManagement.acds'
 WHERE description = 'VC Apportionment' 
   AND action = '/csr/site/ct/admin/apportionment.acds';

@update_tail
