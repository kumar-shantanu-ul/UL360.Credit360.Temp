define version=14
@update_header

alter table chain.card_group_card add (invert_capability_check number(1) default 0 not null);

@..\card_pkg
@..\card_body

@update_tail
