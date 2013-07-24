

/*
 * For debugging
 */

function test() {
  console.log("Test!");
};


$("#testhoverme").hover(
  function() {
    $('#testblock').show();
  },
  function() {
    $('#testblock').hide();
  }
);




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
 * Knockout extender: Numeric
 */

ko.extenders.numeric = function(target, precision) {
    //create a writeable computed observable to intercept writes to our observable
    var result = ko.computed({
        read: target,  //always return the original observables value
        write: function(newValue) {
            var current = target(),
                roundingMultiplier = Math.pow(10, precision),
                newValueAsNum = isNaN(newValue) ? 0 : parseFloat(+newValue),
                valueToWrite = Math.round(newValueAsNum * roundingMultiplier) / roundingMultiplier;

            //only write if it changed
            if (valueToWrite !== current) {
                target(valueToWrite);
            } else {
                //if the rounded value is the same, but a different value was written, force a notification for the current field
                if (newValue !== current) {
                    target.notifySubscribers(valueToWrite);
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
 * Knockout extender: Integer
 */

ko.extenders.integer = function(target) {
    // create a writeable computed observable to intercept writes to our observable
    var result = ko.computed({
        read: target,  // always return the original observables value
        write: function(newValue) {
            var current = target(),
                newValueAsInt = isNaN(newValue) ? 0 : ((newValue == '') ? 0 : parseInt(newValue));

            //console.log("Integer: " + current + " -> " + newValueAsInt + "!");

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
