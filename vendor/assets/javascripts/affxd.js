////////////////////////////////////////////////////////////////////////////////
// affxd V1.1 (c) smarisa 2013-08-05
//
// Usage:
//   var affixedSidebar = new affxd.Sidebar(
//     '#theleftwrapper',
//     '#thecontainer',
//     {
//       minShowHeight: 80,
//       topMargin:     40,
//       toStaticWidth: 964
//     }
//   );
//   affixedSidebar.run();
//
////////////////////////////////////////////////////////////////////////////////


var affxd = (function()
{
  var me = {};

  ////////////////////////////////////////////////////////////////////////////////
  // The Constructor

  function AffixedSidebar( targetElement, mainElement, options )
  {
    // Core variables
    this.targetElement   = $(targetElement);
    this.mainElement     = $(mainElement);
    this.hidden          = false;
    this.static          = false;
    this.status          = undefined;

    // Option related variables
    this.fixedTopElement   = undefined;
    this.minShowHeight     = 0;
    this.topMargin         = 0;
    this.toStaticWidth     = 0;
    this.staticHeight      = 'auto';
    this.minCheckInterval  = undefined;
    this.unlimitedByMain   = false;

    if (options != undefined)
    {
      if (options.hasOwnProperty('minShowHeight'))
        this.minShowHeight = options.minShowHeight;
      if (options.hasOwnProperty('topMargin'))
        this.topMargin = options.topMargin;
      if (options.hasOwnProperty('fixedTopElement'))
        this.fixedTopElement = $(options.fixedTopElement);
      if (options.hasOwnProperty('toStaticWidth'))
        this.toStaticWidth = options.toStaticWidth;
      if (options.hasOwnProperty('staticHeight'))
        this.staticHeight = options.staticHeight;
      if (options.hasOwnProperty('minCheckInterval'))
        this.minCheckInterval = options.minCheckInterval;
      if (options.hasOwnProperty('unlimitedByMain'))
        this.unlimitedByMain = options.unlimitedByMain;
    }

    AffixedSidebar.instances.push(this);
  }


  ////////////////////////////////////////////////////////////////////////////////
  // The Update Function

  AffixedSidebar.prototype.update = function ()
  {
    //console.log('AffixedSidebar::update()!');
    if ($(window).width() <= this.toStaticWidth)
    {
      if (this.static == false)
      {
        //console.log('AffixedSidebar::update(): -> static (height -> ' + this.staticHeight + ')');
        this.targetElement.height(this.staticHeight);
        this.status = 'static';
        this.static = true;
      }
      return;
    } else if (this.static)
    {
      this.static = false;
    }

    var winHeight = $(window).height();
    var fixedTopElementHeight = (this.fixedTopElement != undefined) ? this.fixedTopElement.height() : this.topMargin;
    var winScrollTop = $(window).scrollTop() + fixedTopElementHeight;
    var mainElementTop = this.mainElement.offset().top;
    var upperLimit = mainElementTop;
    var lowerLimit = (this.unlimitedByMain) ? 99999 : mainElementTop + this.mainElement.height();
    var newTop, newHeight;

    //console.log("upper: " + upperLimit + ".");
    //console.log("lower: " + lowerLimit + ".");

    if (winScrollTop < upperLimit)
    {
      this.status = 'top';
      newTop      = upperLimit;
      newHeight   = winHeight - (upperLimit - winScrollTop);
    }
    else if (winScrollTop + winHeight - fixedTopElementHeight < lowerLimit)
    {
      this.status = 'between';
      newTop      = winScrollTop;
      newHeight   = winHeight - fixedTopElementHeight;
    }
    else
    {
      this.status = 'bottom';
      newTop      = winScrollTop;
      newHeight   = lowerLimit - winScrollTop;
    }

    if (newHeight > this.minShowHeight)
    {
      if (this.hidden)
      {
        this.targetElement.show();
        this.hidden = false;
      }
      this.targetElement.css( { top: newTop } );
      this.targetElement.height( newHeight );
    }
    else
    {
      this.status = 'hidden';
      this.hidden = true;
      this.targetElement.hide();
    }
  }


  ////////////////////////////////////////////////////////////////////////////////
  // The Run Function

  AffixedSidebar.prototype.run = function ()
  {
    // Update for the initial view
    this.update();

    var _this = this;

    // Bind the update function to the window resize event
    $(window).resize(
      function ()
      {
        _this.update();
      }
    );

    // Bind the update function to the window scroll event
    $(window).scroll(
      function ()
      {
        _this.update();
      }
    );

    // If a min check interval was specified, start the check loop
    if (this.minCheckInterval > 0)
      setInterval(
        function ()
        {
          _this.update();
        },
        this.minCheckInterval
      );
  }


  ////////////////////////////////////////////////////////////////////////////////
  // A Getter Function

  AffixedSidebar.prototype.get = function ()
  {
    return AffixedSidebar.instances[0];
  }


  AffixedSidebar.instances = [];


  ////////////////////////////////////////////////////////////////////////////////
  // Module functions

  // Add the Sidebar constructor as the only method in the module
  me.Sidebar = AffixedSidebar;


  return me;

}());




////////////////////////////////////////////////////////////////////////////////
