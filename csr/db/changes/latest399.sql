-- Please update version.sql too -- this keeps clean builds in sync
define version=399
@update_header

update security.menu set action='/csr/site/schema/new/indicatorTree.acds' where lower(action) like '/csr/site/schema/indicatortree.acds%';
update security.menu set action='/csr/site/schema/new/regionTree.acds' where lower(action) like '/csr/site/schema/regiontree.acds%';

@update_tail
