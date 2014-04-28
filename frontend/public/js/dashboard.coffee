class window.OnenetDeployDashboard
  constructor: (data, deploy_id) ->
    @deploy_id = deploy_id
    @tmrUpdate = setInterval =>
      @update()
    , 500
    @logs = []
    @lastID = -1

    $('.panel-logs').empty()
    $('.nav-logs .to-be-removed').remove()
    $('.ds-exp-status').html('running').removeClass('label-success').addClass('label-warning')

    @switchHost('all')

    $('.nav-logs').on 'click', 'li a', (e) =>
      @switchHost($(e.target).attr('data-host'))

    $('#onenet-deploy-status').modal()
    $('#onenet-deploy-status').modal('show')
    $('#onenet-deploy-status').on('hide.bs.modal', => clearInterval(@tmrUpdate))

  update: =>
    $.get "/status/#{@deploy_id}", (data) =>
      $('.ds-exp-last-update').html(new Date().toString())
      $('.ds-exp-status').html(data.status)

      if (data.status == 'done')
        $('.ds-exp-status').removeClass('label-warning').addClass('label-success')
        clearInterval(@tmrUpdate)

      logs = data.logs.filter((l) => l.id > @lastID)
      logs.forEach (l) ->
        e = $(Mustache.render(OnenetTemplates.log_entry, l)).hide()
        $('.panel-logs').append(e)
      @switchHost(@selectedHost)
      @updateHosts()
      @logs = @logs.concat(logs)

      if (logs.length > 0)
        @lastID = Math.max.apply(Math, logs.map((l) -> l.id))
      console.log("@lastID = #{@lastID}")
    , 'json'

  switchHost: (host) ->
    @selectedHost = host
    $('.nav-logs li').removeClass('active')
    $(".nav-logs li a[data-host='#{host}']").parent('li').addClass('active')
    if (host != 'all')
      $(".panel-logs .log-entry[data-host!='#{host}']").hide()
      $(".panel-logs .log-entry[data-host='#{host}']").show()
      $(".panel-logs .log-entry .tag").hide()
    else
      $(".panel-logs .log-entry").show()
      $(".panel-logs .log-entry .tag").show()
    $('.panel-logs').scrollTop($('.panel-logs')[0].scrollHeight)

  updateHosts: ->
    hosts = $.unique(@logs.map((l) -> l.host))
    hosts.sort().forEach (h) ->
      if $(".nav-logs li a[data-host='#{h}']").size() == 0
        $('.nav-logs').append($("<li class='to-be-removed'><a href='#' data-host='#{h}'>#{h}</li>"))

  _colorizeLabel: (e, status) ->
    e.removeClass('label-warning').removeClass('label-success')
    if (status == 'up' or status == 'done')
      e.addClass('label-success')
    else
      e.addClass('label-warning')

  _makeNode: (node) ->
    $("<span/>")
      .addClass("label")
      .addClass("label-warning")
      .attr("data-node-name", node.name)
      .html(node.name)

  _makeSwitch: (node) ->
    $("<span/>")
      .addClass("label")
      .addClass("label-warning")
      .attr("data-node-name", node.name)
      .html(node.name)


