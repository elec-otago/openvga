dnl #
dnl # Assembly helpers.
dnl # All modules should not cause hazards.
dnl #
dnl # Author:	Patrick Suggate
dnl #		patrick@physics.otago.ac.nz
dnl #
dnl
define(`arch', `architecture:$1')dnl
dnl
define(`NOP', `		{,,,}')dnl
dnl # This could be smarter and do a check on $2 to see if a couple of NOPs
dnl # can be saved.
define(`mov',dnl
`NOP
		{		,		,		,$2	}
		{		,		,com	->$1\	,	}
NOP')dnl
define(`call',dnl
`		{$1	->bra	,		,pc	->r15\	,	}
NOP')dnl
define(`branch',dnl
`		{$1	->bra	,		,		,	}
NOP')dnl
dnl
define(`mov2r',dnl
`		{		,		,		,$3	}
		{		,		,com	->$1\	,$4	}
		{		,		,com	->$2\	,	}
NOP')dnl
define(`mov3r',dnl
`		{		,		,		,$4	}
		{		,		,com	->$1\	,$5	}
		{		,		,com	->$2\	,$6	}
		{		,		,com	->$3\	,	}
NOP')dnl
dnl
define(`mov4r',dnl
`		{		,		,		,$5	}
		{		,		,com	->$1\	,$6	}
		{		,		,com	->$2\	,$7	}
		{		,		,com	->$3\	,$8	}
		{		,		,com	->$4\	,	}
NOP')dnl
dnl
define(`pushi',dnl
`		{		,		,		,$1	}
		{\r14	->wad	,1	->sub	,com	->mem	,\r14	}
		{		,		,		,	}
		{		,		,diff	->r14\	,	}
		{		,		,		,	}')dnl
dnl
define(`popi',dnl
`		{		,		,		,	}
		{		,-1	->sub	,		,\r14	}
		{		,		,		,	}
		{		,		,diff	->r14\	,diff	}
		{com	->rad	,		,		,	}
		{		,		,		,mem	}
		{		,		,com	->$1\	,	}
NOP')dnl
dnl
define(`lea',dnl
`		{		,		,		,eval($2/128)	}
		{		,		,com	->mul	,128	}
		{		,		,		,	}
		{		,eval($2%128)	->or	,		,plo	}
		{		,		,		,	}
		{		,		,		,bits	}
		{		,		,com	->$1\	,	}
NOP')dnl
dnl