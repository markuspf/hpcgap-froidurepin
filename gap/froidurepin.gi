#
# froidurepin: HPC-GAP froidure-pin
#
# Implementations
#
InstallGlobalFunction( NaiveEnumeration,
function(gens)
    local g, u, elts, n, l, last, ngens, NewElt, rulect;

    rulect := 0;
    ngens := Length(gens);

    if ngens = 0 then
        return rec();
    fi;


    u := rec(   elt := IdentityTransformation
              , forward := [1..ngens] * 0
              , back := -1
              , prev := fail
              , next := fail );
    last := u;
    elts := NewDictionary(gens[1], true);
    AddDictionary(elts, IdentityTransformation, u);

    repeat
        for g in [1..Length(gens)] do
            n := u.elt * gens[g];
            l := LookupDictionary(elts, n);

            if l = fail then
                u.forward[g] := rec( elt := n
                                     , forward := [1..ngens] * 0
                                     , back := g
                                     , prev := u
                                     , next := fail );
                AddDictionary(elts, n, u.forward[g]);

                last.next := u.forward[g];
                last := last.next;
            else
                rulect := rulect + 1;
                u.forward[g] := l;
            fi;
        od;
        u := u.next;
    until u = fail;

    return elts;
end);

# Todo: Get rid of superflous generators, but keep a mapping
#       to process if that information is required
InstallGlobalFunction( FroidurePinEnumeration,
function(gens)
    local ngens, depth, u, v, last, elts,
          newelt, i, l,
          nelts, nruls, curlen,
          c, t, b, n, r, s, new, p,
          id;

    ngens := Length(gens);
    if ngens = 0 then
        return fail;
    fi;

    nelts := 0;
    nruls := 0;

    elts := HTCreate(gens[1], rec( treehashsize := 8192 ));

    u := rec( elt := One(gens[1])           # element in U
              , first := 0
              , last := 0                   # last letter
              , suff := fail                # suffix
              , pref := fail                # prefix
              , next := fail                # next element in military order
              , right := [1..ngens] * 0      # red(u * g)
              , rightred := [1..ngens] * 0   # is red(u * g) = u * g?
              , left := [1..ngens] * 0      # red(g * u)
              , length := 0                 # length of u
              );
    id := u;

    HTAdd_TreeHash_C(elts, u.elt, u);

    last := u;

    for i in [1..ngens] do
        l := HTValue_TreeHash_C(elts, gens[i]);

        if l = fail then
            nelts := nelts + 1;
            last.next := rec( elt := gens[i]              # element in U
                          , first := i
                          , last := i                   # last letter
                          , suff := u                   # suffix
                          , pref := u                   # prefix
                          , next := fail                # next element in military order
                          , right := [1..ngens] * 0     # red(u * gens[i])
                          , rightred := [1..ngens] * 0  # is red(u * gens[i]) = u * gens[i]?
                          , left   := [1..ngens] * 0    # red(gens[i] * u)
                          , length := 1                 # length of u
                          );
            last := last.next;
            u.right[i] := last;
            u.rightred[i] := true;
            u.left[i] := last;

            HTAdd_TreeHash_C(elts, gens[i], last);
        else
            nruls := nruls + 1;

            u.right[i] := l;
            u.rightred[i] := false;
        fi;
    od;

    u := HTValue_TreeHash_C(elts, gens[1]);
    v := u;
    curlen := 1;

    repeat
        Print("length: ", curlen, "\n");
        while u <> fail and (u.length = curlen) do
            b := u.first;
            s := u.suff;
            for i in [1..ngens] do
                if s.rightred[i] = false then
                    r := s.right[i];
                    if r.length = 0 then
                        u.right[i] := id.right[b];
                    else
                        c := r.last;
                        t := r.pref;

                        u.right[i] := t.left[b].right[c];
                    fi;
                    u.rightred[i] := false;
                elif s.rightred[i] = true then
                    new := u.elt * gens[i];
                    l := HTValue_TreeHash_C(elts, new);

                    if l = fail then
                        last.next := rec( elt := new
                                        , first := b
                                        , last := i
                                        , pref := u
                                        , suff := s.right[i]
                                        , next := fail
                                        , right := [1..ngens] * 0
                                        , rightred := [1..ngens] * 0
                                        , left := [1..ngens] * 0
                                        , length := u.length + 1
                        );
                        u.right[i] := last.next;
                        u.rightred[i] := true;
                        HTAdd_TreeHash_C(elts, new, last.next);
                        last := last.next;
                    else
                        nruls := nruls + 1;
                        u.right[i] := l;
                        u.rightred[i] := false;
                    fi;
                else
                    Error("this shouldn't happen\n");
                fi;
            od;
            u := u.next;
        od;

        u := v;

        while u <> fail and u.length = curlen do
            p := u.pref;

            for i in [1..ngens] do
                u.left[i] := p.left[i].right[u.last];
            od;
            u := u.next;
        od;

        v := u;
        curlen := curlen + 1;
    until u = fail;
    return elts;
end);


# Lets first try an absolutely naive approach: 
# Shared Hashtable for elements, worker threads
#InstallGlobalFunction( FroidurePinEnumerationParallel,
#function(gens, opt)
#    local ngens, depth, u, v, last, elts,
#          newelt, i, l,
#          nelts, nruls, curlen,
#          c, t, b, n, r, s, new, p,
#          id;
#
#    ngens := Length(gens);
#    if ngens = 0 then
#        return fail;
#    fi;
#
#    nelts := 0;
#    nruls := 0;
#
#    elts := ShareObj(HTCreate(gens[1], rec( treehashsize := 8192 )));
#
#    u := rec( elt := One(gens[1])           # element in U
#              , first := 0
#              , last := 0                   # last letter
#              , suff := fail                # suffix
#              , pref := fail                # prefix
#              , next := fail                # next element in military order
#              , right := [1..ngens] * 0      # red(u * g)
#              , rightred := [1..ngens] * 0   # is red(u * g) = u * g?
#              , left := [1..ngens] * 0      # red(g * u)
#              , length := 0                 # length of u
#              );
#    id := u;
#
#    atomic readwrite do
#       HTAdd(elts, u.elt, u);
#    od;
#
#    last := u;
#
#    for i in [1..ngens] do
#        atomic readonly do
#            l := HTValue(elts, gens[i]);
#        od;
#
#        if l = fail then
#            nelts := nelts + 1;
#            last.next := rec( elt := gens[i]              # element in U
#                          , first := i
#                          , last := i                   # last letter
#                          , suff := u                   # suffix
#                          , pref := u                   # prefix
#                          , next := fail                # next element in military order
#                          , right := [1..ngens] * 0     # red(u * gens[i])
#                          , rightred := [1..ngens] * 0  # is red(u * gens[i]) = u * gens[i]?
#                          , left   := [1..ngens] * 0    # red(gens[i] * u)
#                          , length := 1                 # length of u
#                          );
#            last := last.next;
#            u.right[i] := last;
#            u.rightred[i] := true;
#            u.left[i] := last;
#
#            atomic readwrite do
#                HTAdd(elts, gens[i], last);
#            od;
#        else
#            nruls := nruls + 1;
#
#            u.right[i] := l;
#            u.rightred[i] := false;
#        fi;
#    od;
#
#    atomic readonly do
#        u := HTValue(elts, gens[1]);
#    od;
#
#    v := u;
#    curlen := 1;
#
#    repeat
#        Print("length: ", curlen, "\n");
#        while u <> fail and (u.length = curlen) do
#            b := u.first;
#            s := u.suff;
#            for i in [1..ngens] do
#                if s.rightred[i] = false then
#                    r := s.right[i];
#                    if r.length = 0 then
#                        u.right[i] := id.right[b];
#                    else
#                        c := r.last;
#                        t := r.pref;
#
#                        u.right[i] := t.left[b].right[c];
#                    fi;
#                    u.rightred[i] := false;
#                elif s.rightred[i] = true then
#                    new := u.elt * gens[i];
#                    atomic readonly do l := HTValue(elts, new); od;
#
#                    if l = fail then
#                        last.next := rec( elt := new
#                                        , first := b
#                                        , last := i
#                                        , pref := u
#                                        , suff := s.right[i]
#                                        , next := fail
#                                        , right := [1..ngens] * 0
#                                        , rightred := [1..ngens] * 0
#                                        , left := [1..ngens] * 0
#                                        , length := u.length + 1
#                        );
#                        u.right[i] := last.next;
#                        u.rightred[i] := true;
#
#                        atomic readwrite do HTAdd(elts, new, last.next); od;
#
#                        last := last.next;
#                    else
#                        nruls := nruls + 1;
#                        u.right[i] := l;
#                        u.rightred[i] := false;
#                    fi;
#                else
#                    Error("this shouldn't happen\n");
#                fi;
#            od;
#            u := u.next;
#        od;
#
#        u := v;
#
#        while u <> fail and u.length = curlen do
#            p := u.pref;
#
#            for i in [1..ngens] do
#                u.left[i] := p.left[i].right[u.last];
#            od;
#            u := u.next;
#        od;
#
#        v := u;
#        curlen := curlen + 1;
#    until u = fail;
#    return elts;
#end);


