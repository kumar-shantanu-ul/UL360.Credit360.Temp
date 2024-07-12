-- Please update version.sql too -- this keeps clean builds in sync
define version=470
@update_header

update security.menu
   set action = '/csr/site/dataExplorer4/dataNavigator/dataBrowser.acds'
 where lower(action) = '/csr/site/dataexplorer/rawdataview.acds';

@update_tail
