alter table tag_group add (show_in_filter number(1,0) default 1 not null);

alter table role add (show_in_filter number(1,0) default 1 not null);

alter table role drop column show_in_list;

alter table task add (last_task_period_dtm date null);
