architecture:oTTAnic1

       {,,,,,,}
       {,,,,,,}
       {        ,       ,                ,                ,               , 21\>  ,                  }
       {        ,       ,                ,                ,               ,     \>r0,                  }
       {        ,       ,                ,                , mem->r0       ,       ,                }
       {        ,       ,                ,                , mem->r0       ,       ,                }
       {        ,       ,                ,                , mem->r1       ,       ,                }
       {        ,       ,                ,                , mem->r1       ,       ,     r1\>           }
       {        ,       ,                ,                , mem->r1       ,       ,     r1\> cycle          }
       {        ,       ,                ,                , mem->r1       ,       ,     r1\> cycle          }
       {        ,       ,                ,                , mem->r1       ,       ,     r1\> cycle          }
       {        ,       ,                ,                , mem->r1       ,       ,     r1\> io         }
       {        ,       ,                ,                , mem->r1       ,       ,     r1\> cycle          }
       {        ,       ,                ,                , mem->r0       ,       ,     r1\> cycle          }
       {        ,       ,                ,                ,               ,       ,     \> cycle          }
       {        ,       ,                , cycle->sub1    , mem->r8              ,           ,     }


       {        ,       , r8->sub0       , cycle->sub1    , mem->r9              ,           ,     }
       {        ,       , r9->sub0       , cycle->sub1    , mem->r10             ,          ,  }
       {        ,       , r10->sub0      , cycle->sub1    , mem->r0              , sout\>       ,     }
       {        ,cycle->mult       ,                ,                ,               , sout\>r2       , branch (start:start:start)     }
       {        ,cycle->mult       , r8->sub0       , mem->sub1      , mem->r12      , sout\>r1       ,     }
       {        ,cycle->mult       , r9->sub0       , mem->sub1      , mem->r13      ,     \>r3       , }


/*
// A=r8,r9,r10
// B=r12,r13,r14 / r18,r19,r20
// Tag=r15
// Prev=r16
// Free:r3,r5,r7
// branch = < >
*/

state0a:{ r1->mul0   , cycle->macc, r8->sub0  , mem->sub1  , mem->r12  , sout\>r1   ,    \> cmpz     }
        { mout->mul0 , cycle->macc, r9->sub0  , mem->sub1  , mem->r13  ,     \>r3   ,                }
start:  { r1->mul0   , sout->mult , r10->sub0 , mem->sub1  , mem->r14  , sout\>     ,                }
        { r2->mul0   , sout->mdep ,           ,            , mem->r15  , sout\>r2   ,                }
        {            , sout->mult ,           ,            , mout->r16 , sout\>r4   , r16\>          }
        { r3->mul0   , r2->mdep   , r8->sub0  , cycle->sub1,           ,     \>r3   ,    \> cmp_hit  }
        {            , r4->mult   , r9->sub0  , cycle->sub1,           , mout\>     ,                }
        { r1->mul0   , r3->mdep   , r10->sub0 , cycle->sub1,           , sout\>r1   ,                }
        { mout->mul0 , cycle->mult,           ,            ,           , sout\>r2   , r15\>          }
state0b:{ r1->mul0   , cycle->macc, r8->sub0  , mem->sub1  , mem->r18  , sout\>r1   ,    \> cmpz     }
        { mout->mul0 , cycle->macc, r9->sub0  , mem->sub1  , mem->r19  ,     \>r3   ,                }
        { r1->mul0   , sout->mult , r10->sub0 , mem->sub1  , mem->r20  , sout\>     ,                }
        { r2->mul0   , sout->mdep ,           ,            , mem->r15  , sout\>r2   ,                }
        {            , sout->mult ,           ,            , mout->r16 , sout\>r4   , r16\>          }
        { r3->mul0   , r2->mdep   , r8->sub0  , cycle->sub1,           ,     \>r3   ,    \> cmp_hit  }
        {            , r4->mult   , r9->sub0  , cycle->sub1,           , mout\>     , branch (state0a:state0a:state0a) }
        { r1->mul0   , r3->mdep   , r10->sub0 , cycle->sub1,           , sout\>r1   ,                }
        { mout->mul0 , cycle->mult,           ,            ,           , sout\>r2   , r15\>          }

/* slide block
state0a:{ r1->mul0   , cycle->macc, r8->sub0  , mem->sub1  , mem->r12  , sout\>r1   ,    \> cmpz     }
        { mout->mul0 , cycle->macc, r9->sub0  , mem->sub1  , mem->r13  ,     \>r3   , branch maybe0:cont0a:between_a}
start:  { r1->mul0   , sout->mult , r10->sub0 , mem->sub1  , mem->r14  , sout\>     ,                }
        { r2->mul0   , sout->mdep ,           ,            , mem->r15  , sout\>r2   ,                }
cont0a: {            , sout->mult ,           ,            , mout->r16 , sout\>r4   , r16\>          }
        { r3->mul0   , r2->mdep   , r8->sub0  , cycle->sub1,           ,     \>r3   ,    \> cmp_hit  }
        {            , r4->mult   , r9->sub0  , cycle->sub1,           , mout\>     , branch data_done:state0b:next_fan_a}
        { r1->mul0   , r3->mdep   , r10->sub0 , cycle->sub1,           , sout\>r1   ,                }
        { mout->mul0 , cycle->mult,           ,            ,           , sout\>r2   , r15\>          }
state0b:{ r1->mul0   , cycle->macc, r8->sub0  , mem->sub1  , mem->r18  , sout\>r1   ,    \> cmpz     }
        { mout->mul0 , cycle->macc, r9->sub0  , mem->sub1  , mem->r19  ,     \>r3   , branch maybe1:cont0b:between_b}
        { r1->mul0   , sout->mult , r10->sub0 , mem->sub1  , mem->r20  , sout\>     ,                }
        { r2->mul0   , sout->mdep ,           ,            , mem->r15  , sout\>r2   ,                }
cont0b: {            , sout->mult ,           ,            , mout->r16 , sout\>r4   , r16\>          }
        { r3->mul0   , r2->mdep   , r8->sub0  , cycle->sub1,           ,     \>r3   ,    \> cmp_hit  }
        {            , r4->mult   , r9->sub0  , cycle->sub1,           , mout\>     , branch data_done:state0c:next_fan_b}
        { r1->mul0   , r3->mdep   , r10->sub0 , cycle->sub1,           , sout\>r1   ,                }
        { mout->mul0 , cycle->mult,           ,            ,           , sout\>r2   , r15\>          }
state0c:{ r1->mul0   , cycle->macc, r8->sub0  , mem->sub1  , mem->r21  , sout\>r1   ,    \> cmpz     }
        { mout->mul0 , cycle->macc, r9->sub0  , mem->sub1  , mem->r22  ,     \>r3   , branch maybe2:cont0c:between_c}
        { r1->mul0   , sout->mult , r10->sub0 , mem->sub1  , mem->r23  , sout\>     ,                }
        { r2->mul0   , sout->mdep ,           ,            , mem->r15  , sout\>r2   ,                }
cont0c: {            , sout->mult ,           ,            , mout->r16 , sout\>r4   , r16\>          }
        { r3->mul0   , r2->mdep   , r8->sub0  , cycle->sub1,           ,     \>r3   ,    \> cmp_hit  }
        {            , r4->mult   , r9->sub0  , cycle->sub1,           , mout\>     , branch data_done:state0a:next_fan_c}
        { r1->mul0   , r3->mdep   , r10->sub0 , cycle->sub1,           , sout\>r1   ,                }
        { mout->mul0 , cycle->mult,           ,            ,           , sout\>r2   , r15\>          }
*/

/* Template block
       { r1->mul0       , sout->mul1     , r10->sub0      , mem->sub1      , mem->r14       , sout\>         ,                }
       { r2->mul0       , sout->mul1_dep ,                ,                , mem->r15       , sout\>r2       ,                }
       {                , sout->mul1     ,                ,                , mout->r16      , sout\>r4       , r16\>          }
start: { r0->mul0       , r5->mul1_dep   , r8->sub0       , cycle->sub1    ,                ,     \>r0       ,    \> cmpe     }
       {                , r4->mul1       , r9->sub0       , cycle->sub1    ,                , mout\>         , branch start:start:start }
       { r1->mul0       , r0->mul1_dep   , r10->sub0      , cycle->sub1    ,                , sout\>r1       ,                }
       { mout->mul0     , cycle->mul1    ,                ,                ,                , sout\>r2       , r15\>          }
       { r1->mul0       , cycle->mul1_acc, r8->sub0       , mem->sub1      , mem->r12       , sout\>r1       ,    \> cmpz     }
       { mout->mul0     , cycle->mul1_acc, r9->sub0       , mem->sub1      , mem->r13       ,     \>r0       , branch start:start:start }
*/

