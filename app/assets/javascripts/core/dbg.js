////////////////////////////////////////////////////////////////////////////////
// Simple functions for ment mainly for debugging and testing
//


var dbg = (function()
{

  var me = {};


  ////////////////////////////////////////////////////////////////////////////////
  // Debugging & Testing
  //

  function test()
  {
    console.log("Test!");
  }
  me.test = test;




  ////////////////////////////////////////////////////////////////////////////////
  // Basic Helper Functions
  ////////////////////////////////////////////////////////////////////////////////


  ////////////////////////////////////////////////////////////////////////////////
  // Get a string representing an unknown objects class
  //

  function type(obj)
  {
    if ((obj == undefined) || (obj == null)) {
      return String(obj);
    }
    var myClass = Object.prototype.toString.call(obj);
    if (type.classToType.hasOwnProperty(myClass)) {
      return type.classToType[myClass];
    }
    return "unrecognized object (" + myClass + ")";
  }

  type.classToType = {
    '[object Boolean]':  'boolean',
    '[object Number]':   'number',
    '[object String]':   'string',
    '[object Function]': 'function',
    '[object Array]':    'array',
    '[object Date]':     'date',
    '[object RegExp]':   'regexp',
    '[object Object]':   'object'
  };

  me.type = type;


  ////////////////////////////////////////////////////////////////////////////////
  // Boolean as letter
  //

  function bal(bool)
  {
    return bool ? 'T' : 'F';
  }


  function bals(bools, delim)
  {
    if (delim == undefined) delim = ':';
    var s = '';
    for (var x = 0; x < bools.length; x++) {
      bools[x] = bools[x] ? 'T' : 'F';
    }
    return bools.join(delim);
  }

  me.bal = bal;
  me.bals = bals;


  ////////////////////////////////////////////////////////////////////////////////
  // Get time as string
  //

  function littleTimeHelper(data)
  {
    var s = '', ss;
    for (var x = 0; x < data.length; x++) {
      ss = data[x][0].toString();
      while (ss.length < data[x][1])
        ss = '0' + ss;
      s += ss;
    }
    return s;
  }

  function getSTimeHMS(date)
  {
    if ((date == undefined) || (date == null)) {
      date = new Date();
    }
    return littleTimeHelper(
      [
        [date.getHours(),        2],  [':', 1],
        [date.getMinutes(),      2],  [':', 1],
        [date.getSeconds(),      2],  ['.', 1],
        [date.getMilliseconds(), 3]
      ]
    );
  }

  me.getSTimeHMS = getSTimeHMS;




  ////////////////////////////////////////////////////////////////////////////////
  // Logging Functions
  ////////////////////////////////////////////////////////////////////////////////


  ////////////////////////////////////////////////////////////////////////////////
  // baselog
  //

  function baselog(type, message)
  {
    if ((message == undefined) || (message == null)) {
      message = '';
    }
    console.log("" + type + "[" + getSTimeHMS() + "]: " + message + "");
  }


  ////////////////////////////////////////////////////////////////////////////////
  // lg   - normal
  //

  function lg(message)
  {
    baselog('DBG', message)
  }

  me.lg = lg;


  ////////////////////////////////////////////////////////////////////////////////
  // lgW  - warning
  //

  function lgW(message)
  {
    baselog('WRN', message)
  }

  me.lgW = lg;


  ////////////////////////////////////////////////////////////////////////////////
  // lgE  - error
  //

  function lgE(message)
  {
    baselog('ERR', message)
  }

  me.lgE = lg;




  ////////////////////////////////////////////////////////////////////////////////
  // Finish
  ////////////////////////////////////////////////////////////////////////////////


  // Returning the newly created lib
  return me;

}());




////////////////////////////////////////////////////////////////////////////////
