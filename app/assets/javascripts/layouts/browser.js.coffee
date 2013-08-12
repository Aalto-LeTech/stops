#=require affxd


jQuery ->
  affixedSidebar = new affxd.Sidebar(
    '#theleftwrapper',
    '#thecontainer',
    {
      minShowHeight: 80,
      topMargin: 40,
      toStaticWidth: 964,
      unlimitedByMain: true,
      minCheckInterval: 1000
    }
  )
  affixedSidebar.run()
