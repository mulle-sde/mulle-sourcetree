
| Configuration | Bits | static/shared  | Windows Suffix |
|---------------|------|----------------|----------------|
| Release       | 32   | MT             |     ""         |
| Release       | 32   | MD             |     ""  ?      |
| Release       | 64   | MT             |     "64"       |
| Release       | 64   | MD             |     "" ?       |
| Debug         | 32   | MTd            |     "d"        |
| Debug         | 32   | MDd            |     "dMD" ?    |
| Debug         | 64   | MTd            |     "d64"  ?   |
| Debug         | 64   | MDd            |     "dMD64" ?  |
     

## Windows

[StackOverflow](https://stackoverflow.com/questions/56061057/what-does-mt-and-md-stand-for/56062820)

* `/MD`  - Creates a multithreaded DLL using MSVCRT.lib.
* `/MDd` - Creates a debug multithreaded DLL using MSVCRTD.lib.
* `/MT`  - Creates a multithreaded executable file using LIBCMT.lib.
* `/MTd` - Creates a debug multithreaded executable file using LIBCMTD.lib

As we build static libraries, except for debugging, that would be /MT as
the preference.


## Decisions

Windows libraries are built with 'd' suffix if built as library, that seems conventional.
For 64/32 bit there are no different suffixes, user installed libraries into a lib64/lib32 dir
with the same name.

There is per-se no differentiation between MD/MT.
