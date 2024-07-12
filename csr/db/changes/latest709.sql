-- Please update version.sql too -- this keeps clean builds in sync
define version=709
@update_header

update security.menu
   set action = replace(lower(action), '/csr/site/donations/browse.acds', '/csr/site/donations2/browse.acds')
 where lower(action) like '/csr/site/donations/browse.acds%';

update security.home_page
   set url = replace(lower(url), '/csr/site/donations/browse.acds', '/csr/site/donations2/browse.acds')
 where lower(url) like '/csr/site/donations/browse.acds%';

@update_tail
