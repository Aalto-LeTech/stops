#=require affxd


jQuery ->
  affixedSidebar = new affxd.Sidebar(
    '#theleftwrapper',
    '#thecontainer',
    {
      minShowHeight: 80,
      topMargin: 40,
      toStaticWidth: 964
    }
  )
  affixedSidebar.run()
