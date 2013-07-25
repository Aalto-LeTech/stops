

/*
 * Debugging & Testing
 * ===================
 */

function test() {
  console.log("Test!");
};




/*
 * Basic Helper Functions
 * ======================
 */


/*
 * Get a string representing an unknown objects class
 */

var classToType = {
  '[object Boolean]':  'boolean',
  '[object Number]':   'number',
  '[object String]':   'string',
  '[object Function]': 'function',
  '[object Array]':    'array',
  '[object Date]':     'date',
  '[object RegExp]':   'regexp',
  '[object Object]':   'object'
};

function type(obj) {
  if ((obj == undefined) || (obj == null)) {
    return String(obj);
  }
  var myClass = Object.prototype.toString.call(obj);
  if (classToType.hasOwnProperty(myClass)) {
    return classToType[myClass];
  }
  return "unrecognized object (" + myClass + ")";
};


/*
 * Boolean as letter
 */

function bal(bool) {
  return bool ? 'T' : 'F';
};


function bals(bools, delim = ':') {
  var s = '';
  for (var x = 0; x < bools.length; x++) {
    bools[x] = bools[x] ? 'T' : 'F';
  }
  return bools.join(delim);
};


/*
 * Get time as string
 */

function littleTimeHelper(data) {
  var s = '', ss;
  for (var x = 0; x < data.length; x++) {
    ss = data[x][0].toString();
    while (ss.length < data[x][1])
      ss = '0' + ss;
    s += ss;
  }
  return s;
}

function getSTimeHMS(date) {
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
};


/*
 * A simple logging/debugging function
 */

function dbg(message) {
  if ((message == undefined) || (message == null)) {
    message = '';
  }
  console.log("DBG[" + getSTimeHMS() + "]: " + message + "");
};




/*
 * Knockout Extenders
 * ==================
 */


/*
 * Knockout extender: Numeric
 *
 * Supports precision ('precision'), and limits ('min' and 'max').
 *
 * Adapted from: http://knockoutjs.com/documentation/extenders.html
 */

ko.extenders.numeric = function(target, params) {
  // create a writeable computed observable to intercept writes to our observable
  var result = ko.computed({
    read: target,  // always return the original observables value on read
    write: function(newValue) {
      // get the original value and parse the new one
      var current = target(),
          newValueAsNum = (isNaN(newValue) || (newValue == '')) ? 0 : parseFloat(newValue);

      if (params) {
        if (params.hasOwnProperty('precision')) {
          var roundingMultiplier = Math.pow(10, params['precision']),
              newValueAsNum = Math.round(newValueAsNum * roundingMultiplier) / roundingMultiplier;
        }
        if (params.hasOwnProperty('min') && (newValueAsNum < params['min'])) {
          newValueAsNum = params['min'];
        } else if (params.hasOwnProperty('max') && (newValueAsNum > params['max'])) {
          newValueAsNum = params['max'];
        }
      }

      // only write if it changed
      if (newValueAsNum !== current) {
        target(newValueAsNum);
      } else {
        // if the rounded value is the same, but a different value was written, force a notification for the current field
        if (newValue !== current) {
          target.notifySubscribers(newValueAsNum);
        }
      }
    }
  });

  //initialize with current value to make sure it is rounded appropriately
  result(target());

  //return the new computed observable
  return result;
};


/*
 * Knockout extender: Integer (optionally limited)
 */

ko.extenders.integer = function(target, params) {
    // create a writeable computed observable to intercept writes to our observable
    var result = ko.computed({
        read: target,  // always return the original observables value on read
        write: function(newValue) {
            var current = target(),
                newValueAsInt = isNaN(newValue) ? 0 : ((newValue == '') ? 0 : parseInt(newValue));

            // dbg("integer: " + newValueAsInt + " (" + params.toString() + ")");

            if ((params) && (params.hasOwnProperty('min')) && (newValueAsInt < params['min'])) {
              newValueAsInt = params['min'];
            } else if ((params) && (params.hasOwnProperty('max')) && (newValueAsInt > params['max'])) {
              newValueAsInt = params['max'];
            }

            // only write if it changed
            if (newValueAsInt !== current) {
                target(newValueAsInt);
            }
        }
    });

    // initialize with current value
    result(target());

    // return the new computed observable
    return result;
};




/*
 * Knockout Binding Handlers
 * =========================
 */


/*
 * Knockout binding handler: Numeric
 *
 * Displays numbers in a configurable way
 */

ko.bindingHandlers.numeric = {
  update: function(element, valueAccessor, allBindingsAccessor) {
    // First get the latest data that we're bound to
    var value = ko.unwrap(valueAccessor()),
        allBindings = allBindingsAccessor(),
        // Get the specified parameters (or defaults)
        decimals = allBindings.decimals || 9,
        // Format the value as specified
        text = value.toFixed(decimals);

    // Update the DOM
    ko.bindingHandlers.text.update(element, function() { return text; });
  }
};


/*
 * Knockout binding handler: Hover
 *
 * Toggles the given CSS classes on while hovering
 *
 * From: http://stackoverflow.com/questions/9226792/knockoutjs-bind-mouseover-or-jquery
 */

ko.bindingHandlers.hoverToggle = {
    update: function(element, valueAccessor) {
       var css = valueAccessor();

        ko.utils.registerEventHandler(element, "mouseover", function() {
            ko.utils.toggleDomNodeCssClass(element, ko.utils.unwrapObservable(css), true);
        });

        ko.utils.registerEventHandler(element, "mouseout", function() {
            ko.utils.toggleDomNodeCssClass(element, ko.utils.unwrapObservable(css), false);
        });
    }
};


// For reference only:
ko.bindingHandlers.hoverVisible = {
    init: function (element, valueAccessor, allBindingsAccessor) {

        function showOrHideElement(show) {
            var canShow = ko.utils.unwrapObservable(valueAccessor());
            $(element).toggle(show && canShow);
        }

        var hideElement = showOrHideElement.bind(null, false);
        var showElement = showOrHideElement.bind(null, true);
        var $hoverTarget = $("#" + ko.utils.unwrapObservable(allBindingsAccessor().hoverTargetId));
        ko.utils.registerEventHandler($hoverTarget, "mouseover", showElement);
        ko.utils.registerEventHandler($hoverTarget, "mouseout", hideElement);
        hideElement();
    }
};


/*
 * Knockout binding handler: Slide Visible
 *
 * Makes elements slide into and out of existence according to the value of an
 * observable
 *
 * From: http://knockoutjs.com/documentation/custom-bindings.html
 */

ko.bindingHandlers.slideVisible = {
    update: function(element, valueAccessor, allBindingsAccessor) {
        // First get the latest data that we're bound to
        var value = ko.unwrap(valueAccessor()), allBindings = allBindingsAccessor();

        // Grab some more data from another binding property and have a default
        // as a backup
        var duration = allBindings.slideDuration || 400;

        // Now manipulate the DOM element and slide the element either visible
        // or invisible
        if (value == true)
            $(element).slideDown(duration);
        else
            $(element).slideUp(duration);
    }
};
