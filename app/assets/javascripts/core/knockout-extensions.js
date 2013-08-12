////////////////////////////////////////////////////////////////////////////////
// Some custom Knockout observable extenders and bindings
//



////////////////////////////////////////////////////////////////////////////////
// Knockout Extenders
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// Knockout extender: Numeric
//
// Supports precision ('precision'), and limits ('min' and 'max').
//
// Adapted from: http://knockoutjs.com/documentation/extenders.html
//

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


////////////////////////////////////////////////////////////////////////////////
// Knockout extender: Integer (optionally limited)
//

ko.extenders.integer = function(target, params) {
  // create a writeable computed observable to intercept writes to our observable
  var result = ko.computed(
  {
    read: target,  // always return the original observables value on read
    write: function(newValue)
    {
      var current = target(),
        newValueAsInt = isNaN(newValue) ? 0 : ((newValue == '') ? 0 : parseInt(newValue));

      // dbg.lg("integer: " + newValueAsInt + " (" + params.toString() + ")");

      if ((params) && (params.hasOwnProperty('min')) && (newValueAsInt < params['min'])) {
        newValueAsInt = params['min'];
      } else if ((params) && (params.hasOwnProperty('max')) && (newValueAsInt > params['max'])) {
        newValueAsInt = params['max'];
      }

      // only write if it changed
      if (newValueAsInt !== current)
      {
        target(newValueAsInt);
      }
    }
  });

  // initialize with current value
  result(target());

  // return the new computed observable
  return result;
};




////////////////////////////////////////////////////////////////////////////////
// Knockout Binding Handlers
////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////
// Knockout binding handler: Numeric
//
// Displays numbers in a configurable way
//

ko.bindingHandlers.numeric = {
  update: function(element, valueAccessor, allBindingsAccessor) {
    // First get the latest data that we're bound to
    var value = ko.unwrap(valueAccessor()),
      allBindings = allBindingsAccessor(),
      // Get the specified parameters (or defaults)
      decimals = allBindings.decimals >= 0 ? allBindings.decimals : 9,
      // Format the value as specified
      text = value.toFixed(decimals);

    // Update the DOM
    ko.bindingHandlers.text.update(element, function() { return text; });
  }
};


////////////////////////////////////////////////////////////////////////////////
// Knockout binding handler: Hover
//
// Toggles an observable boolean while hovering.
// NOT WELL TESTED

ko.bindingHandlers.hover = {
  init: function(element, valueAccessor)
  {
    ko.utils.registerEventHandler(element, "mouseover", function() {
      var value = valueAccessor();
      console.log("Hover -> 1");
      value(true);
    });
    ko.utils.registerEventHandler(element, "mouseout", function() {
      var value = valueAccessor();
      console.log("Hover -> 0");
      value(false);
    });
    console.log("Inited!");
  }
};


////////////////////////////////////////////////////////////////////////////////
// Knockout binding handler: Class Hover
//
// Toggles the given CSS classes on while hovering
//
// From: http://stackoverflow.com/questions/9226792/knockoutjs-bind-mouseover-or-jquery
// NOT WELL TESTED

ko.bindingHandlers.hoverClass = {
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


////////////////////////////////////////////////////////////////////////////////
// NOT WELL TESTED
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


////////////////////////////////////////////////////////////////////////////////
// Knockout binding handler: Slide Visible
//
// Makes elements slide into and out of existence according to the value of an
// observable
//
// From: http://knockoutjs.com/documentation/custom-bindings.html
//
// NOT WELL TESTED

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



////////////////////////////////////////////////////////////////////////////////
// Knockout binding handler: Fade Visible
//
// Makes elements fade into and out of existence according to the value of an
// observable
//
// From: http://knockoutjs.com/examples/animatedTransitions.html
//

ko.bindingHandlers.fadeVisible = {
  init: function(element, valueAccessor) {
    // Initially set the element to be instantly visible/hidden depending on the value
    var value = valueAccessor();
    $(element).toggle(ko.utils.unwrapObservable(value)); // Use "unwrapObservable" so we can handle values that may or may not be observable
  },
  update: function(element, valueAccessor, allBindingsAccessor) {
    // Whenever the value subsequently changes, slowly fade the element in or out
    var value = valueAccessor(),
      allBindings = allBindingsAccessor(),
      // Get the specified parameters (or defaults)
      duration = allBindings.duration > 0 ? allBindings.duration : 400;
    ko.utils.unwrapObservable(value) ? $(element).fadeIn(duration) : $(element).fadeOut(duration);
  }
};




////////////////////////////////////////////////////////////////////////////////
