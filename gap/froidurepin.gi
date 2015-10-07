#
# froidurepin: HPC-GAP froidure-pin
#
# Implementations
#
InstallGlobalFunction( FroidurePinEnumeration,
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

InstallGlobalFunction( FroidurePinEval,
function(fps)
    local e, res;

    e := LookupDictionary(fps, IdentityTransformation);

    res := [];

    repeat
        Add(res, e!.elt);
        e := e.next;
    until e = fail;

    return(res);
end);
