////////////////////////////////////////////////////////////////////////////////
// usefuljs.js
//
// A collection of useful often-needed functions and classes.
//




////////////////////////////////////////////////////////////////////////////////
// Array Related
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// Array.removeIf
//
// Removes an element from the array if found.
//

if (typeof(Array.prototype.removeIf) === "undefined")
{
  Array.prototype.removeIf = function(element)
  {
    var index = this.indexOf(element);
    if (index >= 0)
    {
      this.splice(index, 1);
    }
    return this;
  };
}




////////////////////////////////////////////////////////////////////////////////
// String Related
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// String.trim
//
// Add a trimming function to the String class
//
// Removes leading and trailing whitespace.
//
//   " _ foo1 bar ? "  ->  "_ foo1 bar ?"
//

if (typeof(String.prototype.trim) === "undefined")
{
  String.prototype.trim = function()
  {
    return String(this).replace(/^\s+|\s+$/g, '');
  };
}


////////////////////////////////////////////////////////////////////////////////
// String.toASCIIAlnum
//
// Removes non ASCII alphanumeric characters
//
//   " _ foo1 bar ? "  ->  "foo1bar"
//

if (typeof(String.prototype.toASCIIAlnum) === "undefined")
{
  String.prototype.toASCIIAlnum = function()
  {
    return String(this).replace(/[^A-Za-z0-9]/g, '');
  };
}


////////////////////////////////////////////////////////////////////////////////
// String.toTitleCase
//
// Converts a string to "title case" (= MyTitle).
//
//   " _ foo1 bar ? "  ->  " _ Foo1 Bar ? "
//

if (typeof(String.prototype.toTitleCase) === "undefined")
{
  String.prototype.toTitleCase = function()
  {
    return String(this).replace(
      /\w\S*/g,
      function(mtch)
      {
        return mtch.charAt(0).toUpperCase() + mtch.substr(1).toLowerCase();
      }
    );
  };
}


////////////////////////////////////////////////////////////////////////////////
// String.toJSClassNameCase
//
// Converts a string to "class name case".
//
//   " _ foo1 bar ? "  ->  "Foo1Bar"
//   " _ foo 1bar ? "  ->  "Foo1bar"
//   "___foo_bar    "  ->  "FooBar"
//   "My4EverDBClass"  ->  "My4EverDBClass"
//   "my4everdbclass"  ->  "My4everdbclass"
//

if (typeof(String.prototype.toJSClassNameCase) === "undefined")
{
  String.prototype.toJSClassNameCase = function()
  {
    return String(this).replace(/[^A-Za-z0-9]/g, ' ').replace(
      /^[a-z]|\s[a-z]/g,
      function(mtch)
      {
        return mtch.toUpperCase();
      }
    ).replace(/ /g, '');
  };
}


////////////////////////////////////////////////////////////////////////////////
// String.toJSVarNameCase
//
// Converts a string to "js var case".
//
//   " _ foo1 bar ? "  ->  "foo1Bar"
//   " _ foo 1bar ? "  ->  "foo1bar"
//

if (typeof(String.prototype.toJSVarNameCase) === "undefined")
{
  String.prototype.toJSVarNameCase = function()
  {
    str = String(this).toJSClassNameCase();
    return str.charAt(0).toLowerCase() + str.substr(1);
  };
}


////////////////////////////////////////////////////////////////////////////////
// String.toUnderscoreNameCase
//
// Converts a string to "underscore name case".
//
//   " _ foo1 bar ? "  ->  "foo1_bar"
//   " _ foo 1bar ? "  ->  "foo_1bar"
//   " _ FooBar1    "  ->  "foo_bar1"
//   " __foo1bar__  "  ->  "foo1bar"
//

if (typeof(String.prototype.toUnderscoreNameCase) === "undefined")
{
  String.prototype.toUnderscoreNameCase = function()
  {
    return String(this).toJSVarNameCase().replace(
      /[A-Z]/g,
      function(mtch)
      {
        return '_' + mtch.charAt(0).toLowerCase();
      }
    );
  };
}
