define version=43
@update_header

alter table chain.company add mapping_approval_required number(1) default 1 not null;

@update_tail

