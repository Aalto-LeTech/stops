////////////////////////////////////////////////////////////////////////////////
// strings.js
//
// Functions related to strings
//




////////////////////////////////////////////////////////////////////////////////
// Add a trimming function to the String class

if (typeof(String.prototype.trim) === "undefined")
{
  // Removes leading and trailing whitespace.
  //
  //   " _ foo bar ? "  ->  "_ foo bar ?"
  //
  String.prototype.trim = function()
  {
    return String(this).replace(/^\s+|\s+$/g, '');
  };
}


if (typeof(String.prototype.toAlnum) === "undefined")
{
  // Removes non alphanumeric characters
  //
  //   " _ foo bar ? "  ->  "foobar"
  //
  String.prototype.toAlnum = function()
  {
    return String(this).replace(/\W/g, '');
  };
}


if (typeof(String.prototype.toTitleCase) === "undefined")
{
  // Converts a string to "title case" (= MyTitle).
  //
  //   " _ foo bar ? "  ->  " _ Foo Bar ? "
  //
  String.prototype.toTitleCase = function()
  {
    return String(this).replace(
      /\w\S*/g,
      function(txt)
      {
        return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
      }
    );
  };
}


if (typeof(String.prototype.toJSClassNameCase) === "undefined")
{
  // Converts a string to "class name case".
  //
  //   " _ foo bar ? "  ->  "FooBar"
  //
  String.prototype.toJSClassNameCase = function()
  {
    return String(this).toTitleCase().toAlnum();
  };
}


if (typeof(String.prototype.toJSVarNameCase) === "undefined")
{
  // Converts a string to "js var case".
  //
  //   " _ foo bar ? "  ->  "fooBar"
  //
  String.prototype.toJSVarNameCase = function()
  {
    str = String(this).toJSClassNameCase();
    return str.charAt(0).toLowerCase() + str.substr(1);
  };
}


if (typeof(String.prototype.toUnderscoreCase) === "undefined")
{
  // Converts a string to "underscore case". Essentially lowercases upcased
  // characters and prepends them with an underscore. Consider the examples:
  //
  //   FooBar      ->  foo_bar
  //   FBar        ->  f_bar
  //   fooBar      ->  foo_bar
  //   Foobar      ->  foobar
  //   foobar      ->  (unchanged)
  //   foo_bar     ->  (unchanged)
  //   _foo_bar    ->  (unchanged)
  //   foo bar     ->  foo_bar
  //   Foo Bar     ->  foo_bar
  //   Foo  Bar    ->  foo__bar
  //   etc...
  //
  //   In case you don't want excess underscores: trim the strings in advance!
  //
  String.prototype.toUnderscoreCase = function()
  {
    return String(this).replace(
      /[A-Z]/g,
      function(txt)
      {
        return '_' + txt.charAt(0).toLowerCase();
      }
    ).replace(/ /g, '_');
  };
}
