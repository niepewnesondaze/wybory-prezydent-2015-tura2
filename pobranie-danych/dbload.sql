drop database if exists wybory2015prez2;
create database wybory2015prez2;
use wybory2015prez2;

create table obwody (
	id integer not null,
	siedziba text,
	teryt char(6),
	nrobwodu integer,
	gmina text,
	powiat text comment 'lookup',
	woj text comment 'lookup',
	adres text ) engine=brighthouse default charset='UTF8';

create table protokoly (
	id integer not null,
	item varchar(3) not null comment 'lookup',
	val integer not null ) engine=brighthouse default charset='UTF8';

create table wyniki (
	id integer not null,
	lp integer,
	kandydat text comment 'lookup',
	glosy integer) engine=brighthouse default charset='UTF8';

create table protokolyitem (
	item varchar(3) not null comment 'lookup',
	itemtxt text)  engine=brighthouse default charset='UTF8';

create table gminyteryt (
	teryt char(6),
	typgminy text comment 'lookup')  engine=brighthouse default charset='UTF8';

load data infile 'c:/temp/wybory-prezydent2015/tura2/obwody.csv' into table obwody fields terminated by ';' ESCAPED BY '\\' lines terminated by '\n';
load data infile 'c:/temp/wybory-prezydent2015/tura2/protokoly.csv' into table protokoly fields terminated by ';' ESCAPED BY '\\' lines terminated by '\n';
load data infile 'c:/temp/wybory-prezydent2015/tura2/wyniki.csv' into table wyniki fields terminated by ';' ESCAPED BY '\\' lines terminated by '\n';

load data infile 'c:/temp/wybory-prezydent2015/tura2/protokolyitem.csv' into table protokolyitem fields terminated by ';' ESCAPED BY '\\' lines terminated by '\r\n';
load data infile 'c:/temp/wybory-prezydent2015/tura2/gminyteryt.csv' into table gminyteryt fields terminated by ';' ESCAPED BY '\\' lines terminated by '\r\n';
