-- Tests exercising different behaviour of the WITH RECURSIVE implementation in GPDB
-- GPDB's distributed nature requires thorough testing of many use cases in order to ensure correctness

-- Setup


-- WITH RECURSIVE ref in a sublink in the main query

create schema recursive_cte;
set search_path=recursive_cte;
create table recursive_table_1(id int);
insert into recursive_table_1 values (1), (2), (100);

-- WITH RECURSIVE ref used with IN without correlation
with recursive r(i) as (
   select 1
   union all
   select i + 1 from r
)
select * from recursive_table_1 where recursive_table_1.id IN (select * from r limit 10);

-- WITH RECURSIVE ref used with NOT IN without correlation
with recursive r(i) as (
   select 1
   union all
   select i + 1 from r
)
select * from recursive_table_1 where recursive_table_1.id NOT IN (select * from r limit 10);

-- WITH RECURSIVE ref used with EXISTS without correlation
with recursive r(i) as (
   select 1
   union all
   select i + 1 from r
)
select * from recursive_table_1 where EXISTS (select * from r limit 10);

-- WITH RECURSIVE ref used with NOT EXISTS without correlation
with recursive r(i) as (
   select 1
   union all
   select i + 1 from r
)
select * from recursive_table_1 where NOT EXISTS (select * from r limit 10);

create table recursive_table_2(id int);
insert into recursive_table_2 values (11) , (21), (31);

-- WITH RECURSIVE ref used with IN & correlation
with recursive r(i) as (
	select * from recursive_table_2
	union all
	select r.i + 1 from r, recursive_table_2 where r.i = recursive_table_2.id
)
select recursive_table_1.id from recursive_table_1, recursive_table_2 where recursive_table_1.id IN (select * from r where r.i = recursive_table_2.id);

-- WITH RECURSIVE ref used with NOT IN & correlation
with recursive r(i) as (
	select * from recursive_table_2
	union all
	select r.i + 1 from r, recursive_table_2 where r.i = recursive_table_2.id
)
select recursive_table_1.id from recursive_table_1, recursive_table_2 where recursive_table_1.id NOT IN (select * from r where r.i = recursive_table_2.id);

-- WITH RECURSIVE ref used with EXISTS & correlation
with recursive r(i) as (
	select * from recursive_table_2
	union all
	select r.i + 1 from r, recursive_table_2 where r.i = recursive_table_2.id
)
select recursive_table_1.id from recursive_table_1, recursive_table_2 where recursive_table_1.id = recursive_table_2.id and EXISTS (select * from r where r.i = recursive_table_2.id);

-- WITH RECURSIVE ref used with NOT EXISTS & correlation
with recursive r(i) as (
	select * from recursive_table_2
	union all
	select r.i + 1 from r, recursive_table_2 where r.i = recursive_table_2.id
)
select recursive_table_1.id from recursive_table_1, recursive_table_2 where recursive_table_1.id = recursive_table_2.id and NOT EXISTS (select * from r where r.i = recursive_table_2.id);

-- WITH RECURSIVE ref used within a Expression sublink
with recursive r(i) as (
   select 1
   union all
   select i + 1 from r
)
select * from recursive_table_1 where recursive_table_1.id >= (select i from r limit 1) order by recursive_table_1.id;

-- WITH RECURSIVE ref used within an EXISTS subquery in another recursive CTE
with recursive
r(i) as (
    select 1
    union all
    select r.i + 1 from r, recursive_table_2 where i = recursive_table_2.id
),
y(i) as (
    select 1
    union all
    select i + 1 from y, recursive_table_1 where i = recursive_table_1.id and EXISTS (select * from r limit 10)
)
select * from y limit 10;

-- WITH RECURSIVE ref used within a NOT EXISTS subquery in another recursive CTE
with recursive
r(i) as (
    select 1
    union all
    select r.i + 1 from r, recursive_table_2 where i = recursive_table_2.id
),
y(i) as (
    select 1
    union all
    select i + 1 from y, recursive_table_1 where i = recursive_table_1.id and NOT EXISTS (select * from r limit 10)
)
select * from y limit 10;

-- WITH RECURSIVE ref used within an IN subquery in a non-recursive CTE
with recursive
r(i) as (
    select 1
    union all
    select r.i + 1 from r, recursive_table_2 where i = recursive_table_2.id
),
y as (
    select * from recursive_table_1 where recursive_table_1.id IN (select * from r limit 10)
)
select * from y;

-- WITH RECURSIVE ref used within a NOT IN subquery in a non-recursive CTE
with recursive
r(i) as (
    select 1
    union all
    select r.i + 1 from r, recursive_table_2 where i = recursive_table_2.id
),
y as (
    select * from recursive_table_1 where recursive_table_1.id NOT IN (select * from r limit 10)
)
select * from y;

-- WITH RECURSIVE ref used within an EXISTS subquery in a non-recursive CTE
with recursive
r(i) as (
    select 1
    union all
    select r.i + 1 from r, recursive_table_2 where i = recursive_table_2.id
),
y as (
    select * from recursive_table_1 where EXISTS (select * from r limit 10)
)
select * from y;

-- WITH RECURSIVE ref used within a NOT EXISTS subquery in a non-recursive CTE
with recursive
r(i) as (
    select 1
    union all
    select r.i + 1 from r, recursive_table_2 where i = recursive_table_2.id
),
y as (
    select * from recursive_table_1 where NOT EXISTS (select * from r limit 10)
)
select * from y;

-- WITH RECURSIVE non-recursive ref used within an EXISTS subquery in a recursive CTE
with recursive
r as (
    select * from recursive_table_2
),
y(i) as (
    select 1
    union all
    select i + 1 from y, recursive_table_1 where i = recursive_table_1.id and EXISTS (select * from r)
)
select * from y limit 10;

-- WITH RECURSIVE non-recursive ref used within a NOT EXISTS subquery in a recursive CTE
with recursive
r as (
    select * from recursive_table_2
),
y(i) as (
    select 1
    union all
    select i + 1 from y, recursive_table_1 where i = recursive_table_1.id and NOT EXISTS (select * from r)
)
select * from y limit 10;

-- WITH ref used within an IN subquery in another CTE
with
r as (
    select * from recursive_table_2 where id < 21
),
y as (
    select * from recursive_table_1 where id IN (select * from r)
)
select * from y;

-- WITH ref used within a NOT IN subquery in another CTE
with
r as (
    select * from recursive_table_2 where id < 21
),
y as (
    select * from recursive_table_1 where id NOT IN (select * from r)
)
select * from y;

-- WITH ref used within an EXISTS subquery in another CTE
with
r as (
    select * from recursive_table_2 where id < 21
),
y as (
    select * from recursive_table_1 where EXISTS (select * from r)
)
select * from y;

-- WITH ref used within a NOT EXISTS subquery in another CTE
with
r as (
    select * from recursive_table_2 where id < 21
),
y as (
    select * from recursive_table_1 where NOT EXISTS (select * from r)
)
select * from y;

create table recursive_table_3(id int, a int);
insert into recursive_table_3 values (1, 2), (2, 3);
-- WITH RECURSIVE ref used within a window function
with recursive r(i, j) as (
	select * from recursive_table_3
	union all
	select i + 1, j from r, recursive_table_3 where r.i < recursive_table_3.id
)
select avg(i) over(partition by j) from r limit 100;

