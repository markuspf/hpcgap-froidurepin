#
# froidurepin: HPC-GAP froidure-pin
#
# This file is a script which compiles the package manual.
#
if fail = LoadPackage("AutoDoc", ">= 2014.03.27") then
    Error("AutoDoc version 2014.03.27 is required.");
fi;

AutoDoc( "froidurepin" : scaffold := true, autodoc := true );

QUIT;
