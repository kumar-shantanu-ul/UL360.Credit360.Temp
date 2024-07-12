-- Please update version.sql too -- this keeps clean builds in sync
define version=2098
@update_header

update csr.plugin set js_class = replace(js_class, 'Teamroom.Initiatives.','Credit360.Initiatives.') where js_class like '%Teamroom.Initiatives.%';
-- M and S stuff appeared already in a change script so I've kept this in here. Really client specific stuff shouldn't be in change scripts
update csr.plugin set js_class = replace(js_class, 'MarksAndSpencer.Credit360.Initiatives.','MarksAndSpencer.Initiatives.') where js_class like '%MarksAndSpencer.Credit360.Initiatives.%';
update csr.plugin set js_include = replace(js_include, '/csr/site/teamroomInitiatives/','/csr/site/initiatives/detail/') where js_include like '%/csr/site/teamroomInitiatives/%';

@update_tail