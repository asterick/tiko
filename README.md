# ![alt text](https://github.com/asterick/tiko/raw/master/doc/tiko.png "Tiko") Tiko

**Tiko** is a Lua (5.1) dialect targeting the [Pico-8 fantasy console](https://www.lexaloffle.com/pico-8.php)

## Primary Goals:
* Provide a 'drop in' build system for working with multiple files in external editors
* Allow users to manage their binary data efficiently, without having to remember things like sprite sheet indexes
* Provide intelligent code size reduction
  * Constant folding
  * Inlining functions and constants
  * Intelligent minification with a focus on token counts
* Increase total code and data limit by using modern compression and custom bytecode functions


## Getting started

**Pre-requisites**:
* [Node LTS](https://nodejs.org/en/download/)

Once node is installed on your machine, you simply have to install the package to your project folder (for ease of use).  

```
npm install https://github.com/asterick/tiko.git
```

To run, simply use the `npx` command

```
npx tiko -h
```

## Running Tiko

**TODO**

## Language extensions
### Read-modify-write operations

Tiko has inherited the `+=`, `-=`, `*=`, `/=`, and `%=` operations from the Pico-8.  They work the same way, 
and are simply a way to reduce the amount of typing involved.  The minifier will attempt to find these operations
and insert them itself, so it is simply syntax sugar.

### Modules

Tiko supports modules with private namespaces, by way of the `using` operation.  The using operation takes a single
argument, either a string or an identifier, which specifies the file name of the source for this module.  If no extension is specified, tiko will simply adopt the file extension of the module loading the file.  For more fine tuned support,
a string can use used to specify the qualified path (relative to the loading source) of the module to be loaded

A name for the module may also be supplied by appending a valid variable name after the directive

```
using "subdir/utils.lua" as utils
```

If no name is specified, the module will be identified by the file name, minus the extension.

All globals defined in a referenced module by be read, modified or replaced by simply accessing it as a property
object `utils.global_prop += 9`

Please note, modules are not objects, and thus cannot be referenced indirectly, nor may properties be created on them

### Virtual functions

Tiko is designed with the intention of allowing users to run much more code, abeit much slower, by specifying 
that a function be considered virtual.  This will create a bytecode function (stored in RAM) that is executed by a small
runtime in the native code.  These calls are significantly slower than native calls, and should only be used for
called that are executed periodically, like scripted or single execution events.

These calls are treated as normal, and execution between virtual and native code is transparent.  Please note that
virtual calls cannot capture closure variables from non-native calls, and vice-versa.

To make a function 'virtual', simply place the `virtual` keyboard before your function definition.  All calls to 
this function will be routed automatically

### Inline functions

Much like virtual functions, it is useful to be able to create macro functions that can be heavily optimized by inlining.
To create an inline function, simply place the `inline` keyword before the function definition.

Please note: inline functions must be named, may not be virtual, cannot capture closure variables, and attempting to pass
it by reference will result in a native call being created

### Fixed named globals

The Pico-8 requires that certain calls be created in the global namespace in order for proper timing to be established.

This is accomplished by applying the `fixed` keyword before a function name to lock the name of this defintion down.

```
fixed function _draw()
circfill(64, 64, 32, 100)
end
```

Any function without the fixed keyword will be mangled

## Importing game data

**TODO**
