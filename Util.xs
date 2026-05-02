#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Changes in 5.7 series mean that now IOK is only set if scalar is
   precisely integer but in 5.6 and earlier we need to do a more
   complex test  */
#if PERL_VERSION <= 6
#define DD_is_integer(sv) (SvIOK(sv) && (SvIsUV(val) ? SvUV(sv) == SvNV(sv) : SvIV(sv) == SvNV(sv)))
#else
#define DD_is_integer(sv) SvIOK(sv)
#endif

static int
is_string0( SV *sv )
{
    return SvFLAGS(sv) & (SVf_OK & ~SVf_ROK);
}

static int
is_string( SV *sv )
{
    STRLEN len = 0;
    if( is_string0(sv) )
    {
        const char *pv = SvPV(sv, len);
    }
    return len;
}

static int
is_array( SV *sv )
{
    return SvROK(sv) && ( SVt_PVAV == SvTYPE(SvRV(sv) ) );
}

static int
is_hash( SV *sv )
{
    return SvROK(sv) && ( SVt_PVHV == SvTYPE(SvRV(sv) ) );
}

static int
is_like( SV *sv, const char *like )
{
    int likely = 0;
    if( sv_isobject( sv ) )
    {
        dSP;
        int count;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( sv_2mortal( newSVsv( sv ) ) );
        XPUSHs( sv_2mortal( newSVpv( like, strlen(like) ) ) );
        PUTBACK;

        if( ( count = call_pv("overload::Method", G_SCALAR) ) )
        {
            I32 ax;
            SPAGAIN;

            SP -= count;
            ax = (SP - PL_stack_base) + 1;
            if( SvTRUE(ST(0)) )
                ++likely;
        }

        PUTBACK;
        FREETMPS;
        LEAVE;
    }

    return likely;
}

/* Validate that pv/len is a valid Perl identifier (no ::) */
static int
is_identifier( const char *pv, STRLEN len )
{
    STRLEN i;
    if( len == 0 || !isALPHA(*pv) && *pv != '_' )
        return 0;
    for( i = 1; i < len; i++ )
    {
        if( !isALNUM(pv[i]) )
            return 0;
    }
    return 1;
}

/* Validate that pv/len is a valid Perl class name (identifiers joined by ::) */
static int
is_class( const char *pv, STRLEN len )
{
    STRLEN i;
    if( len == 0 )
        return 0;
    /* first char must be alpha or underscore */
    if( !isALPHA(*pv) && *pv != '_' )
        return 0;
    for( i = 1; i < len; i++ )
    {
        if( pv[i] == ':' )
        {
            /* must be :: followed by \w */
            if( i + 2 >= len || pv[i+1] != ':' )
                return 0;
            i += 2;
            if( !isALNUM(pv[i]) )
                return 0;
        }
        else if( !isALNUM(pv[i]) )
        {
            return 0;
        }
    }
    return 1;
}

MODULE = Params::Util		PACKAGE = Params::Util

void
_STRING(sv)
    SV *sv
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(sv) )
        mg_get(sv);
    if( is_string( sv ) )
    {
        ST(0) = sv;
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

void
_NUMBER(sv)
    SV *sv;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(sv) )
        mg_get(sv);
    if( ( SvIOK(sv) ) || ( SvNOK(sv) ) || ( is_string( sv ) && looks_like_number( sv ) ) )
    {
        ST(0) = sv;
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

## Group 1: String validators

void
_IDENTIFIER(sv)
    SV *sv;
PROTOTYPE: $
ALIAS:
    _IDENTIFIER = 0
    _CLASS      = 1
CODE:
{
    STRLEN len;
    const char *pv;
    if( SvMAGICAL(sv) )
        mg_get(sv);
    if( !is_string0(sv) )
        XSRETURN_UNDEF;
    pv = SvPV(sv, len);
    if( len == 0 )
        XSRETURN_UNDEF;
    if( ix == 0 )
    {
        if( is_identifier(pv, len) )
        {
            ST(0) = sv;
            XSRETURN(1);
        }
    }
    else
    {
        if( is_class(pv, len) )
        {
            ST(0) = sv;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

## Group 2: Numeric validators

void
_POSINT(sv)
    SV *sv;
PROTOTYPE: $
ALIAS:
    _POSINT    = 0
    _NONNEGINT = 1
CODE:
{
    STRLEN len;
    const char *pv;
    STRLEN i;
    if( SvMAGICAL(sv) )
        mg_get(sv);
    if( SvROK(sv) )
        XSRETURN_UNDEF;
    if( !is_string0(sv) )
        XSRETURN_UNDEF;
    pv = SvPV(sv, len);
    if( len == 0 )
        XSRETURN_UNDEF;
    if( ix == 0 )
    {
        /* _POSINT: first digit must be 1-9 */
        if( pv[0] < '1' || pv[0] > '9' )
            XSRETURN_UNDEF;
    }
    else
    {
        /* _NONNEGINT: "0" is ok, otherwise first digit 1-9 */
        if( len == 1 && pv[0] == '0' )
        {
            ST(0) = sv;
            XSRETURN(1);
        }
        if( pv[0] < '1' || pv[0] > '9' )
            XSRETURN_UNDEF;
    }
    for( i = 1; i < len; i++ )
    {
        if( pv[i] < '0' || pv[i] > '9' )
            XSRETURN_UNDEF;
    }
    ST(0) = sv;
    XSRETURN(1);
}

## Group 3: Class dispatchers

void
_CLASSISA(sv, arg)
    SV *sv;
    char *arg;
PROTOTYPE: $$
ALIAS:
    _CLASSISA  = 0
    _CLASSDOES = 1
    _CLASSCAN  = 2
    _SUBCLASS  = 3
CODE:
{
    static const char *methods[] = {"isa", "DOES", "can", "isa"};
    STRLEN svlen;
    const char *pv;
    STRLEN arglen;
    if( SvMAGICAL(sv) )
        mg_get(sv);
    if( !is_string0(sv) )
        XSRETURN_UNDEF;
    pv = SvPV(sv, svlen);
    if( svlen == 0 || !is_class(pv, svlen) )
        XSRETURN_UNDEF;
    if( !arg || ( ( arglen = strlen(arg) ) == 0 ) )
        XSRETURN_UNDEF;

    /* _SUBCLASS: must not be the same class */
    if( ix == 3 && svlen == arglen && strEQ(pv, arg) )
        XSRETURN_UNDEF;

    {
        I32 result = 0;
        int count;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( sv_2mortal( newSVsv( sv ) ) );
        XPUSHs( sv_2mortal( newSVpv( arg, arglen ) ) );
        PUTBACK;

        if( ( count = call_method(methods[ix], G_SCALAR) ) )
        {
            I32 oldax = ax;
            SPAGAIN;
            SP -= count;
            ax = (SP - PL_stack_base) + 1;
            result = SvTRUE(ST(0));
            ax = oldax;
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        if( result )
        {
            ST(0) = sv;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

## Group 4: Instance dispatchers

void
_INSTANCE(ref, arg)
    SV *ref;
    char *arg;
PROTOTYPE: $$
ALIAS:
    _INSTANCE     = 0
    _INSTANCEDOES = 1
    _INSTANCECAN  = 2
CODE:
{
    static const char *methods[] = {"isa", "DOES", "can"};
    STRLEN len;
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) && arg && ( ( len = strlen(arg) ) > 0 ) )
    {
        if( sv_isobject(ref) )
        {
            I32 result = 0;
            int count;

            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs( sv_2mortal( newSVsv( ref ) ) );
            XPUSHs( sv_2mortal( newSVpv( arg, len ) ) );
            PUTBACK;

            if( ( count = call_method(methods[ix], G_SCALAR) ) )
            {
                I32 oldax = ax;
                SPAGAIN;
                SP -= count;
                ax = (SP - PL_stack_base) + 1;
                result = SvTRUE(ST(0));
                ax = oldax;
            }

            PUTBACK;
            FREETMPS;
            LEAVE;

            if( result )
            {
                ST(0) = ref;
                XSRETURN(1);
            }
        }
    }
    XSRETURN_UNDEF;
}

## Group 5: Invocant dispatchers

void
_INVOCANT(sv)
    SV *sv;
PROTOTYPE: $
CODE:
{
    STRLEN len;
    const char *pv;
    if( SvMAGICAL(sv) )
        mg_get(sv);
    /* blessed object? */
    if( SvROK(sv) && sv_isobject(sv) )
    {
        ST(0) = sv;
        XSRETURN(1);
    }
    /* valid class name? */
    if( !is_string0(sv) )
        XSRETURN_UNDEF;
    pv = SvPV(sv, len);
    if( len > 0 && is_class(pv, len) )
    {
        ST(0) = sv;
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

void
_INVOCANTCAN(sv, method)
    SV *sv;
    char *method;
PROTOTYPE: $$
CODE:
{
    STRLEN len;
    const char *pv;
    int is_valid_invocant = 0;
    STRLEN methlen;

    if( SvMAGICAL(sv) )
        mg_get(sv);
    if( !method || ( ( methlen = strlen(method) ) == 0 ) )
        XSRETURN_UNDEF;

    /* blessed object? */
    if( SvROK(sv) && sv_isobject(sv) )
        is_valid_invocant = 1;
    /* valid class name? */
    else if( is_string0(sv) )
    {
        pv = SvPV(sv, len);
        if( len > 0 && is_class(pv, len) )
            is_valid_invocant = 1;
    }

    if( is_valid_invocant )
    {
        I32 result = 0;
        int count;

        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs( sv_2mortal( newSVsv( sv ) ) );
        XPUSHs( sv_2mortal( newSVpv( method, methlen ) ) );
        PUTBACK;

        if( ( count = call_method("can", G_SCALAR) ) )
        {
            I32 oldax = ax;
            SPAGAIN;
            SP -= count;
            ax = (SP - PL_stack_base) + 1;
            result = SvTRUE(ST(0));
            ax = oldax;
        }

        PUTBACK;
        FREETMPS;
        LEAVE;

        if( result )
        {
            ST(0) = sv;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

## Remaining standalone XSUBs

void
_SCALAR0(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) )
    {
        if( ( SvTYPE(SvRV(ref)) <= SVt_PVBM ) && !sv_isobject(ref) )
        {
            ST(0) = ref;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

void
_SCALAR(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) )
    {
        svtype tp = SvTYPE(SvRV(ref));
        if( ( SvTYPE(SvRV(ref)) <= SVt_PVBM ) && (!sv_isobject(ref)) && is_string( SvRV(ref) ) )
        {
            ST(0) = ref;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

void
_REGEX(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) )
    {
        svtype tp = SvTYPE(SvRV(ref));
#if PERL_VERSION >= 11
        if( ( SVt_REGEXP == tp ) )
#else
        if( ( SVt_PVMG == tp ) && sv_isobject(ref)
         && ( 0 == strncmp( "Regexp", sv_reftype(SvRV(ref),TRUE),
                            strlen("Regexp") ) ) )
#endif
        {
            ST(0) = ref;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

void
_ARRAY0(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( is_array(ref) && !sv_isobject(ref) )
    {
        ST(0) = ref;
        XSRETURN(1);
    }

    XSRETURN_UNDEF;
}

void
_ARRAY(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( is_array(ref) && !sv_isobject(ref) && ( av_len((AV *)(SvRV(ref))) >= 0 ) )
    {
        ST(0) = ref;
        XSRETURN(1);
    }
    XSRETURN_UNDEF;
}

void
_ARRAYLIKE(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) )
    {
        if( is_array(ref) || is_like( ref, "@{}" ) )
        {
            ST(0) = ref;
            XSRETURN(1);
        }
    }

    XSRETURN_UNDEF;
}

void
_HASH0(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( is_hash(ref) && !sv_isobject(ref) )
    {
        ST(0) = ref;
        XSRETURN(1);
    }

    XSRETURN_UNDEF;
}

void
_HASH(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( is_hash(ref) && !sv_isobject(ref) && ( HvKEYS(SvRV(ref)) >= 1 ) )
    {
        ST(0) = ref;
        XSRETURN(1);
    }

    XSRETURN_UNDEF;
}

void
_HASHLIKE(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) )
    {
        if( is_hash(ref) || is_like( ref, "%{}" ) )
        {
            ST(0) = ref;
            XSRETURN(1);
        }
    }

    XSRETURN_UNDEF;
}

void
_CODE(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) )
    {
        if( SVt_PVCV == SvTYPE(SvRV(ref)) )
        {
            ST(0) = ref;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

void
_CODELIKE(ref)
    SV *ref;
PROTOTYPE: $
CODE:
{
    if( SvMAGICAL(ref) )
        mg_get(ref);
    if( SvROK(ref) )
    {
        if( ( SVt_PVCV == SvTYPE(SvRV(ref)) ) || ( is_like(ref, "&{}" ) ) )
        {
            ST(0) = ref;
            XSRETURN(1);
        }
    }
    XSRETURN_UNDEF;
}

void
_XScompiled ()
    CODE:
       XSRETURN_YES;
