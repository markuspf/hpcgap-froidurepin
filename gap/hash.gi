InstallMethod( CHooseHashFunction, "for transformations",
        [IsTransformation, IsInt],
function(t, hashlen)
    return rec( func := ORB_HashFunctionForTransformations, data := hashlen );
end);


