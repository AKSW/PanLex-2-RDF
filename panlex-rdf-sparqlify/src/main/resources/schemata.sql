--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plx; Type: COMMENT; Schema: -; Owner: apache
--

COMMENT ON DATABASE plx IS 'PanLex';


--
-- Name: import; Type: SCHEMA; Schema: -; Owner: apache
--

CREATE SCHEMA import;


ALTER SCHEMA import OWNER TO apache;

--
-- Name: SCHEMA import; Type: COMMENT; Schema: -; Owner: apache
--

COMMENT ON SCHEMA import IS 'tables required by daemons smp.pl, tot.pl, and xml.pl';


--
-- Name: interim; Type: SCHEMA; Schema: -; Owner: pool
--

CREATE SCHEMA interim;


ALTER SCHEMA interim OWNER TO pool;

--
-- Name: SCHEMA interim; Type: COMMENT; Schema: -; Owner: pool
--

COMMENT ON SCHEMA interim IS 'short-term tables';


--
-- Name: util; Type: SCHEMA; Schema: -; Owner: pool
--

CREATE SCHEMA util;


ALTER SCHEMA util OWNER TO pool;

--
-- Name: SCHEMA util; Type: COMMENT; Schema: -; Owner: pool
--

COMMENT ON SCHEMA util IS 'objects required for management';


--
-- Name: plperl; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: pool
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plperl;


ALTER PROCEDURAL LANGUAGE plperl OWNER TO pool;

--
-- Name: plperlu; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: postgres
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plperlu;


ALTER PROCEDURAL LANGUAGE plperlu OWNER TO postgres;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: amrm(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION amrm(integer, integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$--create or replace function amrm
--(integer, integer)
--returns void language plpgsql as
declare
dnvar integer;
begin
-- Identify a denotation of the specified
-- approver with the specified expression.
select dn into dnvar from dn, mn
where ex = $1
and mn.mn = dn.mn
and ap = $2;
-- If it exists:
if dnvar is not null
then
---- Delete the denotation.
perform dnrm (dnvar, true, false);
end if;
end;$_$;


ALTER FUNCTION public.amrm(integer, integer) OWNER TO pool;

--
-- Name: FUNCTION amrm(integer, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION amrm(integer, integer) IS 'In: ex of an expression and ap of an approver. Act: Delete an arbitrary denotation, if any, of the approver with the expression and the denotation’s word classifications, metadata, and if orphaned meaning. Use: To prepare an expression in an ambiguity-prohibiting variety for assignment of a meaning to it.';


--
-- Name: apad(text, text, text, text, text, text, integer, integer, integer, text, text, text, text, text, text, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION apad(text, text, text, text, text, text, integer, integer, integer, text, text, text, text, text, text, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function apad
--(text, text, text, text, text, text, integer, integer,
--integer, text, text, text, text, text, text, integer)
--returns integer language plpgsql as
declare
apvar integer;
begin
-- If the label is blank:
if (length ($1)) = 0
then
---- Report the error and quit.
return -1;
end if;
-- Identify an available approver ID.
apvar := (apid ());
-- Add the specified approver.
insert into ap values
(
apvar, default, $1, $2, $3, $4, $5, $6,
$7, $8, $9, $10, $11, $12, $13, $14, $15
);
-- If the user is to be entitled to
-- edit the approver without being a
-- superuser:
if $16 > 0
then
---- Entitle the user to edit the approver.
insert into au values (apvar, $16);
end if;
-- Return the approver’s ID.
return apvar;
end;$_$;


ALTER FUNCTION public.apad(text, text, text, text, text, text, integer, integer, integer, text, text, text, text, text, text, integer) OWNER TO pool;

--
-- Name: FUNCTION apad(text, text, text, text, text, text, integer, integer, integer, text, text, text, text, text, text, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION apad(text, text, text, text, text, text, integer, integer, integer, text, text, text, text, text, text, integer) IS 'In: tt, ur, bn, au, ti, pb, yr, uq, ui, ul, li, ip, co, ad, and fp of a new approver and us of a user that is to be entitled to edit the approver or 0 if none is. Act: Add the approver and, if so specified,  make the user an editor of it. Out: -1 = tt blank, other integer = ap of the approver.';


--
-- Name: apid(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION apid() RETURNS integer
    LANGUAGE sql
    AS $$--create or replace function apid ()
--returns integer language sql as
select min (ap) from (
(
select 1 as ap
union
select ap + 1 as ap from ap
)
except select ap from ap
) as avail;$$;


ALTER FUNCTION public.apid() OWNER TO pool;

--
-- Name: FUNCTION apid(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION apid() IS 'Out: smallest available approver ap.';


--
-- Name: appw(integer, integer, character); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION appw(integer, integer, character) RETURNS boolean
    LANGUAGE sql
    AS $_$--create or replace function appw
--(integer, integer, character)
--returns boolean language sql as
select
($3 = (select pw from us where us = $2))
and (
(select ad from us where us = $2)
or ($2 = (select us from au where ap = $1 and us = $2))
);$_$;


ALTER FUNCTION public.appw(integer, integer, character) OWNER TO pool;

--
-- Name: FUNCTION appw(integer, integer, character); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION appw(integer, integer, character) IS 'In: ap of an approver and us and pw of a user. Out: whether the password is the user’s and the user is either a superuser or an editor of the approver.';


--
-- Name: aprm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION aprm(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$--create or replace function aprm
--(integer, out mndel integer,
--out midel integer, out dfdel integer,
--out dmdel integer, out dndel integer,
--out wcdel integer, out mddel integer)
--returns record language plpgsql as
declare
begin
-- Remove all word classifications of the
-- approver.
insert into wcid
select wc from wc, dn, mn
where ap = $1
and dn.mn = mn.mn
and wc.dn = dn.dn;
delete from wc
using dn, mn
where ap = $1
and dn.mn = mn.mn
and wc.dn = dn.dn;
-- Identify the number of deletions.
get diagnostics wcdel = row_count;
-- Remove all metadata of the approver.
insert into mdid
select md from md, dn, mn
where ap = $1
and dn.mn = mn.mn
and md.dn = dn.dn;
delete from md
using dn, mn
where ap = $1
and dn.mn = mn.mn
and md.dn = dn.dn;
-- Identify the number of deletions.
get diagnostics mddel = row_count;
-- Remove all denotations of the approver.
insert into dnid
select dn from dn, mn
where ap = $1
and dn.mn = mn.mn;
delete from dn
using mn
where ap = $1
and dn.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics dndel = row_count;
-- Remove all meaning identifiers of the
-- approver.
delete from mi
using mn
where ap = $1
and mi.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics midel = row_count;
-- Remove all definitions of the approver.
insert into dfid
select df from df, mn
where ap = $1
and df.mn = mn.mn;
delete from df
using mn
where ap = $1
and df.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics dfdel = row_count;
-- Remove all domains of the approver.
insert into dmid
select dm from dm, mn
where ap = $1
and dm.mn = mn.mn;
delete from dm
using mn
where ap = $1
and dm.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics dmdel = row_count;
-- Remove all meanings of the approver.
insert into mnid
select mn from mn
where ap = $1;
delete from mn
where ap = $1;
-- Identify the number of deletions.
get diagnostics mndel = row_count;
-- Report the deletion counts.
return;
end;$_$;


ALTER FUNCTION public.aprm(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) OWNER TO pool;

--
-- Name: FUNCTION aprm(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION aprm(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) IS 'In: ap of an approver. Act: Delete all approvals of the approver. Out[0-6]: counts of deleted meanings, meaning identifiers, definitions, domains, denotations, word classifications, and metadata.';


--
-- Name: aprm_bad(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION aprm_bad(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$--create or replace function aprm
--(integer, out mndel integer,
--out midel integer, out dfdel integer,
--out dmdel integer, out dndel integer,
--out wcdel integer, out mddel integer)
--returns record language plpgsql as
declare
begin
-- Remove all word classifications of the
-- approver.
insert into wcid
select wc from wc, dn, mn
where ap = $1
and dn.mn = mn.mn
and wc.dn = dn.dn;
delete from wc
using dn, mn
where ap = $1
and dn.mn = mn.mn
and wc.dn = dn.dn;
-- Identify the number of deletions.
get diagnostics wcdel = row_count;
-- Remove all metadata of the approver.
insert into mdid
select md from md, dn, mn
where ap = $1
and dn.mn = mn.mn
and md.dn = dn.dn;
delete from md
using dn, mn
where ap = $1
and dn.mn = mn.mn
and md.dn = dn.dn;
-- Identify the number of deletions.
get diagnostics mddel = row_count;
-- Remove all denotations of the approver.
insert into dnid
select dn from dn, mn
where ap = $1
and dn.mn = mn.mn;
delete from dn
using mn
where ap = $1
and dn.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics dndel = row_count;
-- Remove all meaning identifiers of the
-- approver.
delete from mi
using mn
where ap = $1
and mi.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics midel = row_count;
-- Remove all definitions of the approver.
insert into dfid
select df from df, mn
where ap = $1
and df.mn = mn.mn;
delete from df
using mn
where ap = $1
and df.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics dfdel = row_count;
-- Remove all domains of the approver.
insert into dmid
select dm from dm, mn
where ap = $1
and dm.mn = mn.mn;
delete from dm
using mn
where ap = $1
and dm.mn = mn.mn;
-- Identify the number of deletions.
get diagnostics dmdel = row_count;
-- Remove all meanings of the approver.
insert into mnid
select mn from mn
where ap = $1;
delete from mn
where ap = $1;
-- Identify the number of deletions.
get diagnostics mndel = row_count;
-- If any meanings were deleted:
if mndel > 0
then
---- Vacuum and analyze table “mn”.
vacuum analyze mn;
end if;
-- If any meaning identifiers were deleted:
if midel > 0
then
---- Vacuum and analyze table “mi”.
vacuum analyze mi;
end if;
-- If any definitions were deleted:
if dfdel > 0
then
---- Vacuum and analyze table “df”.
vacuum analyze df;
end if;
-- If any domain specifications were deleted:
if dmdel > 0
then
---- Vacuum and analyze table “dm”.
vacuum analyze dm;
end if;
-- If any denotations were deleted:
if dndel > 0
then
---- Vacuum and analyze table “dn”.
vacuum analyze dn;
end if;
-- If any word classifications were deleted:
if wcdel > 0
then
---- Vacuum and analyze table “wc”.
vacuum analyze wc;
end if;
-- If any metadata were deleted:
if mddel > 0
then
---- Vacuum and analyze table “md”.
vacuum analyze md;
end if;
-- Report the deletion counts.
return;
end;$_$;


ALTER FUNCTION public.aprm_bad(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) OWNER TO pool;

--
-- Name: dfad(integer, integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dfad(integer, integer, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function dfad
--(integer, integer, text)
--returns integer language plpgsql as
declare
dfvar integer;
mnvar integer;
lvvar integer;
begin
-- Identify the specified definition.
select df into dfvar from df
where mn = $1
and lv = $2
and tt = $3;
-- If it exists:
if dfvar is not null
then
---- Report the reason and quit.
return -1;
end if;
-- Identify the specified meaning.
select mn into mnvar from mn
where mn = $1;
-- If it doesn’t exist:
if mnvar is null
then
---- Report the reason and quit.
return -2;
end if;
-- Identify the specified variety.
select lv into lvvar from lv
where lv = $2;
-- If it doesn’t exist:
if lvvar is null
then
---- Report the reason and quit.
return -3;
end if;
-- Identify the new definition.
select * into dfvar from dfgt ();
-- Record it.
insert into df values (dfvar, $1, $2, $3);
-- Return the definition.
return dfvar;
end;$_$;


ALTER FUNCTION public.dfad(integer, integer, text) OWNER TO pool;

--
-- Name: FUNCTION dfad(integer, integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dfad(integer, integer, text) IS 'In: mn, lv, and tt of a definition. Act: Add the definition. Out: -1 = definition exists, -2 = no mn, -3 = no lv, other integer = df.';


--
-- Name: dfgt(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dfgt() RETURNS integer
    LANGUAGE plpgsql
    AS $$--create or replace function dfgt ()
--returns integer language plpgsql as
declare
dfvar integer;
ndfvar integer;
begin
-- Identify the smallest available
-- definition ID.
select min (df) into dfvar from dfid;
-- Make it unavailable.
delete from dfid
where df = dfvar;
-- Identify another available definition.
select df into ndfvar from dfid;
-- If there is none:
if ndfvar is null
then
---- Record the next definition as available.
---- Precondition: The definition with an ID
---- 1 larger than the largest ID of any
---- definition is recorded as available.
insert into dfid values (dfvar + 1);
end if;
-- Return the available definition.
return dfvar;
end;$$;


ALTER FUNCTION public.dfgt() OWNER TO pool;

--
-- Name: FUNCTION dfgt(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dfgt() IS 'Act: Revise the list of available definition IDs. Out: the next available definition ID.';


--
-- Name: dfrm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dfrm(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function dfrm
--(integer) returns integer language plpgsql as
declare
dfvar df;
begin
-- Identify the definition.
select * into dfvar from df
where df = $1;
-- If it doesn’t exist:
if dfvar.df is null
then
---- Report the reason and quit.
return 1;
end if;
-- Record the definition ID as available.
insert into dfid values ($1);
-- Delete the definition.
delete from df
where df = $1;
-- Delete the defined meaning if nothing
-- else refers to it.
perform mnck (dfvar.mn);
-- Return success.
return 0;
end;$_$;


ALTER FUNCTION public.dfrm(integer) OWNER TO pool;

--
-- Name: FUNCTION dfrm(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dfrm(integer) IS 'In: df of a definition. Act: Delete the definition and record its ID as available. Out: 1 = no df, 0 = success.';


--
-- Name: dmad(integer, integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dmad(integer, integer, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function dmad
--(integer, integer, text)
--returns integer language plpgsql as
declare
dmvar integer;
exvar integer;
mnvar integer;
lvvar integer;
begin
-- If the specified text is blank:
if $3 = ''
then
---- Report the reason and quit.
return -1;
end if;
-- Identify the specified meaning.
select mn into mnvar from mn
where mn = $1;
-- If it doesn’t exist:
if mnvar is null
then
---- Report the reason and quit.
return -2;
end if;
-- Identify the specified variety.
select lv into lvvar from lv
where lv = $2;
-- If it doesn’t exist:
if lvvar is null
then
---- Report the reason and quit.
return -3;
end if;
-- Identify the specified expression.
select ex into exvar from ex
where lv = $2 and tt = $3;
-- If it doesn’t exist:
if exvar is null
then
---- Create it.
select * into exvar from exad ($2, $3);
-- Otherwise, if it exists:
else
---- Identify the domain specification.
select dm into dmvar from dm
where mn = $1
and ex = exvar;
---- If it exists:
if dmvar is not null
then
------ Report the reason and quit.
return -4;
end if;
end if;
-- Identify the new domain specification.
select * into dmvar from dmgt ();
-- Record it.
insert into dm values (dmvar, $1, exvar);
-- Return its ID.
return dmvar;
end;$_$;


ALTER FUNCTION public.dmad(integer, integer, text) OWNER TO pool;

--
-- Name: FUNCTION dmad(integer, integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dmad(integer, integer, text) IS 'In: mn, lv, and tt of a domain specification. Act: Add the domain specification and, if necessary, its expression. Out: -1 = blank tt, -2 = no mn, -3 = no lv, -4 = domain description exists, other integer = dm.';


--
-- Name: dmgt(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dmgt() RETURNS integer
    LANGUAGE plpgsql
    AS $$--create or replace function dmgt ()
--returns integer language plpgsql as
declare
dmvar integer;
ndmvar integer;
begin
-- Identify the smallest available
-- domain ID.
select min (dm) into dmvar from dmid;
-- Make it unavailable.
delete from dmid
where dm = dmvar;
-- Identify another missing domain.
select dm into ndmvar from dmid;
-- If there is none:
if ndmvar is null
then
---- Record the next domain as available.
---- Precondition: The domain with an ID
---- 1 larger than the largest ID of any
---- domain is recorded as available.
insert into dmid values (dmvar + 1);
end if;
-- Return the available domain.
return dmvar;
end;$$;


ALTER FUNCTION public.dmgt() OWNER TO pool;

--
-- Name: FUNCTION dmgt(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dmgt() IS 'Act: Revise the list of available domain IDs. Out: the next available domain ID.';


--
-- Name: dmrm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dmrm(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function dmrm
--(integer) returns integer language plpgsql as
declare
dmvar dm;
begin
-- Identify the domain.
select * into dmvar from dm
where dm = $1;
-- If it doesn’t exist:
if dmvar.dm is null
then
---- Report the reason and quit.
return 1;
end if;
-- Record the domain ID as available.
insert into dmid values ($1);
-- Delete the domain.
delete from dm
where dm = $1;
-- Delete the described meaning if nothing
-- else refers to it.
perform mnck (dmvar.mn);
-- Return success.
return 0;
end;$_$;


ALTER FUNCTION public.dmrm(integer) OWNER TO pool;

--
-- Name: FUNCTION dmrm(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dmrm(integer) IS 'In: dm of a domain. Act: Delete the domain and record its ID as available. Out: 1 = no dm, 0 = success.';


--
-- Name: dnad(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dnad(integer, integer, OUT mnout integer, OUT dnout integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$--create or replace function dnad
--(integer, integer, out mnout integer, out dnout integer)
--returns record language plpgsql as
declare
exvar ex;
amvar boolean;
dnvar integer;
begin
-- Identify the properties of the expression.
select * into exvar from ex where ex = $1;
-- If it doesn't exist:
if exvar.ex is null
then
---- Report the reason and quit.
mnout := -1;
dnout := -1;
return;
end if;
-- Identify whether the expression’s variety
-- permits ambiguity.
select am into amvar from lv
where lv = exvar.lv;
-- If not:
if not amvar
then
---- Delete any conflicting denotation.
perform amrm (exvar.ex, $2);
end if;
-- Record the new meaning and identify it.
select * into mnout from mnad ($2);
-- Identify the new denotation.
select * into dnout from dngt ();
-- Record it.
insert into dn values (dnout, mnout, $1);
-- Return the meaning and the denotation.
return;
end;$_$;


ALTER FUNCTION public.dnad(integer, integer, OUT mnout integer, OUT dnout integer) OWNER TO pool;

--
-- Name: FUNCTION dnad(integer, integer, OUT mnout integer, OUT dnout integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dnad(integer, integer, OUT mnout integer, OUT dnout integer) IS 'In: ex of an expression and ap of an approver. Act: Create a denotation by the approver with the expression and a new meaning, replacing any conflicting denotation. Out[0]: -1 = no ex, other integer = meaning. Out[1]: -1 = no ex, other integer = denotation.';


--
-- Name: dnad(integer, text, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dnad(integer, text, integer, OUT exout integer, OUT mnout integer, OUT dnout integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$--create or replace function dnad
--(integer, text, integer, out exout integer,
--out mnout integer, out dnout integer)
--returns record language plpgsql as
declare
amvar boolean;
exnew boolean;
lvvar lv;
begin
-- Identify the expression.
select ex into exout from ex
where lv = $1
and tt = $2;
-- If it doesn’t exist:
if exout is null
then
---- Identify this.
exnew := true;
---- Add it.
select * into exout
from exad ($1, $2);
---- If the addition failed:
if exout < 0
then
------ Report the reason and quit.
exout := -1;
mnout := -1;
dnout := -1;
return;
end if;
-- Otherwise, i.e. if the expression
-- already exists:
else
---- Identify this.
exnew := false;
end if;
-- Identify whether the variety permits
-- ambiguity.
select am into amvar from lv
where lv = $1;
-- If the expression already existed and the
-- variety prohibits ambiguity:
if amvar and not exnew
then
---- Delete any conflicting denotation.
perform amrm (exout, $3);
end if;
-- Record the new meaning and identify it.
select * into mnout from mnad ($3);
-- Identify the new denotation.
select * into dnout from dngt ();
-- Record it.
insert into dn values (dnout, mnout, exout);
-- Return the expression, the meaning, and
-- the denotation.
return;
end;$_$;


ALTER FUNCTION public.dnad(integer, text, integer, OUT exout integer, OUT mnout integer, OUT dnout integer) OWNER TO pool;

--
-- Name: FUNCTION dnad(integer, text, integer, OUT exout integer, OUT mnout integer, OUT dnout integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dnad(integer, text, integer, OUT exout integer, OUT mnout integer, OUT dnout integer) IS 'In: lv of a variety, tt of an expression, and ap of an approver. Act: Create the expression if necessary and a denotation by the approver with the expression and a new meaning, replacing any conflicting denotation. Out[0]: -1 = ex not added, other integer = expression. Out[1]: -1 = ex not added, other integer = meaning. Out[2]: -1 = ex not added, other integer = denotation.';


--
-- Name: dnad(integer, integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dnad(integer, integer, text, OUT exout integer, OUT dnout integer) RETURNS record
    LANGUAGE plpgsql
    AS $_$--create or replace function dnad
--(integer, integer, text,
--out exout integer, out dnout integer)
--returns record language plpgsql as
declare
apvar integer;
exnew boolean;
exvar integer;
lvvar lv;
begin
-- Identify the meaning’s approver.
select ap into apvar from mn
where mn = $1;
-- If it, and thus the meaning, don’t exist:
if apvar is null
then
---- Report the reason and quit.
exout := -1;
dnout := -1;
end if;
-- Identify the expression.
select ex into exvar from ex
where lv = $2
and tt = $3;
-- If it doesn’t exist:
if exvar is null
then
---- Identify this.
exnew := true;
---- Add it.
select * into exvar
from exad ($2, $3);
---- If the addition failed:
if exvar < 0
then
------ Report the reason and quit.
exout := -2;
dnout := -2;
return;
end if;
-- Otherwise, i.e. if the expression already
-- exists:
else
---- Identify this.
exnew := false;
end if;
-- Identify the properties of the variety.
select * into lvvar from lv
where lv = $2;
-- If the expression already existed and the
-- variety prohibits ambiguity:
if not (lvvar.am or exnew)
then
---- Delete any conflicting denotation.
perform amrm (exvar, apvar);
end if;
-- If the variety prohibits synonymy:
if not lvvar.sy
then
---- Delete any conflicting denotation.
perform syrm ($1, $2);
end if;
-- Identify the new denotation.
select * into dnout from dngt ();
-- Add it.
insert into dn values (dnout, $1, exvar);
-- Return the expression and the denotation.
return;
end;$_$;


ALTER FUNCTION public.dnad(integer, integer, text, OUT exout integer, OUT dnout integer) OWNER TO pool;

--
-- Name: FUNCTION dnad(integer, integer, text, OUT exout integer, OUT dnout integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dnad(integer, integer, text, OUT exout integer, OUT dnout integer) IS 'In: mn of a meaning and lv and tt of an expression. Act: Create the expression if necessary and a denotation with the meaning and the expression, replacing any conflicting denotations. Out[0]: -1 = no mn, -2 = ex not added, other integer = expression. Out[1]: -1 = no mn, -2 = ex not added, other integer = denotation.';


--
-- Name: dnad0(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dnad0(integer, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function dnad0
--(integer, integer)
--returns integer language plpgsql as
declare
apvar integer;
dnvar integer;
lvvar lv;
mnvar integer;
mxvar integer;
syvar integer;
begin
-- Identify the properties of the
-- expression’s variety.
select lv.* into lvvar from lv, ex
where ex = $1
and lv.lv = ex.lv;
-- If the expression doesn’t exist:
if lvvar.lv is null
then
---- Report the error and quit.
return -1;
end if;
-- Identify the meaning’s approver.
select ap into apvar from mn
where mn = $2;
-- If the meaning doesn’t exist:
if apvar is null
then
---- Report the error and quit.
return -2;
end if;
-- Identify the specified denotation.
select dn into dnvar from dn
where ex = $1
and mn = $2;
-- If the denotation exists:
if dnvar is not null
then
---- Report the superfluity and quit.
return -3;
end if;
-- If the expression’s variety prohibits synonymy:
if not lvvar.sy
then
---- Delete any existing denotation with the
---- meaning and an expression in the variety.
perform syrm ($2, lvvar.lv);
end if;
-- If the variety prohibits ambiguity:
if not lvvar.am
then
---- Delete any denotation of the approver with
---- the expression.
perform amrm ($1, apvar);
end if;
-- Identify the new denotation.
select * into dnvar from dngt ();
-- Record it.
insert into dn values (dnvar, $2, $1);
-- Return the denotation.
return dnvar;
end;$_$;


ALTER FUNCTION public.dnad0(integer, integer) OWNER TO pool;

--
-- Name: FUNCTION dnad0(integer, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dnad0(integer, integer) IS 'In: ex of an expression and mn of a meaning. Act: Create a denotation with the expression and the meaning, replacing any conflicting denotation. Out: -1 = no ex, -2 = denotation exists, other integer = denotation.';


--
-- Name: dnct(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dnct(integer) RETURNS integer
    LANGUAGE sql
    AS $_$--create or replace function dnct
--(integer)
--returns integer language sql as
select cast (count (ex) as integer)
from dn, mn
where ap = $1
and dn.mn = mn.mn;$_$;


ALTER FUNCTION public.dnct(integer) OWNER TO pool;

--
-- Name: FUNCTION dnct(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dnct(integer) IS 'In: ap of an approver. Out: count of the approver’s denotations.';


--
-- Name: dngt(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dngt() RETURNS integer
    LANGUAGE plpgsql
    AS $$--create or replace function dngt ()
--returns integer language plpgsql as
declare
dnvar integer;
ndnvar integer;
begin
-- Identify the smallest available
-- denotation ID.
select min (dn) into dnvar from dnid;
-- Make it unavailable.
delete from dnid
where dn = dnvar;
-- Identify another missing denotation.
select dn into ndnvar from dnid;
-- If there is none:
if ndnvar is null
then
---- Record the next denotation as available.
---- Precondition: The denotation with an ID
---- 1 larger than the largest ID of any
---- denotation is recorded as available.
insert into dnid values (dnvar + 1);
end if;
-- Return the available denotation.
return dnvar;
end;$$;


ALTER FUNCTION public.dngt() OWNER TO pool;

--
-- Name: FUNCTION dngt(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dngt() IS 'Act: Revise the list of available denotation IDs. Out: the next available denotation ID.';


--
-- Name: dnrm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dnrm(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function dnrm (integer)
--returns integer language plpgsql as
declare
dnvar dn;
begin
-- Identify the denotation.
select * into dnvar from dn
where dn = $1;
-- If it doesn’t exist:
if dnvar.dn is null
then
---- Report the error and quit.
return 1;
end if;
-- Delete all word classifications
-- of the denotation.
insert into wcid
select wc from wc
where dn = $1;
delete from wc
where dn = $1;
-- Delete all metadata of the denotation.
insert into mdid
select md from md
where dn = $1;
delete from md
where dn = $1;
-- Delete the denotation.
insert into dnid values ($1);
delete from dn
where dn = $1;
-- Delete the denotation’s meaning if nothing
-- else refers to it.
perform mnck (dnvar.mn);
-- Delete the denotation’s expression if nothing
-- else refers to it.
perform exck (dnvar.ex);
-- Return success.
return 0;
end;$_$;


ALTER FUNCTION public.dnrm(integer) OWNER TO pool;

--
-- Name: FUNCTION dnrm(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dnrm(integer) IS 'In: dn of a denotation. Act: Delete the denotation, its word classifications, its metadata, and, if thereby orphaned, its meaning, recording their IDs as available. Out: 1 = no dn, 0 = success.';


--
-- Name: dnrm(integer, boolean, boolean); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION dnrm(integer, boolean, boolean) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function dnrm
--(integer, boolean, boolean)
--returns integer language plpgsql as
declare
dnvar dn;
begin
-- Identify the denotation.
select * into dnvar from dn
where dn = $1;
-- If it doesn’t exist:
if dnvar.dn is null
then
---- Report the error and quit.
return 1;
end if;
-- Delete all word classifications
-- of the denotation.
insert into wcid
select wc from wc
where dn = $1;
delete from wc
where dn = $1;
-- Delete all metadata of the denotation.
insert into mdid
select md from md
where dn = $1;
delete from md
where dn = $1;
-- Delete the denotation.
insert into dnid values ($1);
delete from dn
where dn = $1;
-- If the denotation’s meaning is to be
-- deleted if orphaned:
if $2
then
---- Delete it if orphaned.
perform mnck (dnvar.mn);
end if;
-- If the denotation’s expression is to be
-- deleted if orphaned:
if $3
then
---- Delete it if orphaned.
perform exck (dnvar.ex);
end if;
-- Return success.
return 0;
end;$_$;


ALTER FUNCTION public.dnrm(integer, boolean, boolean) OWNER TO pool;

--
-- Name: FUNCTION dnrm(integer, boolean, boolean); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION dnrm(integer, boolean, boolean) IS 'In: dn of a denotation, whether to delete its meaning if orphaned, and whether to delete its expression if orphaned. Act: Delete the denotation, its word classifications, its metadata, and if orphaned and to be deleted its meaning and expression, recording their IDs as available. Out: 1 = no dn, 0 = success.';


--
-- Name: ex(integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION ex(integer, text) RETURNS integer
    LANGUAGE sql
    AS $_$--create or replace function ex (integer, text)
--returns integer language sql as
select ex from ex
where lv = $1
and tt = $2;$_$;


ALTER FUNCTION public.ex(integer, text) OWNER TO pool;

--
-- Name: FUNCTION ex(integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION ex(integer, text) IS 'In: lv of a variety and tt of an expression. Out: ex of the expression.';


--
-- Name: exad(integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exad(integer, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function exad
--(integer, text)
--returns integer language plpgsql as
declare
exvar integer;
lvvar integer;
begin
-- If the specified text is blank:
if $2 = ''
then
---- Report the error and quit.
return -1;
end if;
-- Identify the variety.
select lv into lvvar from lv
where lv = $1;
-- If it doesn’t exist:
if lvvar is null
then
---- Report the error and quit.
return -2;
end if;
-- Identify the expression.
select ex into exvar from ex
where lv = $1 and tt = $2;
-- If it doesn’t exist:
if exvar is null
then
---- Identify a new ID for it.
select * into exvar from exgt ();
---- Add the expression.
insert into ex (ex, lv, tt)
values (exvar, $1, $2);
end if;
-- Report the expression’s ID.
return exvar;
end;
$_$;


ALTER FUNCTION public.exad(integer, text) OWNER TO pool;

--
-- Name: FUNCTION exad(integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exad(integer, text) IS 'In: lv and tt of an expression. Act: Add the expression, if it doesn’t exist. Out: -1 = tt blank, -2 = no lv, other integer = ex.';


--
-- Name: exck(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exck(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$--create or replace function exck
--(integer) returns void language plpgsql as
declare
exvar integer;
begin
-- Identify the expression.
select ex into exvar from ex
where ex = $1;
-- If it doesn’t exist:
if exvar is null
then
---- Quit.
return;
end if;
-- Identify a denotation with the
-- specified expression.
select ex into exvar from dn
where ex = $1;
-- If there is any:
if exvar is not null
then
---- Stop checking.
return;
end if;
-- Identify a domain whose value is the
-- specified expression.
select ex into exvar from dm
where ex = $1;
-- If there is any:
if exvar is not null
then
---- Stop checking.
return;
end if;
-- Delete the expression.
insert into exid values ($1);
delete from ex
where ex = $1;
end;$_$;


ALTER FUNCTION public.exck(integer) OWNER TO pool;

--
-- Name: FUNCTION exck(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exck(integer) IS 'In: ex of an expression. Act: If the expression exists and is not the expression of any denotation or domain, delete it.';


--
-- Name: exgt(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exgt() RETURNS integer
    LANGUAGE plpgsql
    AS $$--create or replace function exgt ()
--returns integer language plpgsql as
declare
exvar integer;
nexvar integer;
begin
-- Identify the smallest available expression ID.
select min (ex) into exvar from exid;
-- Make it unavailable.
delete from exid
where ex = exvar;
-- Identify another missing expression.
select ex into nexvar from exid;
-- If there is none:
if nexvar is null
then
---- Record the next expression as available.
---- Precondition: The expression with an ID
---- 1 larger than the largest ID of any
---- expression is recorded as available.
insert into exid values (exvar + 1);
end if;
-- Return the deleted expression.
return exvar;
end;$$;


ALTER FUNCTION public.exgt() OWNER TO pool;

--
-- Name: FUNCTION exgt(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exgt() IS 'Act: Revise the list of available expression IDs. Out: the next available expression ID.';


--
-- Name: exn(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exn(integer) RETURNS integer
    LANGUAGE sql
    AS $_$--create or replace function exn (integer)
--returns integer language sql as
select cast (count (ex) as integer) from ex
where lv = $1;$_$;


ALTER FUNCTION public.exn(integer) OWNER TO pool;

--
-- Name: FUNCTION exn(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exn(integer) IS 'In: lv of a variety. Out: count of the expressions in the variety';


--
-- Name: exrm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exrm(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$--create or replace function exrm (integer)
--returns void language plpgsql as
declare
exvar integer;
begin
-- Identify the expression.
select ex into exvar from ex
where ex = $1;
-- If it exists:
if exvar is not null
then
---- Delete its denotations and their word
---- classifications, metadata, and orphaned
---- meanings.
perform dnrm (dn, true, false) from dn
where ex = $1;
---- Record the expression ID as available.
insert into exid values ($1);
---- Delete the expression.
delete from ex where ex = $1;
end if;
-- Return.
return;
end;$_$;


ALTER FUNCTION public.exrm(integer) OWNER TO pool;

--
-- Name: FUNCTION exrm(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exrm(integer) IS 'In: ex of an expression. Act: Delete the expression, all denotations with it, all their word classifications and metadata, and all meanings orphaned by the deletion of the denotations.';


--
-- Name: exs(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exs(integer, OUT ex integer, OUT tt text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function exs
--(integer, out ex integer, out tt text)
--returns setof record language sql as
select ex, tt from ex
where lv = $1
order by tt;$_$;


ALTER FUNCTION public.exs(integer, OUT ex integer, OUT tt text) OWNER TO pool;

--
-- Name: FUNCTION exs(integer, OUT ex integer, OUT tt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exs(integer, OUT ex integer, OUT tt text) IS 'In: lv of a variety. Out: ex and tt of each expression in the variety.';


--
-- Name: exttmd(integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exttmd(integer, text) RETURNS smallint
    LANGUAGE plpgsql
    AS $_$--create or replace function exttmd
--(integer, text)
--returns smallint language plpgsql as
declare
delvar record;
exvar ex;
tvar ex;
begin
-- Identify the facts about the expression
-- (source expression).
select * into exvar from ex
where ex = $1;
-- If the source expression doesn't exist:
if exvar.ex is null
then
---- Report the reason and quit.
return 1;
end if;
-- If the new text is blank:
if $2 = ''
then
---- Report the reason and quit.
return 2;
end if;
-- If the new text is the existing one:
if $2 = exvar.tt
then
---- Report success.
return 0;
end if;
-- Identify the existing expression in the
-- variety with the new text (target
-- expression):
select * into tvar from ex
where lv = exvar.lv
and tt = $2;
-- If it doesn’t exist:
if tvar.ex is null
then
---- Amend the source expression's text.
update ex
set tt = $2
where ex = $1;
-- Otherwise, i.e. if the target expression
-- exists:
else
---- Delete every word classification whose
---- denotation’s expression is the source
---- expression if another word classification’s
---- denotation has the same meaning, the target
---- expression, and the same value.
for delvar in
select wc1.wc
from wc as wc1, wc as wc2, dn as dn1, dn as dn2
where dn1.ex = $1
and wc1.dn = dn1.dn
and dn2.ex = tvar.ex
and dn2.mn = dn1.mn
and wc2.dn = dn2.dn
and wc2.ex = wc1.ex
loop
delete from wc
where wc = delvar.wc;
insert into wcid values (delvar.wc);
end loop;
---- Delete every metadatum whose denotation’s
---- expression is the source expression if
---- another metadatum’s denotation has the
---- same meaning, the target expression,
---- the same variable, and the same value.
for delvar in
select md1.md
from md as md1, md as md2, dn as dn1, dn as dn2
where dn1.ex = $1
and md1.dn = dn1.dn
and dn2.ex = tvar.ex
and dn2.mn = dn1.mn
and md2.dn = dn2.dn
and md2.vb = md1.vb
and md2.vl = md1.vl
loop
delete from md
where md = delvar.md;
insert into mdid values (delvar.md);
end loop;
---- Change the denotation of every word
---- classification whose denotation’s
---- expression is the source expression to
---- the denotation that has the same meaning
---- and the target expression, if it exists.
update wc
set dn = dn2.dn
from dn as dn1, dn as dn2
where dn1.ex = $1
and wc.dn = dn1.dn
and dn2.ex = tvar.ex
and dn2.mn = dn1.mn;
---- Change the denotation of every metadatum
---- whose denotation’s expression is the
---- source expression to the denotation that
---- has the same meaning and the target
---- expression, if it exists.
update md
set dn = dn2.dn
from dn as dn1, dn as dn2
where dn1.ex = $1
and md.dn = dn1.dn
and dn2.ex = tvar.ex
and dn2.mn = dn1.mn;
---- Delete every denotation with the source
---- expression if another denotation has the
---- same meaning and the target expression.
for delvar in
select dn1.dn from dn as dn1, dn as dn2
where dn1.ex = $1
and dn2.ex = tvar.ex
and dn2.mn = dn1.mn
loop
delete from dn
where dn = delvar.dn;
insert into dnid values (delvar.dn);
end loop;
---- Change the expression of every denotation
---- with the source expression to the target
---- expression.
update dn
set ex = tvar.ex
where ex = $1;
---- Delete every domain specification with the
---- source expression if another domain
---- specification has the same meaning and the
---- target expression.
for delvar in
select dm1.dm from dm as dm1, dm as dm2
where dm1.ex = $1
and dm2.ex = tvar.ex
and dm2.mn = dm1.mn
loop
delete from dm
where dm = delvar.dm;
insert into dmid values (delvar.dm);
end loop;
---- Change the expression of every domain
---- specification with the source expression to
---- the target expression.
update dm
set ex = tvar.ex
where ex = $1;
---- Delete the source expression.
perform exrm ($1);
end if;
-- Return success.
return 0;
end;$_$;


ALTER FUNCTION public.exttmd(integer, text) OWNER TO pool;

--
-- Name: FUNCTION exttmd(integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exttmd(integer, text) IS 'In: ex of an expression and a text. Act: Make the text the expression’s new tt if no expression in the same variety has it, or otherwise merge the expressions, their denotations, their denotations’ word classes and metadata, and their domain specifications. Out: 1 = no ex, 2 = blank tt, 0 = success.';


--
-- Name: exx(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION exx(integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) RETURNS record
    LANGUAGE sql
    AS $_$--create or replace function exx
--(integer, out lc character (3), out vc smallint,
--out lvtt text, out ex integer, out extt text)
--returns record language sql as
select
lc, vc, lv.tt as lvtt, ex, ex.tt as extt
from ex, lv
where ex = $1
and lv.lv = ex.lv;$_$;


ALTER FUNCTION public.exx(integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) OWNER TO pool;

--
-- Name: FUNCTION exx(integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION exx(integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) IS 'In: ex of an expression. Out: lc, vc, lv tt, ex, and ex tt of the expression.';


--
-- Name: idck(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION idck() RETURNS text
    LANGUAGE plpgsql
    AS $$--create or replace function idck ()
--returns text language plpgsql as
declare
bad text;
clash integer;
ctid integer;
ctmain integer;
maxid integer;
maxmain integer;
begin
-- Initialize result as blank.
bad := '';
-- Check expression IDs.
select count (ex) from exid into ctid;
select count (ex) from ex into ctmain;
select max (ex) from exid into maxid;
select max (ex) from ex into maxmain;
select ex.ex into clash from ex, exid
where exid.ex = ex.ex;
if ctid + ctmain != maxid
or maxid <= maxmain
or clash is not null
then
bad := bad || 'ex ';
end if;
-- Check meaning IDs.
select count (mn) from mnid into ctid;
select count (mn) from mn into ctmain;
select max (mn) from mnid into maxid;
select max (mn) from mn into maxmain;
select mn.mn into clash from mn, mnid
where mnid.mn = mn.mn;
if ctid + ctmain != maxid
or maxid <= maxmain
or clash is not null
then
bad := bad || 'mn ';
end if;
-- Check denotation IDs.
select count (dn) from dnid into ctid;
select count (dn) from dn into ctmain;
select max (dn) from dnid into maxid;
select max (dn) from dn into maxmain;
select dn.dn into clash from dn, dnid
where dnid.dn = dn.dn;
if ctid + ctmain != maxid
or maxid <= maxmain
or clash is not null
then
bad := bad || 'dn ';
end if;
-- Check definition IDs.
select count (df) from dfid into ctid;
select count (df) from df into ctmain;
select max (df) from dfid into maxid;
select max (df) from df into maxmain;
select df.df into clash from df, dfid
where dfid.df = df.df;
if ctid + ctmain != maxid
or maxid <= maxmain
or clash is not null
then
bad := bad || 'df ';
end if;
-- Check domain IDs.
select count (dm) from dmid into ctid;
select count (dm) from dm into ctmain;
select max (dm) from dmid into maxid;
select max (dm) from dm into maxmain;
select dm.dm into clash from dm, dmid
where dmid.dm = dm.dm;
if ctid + ctmain != maxid
or maxid <= maxmain
or clash is not null
then
bad := bad || 'dm ';
end if;
-- Check word-classification IDs.
select count (wc) from wcid into ctid;
select count (wc) from wc into ctmain;
select max (wc) from wcid into maxid;
select max (wc) from wc into maxmain;
select wc.wc into clash from wc, wcid
where wcid.wc = wc.wc;
if ctid + ctmain != maxid
or maxid <= maxmain
or clash is not null
then
bad := bad || 'wc ';
end if;
-- Check metadatum IDs.
select count (md) from mdid into ctid;
select count (md) from md into ctmain;
select max (md) from mdid into maxid;
select max (md) from md into maxmain;
select md.md into clash from md, mdid
where mdid.md = md.md;
if ctid + ctmain != maxid
or maxid <= maxmain
or clash is not null
then
bad := bad || 'md ';
end if;
return bad;
end;$$;


ALTER FUNCTION public.idck() OWNER TO pool;

--
-- Name: FUNCTION idck(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION idck() IS 'Out: string containing right-space-padded names of tables whose “id” tables are defective or blank if none.';


--
-- Name: idw(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION idw() RETURNS void
    LANGUAGE plpgsql
    AS $$--create or replace function idw ()
--returns void language plpgsql as
declare
maxid integer;
idvar integer;
begin
-- Process meanings.
-- Empty the table of available IDs.
truncate mnid;
-- Identify the largest ID.
select max (mn) into maxid from mn;
-- Initiate the table of available IDs
-- with the next integer after that.
insert into mnid values (maxid + 1);
-- If any IDs are missing:
if maxid > (select count (mn) from mn)
then
---- For each possibly missing ID:
for id in 1 .. maxid loop
------ Identify the meaning with it.
select mn into idvar
from mn
where mn = id;
------ If it is missing:
if idvar is null
then
-------- Add it to the table of available IDs.
insert into mnid values (idvar);
end if;
end loop;
end if;
-- Process expressions.
-- Empty the table of available IDs.
truncate exid;
-- Identify the largest ID.
select max (ex) into maxid from ex;
-- Initiate the table of available IDs
-- with the next integer after that.
insert into exid values (maxid + 1);
-- If any IDs are missing:
if maxid > (select count (ex) from ex)
then
---- For each possibly missing ID:
for id in 1 .. maxid loop
------ Identify the expression with it.
select ex into idvar
from ex
where ex = id;
------ If it is missing:
if idvar is null
then
-------- Add it to the table of available IDs.
insert into exid values (id);
end if;
end loop;
end if;
-- Process denotations.
-- Empty the table of available IDs.
truncate dnid;
-- Identify the largest ID.
select max (dn) into maxid from dn;
-- Initiate the table of available IDs
-- with the next integer after that.
insert into dnid values (maxid + 1);
-- If any IDs are missing:
if maxid > (select count (dn) from dn)
then
---- For each possibly missing ID:
for id in 1 .. maxid loop
------ Identify the denotation with it.
select dn into idvar
from dn
where dn = id;
------ If it is missing:
if idvar is null
then
-------- Add it to the table of available IDs.
insert into dnid values (id);
end if;
end loop;
end if;
-- Process definitions.
-- Empty the table of available IDs.
truncate dfid;
-- Identify the largest ID.
select max (df) into maxid from df;
-- Initiate the table of available IDs
-- with the next integer after that.
insert into dfid values (maxid + 1);
-- If any IDs are missing:
if maxid > (select count (df) from df)
then
---- For each possibly missing ID:
for id in 1 .. maxid loop
------ Identify the definition with it.
select df into idvar
from df
where df = id;
------ If it is missing:
if idvar is null
then
-------- Add it to the table of available IDs.
insert into dfid values (id);
end if;
end loop;
end if;
-- Process domains.
-- Empty the table of available IDs.
truncate dmid;
-- Identify the largest ID.
select max (dm) into maxid from dm;
-- Initiate the table of available IDs
-- with the next integer after that.
insert into dmid values (maxid + 1);
-- If any IDs are missing:
if maxid > (select count (dm) from dm)
then
---- For each possibly missing ID:
for id in 1 .. maxid loop
------ Identify the domain with it.
select dm into idvar
from dm
where dm = id;
------ If it is missing:
if idvar is null
then
-------- Add it to the table of available IDs.
insert into dmid values (id);
end if;
end loop;
end if;
-- Process word classifications.
-- Empty the table of available IDs.
truncate wcid;
-- Identify the largest ID.
select max (wc) into maxid from wc;
-- Initiate the table of available IDs
-- with the next integer after that.
insert into wcid values (maxid + 1);
-- If any IDs are missing:
if maxid > (select count (wc) from wc)
then
---- For each possibly missing ID:
for id in 1 .. maxid loop
------ Identify the word classification with it.
select wc into idvar
from wc
where wc = id;
------ If it is missing:
if idvar is null
then
-------- Add it to the table of available IDs.
insert into wcid values (id);
end if;
end loop;
end if;
-- Process metadata.
-- Empty the table of available IDs.
truncate mdid;
-- Identify the largest ID.
select max (md) into maxid from md;
-- Initiate the table of available IDs
-- with the next integer after that.
insert into mdid values (maxid + 1);
-- If any IDs are missing:
if maxid > (select count (md) from md)
then
---- For each possibly missing ID:
for id in 1 .. maxid loop
------ Identify the metadatum with it.
select md into idvar
from md
where md = id;
------ If it is missing:
if idvar is null
then
-------- Add it to the table of available IDs.
insert into mdid values (id);
end if;
end loop;
end if;
end;$$;


ALTER FUNCTION public.idw() OWNER TO pool;

--
-- Name: FUNCTION idw(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION idw() IS 'Act: Repopulate the tables of available IDs.';


--
-- Name: ixck(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION ixck() RETURNS void
    LANGUAGE plpgsql
    AS $$--create or replace function ixck ()
--returns void language plpgsql as
declare
begin
perform * from ex order by ex limit 1000;
perform * from ex order by lv, tt limit 1000;
perform * from ex order by lv limit 1000;
perform * from dn order by dn limit 1000;
perform * from dn order by mn, ex limit 1000;
perform * from dn order by ex limit 1000;
perform * from dn order by mn limit 1000;
perform * from mn order by mn limit 1000;
perform * from mn order by ap limit 1000;
end;$$;


ALTER FUNCTION public.ixck() OWNER TO pool;

--
-- Name: FUNCTION ixck(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION ixck() IS 'Act: Make the server traverse and thus cache all large indices.';


--
-- Name: lcmd(integer, character); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lcmd(integer, character) RETURNS smallint
    LANGUAGE plpgsql
    AS $_$--create or replace function lcmd
--(integer, character (3))
--returns smallint language plpgsql as
declare
lcvar character (3);
lvvar lv;
uvar smallint;
vcvar smallint;
begin
-- Identify the facts about the variety.
select * into lvvar from lv
where lv = $1;
-- If the variety doesn't exist:
if lvvar.lv is null
then
---- Report the reason and quit.
return 1;
end if;
-- If the new ISO code is the existing one:
if $2 = lvvar.lc
then
---- Return success.
return 0;
end if;
-- Identify the new ISO code as a valid code.
select lc into lcvar from lc
where lc = $2;
-- If it doesn't exist:
if lcvar is null
then
---- Report the reason and quit.
return 2;
end if;
-- Initialize the to-be-tested variety code.
vcvar := 0;
-- Initialize the last-tested variety
-- code as used.
uvar := 0;
-- Until the last-tested variety code is
-- unused:
while uvar is not null loop
---- Determine whether the to-be-tested variety
---- code is used.
select vc into uvar from lv
where lc = $2
and vc = vcvar;
---- Increment the to-be-tested variety code.
vcvar := vcvar + 1;
end loop;
-- Amend the variety's ISO code and variety
-- code.
update lv
set lc = $2, vc = vcvar - 1
where lv = $1;
-- Return success.
return 0;
end;$_$;


ALTER FUNCTION public.lcmd(integer, character) OWNER TO pool;

--
-- Name: FUNCTION lcmd(integer, character); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lcmd(integer, character) IS 'In: lv of a variety and lc of a language. Act: Make the lc the variety’s new lc and give the variety the first unused vc. Out: 1 = no lv, 2 = no lc, 0 = success.';


--
-- Name: lcvc(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lcvc(integer) RETURNS character
    LANGUAGE sql
    AS $_$--create or replace function lcvc (integer)
--returns character (7) language sql as
select (lc || '-' || (to_char (vc, 'FM009'))) from lv where lv = $1;$_$;


ALTER FUNCTION public.lcvc(integer) OWNER TO pool;

--
-- Name: FUNCTION lcvc(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lcvc(integer) IS 'In: lv of a variety. Out: variety’s UI.';


--
-- Name: lcvctt(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lcvctt(integer, OUT lcvc character, OUT tt text) RETURNS record
    LANGUAGE sql
    AS $_$--create or replace function lcvctt
--(integer, out lcvc character (7), out tt text)
--returns record language sql as
select (lc || '-' || (to_char (vc, 'FM009'))), tt from lv where lv = $1;$_$;


ALTER FUNCTION public.lcvctt(integer, OUT lcvc character, OUT tt text) OWNER TO pool;

--
-- Name: FUNCTION lcvctt(integer, OUT lcvc character, OUT tt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lcvctt(integer, OUT lcvc character, OUT tt text) IS 'In: lv of a variety. Out: variety’s UI and label.';


--
-- Name: lv(character, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lv(character, integer) RETURNS integer
    LANGUAGE sql
    AS $_$--create or replace function lv
--(character, integer)
--returns integer language sql as
select lv from lv
where lc = $1
and vc = $2;$_$;


ALTER FUNCTION public.lv(character, integer) OWNER TO pool;

--
-- Name: FUNCTION lv(character, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lv(character, integer) IS 'In: lc and vc of a variety. Out: lv of the variety.';


--
-- Name: lvad(character, boolean, boolean, text, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lvad(character, boolean, boolean, text, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function lvad
--(character (3), boolean, boolean,
--text, integer)
--returns integer language plpgsql as
declare
ivar integer;
lcvar character (3);
lvvar integer;
usvar integer;
uvar smallint;
vcvar smallint;
begin
-- Identify the ISO code.
select lc into lcvar from lc
where lc = $1;
-- If it does not exist:
if lcvar is null
then
---- Report the reason and quit.
return -1;
end if;
-- If the label is blank:
if length ($4) = 0
then
---- Report the reason and quit.
return -2;
end if;
-- Identify the smallest unused variety ID.
select min (lvu) into lvvar from
(select 1 as lvu union select lv + 1 as lvu from lv
except select lv as lvu from lv) as subq;
-- Identify an existing variety with the ISO code.
select lv into ivar from lv
where lc = $1;
-- If there is none:
if ivar is null
then
---- Add a variety with the ISO code and
---- 0 as the variety code.
insert into lv values
(lvvar, $1, 0, $2, $3, $4);
-- Otherwise, i.e. if a variety with the
-- ISO code exists:
else
---- Identify the smallest unused variety
---- code among varieties with the ISO code.
select min (vcu) into vcvar from
(select 0 as vcu union select vc + 1 as vcu from lv
where lc = $1 except select vc as vcu from lv
where lc = $1) as subq;
---- Add the specified variety with it.
insert into lv values
(lvvar, $1, vcvar, $2, $3, $4);
end if;
-- If a user is to be entitled to edit the
-- variety:
if $5 > 0
then
---- Make the user an editor of it.
insert into lu values (lvvar, $5);
end if;
-- Return the variety’s ID.
return lvvar;
end;$_$;


ALTER FUNCTION public.lvad(character, boolean, boolean, text, integer) OWNER TO pool;

--
-- Name: FUNCTION lvad(character, boolean, boolean, text, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lvad(character, boolean, boolean, text, integer) IS 'In: lc, sy, am, and tt of a variety and us of a user that is to be entitled to edit the variety or 0 if none is. Act: Add the specified variety and, if so specified, make the user an editor of it. Out: -1 = bad lc, -2 = no tt, other integer = lv of the variety.';


--
-- Name: lvpw(integer, integer, character); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lvpw(integer, integer, character) RETURNS boolean
    LANGUAGE sql
    AS $_$--create or replace function lvpw
--(integer, integer, character)
--returns boolean language sql as
select
($3 = (select pw from us where us = $2))
and (
(select ad from us where us = $2)
or ($2 = (select us from lu where lv = $1 and us = $2))
);$_$;


ALTER FUNCTION public.lvpw(integer, integer, character) OWNER TO pool;

--
-- Name: FUNCTION lvpw(integer, integer, character); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lvpw(integer, integer, character) IS 'In: lv of a variety and us and pw of a user. Out: whether the password is the user’s and the user is either a superuser or an editor of the variety.';


--
-- Name: lvs(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lvs(integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$--create or replace function lvs (integer)
--returns setof integer language sql as
select av.lv from av, lv
where av.ap = $1
and lv.lv = av.lv
order by lc, vc;$_$;


ALTER FUNCTION public.lvs(integer) OWNER TO pool;

--
-- Name: FUNCTION lvs(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lvs(integer) IS 'In: ap of an approver. Out: lv of each declared variety of the approver.';


--
-- Name: lvttmd(integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lvttmd(integer, text) RETURNS smallint
    LANGUAGE plpgsql
    AS $_$--create or replace function lvttmd (integer, text)
--returns smallint language plpgsql as
declare
lvvar lv;
begin
-- Identify the facts about the variety.
select * into lvvar from lv
where lv = $1;
-- If the variety doesn't exist:
if lvvar.lv is null
then
---- Report the reason and quit.
return 1;
end if;
-- If the new label is blank:
if $2 = ''
then
---- Report the reason and quit.
return 2;
end if;
-- If the new label is the existing one:
if $2 = lvvar.tt
then
---- Return success.
return 0;
end if;
-- Amend the variety's label.
update lv
set tt = $2
where lv = $1;
-- Return success.
return 0;
end;$_$;


ALTER FUNCTION public.lvttmd(integer, text) OWNER TO pool;

--
-- Name: FUNCTION lvttmd(integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lvttmd(integer, text) IS 'In: lv of a variety and a text. Act: Make the text the variety’s new tt. Out: 1 = no lv, 2 = blank tt, 0 = success.';


--
-- Name: lvx(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lvx(integer, OUT lc character, OUT vc smallint, OUT tt text) RETURNS record
    LANGUAGE sql
    AS $_$--create or replace function lvx
--(integer, out lc character (3), out vc smallint, out tt text)
--returns record language sql as
select lc, vc, tt from lv
where lv = $1;$_$;


ALTER FUNCTION public.lvx(integer, OUT lc character, OUT vc smallint, OUT tt text) OWNER TO pool;

--
-- Name: FUNCTION lvx(integer, OUT lc character, OUT vc smallint, OUT tt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lvx(integer, OUT lc character, OUT vc smallint, OUT tt text) IS 'In: lv of a variety. Out: lc, vc, and tt of the variety.';


--
-- Name: lvxs(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION lvxs(OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) RETURNS SETOF record
    LANGUAGE sql
    AS $$--create or replace function lvxs
--(out lv integer, out lc character (3),
--out vc smallint, out tt text)
--returns setof record language sql as
select lv, lc, vc, tt
from lv
order by lc, vc;$$;


ALTER FUNCTION public.lvxs(OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) OWNER TO pool;

--
-- Name: FUNCTION lvxs(OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION lvxs(OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) IS 'Out: lv, lc, vc, and tt of each variety.';


--
-- Name: mdad(integer, text, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION mdad(integer, text, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function mdad
--(integer, text, text)
--returns integer language plpgsql as
declare
dnvar integer;
mdvar integer;
begin
-- Identify the specified metadatum.
select md into mdvar from md
where dn = $1
and vb = $2
and vl = $3;
-- If it exists:
if mdvar is not null
then
---- Report the reason and quit.
return -1;
end if;
-- Identify the specified denotation.
select dn into dnvar from dn
where dn = $1;
-- If it doesn’t exist:
if dnvar is null
then
---- Report the reason and quit.
return -2;
end if;
-- Identify the new metadatum.
select * into mdvar from mdgt ();
-- Record it.
insert into md values (mdvar, $1, $2, $3);
-- Return the metadatum.
return mdvar;
end;$_$;


ALTER FUNCTION public.mdad(integer, text, text) OWNER TO pool;

--
-- Name: FUNCTION mdad(integer, text, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION mdad(integer, text, text) IS 'In: dn, vb, and vl of a metadatum. Act: Add the metadatum. Out: -1 = metadatum exists, -2 = no dn, other integer = md.';


--
-- Name: mdgt(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION mdgt() RETURNS integer
    LANGUAGE plpgsql
    AS $$--create or replace function mdgt ()
--returns integer language plpgsql as
declare
mdvar integer;
nmdvar integer;
begin
-- Identify the smallest available
-- metadatum ID.
select min (md) into mdvar from mdid;
-- Make it unavailable.
delete from mdid
where md = mdvar;
-- Identify another missing metadatum.
select md into nmdvar from mdid;
-- If there is none:
if nmdvar is null
then
---- Record the next metadatum as available.
---- Precondition: The metadatum with an ID
---- 1 larger than the largest ID of any
---- metadatum is recorded as available.
insert into mdid values (mdvar + 1);
end if;
-- Return the available metadatum.
return mdvar;
end;$$;


ALTER FUNCTION public.mdgt() OWNER TO pool;

--
-- Name: FUNCTION mdgt(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION mdgt() IS 'Act: Revise the list of available metadatum IDs. Out: the next available metadatum ID.';


--
-- Name: mdrm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION mdrm(integer) RETURNS void
    LANGUAGE sql
    AS $_$--create or replace function mdrm
--(integer) returns void language sql as
insert into mdid
select md from md
where md = $1;
delete from md
where md = $1;$_$;


ALTER FUNCTION public.mdrm(integer) OWNER TO pool;

--
-- Name: FUNCTION mdrm(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION mdrm(integer) IS 'In: md of a metadatum. Act: Delete the metadatum, recording its ID as available.';


--
-- Name: miad(integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION miad(integer, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function miad
--(integer, text)
--returns integer language plpgsql as
declare
mnvar integer;
begin
-- Identify the specified meaning.
select mn into mnvar from mn
where mn = $1;
-- If it doesn’t exist:
if mnvar is null
then
---- Report the reason and quit.
return 1;
end if;
-- Delete any existing identifier of the
-- meaning.
delete from mi
where mn = $1;
-- Record the identifier.
insert into mi values ($1, $2);
-- Return a success report.
return 0;
end;$_$;


ALTER FUNCTION public.miad(integer, text) OWNER TO pool;

--
-- Name: FUNCTION miad(integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION miad(integer, text) IS 'In: mn and tt of a meaning identifier. Act: Add the meaning identifier, replacing any identifier of the meaning. Out: 1 = no mn, 0 = success.';


--
-- Name: mnad(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION mnad(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function mnad (integer)
--returns integer language plpgsql as
declare
mnvar integer;
begin
-- Identify a new meaning ID.
select * into mnvar from mngt ();
-- Record the new meaning.
insert into mn values (mnvar, $1);
-- Return the meaning ID.
return mnvar;
end;$_$;


ALTER FUNCTION public.mnad(integer) OWNER TO pool;

--
-- Name: FUNCTION mnad(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION mnad(integer) IS 'In: ap of an approver. Act: Record a new meaning of the approver. Out: meaning ID.';


--
-- Name: mnck(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION mnck(integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$--create or replace function mnck
--(integer) returns void language plpgsql as
declare
mnvar integer;
begin
-- Identify the meaning.
select mn into mnvar from mn
where mn = $1;
-- If it doesn’t exist:
if mnvar is null
then
---- Quit.
return;
end if;
-- Identify a denotation with the
-- specified meaning.
select mn into mnvar from dn
where mn = $1;
-- If there is any:
if mnvar is not null
then
---- Stop checking.
return;
end if;
-- Identify a definition with the
-- specified meaning.
select mn into mnvar from df
where mn = $1;
-- If there is any:
if mnvar is not null
then
---- Stop checking.
return;
end if;
-- Identify a domain with the
-- specified meaning.
select mn into mnvar from dm
where mn = $1;
-- If there is any:
if mnvar is not null
then
---- Stop checking.
return;
end if;
-- Identify a meaning identifier with the
-- specified meaning.
select mn into mnvar from mi
where mn = $1;
-- If there is any:
if mnvar is not null
then
---- Stop checking.
return;
end if;
-- Delete the meaning.
insert into mnid values ($1);
delete from mn
where mn = $1;
end;$_$;


ALTER FUNCTION public.mnck(integer) OWNER TO pool;

--
-- Name: FUNCTION mnck(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION mnck(integer) IS 'In: mn of a meaning. Act: If the meaning exists and is not the meaning of any denotation, definition, domain, or meaning identifier, delete it.';


--
-- Name: mngt(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION mngt() RETURNS integer
    LANGUAGE plpgsql
    AS $$--create or replace function mngt ()
--returns integer language plpgsql as
declare
mnvar integer;
nmnvar integer;
begin
-- Identify the smallest available meaning ID.
select min (mn) into mnvar from mnid;
-- Make it unavailable.
delete from mnid
where mn = mnvar;
-- Identify another missing meaning.
select mn into nmnvar from mnid;
-- If there is none:
if nmnvar is null
then
---- Record the next meaning as available.
---- Precondition: The meaning with an ID
---- 1 larger than the largest ID of the
---- meaning of any denotation, meaning
---- identifier, definition, or domain is
---- recorded as available.
insert into mnid values (mnvar + 1);
end if;
-- Return the deleted meaning.
return mnvar;
end;$$;


ALTER FUNCTION public.mngt() OWNER TO pool;

--
-- Name: FUNCTION mngt(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION mngt() IS 'Act: Revise the list of available meaning IDs. Out: the next available meaning ID.';


--
-- Name: mnrm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION mnrm(integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function mnrm (integer)
--returns integer language plpgsql as
declare
dnvar record;
mnvar integer;
begin
-- Identify the specified meaning.
select mn into mnvar from mn
where mn = $1;
-- If it doesn’t exist:
if mnvar is null
then
---- Report the reason and quit.
return 1;
end if;
-- Delete the meaning identifier, if any.
delete from mi
where mn = $1;
-- Delete all definitions of the meaning.
insert into dfid
select df from df
where mn = $1;
delete from df
where mn = $1;
-- Delete all domains of the meaning.
insert into dmid
select dm from dm
where mn = $1;
delete from dm
where mn = $1;
-- For each denotation with the meaning:
for dnvar in
select dn from dn
where mn = $1
loop
---- Delete it and its word classifications,
---- metadata, and if orphaned expression.
perform dnrm (dnvar.dn, false, true);
end loop;
-- Record its ID as available.
insert into mnid values ($1);
-- Delete the meaning.
delete from mn where mn = $1;
-- Report success.
return 0;
end;$_$;


ALTER FUNCTION public.mnrm(integer) OWNER TO pool;

--
-- Name: FUNCTION mnrm(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION mnrm(integer) IS 'In: mn of a meaning. Act: Delete the meaning and its identifier, definitions, domains, and denotations.';


--
-- Name: nml(integer, text, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION nml(integer, text, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function nml
--(integer, text, text)
--returns integer language plpgsql as
declare
lvvar lv;
mdvar integer;
begin
-- Identify the facts about the variety.
select * into lvvar from lv
where lv = $1;
-- If the variety doesn't exist:
if lvvar.lv is null
then
---- Report the reason and quit.
return -1;
end if;
-- If the old text is blank:
if $2 = ''
then
---- Report the reason and quit.
return -2;
end if;
-- If the old and new texts are identical:
if $3 = $2
then
---- Return success.
return 0;
end if;
---- Replace every instance of the old text
---- with the new text in every expression
---- in the variety in any denotation containing
---- the old text, making the word class and
---- metadatum tables conform.
select count (exttmd (ex.ex, replace (tt, $2, $3)))
into mdvar
from ex, dn
where lv = $1
and position ($2 in tt) > 0
and dn.ex = ex.ex;
-- Return the count of expressions changed.
return mdvar;
end;$_$;


ALTER FUNCTION public.nml(integer, text, text) OWNER TO pool;

--
-- Name: FUNCTION nml(integer, text, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION nml(integer, text, text) IS 'In: lv of a variety and two texts. Act: Replace every instance of the first with the second text in the text of each expression in the variety in any denotation. Out: 0 = texts identical, -1 = no lv, -2 = old text blank, other integer = count of changed expressions.';


--
-- Name: pl(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION pl() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function pl ()
--returns void language sql as
delete from pl0;
insert into pl0
select tt, ex.ex, mn.mn from dn, ex, mn
where ap = 1
and lv = 1127
and dn.ex = ex.ex
and dn.mn = mn.mn
order by tt;
delete from pl1;
insert into pl1
select pl0.mn, lv, ex.ex from pl0, dn, ex
where dn.mn = pl0.mn
and ex.ex = dn.ex
and lv != 1127
order by pl0.mn, lv, ex.ex;$$;


ALTER FUNCTION public.pl() OWNER TO pool;

--
-- Name: FUNCTION pl(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION pl() IS 'Act: Populate pl0 and pl1.';


--
-- Name: syrm(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION syrm(integer, integer) RETURNS void
    LANGUAGE plpgsql
    AS $_$--create or replace function syrm
--(integer, integer)
--returns void language plpgsql as
declare
exvar integer;
dnvar integer;
begin
-- Identify an expression in the specified
-- variety that has the specified meaning.
select ex.ex into exvar from dn, ex
where mn = $1
and ex.ex = dn.ex
and lv = $2;
-- If there is any:
if exvar is not null
then
---- Identify the denotation with the specified
---- meaning and with that expression.
select dn into dnvar from dn
where mn = $1
and ex = exvar;
---- If it exists:
if dnvar is not null
then
------ Delete the denotation and its word
------ classifications and metadata.
perform dnrm (dnvar, false, true);
end if;
end if;
end;$_$;


ALTER FUNCTION public.syrm(integer, integer) OWNER TO pool;

--
-- Name: FUNCTION syrm(integer, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION syrm(integer, integer) IS 'In: mn of a meaning and lv of a variety. Act: Delete an arbitrary denotation, if any, with the meaning and with an expression in the variety, the denotation’s word classifications and metadata, and if orphaned the expression. Use: To prepare a meaning for assignment to an expression in a synonymy-prohibiting variety.';


--
-- Name: td(text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION td(text) RETURNS text
    LANGUAGE plperlu
    AS $_X$# create or replace function td (text)
# returns text language plperlu as
use encoding 'utf8';
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.
use strict;
use Unicode::Normalize;
my $td = (&NFKD ($_[0]));
# Initialize the degradation of the text as its
# compatibility decomposition (Normalization Form KD).
$td = (lc $td);
# Make the degradation lower-case.
$td =~ s#ı#i#g;
# Replace all instances of “ı” with “i” in the
# degradation.
$td =~ s#[^\p{Ll}\p{Lo}]##g;
# Remove all non-basic characters from the degradation.
# This leaves undegraded many characters that
# arguably merit degradation and does not deal with
# transscriptal confusion or transliteration.
return $td;
# Return the degradation.
$_X$;


ALTER FUNCTION public.td(text) OWNER TO pool;

--
-- Name: FUNCTION td(text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION td(text) IS 'In: a text. Out: the degradation of the text.';


--
-- Name: tdau(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION tdau() RETURNS trigger
    LANGUAGE plperlu
    AS $_X$# create or replace function tdau ()
## returns trigger language plperlu as
use encoding 'utf8';
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.
use strict;
use Unicode::Normalize;
my $tt = ($_TD->{new}{tt});
# Identify the new expression text.
my $td = (&NFKD ($tt));
# Initialize its degradation as its compatibility decomposition (Normalization Form KD).
my $td = (lc $td);
# Make the degradation lower-case.
$td =~ s#ı#i#g;
# Replace all instances of “ı” with “i” in the degradation.
$td =~ s#[^\p{Ll}\p{Lo}]##g;
# Remove all non-basic characters from the degradation.
# This leaves undegraded many characters that arguably merit degradation and does not deal with
# transscriptal confusion or transliteration.
$_TD->{new}{td} = $td;
# Identify the degradation.
return "MODIFY";
# Return the modified row.
$_X$;


ALTER FUNCTION public.tdau() OWNER TO pool;

--
-- Name: FUNCTION tdau(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION tdau() IS 'Act: Set column td to the degradation of column tt.';


--
-- Name: tdw(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION tdw() RETURNS integer
    LANGUAGE plperlu
    AS $_$# create or replace function tdw ()
# returns void language plperl as
use encoding 'utf8';
# Make Perl interpret the script and standard files as UTF-8 rather than bytes.
use strict;
use Unicode::Normalize;
my $sth = (spi_query ('select * from ex'));
# Identify a query to read table ex.
my ($ex, $lv, $rowr, %row, $rv, $td, $tt);
my $changed = 0;
# Initialize the count of degradations.
$rv = (spi_exec_query ('update ex set td = null'));
# Delete column ex.td.
while (defined ($rowr = spi_fetchrow ($sth))) {
# Until all its rows are read:
  %row = %$rowr;
  # Identify the row as a table.
  $ex = $row{ex};
  # Identify the expression’s ID.
  $lv = $row{lv};
  # Identify the expression’s language variety.
  $tt = $row{tt};
  # Identify the expression’s text.
  $td = (&NFKD ($tt));
  # Initialize its degradation as its compatibility decomposition (Normalization Form KD).
  $td = (lc $td);
  # Make the degradation lower-case.
  $td =~ s#ı#i#g;
  # Replace all instances of “ı” with “i” in the degradation.
  $td =~ s#[^\p{Ll}\p{Lo}]##g;
  # Remove all non-basic characters from the degradation.
  # This leaves undegraded many characters that arguably merit degradation and does not deal with
  # transscriptal confusion or transliteration.
  if ($td ne $tt) {
  # If the degradation differs from the text:
    $td =~ s#'#''#g;
    # Double any ASCII apostrophes in the degradation.
    $rv = (spi_exec_query ("insert into extemp values ($ex, '$td')"));
    # Record the degradation in the temporary file.
    $changed++;
    # Increment the degradation count.
  }
}
# $rv = (spi_exec_query ('update ex set td = tt where td is null'));
# Make column ex.td identical to column ex.tt wherever no degradation has been recorded.
return $changed;
# Return the degradation count.
$_$;


ALTER FUNCTION public.tdw() OWNER TO pool;

--
-- Name: FUNCTION tdw(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION tdw() IS 'Act: Populate column ex.td.';


--
-- Name: tr(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION tr(integer, integer, OUT exid integer, OUT extt text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function tr
--(integer, integer,
--out exid integer, out extt text)
--returns setof record language sql as
select distinct dn2.ex as exid, tt as extt
from dn as dn1, dn as dn2, ex
where dn1.ex = $1
and dn2.mn = dn1.mn
and dn2.ex != $1
and ex.ex = dn2.ex
and lv = $2
order by extt;$_$;


ALTER FUNCTION public.tr(integer, integer, OUT exid integer, OUT extt text) OWNER TO pool;

--
-- Name: FUNCTION tr(integer, integer, OUT exid integer, OUT extt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION tr(integer, integer, OUT exid integer, OUT extt text) IS 'In: ex of an expression and lv of a variety. Out: ex and tt of each expression in the variety, other than the expression, that has at least 1 meaning of the expression.';


--
-- Name: traps(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION traps(integer, integer, OUT ap integer, OUT tt text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function traps
--(integer, integer, out ap integer, out tt text)
--returns setof record language sql as
select distinct ap.ap, tt
from dn as dn1, dn as dn2, mn, ap
where dn1.ex = $1
and dn2.ex = $2
and dn2.mn = dn1.mn
and mn.mn = dn1.mn
and ap.ap = mn.ap
order by tt;$_$;


ALTER FUNCTION public.traps(integer, integer, OUT ap integer, OUT tt text) OWNER TO pool;

--
-- Name: FUNCTION traps(integer, integer, OUT ap integer, OUT tt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION traps(integer, integer, OUT ap integer, OUT tt text) IS 'In: ex of 2 expressions. Out: ap and tt of each approver of at least 1 meaning shared by the expressions.';


--
-- Name: trlv(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trlv(integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function trlv
--(integer, out lv integer, out lc character (3),
--out vc smallint, out tt text)
--returns setof record language sql as
select distinct lv.lv, lc, vc, lv.tt
from dn as dn1, dn as dn2, ex, lv
where dn1.ex = $1
and dn2.mn = dn1.mn
and dn2.ex != $1
and ex.ex = dn2.ex
and lv.lv = ex.lv
order by lc, vc$_$;


ALTER FUNCTION public.trlv(integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) OWNER TO pool;

--
-- Name: FUNCTION trlv(integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trlv(integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) IS 'In: ex of an expression. Out: lv, lc, vc, and tt of each variety of any translation or synonym of the expression (i.e. of any other expression of any denotation with any meaning of any denotation of the expression).';


--
-- Name: trmns(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trmns(integer, integer, integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$--create or replace function trmns
--(integer, integer, integer)
--returns setof integer language sql as
select mn.mn from dn as dn1, dn as dn2, mn
where dn1.ex = $1
and dn2.ex = $2
and dn2.mn = dn1.mn
and mn.mn = dn1.mn
and mn.ap = $3
order by mn;$_$;


ALTER FUNCTION public.trmns(integer, integer, integer) OWNER TO pool;

--
-- Name: FUNCTION trmns(integer, integer, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trmns(integer, integer, integer) IS 'In: ex of 2 expressions and ap of an approver. Out: mn of each meaning of the approver shared by the expressions.';


--
-- Name: trp2(text, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trp2(text, integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$--create or replace function trp2
--(text, integer)
--returns text language plpgsql as
declare
mnvar integer;
begin
-- Identify the meaning assigned to the
-- specified expression by PanLex.
select mn into mnvar from pl0
where tt = $1;
-- Return a result.
return trp2a (mnvar, $2);
end;$_$;


ALTER FUNCTION public.trp2(text, integer) OWNER TO pool;

--
-- Name: FUNCTION trp2(text, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trp2(text, integer) IS 'In: tt of a PanLex expression and lv of a variety. Out: text of the translation by PanLex of the expression into the variety or, if none, of the most-attested translation into the variety from the translations by PanLex of the expression, or blank string if none.';


--
-- Name: trp2(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trp2(integer, integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$--create or replace function trp2
--(integer, integer)
--returns text language plpgsql as
declare
mnvar integer;
begin
-- Identify the meaning assigned to the
-- specified expression by PanLex.
select mn into mnvar from pl0
where ex = $1;
-- Return a result.
return trp2a (mnvar, $2);
end;$_$;


ALTER FUNCTION public.trp2(integer, integer) OWNER TO pool;

--
-- Name: FUNCTION trp2(integer, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trp2(integer, integer) IS 'In: ex of a PanLex expression and lv of a variety. Out: text of the translation by PanLex of the expression into the variety or, if none, of the most-attested translation into the variety from the translations by PanLex of the expression, or blank string if none.';


--
-- Name: trp2a(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trp2a(integer, integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$--create or replace function trp2a
--(integer, integer)
--returns text language plpgsql as
declare
exvar integer;
trvar record;
ttvar text;
begin
-- If the specified meaning is undefined:
if $1 is null
then
---- Return a failure result.
return '';
end if;
-- Identify the expression in the specified
-- variety to which PanLex has assigned the
-- specified meaning.
select ex into exvar from pl1
where mn = $1
and lv = $2;
-- If it exists:
if exvar is not null
then
---- Identify its text.
select tt into ttvar from ex
where ex = exvar;
---- Return it.
return ttvar;
-- Otherwise, i.e. if it doesn’t exist:
else
---- Identify the most-attested translation
---- into the specified variety from the
---- expressions to which PanLex has assigned
---- the specified meaning. (Not using a
---- subquery multiplies the cost by about 10.)
select dn2.ex, count (dn2.dn) as dns into trvar
from pl1, dn as dn1, dn as dn2, (
select ex from ex
where lv = $2
) as subq
where pl1.mn = $1
and dn1.ex = pl1.ex
and dn2.mn = dn1.mn
and dn2.ex = subq.ex
group by dn2.ex
order by dns desc;
---- If it doesn’t exist:
if trvar.ex is null
then
------ Return a failure result.
return '';
end if;
---- Identify its text.
select tt into ttvar from ex
where ex = trvar.ex;
---- Return it.
return ttvar;
end if;
end;$_$;


ALTER FUNCTION public.trp2a(integer, integer) OWNER TO pool;

--
-- Name: FUNCTION trp2a(integer, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trp2a(integer, integer) IS 'In: mn of a meaning and lv of a variety. Out: tt of the expression in the variety to which PanLex has assigned the meaning, or, if none, of the most-attested translation into the variety of the expressions to which PanLex has assigned the meaning, or, if none, blank string.';


--
-- Name: trtrmns(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trtrmns(integer, integer, integer, OUT mn0 integer, OUT mn1 integer) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function trtrmns
--(integer, integer, integer,
--out mn0 integer, out mn1 integer)
--returns setof record language sql as
select dn1.mn, dn2.mn
from dn as dn1, dn as dn2, dn as dn3, dn as dn4
where dn1.ex = $1
and dn2.ex = $2
and dn3.ex = $3
and dn4.ex = $3
and dn2.mn != dn1.mn
and dn3.mn = dn1.mn
and dn4.mn = dn2.mn$_$;


ALTER FUNCTION public.trtrmns(integer, integer, integer, OUT mn0 integer, OUT mn1 integer) OWNER TO pool;

--
-- Name: FUNCTION trtrmns(integer, integer, integer, OUT mn0 integer, OUT mn1 integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trtrmns(integer, integer, integer, OUT mn0 integer, OUT mn1 integer) IS 'In: ex of 3 expressions. Out: each mn shared by expressions 0 and 2 and mn shared by expressions 1 and 2.';


--
-- Name: trtrmnxs(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trtrmnxs(integer, integer, integer, OUT mn0 integer, OUT ap0 integer, OUT tt0 text, OUT mn1 integer, OUT ap1 integer, OUT tt1 text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function trtrmnxs
--(integer, integer, integer,
--out mn0 integer, out ap0 integer, out tt0 text,
--out mn1 integer, out ap1 integer, out tt1 text)
--returns setof record language sql as
select mns.mn0, ap0.ap, ap0.tt, mns.mn1, ap1.ap, ap1.tt
from trtrmns ($1, $2, $3) as mns,
mn as mn0, mn as mn1, ap as ap0, ap as ap1
where mn0.mn = mns.mn0
and mn1.mn = mns.mn1
and ap0.ap = mn0.ap
and ap1.ap = mn1.ap
order by ap0.tt, ap1.tt;$_$;


ALTER FUNCTION public.trtrmnxs(integer, integer, integer, OUT mn0 integer, OUT ap0 integer, OUT tt0 text, OUT mn1 integer, OUT ap1 integer, OUT tt1 text) OWNER TO pool;

--
-- Name: FUNCTION trtrmnxs(integer, integer, integer, OUT mn0 integer, OUT ap0 integer, OUT tt0 text, OUT mn1 integer, OUT ap1 integer, OUT tt1 text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trtrmnxs(integer, integer, integer, OUT mn0 integer, OUT ap0 integer, OUT tt0 text, OUT mn1 integer, OUT ap1 integer, OUT tt1 text) IS 'In: ex of 3 expressions. Out: mn, ap, and ap tt of each meaning in a 2-stage translation path between expressions 0 and 1 via expression 2.';


--
-- Name: trtrms(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trtrms(integer, integer) RETURNS SETOF integer
    LANGUAGE sql
    AS $_$--create or replace function trtrms
--(integer, integer)
--returns setof integer language sql as
select distinct dn3.ex
from dn as dn1, dn as dn2, dn as dn3, dn as dn4
where dn1.ex = $1
and dn2.ex = $2
and dn2.mn != dn1.mn
and dn3.mn = dn1.mn
and dn4.mn = dn2.mn
and dn4.ex = dn3.ex
and dn3.ex != $1
and dn3.ex != $2;$_$;


ALTER FUNCTION public.trtrms(integer, integer) OWNER TO pool;

--
-- Name: FUNCTION trtrms(integer, integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trtrms(integer, integer) IS 'In: ex of 2 expressions. Out: ex of each expression other than the expressions that shares distinct meanings with the expressions.';


--
-- Name: trtrmxs(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trtrmxs(integer, integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function trtrmxs
--(integer, integer, out lv integer,
--out lc character (3), out vc smallint,
--out lvtt text, out ex integer, out extt text)
--returns setof record language sql as
select lv.lv, lc, vc, lv.tt as lvtt, ex.ex, ex.tt as extt
from (select * from trtrms ($1, $2)) as mex (ex),
ex, lv
where ex.ex = mex.ex
and lv.lv = ex.lv
order by lc, vc, extt;$_$;


ALTER FUNCTION public.trtrmxs(integer, integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) OWNER TO pool;

--
-- Name: FUNCTION trtrmxs(integer, integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trtrmxs(integer, integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) IS 'In: ex of 2 expressions. Out: lv, lc, vc, lv tt, ex, and ex tt of each expression other than the expressions that shares distinct meanings with the expressions.';


--
-- Name: trtrs(integer, integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION trtrs(integer, integer, OUT exid integer, OUT extt text) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function trtrs
--(integer, integer,
--out exid integer, out extt text)
--returns setof record language sql as
select ex.ex as exid, tt as extt
from (
  select distinct dn2.ex from (
    select distinct dn4.ex from dn as dn3, dn as dn4
    where dn3.ex = $1
    and dn4.mn = dn3.mn
    and dn4.ex != $1
  ) as trs, dn as dn1, dn as dn2
  where dn1.ex = trs.ex
  and dn2.mn = dn1.mn
  and dn2.ex != dn1.ex
) as trtrs, ex
where ex.ex = trtrs.ex
and lv = $2
order by tt;$_$;


ALTER FUNCTION public.trtrs(integer, integer, OUT exid integer, OUT extt text) OWNER TO pool;

--
-- Name: FUNCTION trtrs(integer, integer, OUT exid integer, OUT extt text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION trtrs(integer, integer, OUT exid integer, OUT extt text) IS 'In: ex of an expression and lv of a variety. Out: ex and tt of each translation into the variety of each translation of the expression.';


--
-- Name: usad(text, text, text, text, character); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION usad(text, text, text, text, character) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function usad
--(text, text, text, text, character (32))
--returns integer language plpgsql as
declare
usvar integer;
begin
-- If the alias is blank:
if (length ($2)) = 0
then
---- Report the reason and quit.
return -1;
end if;
-- If the alias is an existing user’s alias:
if (select count (us) from us where al = $2) > 0
then
---- Report the reason and quit.
return -2;
end if;
-- If the password is blank:
if (length ($5)) = 0
then
---- Report the reason and quit.
return -3;
end if;
-- Identify an available user ID.
usvar := (usid ());
-- Add the specified user.
insert into us (us, nm, al, sm, ht, pw)
values (usvar, $1, $2, $3, $4, $5);
-- Return the user's ID.
return usvar;
end;$_$;


ALTER FUNCTION public.usad(text, text, text, text, character) OWNER TO pool;

--
-- Name: FUNCTION usad(text, text, text, text, character); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION usad(text, text, text, text, character) IS 'In: nm, al, sm, ht, and pw of a new user. Act: Add the user. Out: -1 = no al, -2 = used al, -3 = no pw, other integer = us.';


--
-- Name: usid(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION usid() RETURNS integer
    LANGUAGE sql
    AS $$--create or replace function usid ()
--returns integer language sql as
select min (us) from (
(
select 1 as us
union
select us + 1 as us from us
)
except select us from us
) as avail;$$;


ALTER FUNCTION public.usid() OWNER TO pool;

--
-- Name: FUNCTION usid(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION usid() IS 'Out: smallest available user us.';


--
-- Name: uspw(integer, character); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION uspw(integer, character) RETURNS boolean
    LANGUAGE sql
    AS $_$--create or replace function uspwck
--(integer, character (32))
--returns boolean language sql as
select
(
$1 is not null
and $2 is not null
and (select pw from us where us = $1) = $2
and (select ok from us where us = $1)
)
;$_$;


ALTER FUNCTION public.uspw(integer, character) OWNER TO pool;

--
-- Name: FUNCTION uspw(integer, character); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION uspw(integer, character) IS 'In: us and pw of a user. Out: whether the password is the user''s.';


--
-- Name: wcad(integer, text); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION wcad(integer, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$--create or replace function wcad
--(integer, text)
--returns integer language plpgsql as
declare
dnvar integer;
exvar integer;
wcvar integer;
begin
-- Identify the specified word-class’s
-- PanLex expression.
select ex into exvar from wcex
where tt = $2;
-- If it doesn’t exist:
if exvar is null
then
---- Report the reason and quit.
return -1;
end if;
-- Identify the specified denotation.
select dn into dnvar from dn
where dn = $1;
-- If it doesn’t exist:
if dnvar is null
then
---- Report the reason and quit.
return -2;
end if;
-- Identify the word classification.
select wc into wcvar from wc
where dn = dnvar
and ex = exvar;
-- If it does not exist:
if wcvar is null
then
---- Identify the new one.
select * into wcvar from wcgt ();
---- Record it.
insert into wc values (wcvar, $1, exvar);
end if;
-- Return the word classification.
return wcvar;
end;$_$;


ALTER FUNCTION public.wcad(integer, text) OWNER TO pool;

--
-- Name: FUNCTION wcad(integer, text); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION wcad(integer, text) IS 'In: dn and tt of ex of a word classification. Act: Add the word classification. Out: -1 = no tt, -2 = no dn, other integer = wc.';


--
-- Name: wcgt(); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION wcgt() RETURNS integer
    LANGUAGE plpgsql
    AS $$--create or replace function wcgt ()
--returns integer language plpgsql as
declare
wcvar integer;
nwcvar integer;
begin
-- Identify the smallest available word
-- classification ID.
select min (wc) into wcvar from wcid;
-- Make it unavailable.
delete from wcid
where wc = wcvar;
-- Identify another missing word class.
select wc into nwcvar from wcid;
-- If there is none:
if nwcvar is null
then
---- Record the next word classification as
---- available.
---- Precondition: The word classification with
---- an ID 1 larger than the largest ID of any
---- word classification is recorded as available.
insert into wcid values (wcvar + 1);
end if;
-- Return the available word classification.
return wcvar;
end;$$;


ALTER FUNCTION public.wcgt() OWNER TO pool;

--
-- Name: FUNCTION wcgt(); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION wcgt() IS 'Act: Revise the list of available word class IDs. Out: the next available word class ID.';


--
-- Name: wcrm(integer); Type: FUNCTION; Schema: public; Owner: pool
--

CREATE FUNCTION wcrm(integer) RETURNS void
    LANGUAGE sql
    AS $_$--create or replace function wcrm
--(integer) returns void language sql as
insert into wcid
select wc from wc
where wc = $1;
delete from wc
where wc = $1;$_$;


ALTER FUNCTION public.wcrm(integer) OWNER TO pool;

--
-- Name: FUNCTION wcrm(integer); Type: COMMENT; Schema: public; Owner: pool
--

COMMENT ON FUNCTION wcrm(integer) IS 'In: wc of a word classification. Act: Delete the word classification, recording its ID as available.';


SET search_path = util, pg_catalog;

--
-- Name: fndoc(name); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION fndoc(name, OUT io "char"[], OUT argns text[], OUT argts oid[]) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create function fndoc
--(name, out io character[], out argns text[], out argts oid[])
--returns setof record language sql as
select proargmodes, proargnames, proallargtypes
from pg_proc
where proname = $1;$_$;


ALTER FUNCTION util.fndoc(name, OUT io "char"[], OUT argns text[], OUT argts oid[]) OWNER TO pool;

--
-- Name: fndoc(text); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION fndoc(text, OUT io "char"[], OUT argns text[], OUT argts oid[]) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create function fndoc
--(name, out io character[], out argns text[], out argts oid[])
--returns setof record language sql as
select proargmodes, proargnames, proallargtypes
from pg_proc
where proname = $1;$_$;


ALTER FUNCTION util.fndoc(text, OUT io "char"[], OUT argns text[], OUT argts oid[]) OWNER TO pool;

--
-- Name: hml(text); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION hml(text) RETURNS text
    LANGUAGE sql
    AS $_$--create or replace function hml (text)
--returns text language sql as
select (
case
when $1 is null then ''
when $1 = '' then ''
else (
replace ((
replace ((
replace ((
replace ($1, '&', '&amp;')
), '"', '&quot;')
), '<', '&lt;')
), '>', '&gt;')
)
end
);$_$;


ALTER FUNCTION util.hml(text) OWNER TO pool;

--
-- Name: FUNCTION hml(text); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION hml(text) IS 'In: a text value. Out: The text value made tag-safe.';


--
-- Name: mncts(integer); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function mncts
--(integer, out mn integer, out dns integer)
--returns setof record language sql as
select dn.ap, dn.mn, (count (ex))::integer as dns
from dn,
(select distinct ap, mn from dn where ex = $1) as mns
where dn.ap = mns.ap
and dn.mn = mns.mn
group by dn.ap, dn.mn
order by dns desc, dn.mn;$_$;


ALTER FUNCTION util.mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer) OWNER TO pool;

--
-- Name: FUNCTION mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer) IS 'In: ex of an expression. Out: each ap and mn of any denotation with the expression and count of all their denotations, in descending order of the count and ascending order of mn.';


--
-- Name: simdn(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simdn() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simdn ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simdn.
copy (select timeofday () || ': Starting simdn')
to '/var/local/panlex/simprep3';
truncate simdn;
insert into simdn
select dn.ex, mn from simex, dn
where dn.ex = simex.ex
order by mn;
truncate simex;
analyze simdn;$$;


ALTER FUNCTION util.simdn() OWNER TO pool;

--
-- Name: FUNCTION simdn(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simdn() IS 'Act: Populate interim.simdn.';


--
-- Name: simdns(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simdns() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simdns ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simdns.
truncate simdns;
insert into simdns
select simdn.ex, count (mn) as dns
from (
select ex1 as ex from simpt
union select ex2 as ex from simpt
) as tbl, simdn
where simdn.ex = tbl.ex
group by simdn.ex
order by simdn.ex;
truncate simdn;
analyze simdns;$$;


ALTER FUNCTION util.simdns() OWNER TO pool;

--
-- Name: FUNCTION simdns(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simdns() IS 'Act: Populate interim.simdns.';


--
-- Name: simeq(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simeq() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simeq ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simeq.
truncate simeq;
insert into simeq
select count (ext) as trs, dn1.dns as dns1,
ex1, dn2.dns as dns2, ex2
from simpt, simdns as dn1, simdns as dn2
where dn1.ex = simpt.ex1
and dn2.ex = simpt.ex2
group by dn1.dns, ex1, dn2.dns, ex2
order by trs desc, dn1.dns, dn2.dns;
truncate simpt;
truncate simdns;
analyze simeq;$$;


ALTER FUNCTION util.simeq() OWNER TO pool;

--
-- Name: FUNCTION simeq(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simeq() IS 'Act: Populate interim.simeq.';


--
-- Name: simex(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simex() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simex ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simex.
truncate simex;
insert into simex
select ex, ex.lv, tt, ex.td from ex, simtd
where ex.lv = simtd.lv
and ex.td = simtd.td
order by ex;
truncate simtd;
analyze simex;$$;


ALTER FUNCTION util.simex() OWNER TO pool;

--
-- Name: FUNCTION simex(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simex() IS 'Act: Populate interim.simex.';


--
-- Name: simpair(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simpair() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simpair ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simpair.
truncate simpair;
insert into simpair
select ex1.ex as ex1, ex2.ex as ex2
from simex as ex1, simex as ex2
where ex2.lv = ex1.lv
and ex2.td = ex1.td
and ex2.ex > ex1.ex
order by ex1, ex2;
analyze simpair;$$;


ALTER FUNCTION util.simpair() OWNER TO pool;

--
-- Name: FUNCTION simpair(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simpair() IS 'Act: Populate interim.simpair.';


--
-- Name: simpairs(integer); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simpairs(integer, OUT ex1 integer, OUT ex2 integer) RETURNS SETOF record
    LANGUAGE sql
    AS $_$--create or replace function util.simpairs
--(integer, out ex1 integer, out ex2 integer)
--returns setof record language sql as
select ex1.ex as ex1, ex2.ex as ex2
from ex as ex1, ex as ex2
where ex1.lv = $1
and ex2.lv = $1
and ex2.td = ex1.td
and ex2.tt != ex1.tt
and ex2.ex > ex1.ex
order by ex1, ex2;$_$;


ALTER FUNCTION util.simpairs(integer, OUT ex1 integer, OUT ex2 integer) OWNER TO pool;

--
-- Name: FUNCTION simpairs(integer, OUT ex1 integer, OUT ex2 integer); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simpairs(integer, OUT ex1 integer, OUT ex2 integer) IS 'In: lv of a variety. Out: ex of each pair of expressions in the variety whose td are identical and whose tt are not.';


--
-- Name: simprep(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simprep() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simprep ()
--returns void language sql as
-- Populate simtd.
copy (select timeofday () || ': Starting simtd')
to '/var/local/panlex/simprep0';
select * from simtd ();
-- Populate simex.
copy (select timeofday () || ': Starting simex')
to '/var/local/panlex/simprep1';
select * from simex ();
-- Populate simpair.
copy (select timeofday () || ': Starting simpair')
to '/var/local/panlex/simprep2';
select * from simpair ();
-- Populate simdn.
copy (select timeofday () || ': Starting simdn')
to '/var/local/panlex/simprep3';
select * from simdn ();
-- Populate simtr.
copy (select timeofday () || ': Starting simtr')
to '/var/local/panlex/simprep4';
select * from simtr ();
-- Populate simpt.
copy (select timeofday () || ': Starting simpt')
to '/var/local/panlex/simprep5';
select * from simpt ();
-- Populate simdns.
copy (select timeofday () || ': Starting simdns')
to '/var/local/panlex/simprep6';
select * from simdns ();
-- Populate simeq.
copy (select timeofday () || ': Starting simeq')
to '/var/local/panlex/simprep7';
select * from simeq ();$$;


ALTER FUNCTION util.simprep() OWNER TO pool;

--
-- Name: FUNCTION simprep(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simprep() IS 'Act: Populate interim.sim* tables (except simlv) for use by interim.simsee.';


--
-- Name: simpt(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simpt() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simpt ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simpt.
truncate simpt;
insert into simpt
select distinct ex1, ex2, tr2.ext
from simpair, simtr as tr1, simtr as tr2
where tr1.exs = ex1
and tr2.exs = ex2
and tr2.ext = tr1.ext
order by ex1, ex2, tr2.ext;
truncate simpair;
truncate simtr;
analyze simpt;$$;


ALTER FUNCTION util.simpt() OWNER TO pool;

--
-- Name: FUNCTION simpt(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simpt() IS 'Act: Populate interim.simpt.';


--
-- Name: simtd(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simtd() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simtd ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simtd.
truncate simtd;
insert into simtd
select ex.lv, td, count (ex) as exs
from simlv, ex
where ex.lv = simlv.lv
group by ex.lv, td
order by td;
delete from simtd
where exs = 1;
analyze simtd;$$;


ALTER FUNCTION util.simtd() OWNER TO pool;

--
-- Name: FUNCTION simtd(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simtd() IS 'Act: Populate interim.simtd.';


--
-- Name: simtr(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION simtr() RETURNS void
    LANGUAGE sql
    AS $$--create or replace function util.simtr ()
--returns void language sql as
set search_path to public, util, interim;
-- Populate simtr.
truncate simtr;
insert into simtr
select distinct simdn.ex as exs, dn.ex as ext
from simdn, dn
where dn.mn = simdn.mn
and dn.ex != simdn.ex
order by exs, ext;
analyze simtr;$$;


ALTER FUNCTION util.simtr() OWNER TO pool;

--
-- Name: FUNCTION simtr(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION simtr() IS 'Act: Populate interim.simtr.';


--
-- Name: trct0(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION trct0() RETURNS integer
    LANGUAGE sql
    AS $$--create or replace function util.trct0 ()
--returns integer language sql as
select cast (count (ex1) as integer) from (
select distinct dn1.ex as ex1, dn2.ex as ex2
from dn as dn1, dn as dn2
where dn2.mn = dn1.mn
and dn1.ex < dn2.ex
) as tbl;$$;


ALTER FUNCTION util.trct0() OWNER TO pool;

--
-- Name: FUNCTION trct0(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION trct0() IS 'Out: count of distinct pairs of expressions sharing at least 1 meaning.';


--
-- Name: trct1(); Type: FUNCTION; Schema: util; Owner: pool
--

CREATE FUNCTION trct1() RETURNS integer
    LANGUAGE sql
    AS $$--create or replace function util.trct ()
--returns integer language sql as
select
cast (sum (mns * dns * (dns - 1) * 0.5) as integer)
from (
select dns, count (mn) as mns from (
select mn, count (dn) as dns from dn
group by mn
) as ct0
group by dns
) as ct1;$$;


ALTER FUNCTION util.trct1() OWNER TO pool;

--
-- Name: FUNCTION trct1(); Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON FUNCTION trct1() IS 'Out: count of instances of a pair of expressions sharing a meaning.';


SET search_path = import, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: df0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE df0 (
    se integer,
    mn integer,
    lv integer,
    tt text
);


ALTER TABLE import.df0 OWNER TO apache;

--
-- Name: TABLE df0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE df0 IS 'imported definitions';


--
-- Name: COLUMN df0.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df0.se IS 'sequential ID';


--
-- Name: COLUMN df0.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df0.mn IS 'meaning';


--
-- Name: COLUMN df0.lv; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df0.lv IS 'variety';


--
-- Name: COLUMN df0.tt; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df0.tt IS 'text';


--
-- Name: df1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE df1 (
    id integer,
    mn integer,
    lv integer,
    tt text
);


ALTER TABLE import.df1 OWNER TO apache;

--
-- Name: TABLE df1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE df1 IS 'installable definitions';


--
-- Name: COLUMN df1.id; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df1.id IS 'assigned ID';


--
-- Name: COLUMN df1.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df1.mn IS 'meaning';


--
-- Name: COLUMN df1.lv; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df1.lv IS 'variety';


--
-- Name: COLUMN df1.tt; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN df1.tt IS 'text';


--
-- Name: dm0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE dm0 (
    se integer,
    mn integer,
    ex integer
);


ALTER TABLE import.dm0 OWNER TO apache;

--
-- Name: TABLE dm0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE dm0 IS 'imported domains';


--
-- Name: COLUMN dm0.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dm0.se IS 'sequential ID';


--
-- Name: COLUMN dm0.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dm0.mn IS 'meaning';


--
-- Name: COLUMN dm0.ex; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dm0.ex IS 'expression';


--
-- Name: dm1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE dm1 (
    id integer,
    mn integer,
    ex integer
);


ALTER TABLE import.dm1 OWNER TO apache;

--
-- Name: TABLE dm1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE dm1 IS 'installable domains';


--
-- Name: COLUMN dm1.id; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dm1.id IS 'assigned ID';


--
-- Name: COLUMN dm1.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dm1.mn IS 'meaning';


--
-- Name: COLUMN dm1.ex; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dm1.ex IS 'expression';


--
-- Name: dn0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE dn0 (
    se integer,
    mn integer,
    ex integer
);


ALTER TABLE import.dn0 OWNER TO apache;

--
-- Name: TABLE dn0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE dn0 IS 'imported denotations';


--
-- Name: COLUMN dn0.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dn0.se IS 'sequential ID';


--
-- Name: COLUMN dn0.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dn0.mn IS 'meaning’s sequential ID';


--
-- Name: COLUMN dn0.ex; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dn0.ex IS 'expression’s sequential ID';


--
-- Name: dn1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE dn1 (
    se integer,
    id integer,
    mn integer,
    ex integer
);


ALTER TABLE import.dn1 OWNER TO apache;

--
-- Name: TABLE dn1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE dn1 IS 'installable denotations';


--
-- Name: COLUMN dn1.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dn1.se IS 'sequential ID';


--
-- Name: COLUMN dn1.id; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dn1.id IS 'assigned ID';


--
-- Name: COLUMN dn1.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dn1.mn IS 'meaning';


--
-- Name: COLUMN dn1.ex; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN dn1.ex IS 'expression';


--
-- Name: ex0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE ex0 (
    se integer,
    lv integer,
    tt text
);


ALTER TABLE import.ex0 OWNER TO apache;

--
-- Name: TABLE ex0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE ex0 IS 'imported expressions';


--
-- Name: COLUMN ex0.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN ex0.se IS 'sequential ID';


--
-- Name: COLUMN ex0.lv; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN ex0.lv IS 'variety';


--
-- Name: COLUMN ex0.tt; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN ex0.tt IS 'text';


--
-- Name: ex1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE ex1 (
    se integer,
    id integer,
    lv integer,
    tt text
);


ALTER TABLE import.ex1 OWNER TO apache;

--
-- Name: TABLE ex1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE ex1 IS 'installable expressions';


--
-- Name: COLUMN ex1.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN ex1.se IS 'sequential ID';


--
-- Name: COLUMN ex1.id; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN ex1.id IS 'assigned ID';


--
-- Name: COLUMN ex1.lv; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN ex1.lv IS 'variety, or null if the expression is not new';


--
-- Name: COLUMN ex1.tt; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN ex1.tt IS 'text, or null if the expression is not new';


--
-- Name: mapid; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE mapid (
    ts integer,
    id integer
);


ALTER TABLE import.mapid OWNER TO apache;

--
-- Name: TABLE mapid; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE mapid IS 'IDs to be assigned to imported items';


--
-- Name: mapse; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE mapse (
    ts integer,
    se integer
);


ALTER TABLE import.mapse OWNER TO apache;

--
-- Name: TABLE mapse; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE mapse IS 'sequential IDs of imported items';


--
-- Name: md0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE md0 (
    se integer,
    dn integer,
    vb text,
    vl text
);


ALTER TABLE import.md0 OWNER TO apache;

--
-- Name: TABLE md0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE md0 IS 'imported metadata';


--
-- Name: COLUMN md0.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md0.se IS 'sequential ID';


--
-- Name: COLUMN md0.dn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md0.dn IS 'denotation’s sequential ID';


--
-- Name: COLUMN md0.vb; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md0.vb IS 'variable';


--
-- Name: COLUMN md0.vl; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md0.vl IS 'value';


--
-- Name: md1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE md1 (
    id integer,
    dn integer,
    vb text,
    vl text
);


ALTER TABLE import.md1 OWNER TO apache;

--
-- Name: TABLE md1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE md1 IS 'installable metadata';


--
-- Name: COLUMN md1.id; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md1.id IS 'assigned ID';


--
-- Name: COLUMN md1.dn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md1.dn IS 'denotation';


--
-- Name: COLUMN md1.vb; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md1.vb IS 'variable';


--
-- Name: COLUMN md1.vl; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN md1.vl IS 'value';


--
-- Name: mi0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE mi0 (
    mn integer,
    tt text
);


ALTER TABLE import.mi0 OWNER TO apache;

--
-- Name: TABLE mi0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE mi0 IS 'imported meaning identifiers';


--
-- Name: COLUMN mi0.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN mi0.mn IS 'meaning’s sequential ID';


--
-- Name: COLUMN mi0.tt; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN mi0.tt IS 'text';


--
-- Name: mi1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE mi1 (
    mn integer,
    tt text
);


ALTER TABLE import.mi1 OWNER TO apache;

--
-- Name: TABLE mi1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE mi1 IS 'installable meaning identifiers';


--
-- Name: COLUMN mi1.mn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN mi1.mn IS 'meaning';


--
-- Name: COLUMN mi1.tt; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN mi1.tt IS 'text';


--
-- Name: mn0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE mn0 (
    se integer
);


ALTER TABLE import.mn0 OWNER TO apache;

--
-- Name: TABLE mn0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE mn0 IS 'imported meanings';


--
-- Name: COLUMN mn0.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN mn0.se IS 'sequential ID';


--
-- Name: mn1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE mn1 (
    se integer,
    id integer
);


ALTER TABLE import.mn1 OWNER TO apache;

--
-- Name: TABLE mn1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE mn1 IS 'installable meanings';


--
-- Name: COLUMN mn1.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN mn1.se IS 'sequential ID';


--
-- Name: COLUMN mn1.id; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN mn1.id IS 'assigned ID';


--
-- Name: seq; Type: SEQUENCE; Schema: import; Owner: apache
--

CREATE SEQUENCE seq
    START WITH 0
    INCREMENT BY 1
    MINVALUE 0
    NO MAXVALUE
    CACHE 1000;


ALTER TABLE import.seq OWNER TO apache;

--
-- Name: SEQUENCE seq; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON SEQUENCE seq IS 'sequence generator for IDs';


--
-- Name: wc0; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE wc0 (
    se integer,
    dn integer,
    ex integer
);


ALTER TABLE import.wc0 OWNER TO apache;

--
-- Name: TABLE wc0; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE wc0 IS 'imported word classifications';


--
-- Name: COLUMN wc0.se; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN wc0.se IS 'sequential ID';


--
-- Name: COLUMN wc0.dn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN wc0.dn IS 'denotation’s sequential ID';


--
-- Name: COLUMN wc0.ex; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN wc0.ex IS 'word class’s PanLex expression';


--
-- Name: wc1; Type: TABLE; Schema: import; Owner: apache; Tablespace: 
--

CREATE TABLE wc1 (
    id integer,
    dn integer,
    ex integer
);


ALTER TABLE import.wc1 OWNER TO apache;

--
-- Name: TABLE wc1; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON TABLE wc1 IS 'installable word classifications';


--
-- Name: COLUMN wc1.id; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN wc1.id IS 'assigned ID';


--
-- Name: COLUMN wc1.dn; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN wc1.dn IS 'denotation';


--
-- Name: COLUMN wc1.ex; Type: COMMENT; Schema: import; Owner: apache
--

COMMENT ON COLUMN wc1.ex IS 'word class’s PanLex expression';


SET search_path = interim, pg_catalog;

--
-- Name: agrodn; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE agrodn (
    dn integer NOT NULL,
    mn integer,
    ex integer,
    norm boolean
);


ALTER TABLE interim.agrodn OWNER TO pool;

--
-- Name: agroex; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE agroex (
    ex integer NOT NULL,
    lv integer,
    tt text,
    td text
);


ALTER TABLE interim.agroex OWNER TO pool;

--
-- Name: agrokill; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE agrokill (
    dn integer
);


ALTER TABLE interim.agrokill OWNER TO pool;

--
-- Name: agrokillx; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE agrokillx (
    dn integer,
    ex integer,
    lv integer,
    lc character(3),
    vc smallint,
    tt text,
    lone boolean
);


ALTER TABLE interim.agrokillx OWNER TO pool;

--
-- Name: auto; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE auto (
    ap integer NOT NULL,
    sel boolean,
    tsus integer,
    tsok boolean,
    rdm integer
);


ALTER TABLE interim.auto OWNER TO apache;

--
-- Name: TABLE auto; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE auto IS 'approver statuses in 2010 automation study';


--
-- Name: COLUMN auto.ap; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN auto.ap IS 'approver without data in the database';


--
-- Name: COLUMN auto.sel; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN auto.sel IS 'whether the approver has been selected for the automation study';


--
-- Name: COLUMN auto.tsus; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN auto.tsus IS 'user responsible for the creation of training data';


--
-- Name: COLUMN auto.tsok; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN auto.tsok IS 'whether the training data have been created';


--
-- Name: COLUMN auto.rdm; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN auto.rdm IS 'random sampler: smallest-first';


SET search_path = public, pg_catalog;

--
-- Name: af; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE af (
    ap integer NOT NULL,
    fm smallint NOT NULL
);


ALTER TABLE public.af OWNER TO apache;

--
-- Name: TABLE af; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE af IS 'approvers’ source-file formats';


--
-- Name: COLUMN af.ap; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN af.ap IS 'approver';


--
-- Name: COLUMN af.fm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN af.fm IS 'format';


--
-- Name: ap; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE ap (
    ap integer NOT NULL,
    dt date DEFAULT ('now'::text)::date NOT NULL,
    tt text NOT NULL,
    ur text,
    bn text,
    au text,
    ti text,
    pb text,
    yr smallint,
    uq smallint,
    ui smallint,
    ul text,
    li character(2),
    ip text,
    co text,
    ad text,
    fp text
);


ALTER TABLE public.ap OWNER TO apache;

--
-- Name: TABLE ap; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE ap IS 'approvers';


--
-- Name: COLUMN ap.ap; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.ap IS 'ID';


--
-- Name: COLUMN ap.dt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.dt IS 'registration date';


--
-- Name: COLUMN ap.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.tt IS 'label';


--
-- Name: COLUMN ap.ur; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.ur IS 'URI';


--
-- Name: COLUMN ap.bn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.bn IS 'ISBN';


--
-- Name: COLUMN ap.au; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.au IS 'author';


--
-- Name: COLUMN ap.ti; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.ti IS 'title';


--
-- Name: COLUMN ap.pb; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.pb IS 'monograph publisher or serial title, volume, and page range';


--
-- Name: COLUMN ap.yr; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.yr IS 'year of publication';


--
-- Name: COLUMN ap.uq; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.uq IS 'quality measure specified by the user';


--
-- Name: COLUMN ap.ui; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.ui IS 'numeric ID specified by the user';


--
-- Name: COLUMN ap.ul; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.ul IS 'miscellaneous information';


--
-- Name: COLUMN ap.li; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.li IS 'type of offered license';


--
-- Name: COLUMN ap.ip; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.ip IS 'summary of intellectual-property claim';


--
-- Name: COLUMN ap.co; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.co IS 'name of apparent intellectual-property claimant';


--
-- Name: COLUMN ap.ad; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.ad IS 'SMTP address for licensing correspondence';


--
-- Name: COLUMN ap.fp; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ap.fp IS 'source file or directory path';


SET search_path = interim, pg_catalog;

--
-- Name: autox; Type: VIEW; Schema: interim; Owner: pool
--

CREATE VIEW autox AS
    SELECT af.fm, auto.sel, auto.tsus, auto.tsok, auto.rdm, ap.ap, ap.tt FROM public.ap, auto, public.af WHERE (((ap.ap = auto.ap) AND (af.ap = auto.ap)) AND (((af.fm = 10) OR (af.fm = 17)) OR (af.fm = 24))) ORDER BY auto.rdm;


ALTER TABLE interim.autox OWNER TO pool;

--
-- Name: VIEW autox; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON VIEW autox IS 'approvers to be processed';


--
-- Name: COLUMN autox.fm; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN autox.fm IS 'format';


--
-- Name: COLUMN autox.sel; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN autox.sel IS 'whether the approver has been selected for training set creation';


--
-- Name: COLUMN autox.tsus; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN autox.tsus IS 'user assigned training set creation';


--
-- Name: COLUMN autox.tsok; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN autox.tsok IS 'whether the training set has been created';


--
-- Name: COLUMN autox.rdm; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN autox.rdm IS 'random integer';


--
-- Name: COLUMN autox.ap; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN autox.ap IS 'approver ID';


--
-- Name: COLUMN autox.tt; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN autox.tt IS 'approver label';


--
-- Name: chcg; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE chcg (
    lv integer NOT NULL,
    ap integer NOT NULL,
    cpold0 character(5) NOT NULL,
    cpold1 character(5),
    cpnew0 character(5) NOT NULL,
    cpnew1 character(5)
);


ALTER TABLE interim.chcg OWNER TO apache;

--
-- Name: TABLE chcg; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE chcg IS 'required corrections to expression characters';


--
-- Name: COLUMN chcg.lv; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN chcg.lv IS 'variety';


--
-- Name: COLUMN chcg.ap; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN chcg.ap IS 'approver';


--
-- Name: COLUMN chcg.cpold0; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN chcg.cpold0 IS 'first old character';


--
-- Name: COLUMN chcg.cpold1; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN chcg.cpold1 IS 'second old character, if any';


--
-- Name: COLUMN chcg.cpnew0; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN chcg.cpnew0 IS 'first new character';


--
-- Name: COLUMN chcg.cpnew1; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN chcg.cpnew1 IS 'second new character, if any';


--
-- Name: cmn; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE cmn (
    wc text NOT NULL,
    han text NOT NULL,
    py text NOT NULL,
    hanex integer,
    pyex integer
);


ALTER TABLE interim.cmn OWNER TO pool;

--
-- Name: TABLE cmn; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON TABLE cmn IS 'CJKI-provided Chinese lemmata solely for experimentation and not for inclusion in database';


--
-- Name: COLUMN cmn.wc; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN cmn.wc IS 'word classification';


--
-- Name: COLUMN cmn.han; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN cmn.han IS 'lemma encoded in hanzi';


--
-- Name: COLUMN cmn.py; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN cmn.py IS 'lemma encoded in pinyin';


--
-- Name: COLUMN cmn.hanex; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN cmn.hanex IS 'ID of the cmn-000 expression with the hanzi text';


--
-- Name: COLUMN cmn.pyex; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN cmn.pyex IS 'ID of the cmn-000 expression with the pinyin text';


--
-- Name: encoding; Type: VIEW; Schema: interim; Owner: pool
--

CREATE VIEW encoding AS
    SELECT ap.tt, ap.fp, "substring"(ap.ul, 1, 70) AS "substring" FROM public.ap WHERE ((ap.ul ~~ '%ncod%'::text) OR (ap.ul ~~ '%ecoding%'::text)) ORDER BY ap.tt;


ALTER TABLE interim.encoding OWNER TO pool;

SET search_path = public, pg_catalog;

--
-- Name: dn; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE dn (
    dn integer NOT NULL,
    mn integer NOT NULL,
    ex integer NOT NULL
);


ALTER TABLE public.dn OWNER TO apache;

--
-- Name: TABLE dn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE dn IS 'denotations';


--
-- Name: COLUMN dn.dn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dn.dn IS 'ID';


--
-- Name: COLUMN dn.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dn.mn IS 'meaning';


--
-- Name: COLUMN dn.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dn.ex IS 'expression';


--
-- Name: ex; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE ex (
    ex integer NOT NULL,
    lv integer NOT NULL,
    tt text NOT NULL,
    td text NOT NULL
);


ALTER TABLE public.ex OWNER TO apache;

--
-- Name: TABLE ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE ex IS 'expressions';


--
-- Name: COLUMN ex.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ex.ex IS 'ID';


--
-- Name: COLUMN ex.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ex.lv IS 'variety';


--
-- Name: COLUMN ex.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ex.tt IS 'text';


--
-- Name: COLUMN ex.td; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN ex.td IS 'degraded text';


SET search_path = interim, pg_catalog;

--
-- Name: engexv; Type: VIEW; Schema: interim; Owner: pool
--

CREATE VIEW engexv AS
    SELECT dn.ex, count(dn.dn) AS dns, ex.tt, lower(ex.tt) AS ttl FROM public.ex, public.dn WHERE ((ex.lv = 187) AND (dn.ex = ex.ex)) GROUP BY dn.ex, ex.tt, lower(ex.tt) ORDER BY dn.ex;


ALTER TABLE interim.engexv OWNER TO pool;

--
-- Name: VIEW engexv; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON VIEW engexv IS 'generator for content of table engex';


--
-- Name: simdn; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE simdn (
    ex integer NOT NULL,
    mn integer NOT NULL
);


ALTER TABLE interim.simdn OWNER TO pool;

--
-- Name: TABLE simdn; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON TABLE simdn IS 'meanings of simex expressions';


--
-- Name: COLUMN simdn.ex; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN simdn.ex IS 'expression ID';


--
-- Name: COLUMN simdn.mn; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN simdn.mn IS 'meaning';


--
-- Name: simdns; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simdns (
    ex integer NOT NULL,
    dns integer NOT NULL
);


ALTER TABLE interim.simdns OWNER TO apache;

--
-- Name: TABLE simdns; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simdns IS 'counts of denotations of simpt expressions';


--
-- Name: COLUMN simdns.ex; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simdns.ex IS 'expression ID';


--
-- Name: COLUMN simdns.dns; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simdns.dns IS 'denotation count';


--
-- Name: simeq; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simeq (
    trs integer NOT NULL,
    dns1 integer NOT NULL,
    ex1 integer NOT NULL,
    dns2 integer NOT NULL,
    ex2 integer NOT NULL
);


ALTER TABLE interim.simeq OWNER TO apache;

--
-- Name: TABLE simeq; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simeq IS 'counts of denotations with and translations shared by simpair expressions';


--
-- Name: COLUMN simeq.trs; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simeq.trs IS 'count of expressions that are translations of both';


--
-- Name: COLUMN simeq.dns1; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simeq.dns1 IS 'denotations with expression ex1';


--
-- Name: COLUMN simeq.ex1; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simeq.ex1 IS 'smaller ID';


--
-- Name: COLUMN simeq.dns2; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simeq.dns2 IS 'denotations with expression ex2';


--
-- Name: COLUMN simeq.ex2; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simeq.ex2 IS 'larger ID';


--
-- Name: simex; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simex (
    ex integer NOT NULL,
    lv integer NOT NULL,
    tt text NOT NULL,
    td text NOT NULL
);


ALTER TABLE interim.simex OWNER TO apache;

--
-- Name: TABLE simex; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simex IS 'simtd expressions';


--
-- Name: COLUMN simex.ex; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simex.ex IS 'expression ID';


--
-- Name: COLUMN simex.lv; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simex.lv IS 'variety';


--
-- Name: COLUMN simex.tt; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simex.tt IS 'text';


--
-- Name: COLUMN simex.td; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simex.td IS 'degraded text';


--
-- Name: simlv; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simlv (
    lv integer NOT NULL
);


ALTER TABLE interim.simlv OWNER TO apache;

--
-- Name: TABLE simlv; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simlv IS 'varieties selected to be similar-expression-normalization-eligible';


--
-- Name: COLUMN simlv.lv; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simlv.lv IS 'variety ID';


--
-- Name: simpair; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simpair (
    ex1 integer NOT NULL,
    ex2 integer NOT NULL
);


ALTER TABLE interim.simpair OWNER TO apache;

--
-- Name: TABLE simpair; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simpair IS 'pairs of simex expressions sharing varieties and degraded texts';


--
-- Name: COLUMN simpair.ex1; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simpair.ex1 IS 'smaller ex';


--
-- Name: COLUMN simpair.ex2; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simpair.ex2 IS 'larger ex';


--
-- Name: simpt; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simpt (
    ex1 integer NOT NULL,
    ex2 integer NOT NULL,
    ext integer NOT NULL
);


ALTER TABLE interim.simpt OWNER TO apache;

--
-- Name: TABLE simpt; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simpt IS 'shared translations of simpair pairs';


--
-- Name: COLUMN simpt.ex1; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simpt.ex1 IS 'pair’s smaller ID';


--
-- Name: COLUMN simpt.ex2; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simpt.ex2 IS 'pair’s larger ID';


--
-- Name: COLUMN simpt.ext; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simpt.ext IS 'shared translation';


--
-- Name: simsee; Type: VIEW; Schema: interim; Owner: pool
--

CREATE VIEW simsee AS
    SELECT simeq.trs, simeq.dns1, simeq.ex1, ex1.tt AS tt1, simeq.dns2, simeq.ex2, ex2.tt AS tt2 FROM simeq, public.ex ex1, public.ex ex2 WHERE ((ex1.ex = simeq.ex1) AND (ex2.ex = simeq.ex2)) ORDER BY simeq.trs DESC, ex1.tt, ex2.tt;


ALTER TABLE interim.simsee OWNER TO pool;

--
-- Name: VIEW simsee; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON VIEW simsee IS 'report on simeq pairs prioritized for normalization';


--
-- Name: simtd; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simtd (
    lv integer NOT NULL,
    td text NOT NULL,
    exs integer NOT NULL
);


ALTER TABLE interim.simtd OWNER TO apache;

--
-- Name: TABLE simtd; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simtd IS 'simlv varieties and degraded texts with 2+ expressions and their counts';


--
-- Name: COLUMN simtd.lv; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simtd.lv IS 'variety';


--
-- Name: COLUMN simtd.td; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simtd.td IS 'degraded text';


--
-- Name: COLUMN simtd.exs; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simtd.exs IS 'count of expressions in the variety with the degraded text';


--
-- Name: simtr; Type: TABLE; Schema: interim; Owner: apache; Tablespace: 
--

CREATE TABLE simtr (
    exs integer NOT NULL,
    ext integer NOT NULL
);


ALTER TABLE interim.simtr OWNER TO apache;

--
-- Name: TABLE simtr; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON TABLE simtr IS 'translations of simex expressions';


--
-- Name: COLUMN simtr.exs; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simtr.exs IS 'source expression ID';


--
-- Name: COLUMN simtr.ext; Type: COMMENT; Schema: interim; Owner: apache
--

COMMENT ON COLUMN simtr.ext IS 'target expression ID';


--
-- Name: ui; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE ui (
    ui smallint NOT NULL,
    tt text NOT NULL
);


ALTER TABLE interim.ui OWNER TO pool;

--
-- Name: TABLE ui; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON TABLE ui IS 'values of ap.ui during 2010 harvesting of approver data';


--
-- Name: COLUMN ui.ui; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN ui.ui IS 'value of ap.ui';


--
-- Name: COLUMN ui.tt; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN ui.tt IS 'meaning of the value';


--
-- Name: wikt; Type: TABLE; Schema: interim; Owner: pool; Tablespace: 
--

CREATE TABLE wikt (
    prefix text,
    lc character(3),
    total text,
    abbrev text,
    id integer NOT NULL
);


ALTER TABLE interim.wikt OWNER TO pool;

--
-- Name: TABLE wikt; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON TABLE wikt IS 'facts about Wiktionaries during 2010 harvesting of approver data';


--
-- Name: COLUMN wikt.prefix; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN wikt.prefix IS 'lc of Wiktionary’s primary lv';


--
-- Name: COLUMN wikt.total; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN wikt.total IS 'Wiktionary’s name in its primary lv';


--
-- Name: COLUMN wikt.abbrev; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN wikt.abbrev IS 'version of Wiktionary’s name in its primary lv short enough for ap tt';


--
-- Name: COLUMN wikt.id; Type: COMMENT; Schema: interim; Owner: pool
--

COMMENT ON COLUMN wikt.id IS 'approver ID';


--
-- Name: wikt_id_seq; Type: SEQUENCE; Schema: interim; Owner: pool
--

CREATE SEQUENCE wikt_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE interim.wikt_id_seq OWNER TO pool;

--
-- Name: wikt_id_seq; Type: SEQUENCE OWNED BY; Schema: interim; Owner: pool
--

ALTER SEQUENCE wikt_id_seq OWNED BY wikt.id;


SET search_path = public, pg_catalog;

--
-- Name: aped; Type: TABLE; Schema: public; Owner: patrick; Tablespace: 
--

CREATE TABLE aped (
    ap integer NOT NULL,
    q boolean DEFAULT true NOT NULL,
    cx smallint,
    im boolean DEFAULT false NOT NULL,
    re boolean DEFAULT false NOT NULL,
    ed text,
    fp text,
    etc text
);


ALTER TABLE public.aped OWNER TO patrick;

--
-- Name: apf; Type: TABLE; Schema: public; Owner: patrick; Tablespace: 
--

CREATE TABLE apf (
    dt date NOT NULL,
    ap integer NOT NULL,
    rp boolean NOT NULL,
    tt text NOT NULL
);


ALTER TABLE public.apf OWNER TO patrick;

--
-- Name: apli; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE apli (
    id integer NOT NULL,
    li character(2) NOT NULL,
    pl text NOT NULL
);


ALTER TABLE public.apli OWNER TO apache;

--
-- Name: TABLE apli; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE apli IS 'permitted approver permission types';


--
-- Name: COLUMN apli.id; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN apli.id IS 'ID';


--
-- Name: COLUMN apli.li; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN apli.li IS '2-character type code';


--
-- Name: COLUMN apli.pl; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN apli.pl IS 'text of the type’s PanLex expression';


--
-- Name: au; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE au (
    ap integer NOT NULL,
    us integer NOT NULL
);


ALTER TABLE public.au OWNER TO apache;

--
-- Name: TABLE au; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE au IS 'users permitted to edit approvers';


--
-- Name: COLUMN au.ap; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN au.ap IS 'approver';


--
-- Name: COLUMN au.us; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN au.us IS 'user permitted to edit the approver';


--
-- Name: av; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE av (
    ap integer NOT NULL,
    lv integer NOT NULL
);


ALTER TABLE public.av OWNER TO apache;

--
-- Name: TABLE av; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE av IS 'approvers’ declared denotation expression varieties';


--
-- Name: COLUMN av.ap; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN av.ap IS 'approver';


--
-- Name: COLUMN av.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN av.lv IS 'variety';


--
-- Name: cp; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE cp (
    lv integer NOT NULL,
    c0 character(5) NOT NULL,
    c1 character(5) NOT NULL
);


ALTER TABLE public.cp OWNER TO apache;

--
-- Name: TABLE cp; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE cp IS 'variety managers’ approved characters';


--
-- Name: COLUMN cp.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cp.lv IS 'variety';


--
-- Name: COLUMN cp.c0; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cp.c0 IS 'start of character range';


--
-- Name: COLUMN cp.c1; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cp.c1 IS 'end of character range';


--
-- Name: cu; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE cu (
    lv integer NOT NULL,
    c0 character(5) NOT NULL,
    c1 character(5) NOT NULL,
    loc text,
    vb text NOT NULL
);


ALTER TABLE public.cu OWNER TO apache;

--
-- Name: TABLE cu; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE cu IS 'Unicode CLDR exemplar characters';


--
-- Name: COLUMN cu.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cu.lv IS 'variety';


--
-- Name: COLUMN cu.c0; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cu.c0 IS 'start of character range';


--
-- Name: COLUMN cu.c1; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cu.c1 IS 'end of character range';


--
-- Name: COLUMN cu.loc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cu.loc IS 'locale';


--
-- Name: COLUMN cu.vb; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN cu.vb IS 'variable';


--
-- Name: df; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE df (
    df integer NOT NULL,
    mn integer NOT NULL,
    lv integer NOT NULL,
    tt text NOT NULL
);


ALTER TABLE public.df OWNER TO apache;

--
-- Name: TABLE df; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE df IS 'definitions';


--
-- Name: COLUMN df.df; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN df.df IS 'ID';


--
-- Name: COLUMN df.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN df.mn IS 'meaning';


--
-- Name: COLUMN df.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN df.lv IS 'variety of the text';


--
-- Name: COLUMN df.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN df.tt IS 'text';


--
-- Name: dfid; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE dfid (
    df integer NOT NULL
);


ALTER TABLE public.dfid OWNER TO apache;

--
-- Name: TABLE dfid; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE dfid IS 'IDs available for assignment to definitions';


--
-- Name: COLUMN dfid.df; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dfid.df IS 'available ID';


--
-- Name: dm; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE dm (
    dm integer NOT NULL,
    mn integer NOT NULL,
    ex integer NOT NULL
);


ALTER TABLE public.dm OWNER TO apache;

--
-- Name: TABLE dm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE dm IS 'domains';


--
-- Name: COLUMN dm.dm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dm.dm IS 'ID';


--
-- Name: COLUMN dm.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dm.mn IS 'meaning';


--
-- Name: COLUMN dm.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dm.ex IS 'expression';


--
-- Name: dmid; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE dmid (
    dm integer NOT NULL
);


ALTER TABLE public.dmid OWNER TO apache;

--
-- Name: TABLE dmid; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE dmid IS 'IDs available for assignment to domains';


--
-- Name: COLUMN dmid.dm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dmid.dm IS 'available ID';


--
-- Name: dnid; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE dnid (
    dn integer NOT NULL
);


ALTER TABLE public.dnid OWNER TO apache;

--
-- Name: TABLE dnid; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE dnid IS 'IDs available for assignment to denotations';


--
-- Name: COLUMN dnid.dn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN dnid.dn IS 'available ID';


--
-- Name: encoding; Type: VIEW; Schema: public; Owner: pool
--

CREATE VIEW encoding AS
    SELECT ap.ap, ap.tt, ap.fp, ap.ul FROM ap WHERE ((ap.ul ~~ '%ncod%'::text) OR (ap.ul ~~ '%ecoding%'::text)) ORDER BY ap.tt;


ALTER TABLE public.encoding OWNER TO pool;

--
-- Name: exap; Type: TABLE; Schema: public; Owner: patrick; Tablespace: 
--

CREATE TABLE exap (
    ex integer NOT NULL,
    ap integer NOT NULL
);


ALTER TABLE public.exap OWNER TO patrick;

--
-- Name: exid; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE exid (
    ex integer NOT NULL
);


ALTER TABLE public.exid OWNER TO apache;

--
-- Name: TABLE exid; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE exid IS 'IDs available for assignment to expressions';


--
-- Name: COLUMN exid.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN exid.ex IS 'available ID';


--
-- Name: files; Type: VIEW; Schema: public; Owner: apache
--

CREATE VIEW files AS
    SELECT pg_class.relnamespace, pg_class.relname, pg_class.relfilenode, pg_class.relpages FROM pg_class WHERE ((pg_class.relowner = (16846)::oid) AND (pg_class.relname !~~ 'pg%'::text)) ORDER BY pg_class.relnamespace, pg_class.relname;


ALTER TABLE public.files OWNER TO apache;

--
-- Name: VIEW files; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON VIEW files IS 'files comprising the database';


--
-- Name: fm; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE fm (
    fm smallint NOT NULL,
    tt text NOT NULL,
    md text NOT NULL
);


ALTER TABLE public.fm OWNER TO apache;

--
-- Name: TABLE fm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE fm IS 'source file formats';


--
-- Name: COLUMN fm.fm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN fm.fm IS 'ID';


--
-- Name: COLUMN fm.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN fm.tt IS 'label';


--
-- Name: COLUMN fm.md; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN fm.md IS 'examples of distinctive markers';


--
-- Name: i1; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE i1 (
    iso1 character(2) NOT NULL,
    iso3 character(3) NOT NULL
);


ALTER TABLE public.i1 OWNER TO apache;

--
-- Name: TABLE i1; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE i1 IS 'ISO 639-1 and 639-3 codes';


--
-- Name: COLUMN i1.iso1; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN i1.iso1 IS 'ISO 639-1 code';


--
-- Name: COLUMN i1.iso3; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN i1.iso3 IS 'ISO 639-3 code';


--
-- Name: lc; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE lc (
    lc character(3) NOT NULL,
    tp character(1) NOT NULL
);


ALTER TABLE public.lc OWNER TO apache;

--
-- Name: TABLE lc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE lc IS 'ISO 639-3 codes and ISO 639-2 collective language codes';


--
-- Name: COLUMN lc.lc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lc.lc IS 'code';


--
-- Name: COLUMN lc.tp; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lc.tp IS 'code type: “i” = 639-3 ind, “m” = 639-3 macro, “c” = 639-2 coll, “f” = 639-5, “o” = other';


--
-- Name: lv; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE lv (
    lv integer NOT NULL,
    lc character(3) NOT NULL,
    vc smallint NOT NULL,
    sy boolean DEFAULT true NOT NULL,
    am boolean DEFAULT true NOT NULL,
    tt text NOT NULL
);


ALTER TABLE public.lv OWNER TO apache;

--
-- Name: TABLE lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE lv IS 'language varieties';


--
-- Name: COLUMN lv.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lv.lv IS 'ID';


--
-- Name: COLUMN lv.lc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lv.lc IS 'ISO 639 code';


--
-- Name: COLUMN lv.vc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lv.vc IS 'language-specific ID';


--
-- Name: COLUMN lv.sy; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lv.sy IS 'whether the variety permits synonymy';


--
-- Name: COLUMN lv.am; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lv.am IS 'whether the variety permits ambiguity';


--
-- Name: COLUMN lv.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lv.tt IS 'label (with no &, ", <, >)';


--
-- Name: lctt; Type: VIEW; Schema: public; Owner: pool
--

CREATE VIEW lctt AS
    SELECT lv.lv, lv.lc, ex2.ex, ex2.tt AS tte, lv.tt AS ttl FROM ex ex1, lv, dn dn1, dn dn2, ex ex2 WHERE (((((((ex1.lv = 41) AND ((lv.lc)::text = ex1.tt)) AND (lv.vc = 0)) AND (dn1.ex = ex1.ex)) AND (dn2.mn = dn1.mn)) AND (ex2.ex = dn2.ex)) AND (ex2.lv = lv.lv)) ORDER BY lv.lc, ex2.tt;


ALTER TABLE public.lctt OWNER TO pool;

--
-- Name: lu; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE lu (
    lv integer NOT NULL,
    us integer NOT NULL
);


ALTER TABLE public.lu OWNER TO apache;

--
-- Name: TABLE lu; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE lu IS 'users permitted to edit language varieties';


--
-- Name: COLUMN lu.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lu.lv IS 'variety';


--
-- Name: COLUMN lu.us; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN lu.us IS 'user permitted to edit the variety';


--
-- Name: md; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE md (
    md integer NOT NULL,
    dn integer NOT NULL,
    vb text NOT NULL,
    vl text NOT NULL
);


ALTER TABLE public.md OWNER TO apache;

--
-- Name: TABLE md; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE md IS 'denotation metadata';


--
-- Name: COLUMN md.md; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN md.md IS 'ID';


--
-- Name: COLUMN md.dn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN md.dn IS 'denotation';


--
-- Name: COLUMN md.vb; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN md.vb IS 'variable';


--
-- Name: COLUMN md.vl; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN md.vl IS 'value';


--
-- Name: mdid; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE mdid (
    md integer NOT NULL
);


ALTER TABLE public.mdid OWNER TO apache;

--
-- Name: TABLE mdid; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE mdid IS 'IDs available for assignment to metadata';


--
-- Name: COLUMN mdid.md; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN mdid.md IS 'available ID';


--
-- Name: mi; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE mi (
    mn integer NOT NULL,
    tt text NOT NULL
);


ALTER TABLE public.mi OWNER TO apache;

--
-- Name: TABLE mi; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE mi IS 'meaning identifiers';


--
-- Name: COLUMN mi.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN mi.mn IS 'meaning';


--
-- Name: COLUMN mi.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN mi.tt IS 'text';


--
-- Name: mn; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE mn (
    mn integer NOT NULL,
    ap integer NOT NULL
);


ALTER TABLE public.mn OWNER TO apache;

--
-- Name: TABLE mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE mn IS 'meanings';


--
-- Name: COLUMN mn.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN mn.mn IS 'ID';


--
-- Name: COLUMN mn.ap; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN mn.ap IS 'approver';


--
-- Name: mnid; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE mnid (
    mn integer NOT NULL
);


ALTER TABLE public.mnid OWNER TO apache;

--
-- Name: TABLE mnid; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE mnid IS 'IDs available for assignment to meanings';


--
-- Name: COLUMN mnid.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN mnid.mn IS 'available ID';


--
-- Name: pl0; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE pl0 (
    tt text NOT NULL,
    ex integer NOT NULL,
    mn integer NOT NULL
);


ALTER TABLE public.pl0 OWNER TO apache;

--
-- Name: TABLE pl0; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE pl0 IS 'meanings assigned by PanLex to PanLex expressions';


--
-- Name: COLUMN pl0.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN pl0.tt IS 'expression text';


--
-- Name: COLUMN pl0.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN pl0.ex IS 'expression ID';


--
-- Name: COLUMN pl0.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN pl0.mn IS 'meaning';


--
-- Name: pl1; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE pl1 (
    mn integer,
    lv integer,
    ex integer
);


ALTER TABLE public.pl1 OWNER TO apache;

--
-- Name: TABLE pl1; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE pl1 IS 'translations of PanLex expressions by PanLex';


--
-- Name: COLUMN pl1.mn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN pl1.mn IS 'meaning assigned to a PanLex expression by PanLex';


--
-- Name: COLUMN pl1.lv; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN pl1.lv IS 'variety of an expression with the meaning';


--
-- Name: COLUMN pl1.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN pl1.ex IS 'ID of the expression';


--
-- Name: us; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE us (
    us integer NOT NULL,
    dt date DEFAULT ('now'::text)::date NOT NULL,
    nm text,
    al text NOT NULL,
    sm text,
    ht text,
    pw character(32) NOT NULL,
    ok boolean DEFAULT false NOT NULL,
    ad boolean DEFAULT false NOT NULL
);


ALTER TABLE public.us OWNER TO apache;

--
-- Name: TABLE us; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE us IS 'users';


--
-- Name: COLUMN us.us; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.us IS 'ID';


--
-- Name: COLUMN us.dt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.dt IS 'enrollment date';


--
-- Name: COLUMN us.nm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.nm IS 'name';


--
-- Name: COLUMN us.al; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.al IS 'alias (username)';


--
-- Name: COLUMN us.sm; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.sm IS 'SMTP (Internet mail) address';


--
-- Name: COLUMN us.ht; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.ht IS 'HTTP (World Wide Web) address (URL)';


--
-- Name: COLUMN us.pw; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.pw IS 'password';


--
-- Name: COLUMN us.ok; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.ok IS 'whether approved';


--
-- Name: COLUMN us.ad; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN us.ad IS 'whether a PanLex superuser';


--
-- Name: wc; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE wc (
    wc integer NOT NULL,
    dn integer NOT NULL,
    ex integer NOT NULL
);


ALTER TABLE public.wc OWNER TO apache;

--
-- Name: TABLE wc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE wc IS 'word classifications';


--
-- Name: COLUMN wc.wc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN wc.wc IS 'ID';


--
-- Name: COLUMN wc.dn; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN wc.dn IS 'denotation';


--
-- Name: COLUMN wc.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN wc.ex IS 'PanLex word-class expression';


--
-- Name: wcex; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE wcex (
    ex integer NOT NULL,
    tt text NOT NULL
);


ALTER TABLE public.wcex OWNER TO apache;

--
-- Name: TABLE wcex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE wcex IS 'PanLex expressions permitted as word-class IDs';


--
-- Name: COLUMN wcex.ex; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN wcex.ex IS 'expression';


--
-- Name: COLUMN wcex.tt; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN wcex.tt IS 'text';


--
-- Name: wcid; Type: TABLE; Schema: public; Owner: apache; Tablespace: 
--

CREATE TABLE wcid (
    wc integer NOT NULL
);


ALTER TABLE public.wcid OWNER TO apache;

--
-- Name: TABLE wcid; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON TABLE wcid IS 'IDs available for assignment to word classifications';


--
-- Name: COLUMN wcid.wc; Type: COMMENT; Schema: public; Owner: apache
--

COMMENT ON COLUMN wcid.wc IS 'available ID';


--
-- Name: wikt1; Type: TABLE; Schema: public; Owner: pool; Tablespace: 
--

CREATE TABLE wikt1 (
    prefix text,
    ip text
);


ALTER TABLE public.wikt1 OWNER TO pool;

SET search_path = util, pg_catalog;

--
-- Name: bib; Type: VIEW; Schema: util; Owner: pool
--

CREATE VIEW bib AS
    SELECT ((((((((('<tr><td>'::text || hml(ap.au)) || '</td><td>'::text) || '<a href="'::text) || ap.ur) || '">'::text) || hml(ap.ti)) || '</a></td><td>'::text) || CASE WHEN (ap.yr IS NULL) THEN ''::text ELSE (ap.yr)::text END) || '</td></tr>'::text) AS content FROM public.ap WHERE ((ap.ti IS NOT NULL) AND (ap.ur IS NOT NULL)) ORDER BY ap.ti;


ALTER TABLE util.bib OWNER TO pool;

--
-- Name: VIEW bib; Type: COMMENT; Schema: util; Owner: pool
--

COMMENT ON VIEW bib IS 'approvers with titles and URLs as HTML text';


SET search_path = interim, pg_catalog;

--
-- Name: id; Type: DEFAULT; Schema: interim; Owner: pool
--

ALTER TABLE ONLY wikt ALTER COLUMN id SET DEFAULT nextval('wikt_id_seq'::regclass);


--
-- Name: agrodn_mn_ex_key; Type: CONSTRAINT; Schema: interim; Owner: pool; Tablespace: 
--

ALTER TABLE ONLY agrodn
    ADD CONSTRAINT agrodn_mn_ex_key UNIQUE (mn, ex);

ALTER TABLE agrodn CLUSTER ON agrodn_mn_ex_key;


--
-- Name: agrodn_pkey; Type: CONSTRAINT; Schema: interim; Owner: pool; Tablespace: 
--

ALTER TABLE ONLY agrodn
    ADD CONSTRAINT agrodn_pkey PRIMARY KEY (dn);


--
-- Name: agroex_lv_tt_key; Type: CONSTRAINT; Schema: interim; Owner: pool; Tablespace: 
--

ALTER TABLE ONLY agroex
    ADD CONSTRAINT agroex_lv_tt_key UNIQUE (lv, tt);


--
-- Name: agroex_pkey; Type: CONSTRAINT; Schema: interim; Owner: pool; Tablespace: 
--

ALTER TABLE ONLY agroex
    ADD CONSTRAINT agroex_pkey PRIMARY KEY (ex);


--
-- Name: auto_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY auto
    ADD CONSTRAINT auto_pkey PRIMARY KEY (ap);

ALTER TABLE auto CLUSTER ON auto_pkey;


--
-- Name: cmn_pkey; Type: CONSTRAINT; Schema: interim; Owner: pool; Tablespace: 
--

ALTER TABLE ONLY cmn
    ADD CONSTRAINT cmn_pkey PRIMARY KEY (wc, han, py);


--
-- Name: simdn_pkey; Type: CONSTRAINT; Schema: interim; Owner: pool; Tablespace: 
--

ALTER TABLE ONLY simdn
    ADD CONSTRAINT simdn_pkey PRIMARY KEY (ex, mn);

ALTER TABLE simdn CLUSTER ON simdn_pkey;


--
-- Name: simdns_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simdns
    ADD CONSTRAINT simdns_pkey PRIMARY KEY (ex);

ALTER TABLE simdns CLUSTER ON simdns_pkey;


--
-- Name: simeq_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simeq
    ADD CONSTRAINT simeq_pkey PRIMARY KEY (ex1, ex2);

ALTER TABLE simeq CLUSTER ON simeq_pkey;


--
-- Name: simex_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simex
    ADD CONSTRAINT simex_pkey PRIMARY KEY (ex);

ALTER TABLE simex CLUSTER ON simex_pkey;


--
-- Name: simlv_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simlv
    ADD CONSTRAINT simlv_pkey PRIMARY KEY (lv);

ALTER TABLE simlv CLUSTER ON simlv_pkey;


--
-- Name: simpair_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simpair
    ADD CONSTRAINT simpair_pkey PRIMARY KEY (ex1, ex2);

ALTER TABLE simpair CLUSTER ON simpair_pkey;


--
-- Name: simpt_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simpt
    ADD CONSTRAINT simpt_pkey PRIMARY KEY (ex1, ex2, ext);

ALTER TABLE simpt CLUSTER ON simpt_pkey;


--
-- Name: simtd_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simtd
    ADD CONSTRAINT simtd_pkey PRIMARY KEY (lv, td);

ALTER TABLE simtd CLUSTER ON simtd_pkey;


--
-- Name: simtr_pkey; Type: CONSTRAINT; Schema: interim; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY simtr
    ADD CONSTRAINT simtr_pkey PRIMARY KEY (exs, ext);

ALTER TABLE simtr CLUSTER ON simtr_pkey;


--
-- Name: ui_pkey; Type: CONSTRAINT; Schema: interim; Owner: pool; Tablespace: 
--

ALTER TABLE ONLY ui
    ADD CONSTRAINT ui_pkey PRIMARY KEY (ui);

ALTER TABLE ui CLUSTER ON ui_pkey;


SET search_path = public, pg_catalog;

--
-- Name: af_ap_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY af
    ADD CONSTRAINT af_ap_key UNIQUE (ap, fm);


--
-- Name: ap_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY ap
    ADD CONSTRAINT ap_pkey PRIMARY KEY (ap);

ALTER TABLE ap CLUSTER ON ap_pkey;


--
-- Name: ap_tt_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY ap
    ADD CONSTRAINT ap_tt_key UNIQUE (tt);


--
-- Name: apli_li_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY apli
    ADD CONSTRAINT apli_li_key UNIQUE (li);


--
-- Name: apli_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY apli
    ADD CONSTRAINT apli_pkey PRIMARY KEY (id);

ALTER TABLE apli CLUSTER ON apli_pkey;


--
-- Name: apli_pl_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY apli
    ADD CONSTRAINT apli_pl_key UNIQUE (pl);


--
-- Name: au_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY au
    ADD CONSTRAINT au_pkey PRIMARY KEY (ap, us);

ALTER TABLE au CLUSTER ON au_pkey;


--
-- Name: av_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY av
    ADD CONSTRAINT av_pkey PRIMARY KEY (ap, lv);

ALTER TABLE av CLUSTER ON av_pkey;


--
-- Name: cp_lv_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY cp
    ADD CONSTRAINT cp_lv_key UNIQUE (lv, c1);


--
-- Name: cp_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY cp
    ADD CONSTRAINT cp_pkey PRIMARY KEY (lv, c0);

ALTER TABLE cp CLUSTER ON cp_pkey;


--
-- Name: cu_c0_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY cu
    ADD CONSTRAINT cu_c0_key UNIQUE (lv, c0, loc, vb);

ALTER TABLE cu CLUSTER ON cu_c0_key;


--
-- Name: cu_c1_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY cu
    ADD CONSTRAINT cu_c1_key UNIQUE (lv, c1, loc, vb);


--
-- Name: df_mn_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY df
    ADD CONSTRAINT df_mn_key UNIQUE (mn, lv, tt);

ALTER TABLE df CLUSTER ON df_mn_key;


--
-- Name: df_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY df
    ADD CONSTRAINT df_pkey PRIMARY KEY (df);


--
-- Name: dfid_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY dfid
    ADD CONSTRAINT dfid_pkey PRIMARY KEY (df);

ALTER TABLE dfid CLUSTER ON dfid_pkey;


--
-- Name: dm_mn_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY dm
    ADD CONSTRAINT dm_mn_key UNIQUE (mn, ex);

ALTER TABLE dm CLUSTER ON dm_mn_key;


--
-- Name: dm_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY dm
    ADD CONSTRAINT dm_pkey PRIMARY KEY (dm);


--
-- Name: dmid_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY dmid
    ADD CONSTRAINT dmid_pkey PRIMARY KEY (dm);

ALTER TABLE dmid CLUSTER ON dmid_pkey;


--
-- Name: dn_mn_ex_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY dn
    ADD CONSTRAINT dn_mn_ex_key UNIQUE (mn, ex);

ALTER TABLE dn CLUSTER ON dn_mn_ex_key;


--
-- Name: dn_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY dn
    ADD CONSTRAINT dn_pkey PRIMARY KEY (dn);


--
-- Name: dnid_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY dnid
    ADD CONSTRAINT dnid_pkey PRIMARY KEY (dn);

ALTER TABLE dnid CLUSTER ON dnid_pkey;


--
-- Name: ex_lv_tt_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY ex
    ADD CONSTRAINT ex_lv_tt_key UNIQUE (lv, tt);


--
-- Name: ex_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY ex
    ADD CONSTRAINT ex_pkey PRIMARY KEY (ex);


--
-- Name: exid_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY exid
    ADD CONSTRAINT exid_pkey PRIMARY KEY (ex);

ALTER TABLE exid CLUSTER ON exid_pkey;


--
-- Name: fm_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY fm
    ADD CONSTRAINT fm_pkey PRIMARY KEY (fm);

ALTER TABLE fm CLUSTER ON fm_pkey;


--
-- Name: fm_tt_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY fm
    ADD CONSTRAINT fm_tt_key UNIQUE (tt);


--
-- Name: i1_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY i1
    ADD CONSTRAINT i1_pkey PRIMARY KEY (iso1);

ALTER TABLE i1 CLUSTER ON i1_pkey;


--
-- Name: lc_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY lc
    ADD CONSTRAINT lc_pkey PRIMARY KEY (lc);

ALTER TABLE lc CLUSTER ON lc_pkey;


--
-- Name: lu_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY lu
    ADD CONSTRAINT lu_pkey PRIMARY KEY (lv, us);

ALTER TABLE lu CLUSTER ON lu_pkey;


--
-- Name: lv_lc_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY lv
    ADD CONSTRAINT lv_lc_key UNIQUE (lc, vc);


--
-- Name: lv_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY lv
    ADD CONSTRAINT lv_pkey PRIMARY KEY (lv);

ALTER TABLE lv CLUSTER ON lv_pkey;


--
-- Name: md_dn_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY md
    ADD CONSTRAINT md_dn_key UNIQUE (dn, vb, vl);

ALTER TABLE md CLUSTER ON md_dn_key;


--
-- Name: md_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY md
    ADD CONSTRAINT md_pkey PRIMARY KEY (md);


--
-- Name: mdid_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY mdid
    ADD CONSTRAINT mdid_pkey PRIMARY KEY (md);

ALTER TABLE mdid CLUSTER ON mdid_pkey;


--
-- Name: mi_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY mi
    ADD CONSTRAINT mi_pkey PRIMARY KEY (mn);

ALTER TABLE mi CLUSTER ON mi_pkey;


--
-- Name: mn_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY mn
    ADD CONSTRAINT mn_pkey PRIMARY KEY (mn);


--
-- Name: mnid_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY mnid
    ADD CONSTRAINT mnid_pkey PRIMARY KEY (mn);

ALTER TABLE mnid CLUSTER ON mnid_pkey;


--
-- Name: pl0_ex_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY pl0
    ADD CONSTRAINT pl0_ex_key UNIQUE (ex);


--
-- Name: pl0_extt; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY pl0
    ADD CONSTRAINT pl0_extt UNIQUE (ex, tt);


--
-- Name: pl0_mn_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY pl0
    ADD CONSTRAINT pl0_mn_key UNIQUE (mn);


--
-- Name: pl0_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY pl0
    ADD CONSTRAINT pl0_pkey PRIMARY KEY (tt);

ALTER TABLE pl0 CLUSTER ON pl0_pkey;


--
-- Name: pl1_mn_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY pl1
    ADD CONSTRAINT pl1_mn_key UNIQUE (mn, lv, ex);

ALTER TABLE pl1 CLUSTER ON pl1_mn_key;


--
-- Name: us_al_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY us
    ADD CONSTRAINT us_al_key UNIQUE (al);


--
-- Name: us_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY us
    ADD CONSTRAINT us_pkey PRIMARY KEY (us);

ALTER TABLE us CLUSTER ON us_pkey;


--
-- Name: wc_dn_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY wc
    ADD CONSTRAINT wc_dn_key UNIQUE (dn, ex);

ALTER TABLE wc CLUSTER ON wc_dn_key;


--
-- Name: wc_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY wc
    ADD CONSTRAINT wc_pkey PRIMARY KEY (wc);


--
-- Name: wcex_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY wcex
    ADD CONSTRAINT wcex_pkey PRIMARY KEY (ex);

ALTER TABLE wcex CLUSTER ON wcex_pkey;


--
-- Name: wcex_tt_key; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY wcex
    ADD CONSTRAINT wcex_tt_key UNIQUE (tt);


--
-- Name: wcid_pkey; Type: CONSTRAINT; Schema: public; Owner: apache; Tablespace: 
--

ALTER TABLE ONLY wcid
    ADD CONSTRAINT wcid_pkey PRIMARY KEY (wc);

ALTER TABLE wcid CLUSTER ON wcid_pkey;


SET search_path = import, pg_catalog;

--
-- Name: df0_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX df0_se ON df0 USING btree (se);


--
-- Name: dm0_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX dm0_se ON dm0 USING btree (se);


--
-- Name: dn0_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX dn0_se ON dn0 USING btree (se);


--
-- Name: dn1_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX dn1_se ON dn1 USING btree (se);


--
-- Name: ex0_lv; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX ex0_lv ON ex0 USING btree (lv);


--
-- Name: ex0_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX ex0_se ON ex0 USING btree (se);


--
-- Name: ex0_tt; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX ex0_tt ON ex0 USING btree (tt);


--
-- Name: ex1_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX ex1_se ON ex1 USING btree (se);


--
-- Name: mapid_ts; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX mapid_ts ON mapid USING btree (ts);


--
-- Name: mapse_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX mapse_se ON mapse USING btree (se);


--
-- Name: md0_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX md0_se ON md0 USING btree (se);


--
-- Name: mi0_mn; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX mi0_mn ON mi0 USING btree (mn);


--
-- Name: mn0_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX mn0_se ON mn0 USING btree (se);


--
-- Name: mn1_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX mn1_se ON mn1 USING btree (se);


--
-- Name: wc0_se; Type: INDEX; Schema: import; Owner: apache; Tablespace: 
--

CREATE INDEX wc0_se ON wc0 USING btree (se);


SET search_path = interim, pg_catalog;

--
-- Name: agrodn_ex_idx; Type: INDEX; Schema: interim; Owner: pool; Tablespace: 
--

CREATE INDEX agrodn_ex_idx ON agrodn USING btree (ex);


--
-- Name: agrodn_mn_idx; Type: INDEX; Schema: interim; Owner: pool; Tablespace: 
--

CREATE INDEX agrodn_mn_idx ON agrodn USING btree (mn);


--
-- Name: agroex_lv_idx; Type: INDEX; Schema: interim; Owner: pool; Tablespace: 
--

CREATE INDEX agroex_lv_idx ON agroex USING btree (lv);


--
-- Name: agroex_td_idx; Type: INDEX; Schema: interim; Owner: pool; Tablespace: 
--

CREATE INDEX agroex_td_idx ON agroex USING btree (td);


--
-- Name: agroex_tt_idx; Type: INDEX; Schema: interim; Owner: pool; Tablespace: 
--

CREATE INDEX agroex_tt_idx ON agroex USING btree (tt);

ALTER TABLE agroex CLUSTER ON agroex_tt_idx;


SET search_path = public, pg_catalog;

--
-- Name: dn_ex_idx; Type: INDEX; Schema: public; Owner: apache; Tablespace: 
--

CREATE INDEX dn_ex_idx ON dn USING btree (ex);


--
-- Name: dn_mn_idx; Type: INDEX; Schema: public; Owner: apache; Tablespace: 
--

CREATE INDEX dn_mn_idx ON dn USING btree (mn);


--
-- Name: ex_lv_idx; Type: INDEX; Schema: public; Owner: apache; Tablespace: 
--

CREATE INDEX ex_lv_idx ON ex USING btree (lv);


--
-- Name: ex_td_idx; Type: INDEX; Schema: public; Owner: apache; Tablespace: 
--

CREATE INDEX ex_td_idx ON ex USING btree (td);


--
-- Name: ex_tt_idx; Type: INDEX; Schema: public; Owner: apache; Tablespace: 
--

CREATE INDEX ex_tt_idx ON ex USING btree (tt);

ALTER TABLE ex CLUSTER ON ex_tt_idx;


--
-- Name: mn_ap_idx; Type: INDEX; Schema: public; Owner: apache; Tablespace: 
--

CREATE INDEX mn_ap_idx ON mn USING btree (ap);

ALTER TABLE mn CLUSTER ON mn_ap_idx;


--
-- Name: ex_td; Type: TRIGGER; Schema: public; Owner: apache
--

CREATE TRIGGER ex_td BEFORE INSERT OR UPDATE ON ex FOR EACH ROW EXECUTE PROCEDURE tdau();


SET search_path = interim, pg_catalog;

--
-- Name: auto_tsus_fkey; Type: FK CONSTRAINT; Schema: interim; Owner: apache
--

ALTER TABLE ONLY auto
    ADD CONSTRAINT auto_tsus_fkey FOREIGN KEY (tsus) REFERENCES public.us(us);


SET search_path = public, pg_catalog;

--
-- Name: af_ap_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY af
    ADD CONSTRAINT af_ap_fkey FOREIGN KEY (ap) REFERENCES ap(ap) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: af_fm_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY af
    ADD CONSTRAINT af_fm_fkey FOREIGN KEY (fm) REFERENCES fm(fm) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ap_li_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY ap
    ADD CONSTRAINT ap_li_fkey FOREIGN KEY (li) REFERENCES apli(li);


--
-- Name: aped_ap_fkey; Type: FK CONSTRAINT; Schema: public; Owner: patrick
--

ALTER TABLE ONLY aped
    ADD CONSTRAINT aped_ap_fkey FOREIGN KEY (ap) REFERENCES ap(ap);


--
-- Name: au_ap_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY au
    ADD CONSTRAINT au_ap_fkey FOREIGN KEY (ap) REFERENCES ap(ap);


--
-- Name: au_us_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY au
    ADD CONSTRAINT au_us_fkey FOREIGN KEY (us) REFERENCES us(us);


--
-- Name: av_ap_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY av
    ADD CONSTRAINT av_ap_fkey FOREIGN KEY (ap) REFERENCES ap(ap) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: av_lv_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY av
    ADD CONSTRAINT av_lv_fkey FOREIGN KEY (lv) REFERENCES lv(lv) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: cp_lv_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY cp
    ADD CONSTRAINT cp_lv_fkey FOREIGN KEY (lv) REFERENCES lv(lv);


--
-- Name: cu_lv_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY cu
    ADD CONSTRAINT cu_lv_fkey FOREIGN KEY (lv) REFERENCES lv(lv);


--
-- Name: df_lv_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY df
    ADD CONSTRAINT df_lv_fkey FOREIGN KEY (lv) REFERENCES lv(lv);


--
-- Name: df_mn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY df
    ADD CONSTRAINT df_mn_fkey FOREIGN KEY (mn) REFERENCES mn(mn);


--
-- Name: dm_ex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY dm
    ADD CONSTRAINT dm_ex_fkey FOREIGN KEY (ex) REFERENCES ex(ex);


--
-- Name: dm_mn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY dm
    ADD CONSTRAINT dm_mn_fkey FOREIGN KEY (mn) REFERENCES mn(mn);


--
-- Name: dn_ex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY dn
    ADD CONSTRAINT dn_ex_fkey FOREIGN KEY (ex) REFERENCES ex(ex);


--
-- Name: dn_mn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY dn
    ADD CONSTRAINT dn_mn_fkey FOREIGN KEY (mn) REFERENCES mn(mn);


--
-- Name: ex_lv_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY ex
    ADD CONSTRAINT ex_lv_fkey FOREIGN KEY (lv) REFERENCES lv(lv);


--
-- Name: i1_iso3_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY i1
    ADD CONSTRAINT i1_iso3_fkey FOREIGN KEY (iso3) REFERENCES lc(lc);


--
-- Name: lu_lv_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY lu
    ADD CONSTRAINT lu_lv_fkey FOREIGN KEY (lv) REFERENCES lv(lv);


--
-- Name: lu_us_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY lu
    ADD CONSTRAINT lu_us_fkey FOREIGN KEY (us) REFERENCES us(us);


--
-- Name: lv_lc_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY lv
    ADD CONSTRAINT lv_lc_fkey FOREIGN KEY (lc) REFERENCES lc(lc);


--
-- Name: md_dn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY md
    ADD CONSTRAINT md_dn_fkey FOREIGN KEY (dn) REFERENCES dn(dn);


--
-- Name: mi_mn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY mi
    ADD CONSTRAINT mi_mn_fkey FOREIGN KEY (mn) REFERENCES mn(mn);


--
-- Name: mn_ap_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY mn
    ADD CONSTRAINT mn_ap_fkey FOREIGN KEY (ap) REFERENCES ap(ap);


--
-- Name: pl0_ex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY pl0
    ADD CONSTRAINT pl0_ex_fkey FOREIGN KEY (ex) REFERENCES ex(ex);


--
-- Name: pl0_mn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY pl0
    ADD CONSTRAINT pl0_mn_fkey FOREIGN KEY (mn) REFERENCES mn(mn);


--
-- Name: pl1_ex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY pl1
    ADD CONSTRAINT pl1_ex_fkey FOREIGN KEY (ex) REFERENCES ex(ex);


--
-- Name: pl1_lv_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY pl1
    ADD CONSTRAINT pl1_lv_fkey FOREIGN KEY (lv) REFERENCES lv(lv);


--
-- Name: pl1_mn_ex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY pl1
    ADD CONSTRAINT pl1_mn_ex_fkey FOREIGN KEY (mn, ex) REFERENCES dn(mn, ex);


--
-- Name: pl1_mn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY pl1
    ADD CONSTRAINT pl1_mn_fkey FOREIGN KEY (mn) REFERENCES mn(mn);


--
-- Name: wc_dn_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY wc
    ADD CONSTRAINT wc_dn_fkey FOREIGN KEY (dn) REFERENCES dn(dn);


--
-- Name: wc_ex_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY wc
    ADD CONSTRAINT wc_ex_fkey FOREIGN KEY (ex) REFERENCES wcex(ex) ON UPDATE CASCADE;


--
-- Name: wcex_extt_fkey; Type: FK CONSTRAINT; Schema: public; Owner: apache
--

ALTER TABLE ONLY wcex
    ADD CONSTRAINT wcex_extt_fkey FOREIGN KEY (ex, tt) REFERENCES pl0(ex, tt) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: interim; Type: ACL; Schema: -; Owner: pool
--

REVOKE ALL ON SCHEMA interim FROM PUBLIC;
REVOKE ALL ON SCHEMA interim FROM pool;
GRANT ALL ON SCHEMA interim TO pool;
GRANT ALL ON SCHEMA interim TO apache;
GRANT USAGE ON SCHEMA interim TO smc;


--
-- Name: public; Type: ACL; Schema: -; Owner: patrick
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM patrick;
GRANT ALL ON SCHEMA public TO patrick;
GRANT ALL ON SCHEMA public TO pool;
GRANT ALL ON SCHEMA public TO apache;
GRANT USAGE ON SCHEMA public TO smc;
GRANT USAGE ON SCHEMA public TO evans;
GRANT ALL ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO PUBLIC;


--
-- Name: util; Type: ACL; Schema: -; Owner: pool
--

REVOKE ALL ON SCHEMA util FROM PUBLIC;
REVOKE ALL ON SCHEMA util FROM pool;
GRANT ALL ON SCHEMA util TO pool;
GRANT USAGE ON SCHEMA util TO apache;


--
-- Name: amrm(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION amrm(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION amrm(integer, integer) FROM pool;
GRANT ALL ON FUNCTION amrm(integer, integer) TO PUBLIC;


--
-- Name: apid(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION apid() FROM PUBLIC;
REVOKE ALL ON FUNCTION apid() FROM pool;
GRANT ALL ON FUNCTION apid() TO PUBLIC;


--
-- Name: aprm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION aprm(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION aprm(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) FROM pool;
GRANT ALL ON FUNCTION aprm(integer, OUT mndel integer, OUT midel integer, OUT dfdel integer, OUT dmdel integer, OUT dndel integer, OUT wcdel integer, OUT mddel integer) TO PUBLIC;


--
-- Name: dfad(integer, integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dfad(integer, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION dfad(integer, integer, text) FROM pool;
GRANT ALL ON FUNCTION dfad(integer, integer, text) TO PUBLIC;


--
-- Name: dfgt(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dfgt() FROM PUBLIC;
REVOKE ALL ON FUNCTION dfgt() FROM pool;
GRANT ALL ON FUNCTION dfgt() TO PUBLIC;


--
-- Name: dfrm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dfrm(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dfrm(integer) FROM pool;
GRANT ALL ON FUNCTION dfrm(integer) TO PUBLIC;


--
-- Name: dmad(integer, integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dmad(integer, integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION dmad(integer, integer, text) FROM pool;
GRANT ALL ON FUNCTION dmad(integer, integer, text) TO PUBLIC;


--
-- Name: dmgt(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dmgt() FROM PUBLIC;
REVOKE ALL ON FUNCTION dmgt() FROM pool;
GRANT ALL ON FUNCTION dmgt() TO PUBLIC;


--
-- Name: dmrm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dmrm(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dmrm(integer) FROM pool;
GRANT ALL ON FUNCTION dmrm(integer) TO PUBLIC;


--
-- Name: dnad(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dnad(integer, integer, OUT mnout integer, OUT dnout integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dnad(integer, integer, OUT mnout integer, OUT dnout integer) FROM pool;
GRANT ALL ON FUNCTION dnad(integer, integer, OUT mnout integer, OUT dnout integer) TO PUBLIC;


--
-- Name: dnad(integer, text, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dnad(integer, text, integer, OUT exout integer, OUT mnout integer, OUT dnout integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dnad(integer, text, integer, OUT exout integer, OUT mnout integer, OUT dnout integer) FROM pool;
GRANT ALL ON FUNCTION dnad(integer, text, integer, OUT exout integer, OUT mnout integer, OUT dnout integer) TO PUBLIC;


--
-- Name: dnad(integer, integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dnad(integer, integer, text, OUT exout integer, OUT dnout integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dnad(integer, integer, text, OUT exout integer, OUT dnout integer) FROM pool;
GRANT ALL ON FUNCTION dnad(integer, integer, text, OUT exout integer, OUT dnout integer) TO PUBLIC;


--
-- Name: dnad0(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dnad0(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dnad0(integer, integer) FROM pool;
GRANT ALL ON FUNCTION dnad0(integer, integer) TO PUBLIC;


--
-- Name: dnct(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dnct(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dnct(integer) FROM pool;
GRANT ALL ON FUNCTION dnct(integer) TO PUBLIC;


--
-- Name: dngt(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dngt() FROM PUBLIC;
REVOKE ALL ON FUNCTION dngt() FROM pool;
GRANT ALL ON FUNCTION dngt() TO PUBLIC;


--
-- Name: dnrm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION dnrm(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION dnrm(integer) FROM pool;
GRANT ALL ON FUNCTION dnrm(integer) TO PUBLIC;


--
-- Name: exad(integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION exad(integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION exad(integer, text) FROM pool;
GRANT ALL ON FUNCTION exad(integer, text) TO PUBLIC;


--
-- Name: exgt(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION exgt() FROM PUBLIC;
REVOKE ALL ON FUNCTION exgt() FROM pool;
GRANT ALL ON FUNCTION exgt() TO PUBLIC;


--
-- Name: exn(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION exn(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION exn(integer) FROM pool;
GRANT ALL ON FUNCTION exn(integer) TO PUBLIC;


--
-- Name: exrm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION exrm(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION exrm(integer) FROM pool;
GRANT ALL ON FUNCTION exrm(integer) TO PUBLIC;


--
-- Name: exs(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION exs(integer, OUT ex integer, OUT tt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION exs(integer, OUT ex integer, OUT tt text) FROM pool;
GRANT ALL ON FUNCTION exs(integer, OUT ex integer, OUT tt text) TO PUBLIC;


--
-- Name: exttmd(integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION exttmd(integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION exttmd(integer, text) FROM pool;
GRANT ALL ON FUNCTION exttmd(integer, text) TO PUBLIC;


--
-- Name: exx(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION exx(integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION exx(integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) FROM pool;
GRANT ALL ON FUNCTION exx(integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) TO PUBLIC;


--
-- Name: idck(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION idck() FROM PUBLIC;
REVOKE ALL ON FUNCTION idck() FROM pool;
GRANT ALL ON FUNCTION idck() TO PUBLIC;


--
-- Name: ixck(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION ixck() FROM PUBLIC;
REVOKE ALL ON FUNCTION ixck() FROM pool;
GRANT ALL ON FUNCTION ixck() TO PUBLIC;


--
-- Name: lcmd(integer, character); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lcmd(integer, character) FROM PUBLIC;
REVOKE ALL ON FUNCTION lcmd(integer, character) FROM pool;
GRANT ALL ON FUNCTION lcmd(integer, character) TO PUBLIC;


--
-- Name: lcvc(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lcvc(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION lcvc(integer) FROM pool;
GRANT ALL ON FUNCTION lcvc(integer) TO PUBLIC;


--
-- Name: lcvctt(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lcvctt(integer, OUT lcvc character, OUT tt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION lcvctt(integer, OUT lcvc character, OUT tt text) FROM pool;
GRANT ALL ON FUNCTION lcvctt(integer, OUT lcvc character, OUT tt text) TO PUBLIC;


--
-- Name: lv(character, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lv(character, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION lv(character, integer) FROM pool;
GRANT ALL ON FUNCTION lv(character, integer) TO PUBLIC;


--
-- Name: lvs(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lvs(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION lvs(integer) FROM pool;
GRANT ALL ON FUNCTION lvs(integer) TO PUBLIC;


--
-- Name: lvttmd(integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lvttmd(integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION lvttmd(integer, text) FROM pool;
GRANT ALL ON FUNCTION lvttmd(integer, text) TO PUBLIC;


--
-- Name: lvx(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lvx(integer, OUT lc character, OUT vc smallint, OUT tt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION lvx(integer, OUT lc character, OUT vc smallint, OUT tt text) FROM pool;
GRANT ALL ON FUNCTION lvx(integer, OUT lc character, OUT vc smallint, OUT tt text) TO PUBLIC;


--
-- Name: lvxs(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION lvxs(OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION lvxs(OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) FROM pool;
GRANT ALL ON FUNCTION lvxs(OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) TO PUBLIC;


--
-- Name: mdad(integer, text, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION mdad(integer, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION mdad(integer, text, text) FROM pool;
GRANT ALL ON FUNCTION mdad(integer, text, text) TO PUBLIC;


--
-- Name: mdgt(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION mdgt() FROM PUBLIC;
REVOKE ALL ON FUNCTION mdgt() FROM pool;
GRANT ALL ON FUNCTION mdgt() TO PUBLIC;


--
-- Name: mdrm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION mdrm(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION mdrm(integer) FROM pool;
GRANT ALL ON FUNCTION mdrm(integer) TO PUBLIC;


--
-- Name: miad(integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION miad(integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION miad(integer, text) FROM pool;
GRANT ALL ON FUNCTION miad(integer, text) TO PUBLIC;


--
-- Name: mnad(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION mnad(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION mnad(integer) FROM pool;
GRANT ALL ON FUNCTION mnad(integer) TO PUBLIC;


--
-- Name: mnck(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION mnck(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION mnck(integer) FROM pool;
GRANT ALL ON FUNCTION mnck(integer) TO PUBLIC;


--
-- Name: mngt(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION mngt() FROM PUBLIC;
REVOKE ALL ON FUNCTION mngt() FROM pool;
GRANT ALL ON FUNCTION mngt() TO PUBLIC;


--
-- Name: mnrm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION mnrm(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION mnrm(integer) FROM pool;
GRANT ALL ON FUNCTION mnrm(integer) TO PUBLIC;


--
-- Name: pl(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION pl() FROM PUBLIC;
REVOKE ALL ON FUNCTION pl() FROM pool;
GRANT ALL ON FUNCTION pl() TO PUBLIC;


--
-- Name: syrm(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION syrm(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION syrm(integer, integer) FROM pool;
GRANT ALL ON FUNCTION syrm(integer, integer) TO PUBLIC;


--
-- Name: tr(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION tr(integer, integer, OUT exid integer, OUT extt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION tr(integer, integer, OUT exid integer, OUT extt text) FROM pool;
GRANT ALL ON FUNCTION tr(integer, integer, OUT exid integer, OUT extt text) TO PUBLIC;


--
-- Name: traps(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION traps(integer, integer, OUT ap integer, OUT tt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION traps(integer, integer, OUT ap integer, OUT tt text) FROM pool;
GRANT ALL ON FUNCTION traps(integer, integer, OUT ap integer, OUT tt text) TO PUBLIC;


--
-- Name: trlv(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trlv(integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION trlv(integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) FROM pool;
GRANT ALL ON FUNCTION trlv(integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT tt text) TO PUBLIC;


--
-- Name: trmns(integer, integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trmns(integer, integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION trmns(integer, integer, integer) FROM pool;
GRANT ALL ON FUNCTION trmns(integer, integer, integer) TO PUBLIC;


--
-- Name: trp2(text, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trp2(text, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION trp2(text, integer) FROM pool;
GRANT ALL ON FUNCTION trp2(text, integer) TO PUBLIC;


--
-- Name: trp2(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trp2(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION trp2(integer, integer) FROM pool;
GRANT ALL ON FUNCTION trp2(integer, integer) TO PUBLIC;


--
-- Name: trp2a(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trp2a(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION trp2a(integer, integer) FROM pool;
GRANT ALL ON FUNCTION trp2a(integer, integer) TO PUBLIC;


--
-- Name: trtrmns(integer, integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trtrmns(integer, integer, integer, OUT mn0 integer, OUT mn1 integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION trtrmns(integer, integer, integer, OUT mn0 integer, OUT mn1 integer) FROM pool;
GRANT ALL ON FUNCTION trtrmns(integer, integer, integer, OUT mn0 integer, OUT mn1 integer) TO PUBLIC;


--
-- Name: trtrmnxs(integer, integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trtrmnxs(integer, integer, integer, OUT mn0 integer, OUT ap0 integer, OUT tt0 text, OUT mn1 integer, OUT ap1 integer, OUT tt1 text) FROM PUBLIC;
REVOKE ALL ON FUNCTION trtrmnxs(integer, integer, integer, OUT mn0 integer, OUT ap0 integer, OUT tt0 text, OUT mn1 integer, OUT ap1 integer, OUT tt1 text) FROM pool;
GRANT ALL ON FUNCTION trtrmnxs(integer, integer, integer, OUT mn0 integer, OUT ap0 integer, OUT tt0 text, OUT mn1 integer, OUT ap1 integer, OUT tt1 text) TO PUBLIC;


--
-- Name: trtrms(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trtrms(integer, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION trtrms(integer, integer) FROM pool;
GRANT ALL ON FUNCTION trtrms(integer, integer) TO PUBLIC;


--
-- Name: trtrmxs(integer, integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION trtrmxs(integer, integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) FROM PUBLIC;
REVOKE ALL ON FUNCTION trtrmxs(integer, integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) FROM pool;
GRANT ALL ON FUNCTION trtrmxs(integer, integer, OUT lv integer, OUT lc character, OUT vc smallint, OUT lvtt text, OUT ex integer, OUT extt text) TO PUBLIC;


--
-- Name: usad(text, text, text, text, character); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION usad(text, text, text, text, character) FROM PUBLIC;
REVOKE ALL ON FUNCTION usad(text, text, text, text, character) FROM pool;
GRANT ALL ON FUNCTION usad(text, text, text, text, character) TO PUBLIC;


--
-- Name: usid(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION usid() FROM PUBLIC;
REVOKE ALL ON FUNCTION usid() FROM pool;
GRANT ALL ON FUNCTION usid() TO PUBLIC;


--
-- Name: uspw(integer, character); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION uspw(integer, character) FROM PUBLIC;
REVOKE ALL ON FUNCTION uspw(integer, character) FROM pool;
GRANT ALL ON FUNCTION uspw(integer, character) TO PUBLIC;


--
-- Name: wcad(integer, text); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION wcad(integer, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION wcad(integer, text) FROM pool;
GRANT ALL ON FUNCTION wcad(integer, text) TO PUBLIC;


--
-- Name: wcgt(); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION wcgt() FROM PUBLIC;
REVOKE ALL ON FUNCTION wcgt() FROM pool;
GRANT ALL ON FUNCTION wcgt() TO PUBLIC;


--
-- Name: wcrm(integer); Type: ACL; Schema: public; Owner: pool
--

REVOKE ALL ON FUNCTION wcrm(integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION wcrm(integer) FROM pool;
GRANT ALL ON FUNCTION wcrm(integer) TO PUBLIC;


SET search_path = util, pg_catalog;

--
-- Name: fndoc(name); Type: ACL; Schema: util; Owner: pool
--

REVOKE ALL ON FUNCTION fndoc(name, OUT io "char"[], OUT argns text[], OUT argts oid[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION fndoc(name, OUT io "char"[], OUT argns text[], OUT argts oid[]) FROM pool;
GRANT ALL ON FUNCTION fndoc(name, OUT io "char"[], OUT argns text[], OUT argts oid[]) TO pool;
GRANT ALL ON FUNCTION fndoc(name, OUT io "char"[], OUT argns text[], OUT argts oid[]) TO apache;


--
-- Name: fndoc(text); Type: ACL; Schema: util; Owner: pool
--

REVOKE ALL ON FUNCTION fndoc(text, OUT io "char"[], OUT argns text[], OUT argts oid[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION fndoc(text, OUT io "char"[], OUT argns text[], OUT argts oid[]) FROM pool;
GRANT ALL ON FUNCTION fndoc(text, OUT io "char"[], OUT argns text[], OUT argts oid[]) TO pool;
GRANT ALL ON FUNCTION fndoc(text, OUT io "char"[], OUT argns text[], OUT argts oid[]) TO apache;


--
-- Name: hml(text); Type: ACL; Schema: util; Owner: pool
--

REVOKE ALL ON FUNCTION hml(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION hml(text) FROM pool;
GRANT ALL ON FUNCTION hml(text) TO pool;
GRANT ALL ON FUNCTION hml(text) TO apache;


--
-- Name: mncts(integer); Type: ACL; Schema: util; Owner: pool
--

REVOKE ALL ON FUNCTION mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer) FROM pool;
GRANT ALL ON FUNCTION mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer) TO pool;
GRANT ALL ON FUNCTION mncts(integer, OUT ap integer, OUT mn integer, OUT dns integer) TO apache;


SET search_path = public, pg_catalog;

--
-- Name: af; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE af FROM PUBLIC;
REVOKE ALL ON TABLE af FROM apache;
GRANT ALL ON TABLE af TO apache;
GRANT SELECT ON TABLE af TO reader;


--
-- Name: ap; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE ap FROM PUBLIC;
REVOKE ALL ON TABLE ap FROM apache;
GRANT ALL ON TABLE ap TO apache;
GRANT SELECT ON TABLE ap TO reader;


--
-- Name: dn; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE dn FROM PUBLIC;
REVOKE ALL ON TABLE dn FROM apache;
GRANT ALL ON TABLE dn TO apache;
GRANT SELECT ON TABLE dn TO reader;


--
-- Name: ex; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE ex FROM PUBLIC;
REVOKE ALL ON TABLE ex FROM apache;
GRANT ALL ON TABLE ex TO apache;
GRANT SELECT ON TABLE ex TO reader;


SET search_path = interim, pg_catalog;

--
-- Name: simdns; Type: ACL; Schema: interim; Owner: apache
--

REVOKE ALL ON TABLE simdns FROM PUBLIC;
REVOKE ALL ON TABLE simdns FROM apache;
GRANT ALL ON TABLE simdns TO apache;


--
-- Name: simeq; Type: ACL; Schema: interim; Owner: apache
--

REVOKE ALL ON TABLE simeq FROM PUBLIC;
REVOKE ALL ON TABLE simeq FROM apache;
GRANT ALL ON TABLE simeq TO apache;


--
-- Name: simex; Type: ACL; Schema: interim; Owner: apache
--

REVOKE ALL ON TABLE simex FROM PUBLIC;
REVOKE ALL ON TABLE simex FROM apache;
GRANT ALL ON TABLE simex TO apache;


--
-- Name: simlv; Type: ACL; Schema: interim; Owner: apache
--

REVOKE ALL ON TABLE simlv FROM PUBLIC;
REVOKE ALL ON TABLE simlv FROM apache;
GRANT ALL ON TABLE simlv TO apache;


--
-- Name: simpair; Type: ACL; Schema: interim; Owner: apache
--

REVOKE ALL ON TABLE simpair FROM PUBLIC;
REVOKE ALL ON TABLE simpair FROM apache;
GRANT ALL ON TABLE simpair TO apache;


--
-- Name: simpt; Type: ACL; Schema: interim; Owner: apache
--

REVOKE ALL ON TABLE simpt FROM PUBLIC;
REVOKE ALL ON TABLE simpt FROM apache;
GRANT ALL ON TABLE simpt TO apache;


--
-- Name: simtr; Type: ACL; Schema: interim; Owner: apache
--

REVOKE ALL ON TABLE simtr FROM PUBLIC;
REVOKE ALL ON TABLE simtr FROM apache;
GRANT ALL ON TABLE simtr TO apache;


SET search_path = public, pg_catalog;

--
-- Name: apli; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE apli FROM PUBLIC;
REVOKE ALL ON TABLE apli FROM apache;
GRANT ALL ON TABLE apli TO apache;
GRANT SELECT ON TABLE apli TO reader;


--
-- Name: av; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE av FROM PUBLIC;
REVOKE ALL ON TABLE av FROM apache;
GRANT ALL ON TABLE av TO apache;
GRANT SELECT ON TABLE av TO reader;


--
-- Name: cp; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE cp FROM PUBLIC;
REVOKE ALL ON TABLE cp FROM apache;
GRANT ALL ON TABLE cp TO apache;
GRANT SELECT ON TABLE cp TO reader;


--
-- Name: cu; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE cu FROM PUBLIC;
REVOKE ALL ON TABLE cu FROM apache;
GRANT ALL ON TABLE cu TO apache;
GRANT SELECT ON TABLE cu TO reader;


--
-- Name: df; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE df FROM PUBLIC;
REVOKE ALL ON TABLE df FROM apache;
GRANT ALL ON TABLE df TO apache;
GRANT SELECT ON TABLE df TO reader;


--
-- Name: dfid; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE dfid FROM PUBLIC;
REVOKE ALL ON TABLE dfid FROM apache;
GRANT ALL ON TABLE dfid TO apache;
GRANT SELECT ON TABLE dfid TO reader;


--
-- Name: dm; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE dm FROM PUBLIC;
REVOKE ALL ON TABLE dm FROM apache;
GRANT ALL ON TABLE dm TO apache;
GRANT SELECT ON TABLE dm TO reader;


--
-- Name: dmid; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE dmid FROM PUBLIC;
REVOKE ALL ON TABLE dmid FROM apache;
GRANT ALL ON TABLE dmid TO apache;
GRANT SELECT ON TABLE dmid TO reader;


--
-- Name: dnid; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE dnid FROM PUBLIC;
REVOKE ALL ON TABLE dnid FROM apache;
GRANT ALL ON TABLE dnid TO apache;
GRANT SELECT ON TABLE dnid TO reader;


--
-- Name: exid; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE exid FROM PUBLIC;
REVOKE ALL ON TABLE exid FROM apache;
GRANT ALL ON TABLE exid TO apache;
GRANT SELECT ON TABLE exid TO reader;


--
-- Name: files; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE files FROM PUBLIC;
REVOKE ALL ON TABLE files FROM apache;
GRANT ALL ON TABLE files TO apache;
GRANT SELECT ON TABLE files TO reader;


--
-- Name: fm; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE fm FROM PUBLIC;
REVOKE ALL ON TABLE fm FROM apache;
GRANT ALL ON TABLE fm TO apache;
GRANT SELECT ON TABLE fm TO reader;


--
-- Name: i1; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE i1 FROM PUBLIC;
REVOKE ALL ON TABLE i1 FROM apache;
GRANT ALL ON TABLE i1 TO apache;
GRANT SELECT ON TABLE i1 TO reader;


--
-- Name: lc; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE lc FROM PUBLIC;
REVOKE ALL ON TABLE lc FROM apache;
GRANT ALL ON TABLE lc TO apache;
GRANT SELECT ON TABLE lc TO reader;


--
-- Name: lv; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE lv FROM PUBLIC;
REVOKE ALL ON TABLE lv FROM apache;
GRANT ALL ON TABLE lv TO apache;
GRANT SELECT ON TABLE lv TO reader;


--
-- Name: md; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE md FROM PUBLIC;
REVOKE ALL ON TABLE md FROM apache;
GRANT ALL ON TABLE md TO apache;
GRANT SELECT ON TABLE md TO reader;


--
-- Name: mdid; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE mdid FROM PUBLIC;
REVOKE ALL ON TABLE mdid FROM apache;
GRANT ALL ON TABLE mdid TO apache;
GRANT SELECT ON TABLE mdid TO reader;


--
-- Name: mi; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE mi FROM PUBLIC;
REVOKE ALL ON TABLE mi FROM apache;
GRANT ALL ON TABLE mi TO apache;
GRANT SELECT ON TABLE mi TO reader;


--
-- Name: mn; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE mn FROM PUBLIC;
REVOKE ALL ON TABLE mn FROM apache;
GRANT ALL ON TABLE mn TO apache;
GRANT SELECT ON TABLE mn TO reader;


--
-- Name: mnid; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE mnid FROM PUBLIC;
REVOKE ALL ON TABLE mnid FROM apache;
GRANT ALL ON TABLE mnid TO apache;
GRANT SELECT ON TABLE mnid TO reader;


--
-- Name: pl0; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE pl0 FROM PUBLIC;
REVOKE ALL ON TABLE pl0 FROM apache;
GRANT ALL ON TABLE pl0 TO apache;
GRANT SELECT ON TABLE pl0 TO reader;


--
-- Name: pl1; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE pl1 FROM PUBLIC;
REVOKE ALL ON TABLE pl1 FROM apache;
GRANT ALL ON TABLE pl1 TO apache;
GRANT SELECT ON TABLE pl1 TO reader;


--
-- Name: us; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE us FROM PUBLIC;
REVOKE ALL ON TABLE us FROM apache;
GRANT ALL ON TABLE us TO apache;


--
-- Name: us.us; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL(us) ON TABLE us FROM PUBLIC;
REVOKE ALL(us) ON TABLE us FROM apache;
GRANT SELECT(us) ON TABLE us TO reader;


--
-- Name: us.dt; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL(dt) ON TABLE us FROM PUBLIC;
REVOKE ALL(dt) ON TABLE us FROM apache;
GRANT SELECT(dt) ON TABLE us TO reader;


--
-- Name: us.nm; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL(nm) ON TABLE us FROM PUBLIC;
REVOKE ALL(nm) ON TABLE us FROM apache;
GRANT SELECT(nm) ON TABLE us TO reader;


--
-- Name: us.al; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL(al) ON TABLE us FROM PUBLIC;
REVOKE ALL(al) ON TABLE us FROM apache;
GRANT SELECT(al) ON TABLE us TO reader;


--
-- Name: us.sm; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL(sm) ON TABLE us FROM PUBLIC;
REVOKE ALL(sm) ON TABLE us FROM apache;
GRANT SELECT(sm) ON TABLE us TO reader;


--
-- Name: us.ht; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL(ht) ON TABLE us FROM PUBLIC;
REVOKE ALL(ht) ON TABLE us FROM apache;
GRANT SELECT(ht) ON TABLE us TO reader;


--
-- Name: us.ok; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL(ok) ON TABLE us FROM PUBLIC;
REVOKE ALL(ok) ON TABLE us FROM apache;
GRANT SELECT(ok) ON TABLE us TO reader;


--
-- Name: wc; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE wc FROM PUBLIC;
REVOKE ALL ON TABLE wc FROM apache;
GRANT ALL ON TABLE wc TO apache;
GRANT SELECT ON TABLE wc TO reader;


--
-- Name: wcex; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE wcex FROM PUBLIC;
REVOKE ALL ON TABLE wcex FROM apache;
GRANT ALL ON TABLE wcex TO apache;
GRANT SELECT ON TABLE wcex TO reader;


--
-- Name: wcid; Type: ACL; Schema: public; Owner: apache
--

REVOKE ALL ON TABLE wcid FROM PUBLIC;
REVOKE ALL ON TABLE wcid FROM apache;
GRANT ALL ON TABLE wcid TO apache;
GRANT SELECT ON TABLE wcid TO reader;


--
-- PostgreSQL database dump complete
--

