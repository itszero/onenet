class window.LinkMouseGestureHandler
  constructor: (delegate) ->
    @delegate = delegate

  mouseDown: (d) ->
    if (d3.event.button == @delegate.MOUSE_EVENT_BUTTON_RIGHT)
      e = $(d3.event.target)
      if not e.is('.link')
        e = e.parent('.link')
      @delegate.hideAllPopover()
      $(e).popover
        trigger: 'manual'
        content: Mustache.render(OnenetTemplates.link_popover, {link: d})
        container: 'body'
        html: true
      $(e).popover 'show'

  mouseUp: (d) ->
    return

