-- Please update version.sql too -- this keeps clean builds in sync
define version=2375
@update_header

grant execute on csr.plugin_pkg to cms;

@..\plugin_pkg

@..\plugin_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail

