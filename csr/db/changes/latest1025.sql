-- Please update version.sql too -- this keeps clean builds in sync
define version=1025
@update_header

-- menus have moved
update security.menu set action = replace(lower(action), '/csr/site/schema/new/regiontree.acds', '/csr/site/schema/indRegion/regionTree.acds')
 where lower(action) like '%/csr/site/schema/new/regiontree.acds%';

update security.menu set action = replace(lower(action), '/csr/site/schema/new/indicatortree.acds', '/csr/site/schema/indRegion/indicatorTree.acds')
 where lower(action) like '%/csr/site/schema/new/indicatortree.acds%';
 
@update_tail
