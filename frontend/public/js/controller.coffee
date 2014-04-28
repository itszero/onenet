class window.OnenetController
  constructor: (width, height, top)->
    @MOUSE_EVENT_BUTTON_LEFT = 0
    @MOUSE_EVENT_BUTTON_RIGHT = 2
    @nodeMouseGestureHandler = new NodeMouseGestureHandler(this)
    @linkMouseGestureHandler = new LinkMouseGestureHandler(this)

    # root svg element
    @canvas = d3.select('#canvas-container').append('svg:svg')
      .attr('width', width)
      .attr('height', height)
      .attr('pointer-events', 'all')
      .style('position', 'absolute')
      .style('top', top + 'px')
      .style('left', '0')
      .style('z-index', '20')

    @vis = @canvas
      .append('svg:g')
      .append('svg:g')
        .on("mousemove", @mousemove.bind(this))
        .on("mousedown", @mousedown.bind(this))
        .on("mouseup", @mouseup.bind(this))

    # give it a white background
    @vis.append('svg:rect')
      .attr('width', width)
      .attr('height', height)
      .attr('fill', 'white')

    @forceLayout = d3.layout.force()
      .size([width, height])
      .nodes([{name: 'backbone', type: 'backbone', pno: -1}])
      .links([])
      .linkDistance((d) =>
        types = [@_findNodeByName(d.source).type, @_findNodeByName(d.target).type].sort()
        if (types[0] == 'switch' and types[1] == 'switch')
          300
        else if (types[0] == 'backbone' or types[1] == 'backbone')
          50
        else
          100
      )
      .charge(-1000)
      .on("tick", @tick.bind(this))

    # a line for dragging
    @drag_line = @vis.append("line")
      .attr("class", "drag_line")
      .attr("x1", 0)
      .attr("y1", 0)
      .attr("x2", 0)
      .attr("y2", 0)

    # block context menu
    $('#canvas-container').on 'contextmenu', (e) ->
      e.preventDefault()

    @redraw()
    @setMode('cursor')

    @bindNodePopoverToolbar()
    @bindLinkPopoverToolbar()
    @bindEditor()
    @bindDeployDialog()

  bindEditor: ->
    $(document).on 'click', '.onenet-editor-btn', (e) =>
      elm = e.target
      if not $(elm).is('button')
        elm = $(elm).parent('button')
      save_to = $(elm).data('save-to').split(",")
      action = $(elm).data('action')
      switch action
        when "save"
          fields = $(elm).data('fields').split(',').map (e) -> e.split(':')
          fields.forEach (e) =>
            from = e[0]
            to = e[1]
            switch save_to[0]
              when "node"
                @_findNodeByName(save_to[1])[to] = $("##{from}").val()
              when "link"
                @_findLinkByPair(save_to[1], save_to[2])[to] = $("##{from}").val()
          @redraw()
          $('#onenet-modal .modal').modal('hide')

  bindDeployDialog: ->
    $('.onenet-btn-deploy').click (e) =>
      @deploy()

  bindNodePopoverToolbar: ->
    $(document).on 'click', '.onenet-node-popover-btn', (e) =>
      elm = e.target
      if not $(elm).is('button')
        elm = $(elm).parent('button')
      node_name = $(elm).data('node-name')
      action = $(elm).data('action')
      switch action
        when "delete"
          nodes = @forceLayout.nodes().filter (n) ->
            n.name != node_name
          links = @forceLayout.links().filter (l) ->
            l.source != node_name and l.target != node_name
          @forceLayout.nodes(nodes).links(links)
          @redraw()
        when "edit"
          @showNodeEditor(node_name)
      @hideAllPopover()

  bindLinkPopoverToolbar: ->
    $(document).on 'click', '.onenet-link-popover-btn', (e) =>
      elm = e.target
      if not $(elm).is('button')
        elm = $(elm).parent('button')
      link_src = $(elm).data('link-src')
      link_dst = $(elm).data('link-dst')
      action = $(elm).data('action')
      switch action
        when "delete"
          links = @forceLayout.links().filter (l) ->
            l.source != link_src and l.target != link_dst
          @forceLayout.links(links)
          @redraw()
        when "edit"
          @showLinkEditor(link_src, link_dst)
      @hideAllPopover()

  showNodeEditor: (node_name) ->
    elm = $("g[data-node-name=\"#{node_name}\"]")
    node = @_findNodeByName(node_name)
    content = Mustache.render(OnenetTemplates.node_edit_modal, { node: node })
    $('#onenet-modal').html(content)
    $('#onenet-modal .modal').modal({show: true})

  showLinkEditor: (link_src, link_dst) ->
    elm = $("line[data-link-src=\"#{link_src}\", data-link-dst=\"#{link_dst}\"]")
    link = @_findLinkByPair(link_src, link_dst)
    content = Mustache.render(OnenetTemplates.link_edit_modal, { link: link })
    $('#onenet-modal').html(content)
    $('#onenet-modal .modal').modal({show: true})

  hideAllPopover: ->
    if $('.popover').length > 0
      $('svg g, svg line').popover('hide')

  redraw: ->
    @_updateNodes()
    @_updateLink()

    if (d3.event)
      d3.event.preventDefault()

    @forceLayout.start()

  # event handlers

  tick: ->
    @vis.selectAll(".link")
      .attr("x1", (d) => @_findNodeByName(d.source).x )
      .attr("y1", (d) => @_findNodeByName(d.source).y )
      .attr("x2", (d) => @_findNodeByName(d.target).x )
      .attr("y2", (d) => @_findNodeByName(d.target).y )

    @vis.selectAll(".node")
      .attr "transform", (d) -> "translate(#{d.x}, #{d.y})"

  rescale: ->
    trans = d3.event.translate;
    scale = d3.event.scale;

    @vis.attr "transform", "translate(#{trans}) scale(#{scale})"

  mousedown: ->
    d3.event.preventDefault()

    if (d3.event.button != @MOUSE_EVENT_BUTTON_LEFT)
      return

    @hideAllPopover()

    if (@mode == 'host' || @mode == 'switch')
      p = d3.mouse(d3.event.target)
      prefix = switch @mode
        when 'host' then 'h'
        when 'switch' then 's'
      node = {type: @mode, name: @_nextEmptyNodeName(prefix), x: p[0], y: p[1]}
      @forceLayout.nodes().push(node)
      @redraw()

  mousemove: ->
    if (@nodeMouseGestureHandler.node_a) # dragging from a node
      p = d3.mouse(@vis[0][0])
      if (@mode == 'link')
        @drag_line
          .attr('x1', @nodeMouseGestureHandler.node_a.x)
          .attr('y1', @nodeMouseGestureHandler.node_a.y)
          .attr('x2', p[0])
          .attr('y2', p[1])

  mouseup: ->
    if (@mode == 'link')
      # end of drag: not up in a node
      if (@nodeMouseGestureHandler.node_a and !@nodeMouseGestureHandler.node_b)
        @drag_line.transition()
          .each('end', => @drag_line.attr('class', 'drag_line_hidden'))
          .attr('x2', @drag_line.attr('x1'))
          .attr('y2', @drag_line.attr('y1'))
      else
        @drag_line.attr('class', 'drag_line_hidden')
    @nodeMouseGestureHandler.resetState()

  # toolbar handlers

  setMode: (mode) ->
    if (mode == 'cursor')
      @enableDrag()
    else
      @disableDrag()

    @mode = mode

  clear: ->
    @forceLayout.nodes([]).links([])
    @_updateNodes()

  deploy: ->
    layout_nodes = @forceLayout.nodes()
    nodes = layout_nodes.filter((n) -> n.type == 'host').map((n) -> (new Host(n)).toJSON())
    switches = layout_nodes.filter((n) -> n.type == 'switch').map((n) -> (new Switch(n)).toJSON())
    links = @forceLayout.links().map((l) -> (new Link(l)).toJSON())
    data =
      nodes: nodes
      switches: switches
      links: links
      code:
        experiment: ace.edit('editor-exp').getSession().getValue()
        controller: ace.edit('editor-controller').getSession().getValue()

    console.log(JSON.stringify(data))
    $.post '/deploy', {data: JSON.stringify(data)}, (resp) ->
      $('#onenet-deploy-modal').modal('hide')
      new OnenetDeployDashboard(data, resp.deploy_id)
    , 'json'

  # utils

  validateLinks: ->
    nodes = @forceLayout.nodes()
    links = @forceLayout.links()

    nodes.forEach (e) -> e.pno = -1
    @_findConnectedNodes('backbone').forEach((e, i) => @_floodFillPno(e, i, ['backbone']))

    links = links.filter((l) =>
      (l.source == 'backbone' or l.target == 'backbone') or
      (@_findNodeByName(l.source).pno == @_findNodeByName(l.target).pno) )
    @forceLayout.nodes(nodes).links(links)

  _findConnectedNodes: (name) ->
    @forceLayout.links().filter((l) -> l.source == name or l.target == name)
      .map((l) =>
        if l.source == name
          @_findNodeByName(l.target)
        else
          @_findNodeByName(l.source)
      )

  _floodFillPno: (n, pno, v) ->
    if (n.pno >= 0 and n.pno != pno)
      n.pno = pno
      return
    else if (n.name in v)
      return

    n.pno = pno
    v.push(n.name)
    @_findConnectedNodes(n.name).forEach((e) => @_floodFillPno(e, pno, v))

  enableDrag: ->
    @vis.selectAll(".node").call(@forceLayout.drag)

  disableDrag: ->
    @vis.selectAll(".node").on(".force", null).on(".drag", null)

  _updateNodes: ->
    layout_nodes = @forceLayout.nodes()
    nodes = @vis.selectAll(".node").data(layout_nodes)
    colors = d3.scale.category10().domain([0,1,2,3,4,5,6,7,8,9])

    nodes.enter().insert("g")
      .attr('class', 'node')
      .attr('data-node-name', (d) -> d.name)
      .attr('data-node-type', (d) -> d.type)
      .attr('data-target', '#onenet-modal')
      .on('mousedown', @nodeMouseGestureHandler.mouseDown.bind(@nodeMouseGestureHandler))
      .on('mouseup', @nodeMouseGestureHandler.mouseUp.bind(@nodeMouseGestureHandler))
      .call (sel) ->
        sel.each (d) ->
          node = d3.select(this)

          node.append('circle')
            .attr('r', 0)
            .style('fill', (d) ->
              if d.pno < 0
                'black'
              else if d.pno >= 10 or not d.pno?
                'darkgray'
              else
                color(d.pno)
            )
            .transition()
              .duration(750)
              .ease('elastic')
              .attr('r', 20)

          node.append('text')
            .attr('dx', '-7')
            .attr('dy', '7')
            .attr('class', 'node_icon')
            .style('font-family', 'SSStandard')
            .style('fill', 'white')
            .style('opacity', 0)
            .text((d) ->
              if (d.type == 'host')
                '💻'
              else if (d.type == 'switch')
                '🌎'
              else if (d.type == 'backbone')
                '☁'
            )
            .transition()
              .duration(250)
              .style('opacity', 1)

          node.append('text')
            .attr('dx', -7)
            .attr('dy', 35)
            .attr('class', 'node_name')
            .text( (d) ->
              if (d.type == 'backbone')
                ''
              else
                d.name
            )
            .style('fill', 'black')
            .style('opacity', 0)
            .transition()
              .duration(250)
              .style('opacity', 1)

    nodes.call (sel) ->
        sel.each (d) ->
          node = d3.select(this)
          node.attr('data-node-name', (d) -> d.name)
          node.select('circle').style('fill', (d) ->
            if d.name == 'backbone'
              'black'
            else if d.pno < 0 or d.pno >= 10 or not d.pno?
              'darkgray'
            else
              colors(d.pno)
          )
          node.select('text.node_icon').text((d) ->
            if (d.type == 'host')
              '💻'
            else if (d.type == 'switch')
              '🌎'
            else if (d.type == 'backbone')
              '☁'
          )
          node.select('text.node_name').text( (d) ->
            if (d.type == 'backbone')
              ''
            else
              d.name
          )

    nodes.exit()
      .transition()
        .duration(750)
        .remove()
        .call (sel) ->
          sel.each (d) ->
            node = d3.select(this)
            node.selectAll('circle').transition()
              .duration(750)
              .attr('r', 0)
              .remove()
            node.selectAll('text').transition()
              .duration(250)
              .style('opacity', 0)
              .remove()

  _updateLink: ->
    layout_links = @forceLayout.links()

    links = @vis.selectAll(".link").data(layout_links)

    links.enter().insert('line', '.node')
      .on('mousedown', @linkMouseGestureHandler.mouseDown.bind(@linkMouseGestureHandler))
      .on('mouseup', @linkMouseGestureHandler.mouseUp.bind(@linkMouseGestureHandler))
      .attr('class', 'link')
      .attr('x1', (d) => @_findNodeByName(d.source).x)
      .attr('y1', (d) => @_findNodeByName(d.source).y)
      .attr('x2', (d) => @_findNodeByName(d.target).x)
      .attr('y2', (d) => @_findNodeByName(d.target).y)
      .call (sel) =>
        sel.each (d) =>
          d.xcenter = (@_findNodeByName(d.source).x + @_findNodeByName(d.target).x) / 2
          d.ycenter = (@_findNodeByName(d.source).y + @_findNodeByName(d.target).y) / 2

    links.exit().transition()
      .attr('x1', (d) => d.xcenter)
      .attr('y1', (d) => d.ycenter)
      .attr('x2', (d) => d.xcenter)
      .attr('y2', (d) => d.ycenter)
      .remove()

  _findNodeByName: (name) ->
    @forceLayout.nodes().filter((n) ->
      n.name == name
    )[0]

  _findLinkByPair: (link_src, link_dst) ->
    @forceLayout.links().filter((n) ->
      n.source == link_src and n.target == link_dst
    )[0]

  _nextEmptyNodeName: (prefix) ->
    i = 1
    while @forceLayout.nodes().some( (e) -> e.name == "#{prefix}#{i}" )
      i = i + 1
    "#{prefix}#{i}"

