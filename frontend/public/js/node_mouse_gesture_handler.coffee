class window.NodeMouseGestureHandler
  constructor: (delegate) ->
    @delegate = delegate
    @node_a = null
    @node_b = null

  mouseDown: (d) ->
    if (d3.event.button == @delegate.MOUSE_EVENT_BUTTON_LEFT)
      @node_a = d

      if (@delegate.mode == 'link')
        @delegate.drag_line
          .attr('class', 'drag_line')
          .attr('x1', d.x)
          .attr('y1', d.y)
          .attr('x2', d.x)
          .attr('y2', d.y)
    else if (d3.event.button == @delegate.MOUSE_EVENT_BUTTON_RIGHT)
      e = $(d3.event.target)
      if not e.is('.node')
        e = e.parent('.node')
      if $(e).attr('node-type') == 'backbone'
        return
      @delegate.hideAllPopover()
      $(e).popover
        trigger: 'manual'
        content: Mustache.render(OnenetTemplates.node_popover, {node: d})
        container: 'body'
        html: true
      $(e).popover 'show'

  mouseUp: (d) ->
    if (d3.event.button == @delegate.MOUSE_EVENT_BUTTON_RIGHT)
      return

    if (@node_a) # means the down event happened in a node
      if (@delegate.mode == 'link')
        @node_b = d

        # huh? no link between the same node for you
        if (@node_a == @node_b)
          @resetState()
          return

        link =
          source: @node_a.name
          target: @node_b.name
        @delegate.forceLayout.links().push(link)
        @delegate.validateLinks()

    @delegate.redraw()

  resetState: ->
    @node_a = null
    @node_b = null

