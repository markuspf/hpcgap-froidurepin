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

    elts := NewDictionary(gens[1], true);

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

    AddDictionary(elts, u.elt, u);

    last := u;

    for i in [1..ngens] do
        l := LookupDictionary(elts, gens[i]);

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

            AddDictionary(elts, gens[i], last);
        else
            nruls := nruls + 1;

            u.right[i] := l;
            u.rightred[i] := false;
        fi;
    od;

    u := LookupDictionary(elts, gens[1]);
    v := u;
#    last := LookupDictionary(elts, gens[ngens]);
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
                    l := LookupDictionary(elts, new);

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
                        AddDictionary(elts, new, last.next);
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

        if curlen = 1 then
            while u.length = curlen do
                for i in [1..ngens] do
                    u.left[i] := id.right[i].right[u.first];
                od;
                u := u.next;
            od;
        else
            while u <> fail and u.length = curlen do
                p := u.pref;

                for i in [1..ngens] do
                    u.left[i] := p.left[i].right[u.last];
                od;
                u := u.next;
            od;
        fi;

        v := u;
        curlen := curlen + 1;
    until u = fail;
    return elts;
end);


InstallGlobalFunction( FroidurePinEval,
function(fps)
    local e, root, res, words, TraceBack;

    root := LookupDictionary(fps, IdentityTransformation);
    e := root;

    TraceBack := function(elt)
        local f, res;

        res := [];
        f := elt;

        while f.back <> -1 do
            Add(res, f.back);
            f := f.prev;
        od;
        return res;
    end;

    res := [];
    words := [];

    repeat
        Add(res, e!.elt);
        Add(words, TraceBack(e));
        e := e.next;
    until e = fail;

    return([res, words]);
end);
